import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:wallet_test/features/auth/auth_repository.dart';

class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier({
    required IAuthRepository auth,
    required GoRouter router,
  }) : _router = router {
    _subscription = auth.onAuthChanged.listen((_) {
      if (_isDisposed) {
        return;
      }

      _router.refresh();
    });
  }

  final GoRouter _router;

  late final StreamSubscription<bool> _subscription;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_subscription.cancel());

    super.dispose();
  }
}
