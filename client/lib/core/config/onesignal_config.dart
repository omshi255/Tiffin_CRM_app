/// OneSignal Dashboard → Settings → Keys & IDs → OneSignal App ID.
/// Prefer: `flutter run --dart-define=ONESIGNAL_APP_ID=your-id`
const String kOneSignalAppId = String.fromEnvironment(
  'ONESIGNAL_APP_ID',
  defaultValue: '',
);
