import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<Uint8List> loadLocalUriBytes(String uri) async {
  final response = await web.window.fetch(uri.toJS).toDart;
  if (!response.ok) {
    throw StateError(
      'Failed to load local URI bytes: ${response.status} ${response.statusText}',
    );
  }
  final buffer = await response.arrayBuffer().toDart;
  return Uint8List.view(buffer.toDart);
}
