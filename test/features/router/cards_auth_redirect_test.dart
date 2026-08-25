import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_test/features/router/cards_auth_redirect.dart';

void main() {
  group('cardsAuthRedirect', () {
    test('redirects unauthenticated cards deep link to onboarding', () {
      final result = cardsAuthRedirect(
        Uri.parse('/cards/card_1/issue?step=2'),
        false,
      );

      expect(
        result,
        '/onboarding?next=%2Fcards%2Fcard_1%2Fissue%3Fstep%3D2',
      );
    });

    test('returns to cards deep link after authentication', () {
      final result = cardsAuthRedirect(
        Uri.parse(
          '/onboarding'
          '?next=%2Fcards%2Fcard_1%2Fissue%3Fstep%3D2',
        ),
        true,
      );

      expect(
        result,
        '/cards/card_1/issue?step=2',
      );
    });

    test('rejects an external next URL', () {
      final result = cardsAuthRedirect(
        Uri.parse(
          '/onboarding'
          '?next=https%3A%2F%2Fevil.com',
        ),
        true,
      );

      expect(result, '/cards');
    });

    test('does not redirect unauthenticated onboarding page', () {
      final result = cardsAuthRedirect(
        Uri.parse('/onboarding'),
        false,
      );

      expect(result, isNull);
    });

    test('does not redirect authenticated cards page', () {
      final result = cardsAuthRedirect(
        Uri.parse('/cards'),
        true,
      );

      expect(result, isNull);
    });

    test('redirects authenticated onboarding without next to cards', () {
      final result = cardsAuthRedirect(
        Uri.parse('/onboarding'),
        true,
      );

      expect(result, '/cards');
    });

    test('rejects a protocol-relative external URL', () {
      final result = cardsAuthRedirect(
        Uri.parse(
          '/onboarding'
          '?next=%2F%2Fevil.com%2Fcards',
        ),
        true,
      );

      expect(result, '/cards');
    });

    test('rejects a non-cards internal next location', () {
      final result = cardsAuthRedirect(
        Uri.parse(
          '/onboarding'
          '?next=%2Fwallet',
        ),
        true,
      );

      expect(result, '/cards');
    });

    test('does not protect a path that only starts similarly', () {
      final result = cardsAuthRedirect(
        Uri.parse('/cards-other'),
        false,
      );

      expect(result, isNull);
    });

    test('preserves query parameters in the cards deep link', () {
      final result = cardsAuthRedirect(
        Uri.parse('/cards/card_1/issue?step=2&source=notification'),
        false,
      );

      expect(
        result,
        '/onboarding'
        '?next=%2Fcards%2Fcard_1%2Fissue'
        '%3Fstep%3D2%26source%3Dnotification',
      );
    });
  });
}
