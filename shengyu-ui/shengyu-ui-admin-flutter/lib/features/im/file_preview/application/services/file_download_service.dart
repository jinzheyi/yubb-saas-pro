import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

abstract class FileDownloadService {
  Future<File> download(Uri uri);
}

class DioFileDownloadService implements FileDownloadService {
  const DioFileDownloadService(this._dio);

  final Dio _dio;

  @override
  Future<File> download(Uri uri) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${_resolveFileName(uri)}');
    await _dio.downloadUri(uri, file.path);
    return file;
  }

  String _resolveFileName(Uri uri) {
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.last.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }
}
