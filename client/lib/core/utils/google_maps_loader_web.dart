import 'dart:async';
import 'dart:html' as html;

bool _isGoogleMapsAvailable() {
  final google = (html.window as dynamic)['google'];
  if (google == null) return false;
  final maps = (google as dynamic)['maps'];
  return maps != null;
}

String? _readMapsKey() {
  final raw = (html.window as dynamic)['__TiffinGmapsKey'];
  final key = raw?.toString() ?? '';
  if (key.isEmpty || key == 'YOUR_GOOGLE_MAPS_API_KEY') return null;
  return key;
}

Future<bool> ensureGoogleMapsLoaded({
  Duration timeout = const Duration(seconds: 8),
}) async {
  if (_isGoogleMapsAvailable()) return true;

  final key = _readMapsKey();
  if (key == null) return false;

  const scriptId = 'tiffin-google-maps-js';
  final existing = html.document.getElementById(scriptId);
  final desiredSrc =
      'https://maps.googleapis.com/maps/api/js?key=${Uri.encodeComponent(key)}';

  // Debug helpers to verify loader execution in the browser console.
  (html.window as dynamic)['__TiffinGmapsLoaderCalled'] = true;
  (html.window as dynamic)['__TiffinGmapsDesiredSrc'] = desiredSrc;

  if (existing == null || existing.getAttribute('src') != desiredSrc) {
    existing?.remove();
    final script = html.ScriptElement()
      ..id = scriptId
      ..type = 'text/javascript'
      ..src = desiredSrc;
    // Some embedded runners may not expose `head` immediately; append to the
    // first available container.
    if (html.document.head != null) {
      html.document.head!.append(script);
    } else if (html.document.body != null) {
      html.document.body!.append(script);
    } else {
      html.document.documentElement?.append(script);
    }

    // Mark that we attempted script injection.
    (html.window as dynamic)['__TiffinGmapsInjected'] = true;
  }

  // Wait for `window.google.maps` to become available.
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (_isGoogleMapsAvailable()) return true;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  return _isGoogleMapsAvailable();
}

