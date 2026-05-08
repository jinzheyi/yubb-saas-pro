import 'local_file_size_loader_stub.dart'
    if (dart.library.io) 'local_file_size_loader_io.dart'
    as impl;

Future<int?> loadLocalFileSize(String path) {
  return impl.loadLocalFileSize(path);
}
