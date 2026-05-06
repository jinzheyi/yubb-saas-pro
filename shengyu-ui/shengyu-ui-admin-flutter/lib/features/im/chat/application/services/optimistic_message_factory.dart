import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/contact_card_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message_extra.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/mention_segment.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/quote_info.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_payload.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_status.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';
import 'package:uuid/uuid.dart';

final optimisticMessageFactoryProvider = Provider<OptimisticMessageFactory>((
  ref,
) {
  return OptimisticMessageFactory(ref, const Uuid());
});

class OptimisticMessageFactory {
  OptimisticMessageFactory(this._ref, this._uuid);

  final Ref _ref;
  final Uuid _uuid;

  String _legacyPrefixedId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = 100000 + (_uuid.v4().hashCode.abs() % 900000);
    return '${prefix}_${timestamp}_$random';
  }

  Message createText({
    required String chatId,
    required String content,
    QuoteInfo? quoteInfo,
    List<String> atUserIds = const <String>[],
    List<MentionSegment> mentions = const <MentionSegment>[],
  }) {
    final session = _ref.read(authSessionProvider);
    final clientMessageId = _uuid.v4();
    return Message(
      messageId: clientMessageId,
      clientMessageId: clientMessageId,
      chatId: chatId,
      senderId: session.userId,
      senderName: '',
      type: MessageType.text,
      status: MessageStatus.sending,
      content: content,
      sentAt: DateTime.now(),
      isOutgoing: true,
      quoteInfo: quoteInfo,
      extra: MessageExtra(
        quoteMessageId: quoteInfo?.messageId,
        quoteContent: quoteInfo?.preview,
        quoteSenderName: quoteInfo?.senderName,
        atUserIds: atUserIds,
        mentions: mentions,
      ),
    );
  }

  Message createImage({
    required String chatId,
    required String fileName,
    required int fileSize,
    required String mimeType,
    required String localPath,
  }) {
    final session = _ref.read(authSessionProvider);
    final clientMessageId = _uuid.v4();
    final resolvedName = _resolveFileName(
      fileName: fileName,
      type: MessageType.image,
    );
    final resolvedMimeType = _resolveMimeType(
      fileName: resolvedName,
      mimeType: mimeType,
      type: MessageType.image,
    );
    return Message(
      messageId: clientMessageId,
      clientMessageId: clientMessageId,
      chatId: chatId,
      senderId: session.userId,
      senderName: '',
      type: MessageType.image,
      status: MessageStatus.sending,
      content: localPath,
      sentAt: DateTime.now(),
      isOutgoing: true,
      extra: MessageExtra(
        localPath: localPath,
        fileUrl: localPath,
        fileName: resolvedName,
        fileType: resolvedMimeType,
        fileSize: fileSize,
        thumbnailUrl: localPath,
      ),
    );
  }

  Message createVideo({
    required String chatId,
    required String fileName,
    required int fileSize,
    required String mimeType,
    required String localPath,
  }) {
    final session = _ref.read(authSessionProvider);
    final clientMessageId = _uuid.v4();
    final resolvedName = _resolveFileName(
      fileName: fileName,
      type: MessageType.video,
    );
    final resolvedMimeType = _resolveMimeType(
      fileName: resolvedName,
      mimeType: mimeType,
      type: MessageType.video,
    );
    return Message(
      messageId: clientMessageId,
      clientMessageId: clientMessageId,
      chatId: chatId,
      senderId: session.userId,
      senderName: '',
      type: MessageType.video,
      status: MessageStatus.sending,
      content: localPath,
      sentAt: DateTime.now(),
      isOutgoing: true,
      extra: MessageExtra(
        localPath: localPath,
        fileUrl: localPath,
        fileName: resolvedName,
        fileType: resolvedMimeType,
        fileSize: fileSize,
        thumbnailUrl: localPath,
      ),
    );
  }

  Message createVoice({
    required String chatId,
    required String localPath,
    required int duration,
    required int durationMs,
    required int fileSize,
    required String format,
  }) {
    final session = _ref.read(authSessionProvider);
    final clientMessageId = _uuid.v4();
    return Message(
      messageId: clientMessageId,
      clientMessageId: clientMessageId,
      chatId: chatId,
      senderId: session.userId,
      senderName: '',
      type: MessageType.voice,
      status: MessageStatus.sending,
      content: '',
      sentAt: DateTime.now(),
      isOutgoing: true,
      extra: MessageExtra(
        localPath: localPath,
        fileType: format,
        fileSize: fileSize,
        duration: duration,
        durationMs: durationMs,
        voicePlayed: true,
      ),
    );
  }

  Message createFile({
    required String chatId,
    required String fileName,
    required int fileSize,
    required String mimeType,
    required String localPath,
  }) {
    final session = _ref.read(authSessionProvider);
    final clientMessageId = _uuid.v4();
    final resolvedName = _resolveFileName(
      fileName: fileName,
      type: MessageType.file,
    );
    final resolvedMimeType = _resolveMimeType(
      fileName: resolvedName,
      mimeType: mimeType,
      type: MessageType.file,
    );
    return Message(
      messageId: clientMessageId,
      clientMessageId: clientMessageId,
      chatId: chatId,
      senderId: session.userId,
      senderName: '',
      type: MessageType.file,
      status: MessageStatus.sending,
      content: localPath,
      sentAt: DateTime.now(),
      isOutgoing: true,
      extra: MessageExtra(
        localPath: localPath,
        fileUrl: localPath,
        fileName: resolvedName,
        fileType: resolvedMimeType,
        fileSize: fileSize,
      ),
    );
  }

  Message createContactCard({
    required String chatId,
    required ContactCardSharePayload payload,
  }) {
    final session = _ref.read(authSessionProvider);
    final clientMessageId = _legacyPrefixedId('ccard');
    final displayName = payload.displayName.trim();
    final contentRaw = jsonEncode(<String, Object?>{
      'type': 'CONTACT_CARD',
      'userId': payload.userId,
      'displayName': displayName,
      'deptName': payload.departmentName,
      'postName': payload.postName,
      'avatar': payload.avatar,
    });
    return Message(
      messageId: clientMessageId,
      clientMessageId: clientMessageId,
      chatId: chatId,
      senderId: session.userId,
      senderName: '',
      type: MessageType.custom,
      status: MessageStatus.sending,
      content: contentRaw,
      sentAt: DateTime.now(),
      isOutgoing: true,
      extra: MessageExtra(
        customType: 'CONTACT_CARD',
        contactUserId: payload.userId,
        contactDisplayName: displayName,
        contactDepartmentName: payload.departmentName,
        contactPostName: payload.postName,
        contactAvatar: payload.avatar,
      ),
    );
  }

  Message createLocation({
    required String chatId,
    required LocationSharePayload payload,
  }) {
    final session = _ref.read(authSessionProvider);
    final clientMessageId = _uuid.v4();
    final preview = payload.address.trim().isNotEmpty
        ? payload.address.trim()
        : payload.name.trim();
    return Message(
      messageId: clientMessageId,
      clientMessageId: clientMessageId,
      chatId: chatId,
      senderId: session.userId,
      senderName: '',
      type: MessageType.location,
      status: MessageStatus.sending,
      content: preview,
      sentAt: DateTime.now(),
      isOutgoing: true,
      extra: MessageExtra(
        locationName: payload.name,
        locationAddress: payload.address,
        locationLatitude: payload.latitude,
        locationLongitude: payload.longitude,
        locationProvider: payload.provider,
        locationPoiId: payload.poiId,
      ),
    );
  }

  Message createSticker({
    required String chatId,
    required StickerPayload payload,
  }) {
    final session = _ref.read(authSessionProvider);
    final clientMessageId = _legacyPrefixedId('stk');
    final stickerUrl = payload.url.trim();
    return Message(
      messageId: clientMessageId,
      clientMessageId: clientMessageId,
      chatId: chatId,
      senderId: session.userId,
      senderName: '',
      type: MessageType.sticker,
      status: MessageStatus.sending,
      content: stickerUrl,
      sentAt: DateTime.now(),
      isOutgoing: true,
      extra: MessageExtra(
        stickerId: payload.stickerId,
        customType: 'STICKER',
        fileId: payload.fileId,
        fileUrl: stickerUrl,
        thumbFileId: payload.thumbFileId,
        thumbnailUrl: (payload.thumbUrl ?? '').trim().isNotEmpty
            ? payload.thumbUrl!.trim()
            : stickerUrl,
        md5: payload.md5,
        width: payload.width,
        height: payload.height,
        mimeType: payload.mimeType,
      ),
    );
  }

  String _resolveFileName({
    required String fileName,
    required MessageType type,
  }) {
    final resolved = fileName.trim();
    if (resolved.isNotEmpty) {
      return resolved;
    }
    return switch (type) {
      MessageType.image => 'image',
      MessageType.video => 'video',
      _ => 'file',
    };
  }

  String _resolveMimeType({
    required String fileName,
    required String mimeType,
    required MessageType type,
  }) {
    final resolvedMimeType = mimeType.trim();
    if (resolvedMimeType.isNotEmpty) {
      return resolvedMimeType;
    }
    final lowerName = fileName.toLowerCase();
    if (type == MessageType.image ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.webp') ||
        lowerName.endsWith('.gif')) {
      return 'image/*';
    }
    if (lowerName.endsWith('.mp4') ||
        lowerName.endsWith('.mov') ||
        lowerName.endsWith('.m4v') ||
        lowerName.endsWith('.avi') ||
        lowerName.endsWith('.mkv') ||
        lowerName.endsWith('.webm')) {
      return 'video/*';
    }
    return 'application/octet-stream';
  }
}
