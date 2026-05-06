import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_viewport_state.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message_extra.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/message_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/message_window_response_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/chat_window_result.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

abstract final class MessageDtoMapper {
  static Message toEntity(MessageDto dto) {
    return Message(
      messageId: dto.messageId,
      chatId: dto.chatId,
      senderId: dto.senderId,
      senderName: dto.senderName,
      type: dto.type,
      status: dto.status,
      content: dto.content,
      sentAt: dto.sentAt,
      isOutgoing: dto.isOutgoing,
      clientMessageId: dto.clientMessageId.isEmpty ? null : dto.clientMessageId,
      sequence: dto.sequence,
      quoteInfo: dto.quoteInfo,
      extra: MessageExtra(
        revision: dto.revision,
        stickerId: dto.stickerId,
        fileId: dto.fileId,
        fileUrl: dto.type == MessageType.emoji ? null : dto.fileUrl,
        thumbFileId: dto.thumbFileId,
        thumbnailUrl: dto.type == MessageType.emoji ? null : dto.thumbnailUrl,
        mimeType: dto.mimeType,
        fileName: dto.fileName,
        fileType: dto.fileType,
        fileSize: dto.fileSize,
        width: dto.width,
        height: dto.height,
        duration: dto.duration,
        durationMs: dto.durationMs,
        voicePlayed: dto.voicePlayed,
        md5: dto.md5,
        customType: dto.customType,
        contactUserId: dto.contactUserId,
        contactDisplayName: dto.contactDisplayName,
        contactDepartmentName: dto.contactDepartmentName,
        contactPostName: dto.contactPostName,
        contactAvatar: dto.contactAvatar,
        locationName: dto.locationName,
        locationAddress: dto.locationAddress,
        locationLatitude: dto.locationLatitude,
        locationLongitude: dto.locationLongitude,
        locationProvider: dto.locationProvider,
        locationPoiId: dto.locationPoiId,
        quoteMessageId: dto.quoteInfo?.messageId,
        quoteContent: dto.quoteInfo?.preview,
        quoteSenderName: dto.quoteInfo?.senderName,
        forwardedFrom: dto.forwardedFrom,
        atUserIds: dto.atUserIds,
        mentions: dto.mentions,
        reeditContent: dto.reeditContent,
        reeditDeadlineTs: dto.reeditDeadlineTs,
        systemEventKey: dto.systemEventKey,
      ),
    );
  }

  static ChatWindowResult toWindowResult(MessageWindowResponseDto dto) {
    return ChatWindowResult(
      messages: dto.messages.map(toEntity).toList(),
      viewportState: ChatViewportState(
        anchorMessageId: dto.anchorMessageId,
        hasMoreBefore: dto.hasMoreBefore,
        hasMoreAfter: dto.hasMoreAfter,
        anchorFound: dto.anchorFound,
        oldestSequence: dto.oldestSequence,
        newestSequence: dto.newestSequence,
      ),
    );
  }
}
