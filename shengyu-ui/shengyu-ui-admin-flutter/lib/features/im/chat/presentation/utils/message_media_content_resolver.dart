import 'dart:convert';
import 'package:flutter/foundation.dart';

String extractMediaUrlFromRawContent(
  String raw, {
  bool fallbackMixedContent = false,
}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final parsed = _tryParseJsonObject(trimmed);
  if (parsed != null) {
    final direct = parsed['url']?.toString().trim() ?? '';
    if (direct.isNotEmpty) {
      return direct;
    }
    final nested = parsed['content'];
    if (nested is String) {
      final value = nested.trim();
      if (value.isNotEmpty) {
        return fallbackMixedContent
            ? _extractFileUrlFromMixedContent(value)
            : value;
      }
    }
    if (nested is Map<String, dynamic>) {
      final value = nested['url']?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    if (nested is Map) {
      final value = nested['url']?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
  }
  return fallbackMixedContent
      ? _extractFileUrlFromMixedContent(trimmed)
      : trimmed;
}

String basenameFromUrlOrPath(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final uri = Uri.tryParse(trimmed);
  final path = (uri?.path ?? trimmed).trim();
  if (path.isEmpty) {
    return '';
  }
  final segments = path.split('/');
  if (segments.isEmpty) {
    return '';
  }
  return segments.last.trim();
}

Map<String, dynamic>? _tryParseJsonObject(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty ||
      ((!trimmed.startsWith('{') || !trimmed.endsWith('}')) &&
          (!trimmed.startsWith('[') || !trimmed.endsWith(']')))) {
    return null;
  }
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } catch (e) {
    debugPrint('[MediaResolver] extract failed: $e');
  }
  return null;
}

String _extractFileUrlFromMixedContent(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final urlMatch = RegExp(
    r'https?:\/\/[^\s|,]+',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (urlMatch != null) {
    return urlMatch.group(0) ?? trimmed;
  }
  return trimmed;
}
