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
  if (normalizedRemote.isNotEmpty && _isValidImageUrl(normalizedRemote)) {
    return NetworkImage(normalizedRemote);
  }
  return null;
}

/// 校验是否为合法图片URL，拒绝纯文本、预览文本等无效值。
bool _isValidImageUrl(String url) {
  if (url.startsWith('[') && url.endsWith(']')) {
    return false;
  }
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) {
    return false;
  }
  final scheme = uri.scheme.toLowerCase();
  return scheme == 'http' || scheme == 'https' || scheme == 'data' || scheme == 'blob';
}
