import 'package:shared_preferences/shared_preferences.dart';

abstract class OnboardingStorage {
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted();
}

const String _keyOnboardingCompleted = 'onboarding_completed';

class OnboardingStorageImpl implements OnboardingStorage {
  OnboardingStorageImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<bool> isOnboardingCompleted() async {
    return _prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  @override
  Future<void> setOnboardingCompleted() async {
    await _prefs.setBool(_keyOnboardingCompleted, true);
  }
}
