import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_preferences_provider.dart';

const _keyUserName = 'user_profile_name';

/// Saves the user name (e.g. from Truecaller SDK after authentication).
/// When Truecaller SDK is integrated, replace the placeholder in TruecallerScreen
/// with: final profile = await TruecallerSdk.getProfile(); await saveUserName(prefs, profile.fullName);
Future<void> saveUserName(SharedPreferences prefs, String name) async {
  await prefs.setString(_keyUserName, name);
}

/// Provider for the current user's display name.
/// Fetched from storage (set when user signs in via Truecaller or OTP).
final userNameProvider = FutureProvider<String>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getString(_keyUserName) ?? 'Guest';
});
