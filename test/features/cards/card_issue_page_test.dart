import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:wallet_test/core/dev_stubs/dev_card_issuer.dart';
import 'package:wallet_test/features/cards/card_issue_bloc.dart';
import 'package:wallet_test/features/cards/card_issue_page.dart';
import 'package:wallet_test/features/cards/card_issuer.dart';

import '../../helpers/test_get_it.dart';

class _TrackingCardIssueBloc extends CardIssueBloc {
  _TrackingCardIssueBloc({
    required super.issuer,
  });

  int closeCalls = 0;

  @override
  Future<void> close() {
    closeCalls++;
    return super.close();
  }
}

Future<void> _pumpCardIssuePage(WidgetTester tester) {
  return tester.pumpWidget(
    const MaterialApp(
      home: CardIssuePage(
        cardId: 'card_1',
      ),
    ),
  );
}

Future<void> _removeCardIssuePage(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  group('CardIssuePage', () {
    testWidgets('renders issue card button', (tester) async {
      await testWithGetIt(() async {
        await _pumpCardIssuePage(tester);

        expect(find.byType(CardIssuePage), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.text('Issue card'), findsOneWidget);

        await _removeCardIssuePage(tester);
      });
    });

    testWidgets('gets CardIssueBloc from GetIt and closes it on dispose', (
      tester,
    ) async {
      await testWithGetIt(() async {
        final getIt = GetIt.instance;
        final issuer = getIt<ICardIssuer>();

        final bloc = _TrackingCardIssueBloc(
          issuer: issuer,
        );

        await getIt.unregister<CardIssueBloc>();
        getIt.registerSingleton<CardIssueBloc>(bloc);

        await _pumpCardIssuePage(tester);

        expect(bloc.closeCalls, 0);

        await _removeCardIssuePage(tester);

        expect(bloc.closeCalls, 1);
      });
    });

    testWidgets('gets ICardIssuer from GetIt and cancels exactly once', (
      tester,
    ) async {
      await testWithGetIt(() async {
        final issuer = GetIt.instance<ICardIssuer>() as DevCardIssuer;

        expect(issuer.cancelCalls, 0);

        await _pumpCardIssuePage(tester);
        await _removeCardIssuePage(tester);

        expect(issuer.cancelCalls, 1);

        // Повторная перестройка не должна повторно вызывать dispose страницы.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        expect(issuer.cancelCalls, 1);
      });
    });

    testWidgets('uses GetIt dependencies when issue button is tapped', (
      tester,
    ) async {
      await testWithGetIt(() async {
        final issuer = GetIt.instance<ICardIssuer>() as DevCardIssuer;

        await _pumpCardIssuePage(tester);

        await tester.tap(find.text('Issue card'));
        await tester.pump();

        // DevCardIssuer выполняет операцию через 80 ms.
        await tester.pump(const Duration(milliseconds: 81));
        await tester.pump();

        expect(issuer.cancelCalls, 0);

        await _removeCardIssuePage(tester);

        expect(issuer.cancelCalls, 1);
      });
    });
  });
}
