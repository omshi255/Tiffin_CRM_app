import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

/// Android / iOS / desktop: uses [FileSaver] (e.g. public Downloads on Android).
Future<String?> downloadReceiptPdfForUser(Uint8List bytes, String fileName) async {
  final trimmed = fileName.trim();
  final safeName = trimmed.isEmpty
      ? 'Receipt'
      : trimmed.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
  try {
    final path = await FileSaver.instance.saveFile(
      name: safeName,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
    return path.isNotEmpty ? path : null;
  } catch (_) {
    return null;
  }
}
