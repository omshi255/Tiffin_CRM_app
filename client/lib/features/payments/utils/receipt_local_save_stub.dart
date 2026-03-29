import 'dart:typed_data';

/// Web / non-IO: local PDF save is not supported.
Future<String?> saveReceiptPdfToDocuments(Uint8List bytes, String fileName) async =>
    null;
