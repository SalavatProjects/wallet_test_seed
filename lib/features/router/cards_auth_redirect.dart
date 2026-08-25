String? cardsAuthRedirect(
  Uri uri,
  bool isAuthed,
) {
  final isCardsLocation = _isCardsPath(uri.path);

  if (!isAuthed) {
    if (uri.path == '/onboarding') {
      return null;
    }

    if (isCardsLocation) {
      final encodedLocation = Uri.encodeComponent(
        uri.toString(),
      );

      return '/onboarding?next=$encodedLocation';
    }

    return null;
  }

  if (uri.path == '/onboarding') {
    final String? next;

    try {
      next = uri.queryParameters['next'];
    } on FormatException {
      return '/cards';
    }

    if (next == null || next.isEmpty) {
      return '/cards';
    }

    final nextUri = Uri.tryParse(next);

    if (nextUri == null || !_isSafeCardsLocation(next, nextUri)) {
      return '/cards';
    }

    return next;
  }

  return null;
}

bool _isSafeCardsLocation(
  String location,
  Uri uri,
) {
  if (!location.startsWith('/')) {
    return false;
  }

  if (uri.hasScheme || uri.hasAuthority || uri.host.isNotEmpty) {
    return false;
  }

  return _isCardsPath(uri.path);
}

bool _isCardsPath(String path) {
  return path == '/cards' || path.startsWith('/cards/');
}
