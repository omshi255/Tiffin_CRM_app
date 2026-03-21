import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe' show JSObjectUnsafeUtilExtension;
import 'package:web/web.dart' as web;

// ─── JS Interop declarations ──────────────────────────────────────────────────
@JS('google')
external JSObject? get _google;

@JS('google.maps')
external JSObject? get _googleMaps;

@JS('__TiffinGmapsKey')
external JSString? get _gmapsKey;

// ─── Helpers ──────────────────────────────────────────────────────────────────
bool _isGoogleMapsAvailable() {
  try {
    return _google != null && _googleMaps != null;
  } catch (_) {
    return false;
  }
}

String? _readMapsKey() {
  try {
    final key = _gmapsKey?.toDart ?? '';
    if (key.isEmpty || key == 'YOUR_GOOGLE_MAPS_API_KEY') return null;
    return key;
  } catch (_) {
    return null;
  }
}

// ─── Main loader ──────────────────────────────────────────────────────────────
Future<bool> ensureGoogleMapsLoaded({
  Duration timeout = const Duration(seconds: 8),
}) async {
  if (_isGoogleMapsAvailable()) return true;

  final key = _readMapsKey();
  if (key == null) return false;

  const scriptId = 'tiffin-google-maps-js';
  final desiredSrc =
      'https://maps.googleapis.com/maps/api/js?key=${Uri.encodeComponent(key)}';

  // Debug markers visible in browser console
  _setWindowProp('__TiffinGmapsLoaderCalled', true.toJS);
  _setWindowProp('__TiffinGmapsDesiredSrc', desiredSrc.toJS);

  final existing = web.document.getElementById(scriptId);
  final existingSrc = existing?.getAttribute('src') ?? '';

  if (existing == null || existingSrc != desiredSrc) {
    existing?.remove();

    final script = web.document.createElement('script') as web.HTMLScriptElement
      ..id = scriptId
      ..type = 'text/javascript'
      ..src = desiredSrc;

    final head = web.document.head;
    final body = web.document.body;

    if (head != null) {
      head.append(script);
    } else if (body != null) {
      body.append(script);
    } else {
      web.document.documentElement?.append(script);
    }

    _setWindowProp('__TiffinGmapsInjected', true.toJS);
  }

  // Poll until google.maps is available or timeout
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (_isGoogleMapsAvailable()) return true;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  return _isGoogleMapsAvailable();
}

// ─── Helper: set property on window object ────────────────────────────────────
@JS('Object.defineProperty')
// ignore: unused_element
external void _defineProperty(JSObject obj, JSString prop, JSObject descriptor);

void _setWindowProp(String name, JSAny value) {
  try {
    (web.window as JSObject).setProperty(name.toJS, value);
  } catch (_) {}
}
