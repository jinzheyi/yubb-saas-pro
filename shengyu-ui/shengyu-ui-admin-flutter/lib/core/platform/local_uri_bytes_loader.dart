import 'dart:typed_data';

import 'local_uri_bytes_loader_stub.dart'
    if (dart.library.html) 'local_uri_bytes_loader_web.dart'
    as impl;

Future<Uint8List> loadLocalUriBytes(String uri) {
  return impl.loadLocalUriBytes(uri);
}
