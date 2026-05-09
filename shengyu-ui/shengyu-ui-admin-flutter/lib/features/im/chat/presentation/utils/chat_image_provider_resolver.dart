import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

ImageProvider? resolveChatImageProvider({
  String? localPath,
  String? remoteUrl,
}) {
  final normalizedLocal = localPath?.trim() ?? '';
  if (normalizedLocal.isNotEmpty) {
    final uri = Uri.tryParse(normalizedLocal);
    final scheme = (uri?.scheme ?? '').toLowerCase();
    if (scheme == 'data') {
      final commaIndex = normalizedLocal.indexOf(',');
      if (commaIndex > 0 &&
          normalizedLocal.substring(0, commaIndex).contains(';base64')) {
        return MemoryImage(
          base64Decode(normalizedLocal.substring(commaIndex + 1)),
        );
      }
      return NetworkImage(normalizedLocal);
    }
    if (scheme == 'blob' || scheme == 'http' || scheme == 'https') {
      return NetworkImage(normalizedLocal);
    }
    if (!kIsWeb) {
      return FileImage(File(normalizedLocal));
    }
  }
  final normalizedRemote = remoteUrl?.trim() ?? '';
  if (normalizedRemote.isNotEmpty) {
    return NetworkImage(normalizedRemote);
  }
  return null;
}
