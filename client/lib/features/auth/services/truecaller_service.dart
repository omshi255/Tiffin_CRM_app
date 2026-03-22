// Truecaller OAuth integration (Android only). iOS never initializes the SDK.
//
// The official plugin exposes [TcSdk]. This file wraps it in [TruecallerService]
// and exposes [TruecallerSdk] with an `isUsable` getter (alias for OAuth flow support).

import 'dart:async';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:truecaller_sdk/truecaller_sdk.dart';

/// Outcome of attempting Truecaller OAuth (PKCE) sign-in.
///
/// On [ok] == true, [authorizationCode] must be sent to your backend together with
/// [codeVerifier] so the server can exchange them for a Truecaller access token.
/// The API placeholder names this value `accessToken` in JSON — see [AuthApi.verifyTruecallerToken].
class TruecallerSignInOutcome {
  const TruecallerSignInOutcome._({
    required this.ok,
    this.authorizationCode,
    this.codeVerifier,
    this.oauthState,
    this.errorMessage,
    this.requiresOtpFallback = false,
  });

  final bool ok;

  /// OAuth authorization code (not the final access token until backend exchanges it).
  final String? authorizationCode;
  final String? codeVerifier;
  final String? oauthState;
  final String? errorMessage;

  /// True when user must continue with phone OTP (dismissed UI, non-TC user path, etc.).
  final bool requiresOtpFallback;

  factory TruecallerSignInOutcome.success({
    required String authorizationCode,
    required String codeVerifier,
    required String oauthState,
  }) {
    return TruecallerSignInOutcome._(
      ok: true,
      authorizationCode: authorizationCode,
      codeVerifier: codeVerifier,
      oauthState: oauthState,
    );
  }

  factory TruecallerSignInOutcome.failure(String message, {bool otpFallback = false}) {
    return TruecallerSignInOutcome._(
      ok: false,
      errorMessage: message,
      requiresOtpFallback: otpFallback,
    );
  }
}

/// Thin naming layer matching common `TruecallerSdk.isUsable` examples — delegates to [TcSdk.isOAuthFlowUsable].
abstract final class TruecallerSdk {
  /// Whether Truecaller OAuth can be shown on this device (requires [TruecallerService.initialize] first).
  static Future<bool> get isUsable async => TruecallerService.instance.isOAuthFlowUsable;
}

bool _isAndroidDevice() =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Handles SDK init, usability checks, OAuth PKCE setup, and [TcSdk.streamCallbackData] listening.
final class TruecallerService {
  TruecallerService._();
  static final TruecallerService instance = TruecallerService._();

  bool _initialized = false;
  StreamSubscription<TcSdkCallback>? _callbackSubscription;

  /// Step 1: Call once on Android before [isOAuthFlowUsable] / [signInWithTruecaller].
  /// Uses [TcSdkOptions.OPTION_VERIFY_ONLY_TC_USERS] so non-Truecaller users fall back to OTP in-app.
  Future<void> initialize() async {
    if (!_isAndroidDevice()) return;
    if (_initialized) return;

    // Initialize native SDK — consent UI is customized via defaults in plugin.
    await TcSdk.initializeSDK(
      sdkOption: TcSdkOptions.OPTION_VERIFY_ONLY_TC_USERS,
    );
    _initialized = true;
  }

  /// Whether the device can run the OAuth flow (Truecaller installed & eligible).
  Future<bool> get isOAuthFlowUsable async {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (!_initialized) await initialize();
    final dynamic usable = await TcSdk.isOAuthFlowUsable;
    return usable == true;
  }

  /// Cancels the active callback subscription (e.g. when leaving the login screen).
  void disposeCallbackSubscription() {
    unawaited(_callbackSubscription?.cancel());
    _callbackSubscription = null;
  }

  /// Full OAuth flow: PKCE + consent sheet + stream handling.
  ///
  /// Returns [TruecallerSignInOutcome.failure] with [TruecallerSignInOutcome.requiresOtpFallback] for
  /// user dismiss, missing app, or [TcSdkCallbackResult.verification] (manual path — use OTP).
  Future<TruecallerSignInOutcome> signInWithTruecaller() async {
    if (!_isAndroidDevice()) {
      return TruecallerSignInOutcome.failure(
        'Truecaller is only available on Android',
        otpFallback: true,
      );
    }
    if (!_initialized) await initialize();

    final usable = await isOAuthFlowUsable;
    if (!usable) {
      return TruecallerSignInOutcome.failure(
        'Truecaller is not available on this device',
        otpFallback: true,
      );
    }

    // 3.1 Unique OAuth state (CSRF protection) — store and compare in success callback.
    final oauthState = '${DateTime.now().microsecondsSinceEpoch}_${_randSuffix()}';
    await TcSdk.setOAuthState(oauthState);

    // 3.2 Scopes requested from Truecaller.
    await TcSdk.setOAuthScopes(['profile', 'phone', 'openid']);

    // 3.3–3.4 PKCE: verifier + challenge.
    final dynamic verifierRaw = await TcSdk.generateRandomCodeVerifier;
    if (verifierRaw is! String || verifierRaw.isEmpty) {
      return TruecallerSignInOutcome.failure(
        'Could not create login challenge',
        otpFallback: true,
      );
    }
    final codeVerifier = verifierRaw;

    final dynamic challengeRaw = await TcSdk.generateCodeChallenge(codeVerifier);
    if (challengeRaw == null || challengeRaw is! String || challengeRaw.isEmpty) {
      return TruecallerSignInOutcome.failure(
        'This device cannot complete Truecaller login',
        otpFallback: true,
      );
    }
    await TcSdk.setCodeChallenge(challengeRaw);

    // Listen before opening the consent UI so we do not miss events.
    final completer = Completer<TruecallerSignInOutcome>();
    await _callbackSubscription?.cancel();

    _callbackSubscription = TcSdk.streamCallbackData.listen(
      (TcSdkCallback cb) {
        void completeOnce(TruecallerSignInOutcome o) {
          if (completer.isCompleted) return;
          completer.complete(o);
          unawaited(_callbackSubscription?.cancel());
          _callbackSubscription = null;
        }

        // OAuth consent flow only — ignore non-OAuth callbacks (missed call / OTP paths).
        if (cb.result == TcSdkCallbackResult.success) {
          final data = cb.tcOAuthData;
          if (data == null) {
            completeOnce(
              TruecallerSignInOutcome.failure('Empty Truecaller response', otpFallback: true),
            );
            return;
          }
          if (data.state != oauthState) {
            completeOnce(
              TruecallerSignInOutcome.failure('Security check failed (state mismatch)', otpFallback: true),
            );
            return;
          }
          completeOnce(
            TruecallerSignInOutcome.success(
              authorizationCode: data.authorizationCode,
              codeVerifier: codeVerifier,
              oauthState: oauthState,
            ),
          );
          return;
        }
        if (cb.result == TcSdkCallbackResult.failure) {
          final code = cb.error?.code;
          final msg = cb.error?.message ?? 'Truecaller login failed';
          completeOnce(
            TruecallerSignInOutcome.failure(
              code != null ? '($code) $msg' : msg,
              otpFallback: true,
            ),
          );
          return;
        }
        if (cb.result == TcSdkCallbackResult.verification) {
          completeOnce(
            TruecallerSignInOutcome.failure(
              'Additional verification required — use OTP',
              otpFallback: true,
            ),
          );
          return;
        }
      },
      onError: (Object e, _) {
        if (!completer.isCompleted) {
          completer.complete(
            TruecallerSignInOutcome.failure('$e', otpFallback: true),
          );
        }
      },
    );

    // 3.6 Show Truecaller consent and return authorization code via stream.
    try {
      await TcSdk.getAuthorizationCode;
    } catch (e) {
      await _callbackSubscription?.cancel();
      _callbackSubscription = null;
      return TruecallerSignInOutcome.failure('$e', otpFallback: true);
    }

    try {
      return await completer.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          unawaited(_callbackSubscription?.cancel());
          _callbackSubscription = null;
          return TruecallerSignInOutcome.failure(
            'Truecaller login timed out',
            otpFallback: true,
          );
        },
      );
    } catch (e) {
      return TruecallerSignInOutcome.failure('$e', otpFallback: true);
    }
  }

  String _randSuffix() {
    final b = StringBuffer();
    for (var i = 0; i < 6; i++) {
      b.write((DateTime.now().microsecond + i * 17) % 10);
    }
    return b.toString();
  }
}
