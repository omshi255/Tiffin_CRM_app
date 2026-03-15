import 'package:url_launcher/url_launcher.dart';

abstract final class WhatsAppHelper {
  static Future<void> openChat(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final number = clean.length == 10 ? '91$clean' : clean;
    final url = Uri.parse('https://wa.me/$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> openWithMessage(String phone, String message) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final number = clean.length == 10 ? '91$clean' : clean;
    final enc = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$number?text=$enc');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> callPhone(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  /// Low balance message template for customer.
  static String lowBalanceMessage(String name, num balance) {
    return 'Hi $name, your TiffinCRM wallet balance is ₹$balance. '
        'Please add money to continue receiving your daily tiffin. 🙏';
  }
}
