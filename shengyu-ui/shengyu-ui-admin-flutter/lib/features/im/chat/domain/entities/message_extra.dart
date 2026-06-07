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
    );
  }
}
