import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 批量 DTO 解析 Isolate 入口函数
///
/// 用于在后台 Isolate 中将原始 JSON 消息数组解析为结构化的 Map 数据，
/// 减少主线程的 JSON 解析开销。
///
/// [params] 包含：
/// - rawDataList: 原始消息 JSON 数组字符串
///
/// 返回结构化后的消息 Map 列表。每个 Map 包含预解析的字段，
/// 主线程可直接映射为 MessageDto/Message 对象。
///
/// 注意：Isolate 中不引用任何框架层对象（Riverpod/BuildContext），
/// 仅使用 dart:convert 进行纯数据处理。
List<dynamic> _parseMessagesIsolate(List<dynamic> params) {
  final String rawDataJson = params[0] as String;
  final List<dynamic> rawDataList = jsonDecode(rawDataJson) as List<dynamic>;

  final result = <Map<String, dynamic>>[];
  for (final rawItem in rawDataList) {
    if (rawItem is! Map) continue;
    final raw = rawItem as Map<String, dynamic>;

    // 预解析 extra 字段（从字符串转为 Map，避免主线程重复解析）
    final extra = _parseExtra(raw['extra']);
    final contentMap = _parseExtra(raw['content']);

    // 合并结构化字段
    final structuredFields = <String, dynamic>{...extra, ...contentMap};

    // 解析类型
    final rawType = raw['type']?.toString() ?? raw['messageType']?.toString() ?? '';

    // 解析状态
    final rawStatus = raw['status']?.toString() ?? raw['messageStatus']?.toString() ?? '';

    // 解析时间戳（转为数字，避免主线程重复解析日期字符串）
    final timestamp = _parseTimestamp(
      raw['createdAt'] ??
          raw['createdTime'] ??
          raw['sentAt'] ??
          raw['sendTime'] ??
          raw['timestamp'],
    );

    // 预解析 quote 信息
    final quoteMessageId = _extractQuoteMessageId(raw, extra, contentMap);

    // 构建结构化结果（附带预解析的元数据）
    result.add({
      'raw': raw,
      'extra': extra,
      'contentMap': contentMap,
      'structuredFields': structuredFields,
      'rawType': rawType,
      'rawStatus': rawStatus,
      'timestamp': timestamp,
      'quoteMessageId': quoteMessageId,
    });
  }

  return result;
}

/// 解析 extra 字段（支持嵌套 JSON 字符串）
Map<String, dynamic> _parseExtra(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = raw.startsWith('{') ? raw : '';
      if (decoded.isNotEmpty) {
        return Map<String, dynamic>.from(
          jsonDecode(decoded) as Map<dynamic, dynamic>,
        );
      }
    } catch (_) {
      return const <String, dynamic>{};
    }
  }
  return const <String, dynamic>{};
}

/// 解析时间戳为毫秒数
int _parseTimestamp(dynamic raw) {
  if (raw == null) return 0;
  if (raw is num) return raw.toInt();
  final text = raw.toString().trim();
  if (text.isEmpty) return 0;
  final numeric = int.tryParse(text);
  if (numeric != null) return numeric;
  // 尝试解析 ISO 8601 字符串
  try {
    return DateTime.parse(text).millisecondsSinceEpoch;
  } catch (_) {
    return 0;
  }
}

/// 提取引用消息 ID
String? _extractQuoteMessageId(
  Map<String, dynamic> raw,
  Map<String, dynamic> extra,
  Map<String, dynamic> contentMap,
) {
  final candidates = <dynamic>[
    raw['quoteMessageId'],
    extra['quoteMessageId'],
    contentMap['quotedMessageId'],
    contentMap['quoteMessageId'],
  ];

  for (final candidate in candidates) {
    if (candidate != null) {
      final text = candidate.toString().trim();
      if (text.isNotEmpty && text != '0' && text != 'null') {
        return text;
      }
    }
  }

  // 从嵌套 JSON 字符串中提取
  for (final field in [raw['content'], raw['extra']]) {
    final value = _extractQuoteIdFromJsonString(field);
    if (value != null) return value;
  }

  return null;
}

/// 从 JSON 字符串中提取 quotedMessageId
String? _extractQuoteIdFromJsonString(dynamic raw) {
  final text = raw?.toString() ?? '';
  if (text.isEmpty || !text.contains('quotedMessageId')) {
    return null;
  }

  // 使用简单正则提取
  final patterns = [
    RegExp(r'"quotedMessageId"\s*:\s*"([^"]+)"'),
    RegExp(r'"quoteMessageId"\s*:\s*"([^"]+)"'),
  ];

  for (final pattern in patterns) {
    final matched = pattern.firstMatch(text);
    final value = matched?.group(1)?.trim() ?? '';
    if (value.isNotEmpty && value != '0' && value != 'null') {
      return value;
    }
  }

  return null;
}

/// 公开 API：使用 compute() 在后台 Isolate 中批量解析消息
///
/// [rawJsonList] 为原始消息 JSON 列表。
/// 返回预解析后的结构化数据列表，主线程可快速映射为 Message 对象。
Future<List<dynamic>> computeMessageParse({
  required List<dynamic> rawJsonList,
}) async {
  return compute(
    _parseMessagesIsolate,
    [jsonEncode(rawJsonList)],
  );
}
