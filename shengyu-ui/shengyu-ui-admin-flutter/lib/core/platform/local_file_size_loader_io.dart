import 'dart:io';

Future<int?> loadLocalFileSize(String path) async {
  final normalized = path.trim();
  if (normalized.isEmpty) {
    return null;
  }
  final file = File(normalized);
  if (!await file.exists()) {
    return null;
  }
  return file.length();
}
