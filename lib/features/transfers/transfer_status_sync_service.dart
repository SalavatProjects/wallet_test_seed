import 'package:dio/dio.dart';

import 'package:wallet_test/core/errors/app_exception.dart';
import 'package:wallet_test/core/network/api_client.dart';
import 'package:wallet_test/features/transfers/transfer.dart';
import 'package:wallet_test/features/transfers/transfer_repository.dart';

class TransferStatusSyncService {
  TransferStatusSyncService({
    required ApiClient api,
    required ITransferRepository repository,
  })  : _api = api,
        _repository = repository;

  static const List<Duration> _retryDelays = [
    Duration(milliseconds: 200),
    Duration(milliseconds: 500),
  ];

  static const Set<int> _retryableStatusCodes = {
    408,
    429,
    503,
  };

  final ApiClient _api;
  final ITransferRepository _repository;

  Future<TransferStatus> sync(
    Transfer transfer, {
    CancelToken? cancelToken,
  }) async {
    final idempotencyKey =
        '${transfer.network.toLowerCase()}:${transfer.txHash}';

    final response = await _requestWithRetry(
      transfer: transfer,
      idempotencyKey: idempotencyKey,
      cancelToken: cancelToken,
    );

    _throwIfCancelled(cancelToken);

    final responseData = response.data;
    final rawStatus =
        responseData is Map<String, dynamic> ? responseData['status'] : null;

    final status = TransferStatus.fromName(
      rawStatus is String ? rawStatus : 'unknown',
    );

    try {
      await _repository.applyStatus(
        transfer,
        status,
        DateTime.now(),
      );
    } catch (_) {
      throw const TransferSyncException(
        code: 'localPersistenceFailed',
      );
    }

    return status;
  }

  Future<Response<dynamic>> _requestWithRetry({
    required Transfer transfer,
    required String idempotencyKey,
    CancelToken? cancelToken,
  }) async {
    var failedAttemptIndex = 0;

    while (true) {
      _throwIfCancelled(cancelToken);

      try {
        return await _api.dio.get<dynamic>(
          '/v1/transfers/${transfer.txHash}/status',
          options: Options(
            headers: {
              'Idempotency-Key': idempotencyKey,
            },
          ),
          cancelToken: cancelToken,
        );
      } on DioException catch (exception) {
        if (exception.type == DioExceptionType.cancel ||
            cancelToken?.isCancelled == true) {
          throw const CancelException();
        }

        final hasAnotherAttempt = failedAttemptIndex < _retryDelays.length;

        if (!_shouldRetry(exception) || !hasAnotherAttempt) {
          throw _mapDioException(exception);
        }

        final delay = _retryDelays[failedAttemptIndex];
        failedAttemptIndex++;

        await _waitBeforeRetry(
          delay,
          cancelToken,
        );
      }
    }
  }

  bool _shouldRetry(DioException exception) {
    if (_isRetryableNetworkError(exception.type)) {
      return true;
    }

    if (exception.type == DioExceptionType.badResponse) {
      return _retryableStatusCodes.contains(
        exception.response?.statusCode,
      );
    }

    return false;
  }

  bool _isRetryableNetworkError(DioExceptionType type) {
    return switch (type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.connectionError ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        true,
      _ => false,
    };
  }

  TransferSyncException _mapDioException(
    DioException exception,
  ) {
    if (_isRetryableNetworkError(exception.type)) {
      return const TransferSyncException(
        code: 'network',
      );
    }

    final statusCode = exception.response?.statusCode;

    switch (statusCode) {
      case 401:
        return const TransferSyncException(
          code: 'unauthorized',
        );

      case 404:
        return const TransferSyncException(
          code: 'notFound',
        );

      case 409:
        return const TransferSyncException(
          code: 'conflict',
        );

      case 408:
      case 429:
        return const TransferSyncException(
          code: 'rateLimited',
        );

      case 503:
        return const TransferSyncException(
          code: 'serverUnavailable',
        );

      case 500:
        return const TransferSyncException(
          code: 'internal',
        );

      default:
        return const TransferSyncException(
          code: 'internal',
        );
    }
  }

  Future<void> _waitBeforeRetry(
    Duration delay,
    CancelToken? cancelToken,
  ) async {
    _throwIfCancelled(cancelToken);

    if (cancelToken == null) {
      await Future<void>.delayed(delay);
      return;
    }

    await Future.any<void>([
      Future<void>.delayed(delay),
      cancelToken.whenCancel.then<void>((_) {}),
    ]);

    _throwIfCancelled(cancelToken);
  }

  void _throwIfCancelled(CancelToken? cancelToken) {
    if (cancelToken?.isCancelled == true) {
      throw const CancelException();
    }
  }
}
