import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Saves PDF under app documents: `TiffinCRM/Receipts/`.
Future<String?> saveReceiptPdfToDocuments(Uint8List bytes, String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final folder = Directory(p.join(dir.path, 'TiffinCRM', 'Receipts'));
  await folder.create(recursive: true);
  final path = p.join(folder.path, fileName);
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
