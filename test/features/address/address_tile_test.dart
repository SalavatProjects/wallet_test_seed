import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:wallet_test/core/dev_stubs/in_memory_address_repository.dart';
import 'package:wallet_test/core/theme/app_tokens.dart';
import 'package:wallet_test/features/address/address_repository.dart';
import 'package:wallet_test/features/address/address_tile.dart';
import 'package:wallet_test/features/address/address_tile_bloc.dart';

import '../../helpers/test_get_it.dart';

const _address = '0x1234567890abcdef1234567890abcdef12345678';
const _network = 'Ethereum';

class _TrackingAddressTileBloc extends AddressTileBloc {
  _TrackingAddressTileBloc({
    required super.repository,
  });

  int closeCalls = 0;

  @override
  Future<void> close() async {
    closeCalls++;
    return await super.close();
  }
}

Future<void> _pumpAddressTile(
  WidgetTester tester, {
  double textScaleFactor = 1,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScaleFactor),
        ),
        child: const Scaffold(
          body: AddressTile(
            address: _address,
            network: _network,
          ),
        ),
      ),
    ),
  );
}

Future<void> _tapCopyAndWait(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.copy));

  // Запускаем обработчик события BLoC.
  await tester.pump();

  // InMemoryAddressRepository завершает операцию через 30 ms.
  await tester.pump(const Duration(milliseconds: 31));

  // Перестраиваем виджет после изменения состояния.
  await tester.pump();
}

Future<void> _removeAddressTile(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  group('AddressTile', () {
    testWidgets('renders network, formatted address and copy icon', (
      tester,
    ) async {
      await testWithGetIt(() async {
        await _pumpAddressTile(tester);

        expect(find.byType(AddressTile), findsOneWidget);
        expect(find.text(_network), findsOneWidget);
        expect(find.text('0x123456…5678'), findsOneWidget);
        expect(find.byIcon(Icons.copy), findsOneWidget);

        final icon = tester.widget<Icon>(find.byIcon(Icons.copy));
        expect(icon.color, AppTokens.textSecondary);

        await _removeAddressTile(tester);
      });
    });

    testWidgets('does not overflow at text scale 2.0', (tester) async {
      await testWithGetIt(() async {
        await _pumpAddressTile(
          tester,
          textScaleFactor: 2,
        );

        expect(find.text('0x1234…5678'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await _removeAddressTile(tester);
      });
    });

    testWidgets('calls copyAddress when copy button is tapped', (
      tester,
    ) async {
      await testWithGetIt(() async {
        final repository =
            GetIt.instance<IAddressRepository>() as InMemoryAddressRepository;

        await _pumpAddressTile(tester);
        await _tapCopyAndWait(tester);

        expect(repository.copyCalls, 1);
        expect(repository.lastAddress, _address);

        await _removeAddressTile(tester);
      });
    });

    testWidgets('shows copied state after successful copy', (
      tester,
    ) async {
      await testWithGetIt(() async {
        await _pumpAddressTile(tester);
        await _tapCopyAndWait(tester);

        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(find.byIcon(Icons.copy), findsNothing);

        final icon = tester.widget<Icon>(find.byIcon(Icons.check));
        expect(icon.color, AppTokens.success);

        await _removeAddressTile(tester);
      });
    });

    testWidgets('shows error state when copying fails', (
      tester,
    ) async {
      await testWithGetIt(() async {
        final repository =
            GetIt.instance<IAddressRepository>() as InMemoryAddressRepository;

        repository.shouldFail = true;

        await _pumpAddressTile(tester);
        await _tapCopyAndWait(tester);

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.byIcon(Icons.copy), findsNothing);

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.error_outline),
        );
        expect(icon.color, AppTokens.danger);

        await _removeAddressTile(tester);
      });
    });

    testWidgets('resets copied state after 1500 ms', (tester) async {
      await testWithGetIt(() async {
        await _pumpAddressTile(tester);
        await _tapCopyAndWait(tester);

        expect(find.byIcon(Icons.check), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 1500));
        await tester.pump();

        expect(find.byIcon(Icons.copy), findsOneWidget);
        expect(find.byIcon(Icons.check), findsNothing);

        await _removeAddressTile(tester);
      });
    });

    testWidgets('closes BLoC when widget is disposed', (tester) async {
      await testWithGetIt(() async {
        final getIt = GetIt.instance;
        final repository = getIt<IAddressRepository>();

        final bloc = _TrackingAddressTileBloc(
          repository: repository,
        );

        await getIt.unregister<AddressTileBloc>();
        getIt.registerSingleton<AddressTileBloc>(bloc);

        await _pumpAddressTile(tester);

        expect(bloc.closeCalls, 0);

        await _removeAddressTile(tester);

        expect(bloc.closeCalls, 1);
      });
    });
  });
}
