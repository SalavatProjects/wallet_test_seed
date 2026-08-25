import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_test/core/dev_stubs/in_memory_transfer_repository.dart';
import 'package:wallet_test/core/errors/app_exception.dart';
import 'package:wallet_test/core/network/api_client.dart';
import 'package:wallet_test/features/transfers/transfer.dart';
import 'package:wallet_test/features/transfers/transfer_status_sync_service.dart';

import '../../fakes/fake_http_client_adapter.dart';

const _transfer = Transfer(
  id: 'transfer_1',
  network: 'Ethereum',
  txHash: '0x1234abcd',
);

class _TestFixture {
  _TestFixture(List<HttpOutcome> outcomes) {
    dio = Dio();
    adapter = FakeHttpClientAdapter(outcomes);
    dio.httpClientAdapter = adapter;

    repository = InMemoryTransferRepository();

    service = TransferStatusSyncService(
      api: ApiClient(dio: dio),
      repository: repository,
    );
  }

  late final Dio dio;
  late final FakeHttpClientAdapter adapter;
  late final InMemoryTransferRepository repository;
  late final TransferStatusSyncService service;

  void dispose() {
    dio.close(force: true);
  }
}

Matcher _isTransferSyncException(String code) {
  return isA<TransferSyncException>().having(
    (exception) => exception.code,
    'code',
    code,
  );
}

void main() {
  group('TransferStatusSyncService', () {
    test('retries 429 and returns confirmed after successful response',
        () async {
      final fixture = _TestFixture([
        HttpOutcome(429),
        HttpOutcome(
          200,
          body: {'status': 'confirmed'},
        ),
      ]);
      addTearDown(fixture.dispose);

      final result = await fixture.service.sync(_transfer);

      expect(result, TransferStatus.confirmed);
      expect(fixture.adapter.calls, hasLength(2));

      expect(fixture.repository.applyCalls, 1);
      expect(
        fixture.repository.lastStatus,
        TransferStatus.confirmed,
      );
      expect(
        fixture.repository.lastTransfer,
        same(_transfer),
      );
      expect(
        fixture.repository.lastUpdatedAt,
        isNotNull,
      );
    });

    test('does not retry 401 and throws unauthorized', () async {
      final fixture = _TestFixture([
        HttpOutcome(401),
      ]);
      addTearDown(fixture.dispose);

      await expectLater(
        fixture.service.sync(_transfer),
        throwsA(
          _isTransferSyncException('unauthorized'),
        ),
      );

      expect(fixture.adapter.calls, hasLength(1));
      expect(fixture.repository.applyCalls, 0);
    });

    test('does not retry 500 and throws internal', () async {
      final fixture = _TestFixture([
        HttpOutcome(500),
      ]);
      addTearDown(fixture.dispose);

      await expectLater(
        fixture.service.sync(_transfer),
        throwsA(
          _isTransferSyncException('internal'),
        ),
      );

      expect(fixture.adapter.calls, hasLength(1));
      expect(fixture.repository.applyCalls, 0);
    });

    test('stops after three 429 responses and throws rateLimited', () async {
      final fixture = _TestFixture([
        HttpOutcome(429),
        HttpOutcome(429),
        HttpOutcome(429),
      ]);
      addTearDown(fixture.dispose);

      await expectLater(
        fixture.service.sync(_transfer),
        throwsA(
          _isTransferSyncException('rateLimited'),
        ),
      );

      expect(fixture.adapter.calls, hasLength(3));
      expect(fixture.repository.applyCalls, 0);
    });

    test('throws localPersistenceFailed when repository fails', () async {
      final fixture = _TestFixture([
        HttpOutcome(
          200,
          body: {'status': 'confirmed'},
        ),
      ]);
      addTearDown(fixture.dispose);

      fixture.repository.shouldFail = true;

      await expectLater(
        fixture.service.sync(_transfer),
        throwsA(
          _isTransferSyncException('localPersistenceFailed'),
        ),
      );

      expect(fixture.adapter.calls, hasLength(1));
      expect(fixture.repository.applyCalls, 1);
    });

    test('sends GET request to the expected path', () async {
      final fixture = _TestFixture([
        HttpOutcome(
          200,
          body: {'status': 'confirmed'},
        ),
      ]);
      addTearDown(fixture.dispose);

      await fixture.service.sync(_transfer);

      final call = fixture.adapter.calls.single;

      expect(call.method, 'GET');
      expect(
        call.path,
        '/v1/transfers/0x1234abcd/status',
      );
    });

    test('lowercases network but preserves txHash in Idempotency-Key',
        () async {
      final fixture = _TestFixture([
        HttpOutcome(
          200,
          body: {'status': 'confirmed'},
        ),
      ]);
      addTearDown(fixture.dispose);

      const mixedCaseTransfer = Transfer(
        id: 'transfer_2',
        network: 'EtHeReUm',
        txHash: '0xAbCd1234',
      );

      await fixture.service.sync(mixedCaseTransfer);

      final call = fixture.adapter.calls.single;

      expect(
        call.headers['Idempotency-Key'],
        'ethereum:0xAbCd1234',
      );
    });

    test('uses the same Idempotency-Key for every retry', () async {
      final fixture = _TestFixture([
        HttpOutcome(429),
        HttpOutcome(
          200,
          body: {'status': 'confirmed'},
        ),
      ]);
      addTearDown(fixture.dispose);

      await fixture.service.sync(_transfer);

      expect(fixture.adapter.calls, hasLength(2));

      for (final call in fixture.adapter.calls) {
        expect(
          call.headers['Idempotency-Key'],
          'ethereum:0x1234abcd',
        );
      }
    });

    test('throws CancelException without HTTP or database calls', () async {
      final fixture = _TestFixture([
        HttpOutcome(
          200,
          body: {'status': 'confirmed'},
        ),
      ]);
      addTearDown(fixture.dispose);

      final cancelToken = CancelToken();
      cancelToken.cancel();

      await expectLater(
        fixture.service.sync(
          _transfer,
          cancelToken: cancelToken,
        ),
        throwsA(isA<CancelException>()),
      );

      expect(fixture.adapter.calls, isEmpty);
      expect(fixture.repository.applyCalls, 0);
    });
  });
}
