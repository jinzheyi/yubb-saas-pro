import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

abstract class FileDownloadService {
  Future<void> download(Uri uri, {String? suggestedFileName});
}

class DioFileDownloadService implements FileDownloadService {
  const DioFileDownloadService(this._dio);

  final Dio _dio;

  @override
  Future<void> download(Uri uri, {String? suggestedFileName}) async {
    final fileName = _resolveFileName(uri, suggestedFileName);
    if (kIsWeb) {
      final response = await _dio.getUri<List<int>>(
        uri,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw StateError('empty download payload');
      }
      await FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
      );
      return;
    }
    final savePath = await FilePicker.platform.saveFile(fileName: fileName);
    if (savePath == null || savePath.trim().isEmpty) {
      return;
    }
    await _dio.downloadUri(uri, savePath);
  }

  String _resolveFileName(Uri uri, String? suggestedFileName) {
    final suggested = suggestedFileName?.trim() ?? '';
    if (suggested.isNotEmpty) {
      return suggested;
    }
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.last.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }
}
