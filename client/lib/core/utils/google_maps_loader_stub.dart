import 'dart:async';

Future<bool> ensureGoogleMapsLoaded({
  Duration timeout = const Duration(seconds: 2),
}) async {
  // Non-web platforms: use the embedded map directly (native), or fallback.
  return false;
}

