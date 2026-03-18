abstract final class AppConfig {
  /// Set to true for local backend (e.g. http://localhost:5800), false for Render.
  static const bool useLocalApi = false;

  static const String apiUrlLocal = 'http://localhost:5800/api/v1';
  static const String apiUrlProduction =
      'https://tiffin-crm-app.onrender.com/api/v1';

  static String get baseUrl => useLocalApi ? apiUrlLocal : apiUrlProduction;

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'YOUR_GOOGLE_MAPS_API_KEY',
  );

  static const String fcmSenderId = String.fromEnvironment(
    'FCM_SENDER_ID',
    defaultValue: '',
  );

  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'YOUR_RAZORPAY_KEY_ID',
  );

  static const String truecallerAppKey = String.fromEnvironment(
    'TRUECALLER_APP_KEY',
    defaultValue: '',
  );
}
