import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 消息合并 Isolate 入口函数
///
/// 用于在后台 Isolate 中执行两条消息列表的合并去重逻辑，
/// 避免大数据量（100+ 条消息）时阻塞主线程 UI 渲染。
///
/// [params] 包含：
/// - existingMessages: 现有消息的 JSON 数组字符串
/// - incomingMessages: 新消息的 JSON 数组字符串
///
/// 返回合并后的消息 JSON 数组字符串。
///
/// 注意：Isolate 中不可引用 Riverpod/BuildContext 等不可序列化对象，
/// 仅使用纯 JSON 数据做序列化/反序列化和合并计算。
List<dynamic> _mergeMessagesIsolate(List<dynamic> params) {
  final String existingJson = params[0] as String;
  final String incomingJson = params[1] as String;

  // 解析 JSON 数据
  final List<dynamic> existing = jsonDecode(existingJson) as List<dynamic>;
  final List<dynamic> incoming = jsonDecode(incomingJson) as List<dynamic>;

  if (existing.isEmpty || incoming.isEmpty) {
    return incoming;
  }

  // 构建现有消息的哈希索引（O(1) 查找）
  final existingIndex = <String, dynamic>{};
  for (final item in existing) {
    final msg = item as Map<String, dynamic>;
    final messageId = msg['messageId']?.toString() ?? '';
    if (messageId.isNotEmpty) {
      existingIndex[messageId] = msg;
    }
    final cid = msg['clientMessageId']?.toString() ?? '';
    if (cid.isNotEmpty) {
      existingIndex[cid] = msg;
    }
    final seq = msg['sequence']?.toString() ?? '';
    if (seq.isNotEmpty) {
      existingIndex[seq] = msg;
    }
  }

  // 合并消息：新消息优先，匹配时保留已有完整字段
  final result = <Map<String, dynamic>>[];
  final processedKeys = <String>{};

  for (final incomingItem in incoming) {
    final incomingMsg = incomingItem as Map<String, dynamic>;
    final matched = _findMatchedByHash(incomingMsg, existingIndex);
    if (matched != null) {
      // 匹配到已有消息：合并字段（incoming 优先，existing 补充缺失字段）
      final merged = _mergeMessageJson(matched, incomingMsg);
      result.add(merged);
      // 记录已处理的 key
      final mid = matched['messageId']?.toString() ?? '';
      if (mid.isNotEmpty) processedKeys.add(mid);
      final cid = matched['clientMessageId']?.toString() ?? '';
      if (cid.isNotEmpty) processedKeys.add(cid);
    } else {
      // 新消息直接追加
      result.add(incomingMsg);
    }
  }

  // 保留 existing 中未被匹配的原有消息
  for (final existingItem in existing) {
    final existingMsg = existingItem as Map<String, dynamic>;
    final mid = existingMsg['messageId']?.toString() ?? '';
    if (mid.isNotEmpty && !processedKeys.contains(mid)) {
      result.add(existingMsg);
    } else if (mid.isEmpty) {
      final cid = existingMsg['clientMessageId']?.toString() ?? '';
      if (cid.isEmpty || !processedKeys.contains(cid)) {
        result.add(existingMsg);
      }
    }
  }

  // 按 sequence 排序，确保消息时间线正确（处理 API 返回历史消息导致的顺序错乱）
  result.sort((a, b) {
    final seqA = a['sequence']?.toString() ?? '';
    final seqB = b['sequence']?.toString() ?? '';
    if (seqA.isNotEmpty && seqB.isNotEmpty) {
      final numA = int.tryParse(seqA) ?? 0;
      final numB = int.tryParse(seqB) ?? 0;
      return numA.compareTo(numB);
    }
    // 如果 sequence 缺失，回退到时间戳排序
    final timeA = _parseTimestamp(a);
    final timeB = _parseTimestamp(b);
    return timeA.compareTo(timeB);
  });

  return result;
}

/// 通过哈希索引快速查找匹配消息（O(1) 复杂度）
Map<String, dynamic>? _findMatchedByHash(
  Map<String, dynamic> target,
  Map<String, dynamic> index,
) {
  // 按优先级尝试匹配：messageId > clientMessageId > sequence
  final messageId = target['messageId']?.toString() ?? '';
  if (messageId.isNotEmpty) {
    final matched = index[messageId];
    if (matched != null && _isSameMessage(matched, target)) {
      return matched as Map<String, dynamic>;
    }
  }

  final cid = target['clientMessageId']?.toString() ?? '';
  if (cid.isNotEmpty) {
    final matched = index[cid];
    if (matched != null && _isSameMessage(matched, target)) {
      return matched as Map<String, dynamic>;
    }
  }

  final seq = target['sequence']?.toString() ?? '';
  if (seq.isNotEmpty) {
    final matched = index[seq];
    if (matched != null && _isSameMessage(matched, target)) {
      return matched as Map<String, dynamic>;
    }
  }

  return null;
}

/// 判断两条消息是否相同
bool _isSameMessage(Map<String, dynamic> previous, Map<String, dynamic> next) {
  final prevId = previous['messageId']?.toString() ?? '';
  final nextId = next['messageId']?.toString() ?? '';
  if (prevId.isNotEmpty && prevId == nextId) {
    return true;
  }

  final prevCid = previous['clientMessageId']?.toString() ?? '';
  final nextCid = next['clientMessageId']?.toString() ?? '';
  if (prevCid.isNotEmpty && nextCid.isNotEmpty && prevCid == nextCid) {
    return true;
  }

  final prevSeq = previous['sequence']?.toString() ?? '';
  final nextSeq = next['sequence']?.toString() ?? '';
  if (prevSeq.isNotEmpty && nextSeq.isNotEmpty && prevSeq == nextSeq) {
    return true;
  }

  return false;
}

/// 合并两条 JSON 消息（incoming 优先，existing 补充缺失字段）
Map<String, dynamic> _mergeMessageJson(
  Map<String, dynamic> previous,
  Map<String, dynamic> next,
) {
  // 以 incoming 为基础，补充 previous 中有但 incoming 中缺失的字段
  final merged = <String, dynamic>{};

  // 基础字段：优先使用 next 的非空值
  final basicFields = [
    'messageId', 'chatId', 'senderId', 'senderName', 'senderAvatar',
    'type', 'status', 'content', 'createdAt', 'createdTime', 'sentAt',
    'sendTime', 'timestamp', 'isOutgoing', 'isSelf',
    'clientMessageId', 'reqMessageId', 'sequence', 'sortKey',
    'revision', 'rev',
  ];

  for (final field in basicFields) {
    if (next.containsKey(field) && _isMeaningful(next[field])) {
      merged[field] = next[field];
    } else if (previous.containsKey(field) && _isMeaningful(previous[field])) {
      merged[field] = previous[field];
    }
  }

  // extra 字段合并
  final prevExtra = _parseExtra(previous['extra']);
  final nextExtra = _parseExtra(next['extra']);
  if (prevExtra.isNotEmpty || nextExtra.isNotEmpty) {
    final mergedExtra = <String, dynamic>{...prevExtra};
    nextExtra.forEach((key, value) {
      if (_isMeaningful(value)) {
        mergedExtra[key] = value;
      }
    });
    merged['extra'] = mergedExtra;
  }

  // content 字段合并（可能是 JSON 字符串或对象）
  final prevContentMap = _parseExtra(previous['content']);
  final nextContentMap = _parseExtra(next['content']);
  if (prevContentMap.isNotEmpty || nextContentMap.isNotEmpty) {
    final mergedContent = <String, dynamic>{...prevContentMap};
    nextContentMap.forEach((key, value) {
      if (_isMeaningful(value)) {
        mergedContent[key] = value;
      }
    });
    merged['content'] = mergedContent;
  }

  return merged;
}

/// 解析消息时间戳（兼容多种时间字段名）
int _parseTimestamp(Map<String, dynamic> msg) {
  // 尝试常见时间字段
  for (final field in ['sendTime', 'sentAt', 'createdAt', 'createdTime', 'timestamp']) {
    final value = msg[field];
    if (value != null) {
      final parsed = int.tryParse(value.toString());
      if (parsed != null && parsed > 0) return parsed;
    }
  }
  return 0;
}

/// 判断值是否有意义（非 null、非空字符串、非零）
bool _isMeaningful(dynamic value) {
  if (value == null) return false;
  if (value is String) return value.trim().isNotEmpty && value != 'null';
  return true;
}

/// 解析 extra 字段（支持 Map 或 JSON 字符串）
Map<String, dynamic> _parseExtra(dynamic raw) {
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  if (raw is String && raw.isNotEmpty && raw.startsWith('{')) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      // ignore
    }
  }
  return const <String, dynamic>{};
}

/// 公开 API：使用 compute() 在后台 Isolate 中合并消息
///
/// [existingMessages] 和 [incomingMessages] 为消息 JSON 列表。
/// 返回合并后的消息 JSON 列表。
Future<List<dynamic>> computeMessageMerge({
  required List<dynamic> existingMessages,
  required List<dynamic> incomingMessages,
}) async {
  return compute(
    _mergeMessagesIsolate,
    [
      jsonEncode(existingMessages),
      jsonEncode(incomingMessages),
    ],
  );
}
