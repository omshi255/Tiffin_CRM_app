import '../socket/delivery_tracking_socket.dart';
import '../storage/secure_storage.dart';

/// Clears local credentials and tears down realtime connections.
abstract final class AuthSession {
  static Future<void> clearLocalSession() async {
    DeliveryTrackingSocket.instance.disconnect();
    await SecureStorage.clearAll();
  }
}
