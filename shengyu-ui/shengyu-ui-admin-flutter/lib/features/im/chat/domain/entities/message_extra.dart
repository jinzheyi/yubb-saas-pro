import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/mention_segment.dart';

class MessageExtra {
  const MessageExtra({
    this.revision,
    this.localId,
    this.localPath,
    this.stickerId,
    this.fileId,
    this.fileUrl,
    this.thumbFileId,
    this.thumbnailUrl,
    this.mimeType,
    this.fileName,
    this.fileType,
    this.fileSize,
    this.width,
    this.height,
    this.duration,
    this.durationMs,
    this.voicePlayed,
    this.md5,
    this.customType,
    this.contactUserId,
    this.contactDisplayName,
    this.contactDepartmentName,
    this.contactPostName,
    this.contactAvatar,
    this.locationName,
    this.locationAddress,
    this.locationLatitude,
    this.locationLongitude,
    this.locationProvider,
    this.locationPoiId,
    this.quoteMessageId,
    this.quoteContent,
    this.quoteSenderName,
    this.forwardedFrom,
    this.atUserIds = const <String>[],
    this.mentions = const <MentionSegment>[],
    this.reeditContent,
    this.reeditDeadlineTs,
    this.systemEventKey,
    this.systemEventParams,
    // 通话记录相关字段
    this.callId,
    this.callType,
    this.callStatus,
    this.callerId,
    this.calleeId,
    this.callerName,
    this.calleeName,
    this.initiateTime,
    this.isGroupCall,
    this.inviteeNames,
  });

  final String? revision;
  final String? localId;
  final String? localPath;
  final String? stickerId;
  final String? fileId;
  final String? fileUrl;
  final String? thumbFileId;
  final String? thumbnailUrl;
  final String? mimeType;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final int? width;
  final int? height;
  final int? duration;
  final int? durationMs;
  final bool? voicePlayed;
  final String? md5;
  final String? customType;
  final String? contactUserId;
  final String? contactDisplayName;
  final String? contactDepartmentName;
  final String? contactPostName;
  final String? contactAvatar;
  final String? locationName;
  final String? locationAddress;
  final double? locationLatitude;
  final double? locationLongitude;
  final String? locationProvider;
  final String? locationPoiId;
  final String? quoteMessageId;
  final String? quoteContent;
  final String? quoteSenderName;
  final String? forwardedFrom;
  final List<String> atUserIds;
  final List<MentionSegment> mentions;
  final String? reeditContent;
  final int? reeditDeadlineTs;
  final String? systemEventKey;
  final Map<String, String>? systemEventParams;
  // 通话记录相关字段
  final String? callId;
  final int? callType;
  final int? callStatus;
  final String? callerId;
  final String? calleeId;
  final String? callerName;
  final String? calleeName;
  final int? initiateTime;
  final bool? isGroupCall;
  final List<String>? inviteeNames;
  MessageExtra copyWith({
    String? revision,
    String? localId,
    String? localPath,
    String? stickerId,
    String? fileId,
    String? fileUrl,
    String? thumbFileId,
    String? thumbnailUrl,
    String? mimeType,
    String? fileName,
    String? fileType,
    int? fileSize,
    int? width,
    int? height,
    int? duration,
    int? durationMs,
    bool? voicePlayed,
    String? md5,
    String? customType,
    String? contactUserId,
    String? contactDisplayName,
    String? contactDepartmentName,
    String? contactPostName,
    String? contactAvatar,
    String? locationName,
    String? locationAddress,
    double? locationLatitude,
    double? locationLongitude,
    String? locationProvider,
    String? locationPoiId,
    String? quoteMessageId,
    String? quoteContent,
    String? quoteSenderName,
    String? forwardedFrom,
    List<String>? atUserIds,
    List<MentionSegment>? mentions,
    String? reeditContent,
    int? reeditDeadlineTs,
    String? systemEventKey,
    Map<String, String>? systemEventParams,
    // 通话记录相关字段
    String? callId,
    int? callType,
    int? callStatus,
    String? callerId,
    String? calleeId,
    String? callerName,
    String? calleeName,
    int? initiateTime,
    bool? isGroupCall,
    List<String>? inviteeNames,
    int? callDuration,
  }) {
    return MessageExtra(
      revision: revision ?? this.revision,
      localId: localId ?? this.localId,
      localPath: localPath ?? this.localPath,
      stickerId: stickerId ?? this.stickerId,
      fileId: fileId ?? this.fileId,
      fileUrl: fileUrl ?? this.fileUrl,
      thumbFileId: thumbFileId ?? this.thumbFileId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mimeType: mimeType ?? this.mimeType,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      duration: duration ?? this.duration,
      durationMs: durationMs ?? this.durationMs,
      voicePlayed: voicePlayed ?? this.voicePlayed,
      md5: md5 ?? this.md5,
      customType: customType ?? this.customType,
      contactUserId: contactUserId ?? this.contactUserId,
      contactDisplayName: contactDisplayName ?? this.contactDisplayName,
      contactDepartmentName:
          contactDepartmentName ?? this.contactDepartmentName,
      contactPostName: contactPostName ?? this.contactPostName,
      contactAvatar: contactAvatar ?? this.contactAvatar,
      locationName: locationName ?? this.locationName,
      locationAddress: locationAddress ?? this.locationAddress,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      locationProvider: locationProvider ?? this.locationProvider,
      locationPoiId: locationPoiId ?? this.locationPoiId,
      quoteMessageId: quoteMessageId ?? this.quoteMessageId,
      quoteContent: quoteContent ?? this.quoteContent,
      quoteSenderName: quoteSenderName ?? this.quoteSenderName,
      forwardedFrom: forwardedFrom ?? this.forwardedFrom,
      atUserIds: atUserIds ?? this.atUserIds,
      mentions: mentions ?? this.mentions,
      reeditContent: reeditContent ?? this.reeditContent,
      reeditDeadlineTs: reeditDeadlineTs ?? this.reeditDeadlineTs,
      systemEventKey: systemEventKey ?? this.systemEventKey,
      systemEventParams: systemEventParams ?? this.systemEventParams,
      // 通话记录相关字段
      callId: callId ?? this.callId,
      callType: callType ?? this.callType,
      callStatus: callStatus ?? this.callStatus,
      callerId: callerId ?? this.callerId,
      calleeId: calleeId ?? this.calleeId,
      callerName: callerName ?? this.callerName,
      calleeName: calleeName ?? this.calleeName,
      initiateTime: initiateTime ?? this.initiateTime,
      isGroupCall: isGroupCall ?? this.isGroupCall,
      inviteeNames: inviteeNames ?? this.inviteeNames,
    );
  }

  /// 序列化为 JSON（用于 Isolate 跨线程通信）
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    _putIf(map, 'revision', revision);
    _putIf(map, 'localId', localId);
    _putIf(map, 'localPath', localPath);
    _putIf(map, 'stickerId', stickerId);
    _putIf(map, 'fileId', fileId);
    _putIf(map, 'fileUrl', fileUrl);
    _putIf(map, 'thumbFileId', thumbFileId);
    _putIf(map, 'thumbnailUrl', thumbnailUrl);
    _putIf(map, 'mimeType', mimeType);
    _putIf(map, 'fileName', fileName);
    _putIf(map, 'fileType', fileType);
    _putIf(map, 'fileSize', fileSize);
    _putIf(map, 'width', width);
    _putIf(map, 'height', height);
    _putIf(map, 'duration', duration);
    _putIf(map, 'durationMs', durationMs);
    _putIf(map, 'voicePlayed', voicePlayed);
    _putIf(map, 'md5', md5);
    _putIf(map, 'customType', customType);
    _putIf(map, 'contactUserId', contactUserId);
    _putIf(map, 'contactDisplayName', contactDisplayName);
    _putIf(map, 'contactDepartmentName', contactDepartmentName);
    _putIf(map, 'contactPostName', contactPostName);
    _putIf(map, 'contactAvatar', contactAvatar);
    _putIf(map, 'locationName', locationName);
    _putIf(map, 'locationAddress', locationAddress);
    _putIf(map, 'locationLatitude', locationLatitude);
    _putIf(map, 'locationLongitude', locationLongitude);
    _putIf(map, 'locationProvider', locationProvider);
    _putIf(map, 'locationPoiId', locationPoiId);
    _putIf(map, 'quoteMessageId', quoteMessageId);
    _putIf(map, 'quoteContent', quoteContent);
    _putIf(map, 'quoteSenderName', quoteSenderName);
    _putIf(map, 'forwardedFrom', forwardedFrom);
    if (atUserIds.isNotEmpty) {
      map['atUserIds'] = atUserIds;
    }
    if (mentions.isNotEmpty) {
      map['mentions'] = mentions.map((m) => m.toJson()).toList();
    }
    _putIf(map, 'reeditContent', reeditContent);
    _putIf(map, 'reeditDeadlineTs', reeditDeadlineTs);
    _putIf(map, 'systemEventKey', systemEventKey);
    if (systemEventParams != null && systemEventParams!.isNotEmpty) {
      map['systemEventParams'] = systemEventParams;
    }
    // 通话记录相关字段
    _putIf(map, 'callId', callId);
    _putIf(map, 'callType', callType);
    _putIf(map, 'callStatus', callStatus);
    _putIf(map, 'callerId', callerId);
    _putIf(map, 'calleeId', calleeId);
    _putIf(map, 'callerName', callerName);
    _putIf(map, 'calleeName', calleeName);
    _putIf(map, 'initiateTime', initiateTime);
    _putIf(map, 'isGroupCall', isGroupCall);
    if (inviteeNames != null && inviteeNames!.isNotEmpty) {
      map['inviteeNames'] = inviteeNames;
    }
    return map;
  }

  /// 从 JSON 反序列化（用于 Isolate 返回结果解析）
  factory MessageExtra.fromJson(Map<String, dynamic> json) {
    return MessageExtra(
      revision: json['revision']?.toString(),
      localId: json['localId']?.toString(),
      localPath: json['localPath']?.toString(),
      stickerId: json['stickerId']?.toString(),
      fileId: json['fileId']?.toString(),
      fileUrl: json['fileUrl']?.toString(),
      thumbFileId: json['thumbFileId']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      mimeType: json['mimeType']?.toString(),
      fileName: json['fileName']?.toString(),
      fileType: json['fileType']?.toString(),
      fileSize: (json['fileSize'] as num?)?.toInt(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt(),
      durationMs: (json['durationMs'] as num?)?.toInt(),
      voicePlayed: json['voicePlayed'] as bool?,
      md5: json['md5']?.toString(),
      customType: json['customType']?.toString(),
      contactUserId: json['contactUserId']?.toString(),
      contactDisplayName: json['contactDisplayName']?.toString(),
      contactDepartmentName: json['contactDepartmentName']?.toString(),
      contactPostName: json['contactPostName']?.toString(),
      contactAvatar: json['contactAvatar']?.toString(),
      locationName: json['locationName']?.toString(),
      locationAddress: json['locationAddress']?.toString(),
      locationLatitude: (json['locationLatitude'] as num?)?.toDouble(),
      locationLongitude: (json['locationLongitude'] as num?)?.toDouble(),
      locationProvider: json['locationProvider']?.toString(),
      locationPoiId: json['locationPoiId']?.toString(),
      quoteMessageId: json['quoteMessageId']?.toString(),
      quoteContent: json['quoteContent']?.toString(),
      quoteSenderName: json['quoteSenderName']?.toString(),
      forwardedFrom: json['forwardedFrom']?.toString(),
      atUserIds: json['atUserIds'] is List
          ? (json['atUserIds'] as List).map((e) => e.toString()).toList()
          : const <String>[],
      mentions: json['mentions'] is List
          ? (json['mentions'] as List)
              .whereType<Map<String, dynamic>>()
              .map(MentionSegment.fromJson)
              .toList()
          : const <MentionSegment>[],
      reeditContent: json['reeditContent']?.toString(),
      reeditDeadlineTs: (json['reeditDeadlineTs'] as num?)?.toInt(),
      systemEventKey: json['systemEventKey']?.toString(),
      systemEventParams: json['systemEventParams'] is Map
          ? (json['systemEventParams'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            )
          : null,
      // 通话记录相关字段
      callId: json['callId']?.toString(),
      callType: (json['callType'] as num?)?.toInt(),
      callStatus: (json['callStatus'] as num?)?.toInt(),
      callerId: json['callerId']?.toString(),
      calleeId: json['calleeId']?.toString(),
      callerName: json['callerName']?.toString(),
      calleeName: json['calleeName']?.toString(),
      initiateTime: (json['initiateTime'] as num?)?.toInt(),
      isGroupCall: json['isGroupCall'] as bool?,
      inviteeNames: json['inviteeNames'] is List
          ? (json['inviteeNames'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }

  static void _putIf(Map<String, dynamic> map, String key, dynamic value) {
    if (value != null) {
      map[key] = value;
    }
  }
}
