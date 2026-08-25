import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_test/features/wallet/wallet_page.dart';

import 'package:wallet_test/main.dart';
import 'helpers/test_get_it.dart';

void main() {
  testWidgets('app renders wallet page', (WidgetTester tester) async {
    await testWithGetIt(() async {
      await tester.pumpWidget(const WalletApp());
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(WalletPage), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
