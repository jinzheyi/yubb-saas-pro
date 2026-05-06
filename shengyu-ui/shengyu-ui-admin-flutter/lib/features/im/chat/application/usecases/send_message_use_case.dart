import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/contact_card_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/mention_segment.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/send_message_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/quote_info.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/message_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_payload.dart';

class SendMessageUseCase {
  const SendMessageUseCase(this._repository);

  final MessageRepository _repository;

  Future<SendMessageResult> call({
    required String chatId,
    required String text,
    required String clientMessageId,
    QuoteInfo? quoteInfo,
    List<String> atUserIds = const <String>[],
    List<MentionSegment> mentions = const <MentionSegment>[],
  }) {
    return _repository.sendTextMessage(
      chatId: chatId,
      text: text,
      clientMessageId: clientMessageId,
      quoteInfo: quoteInfo,
      atUserIds: atUserIds,
      mentions: mentions,
    );
  }

  Future<SendMessageResult> sendContactCard({
    required String chatId,
    required ContactCardSharePayload payload,
    required String clientMessageId,
  }) {
    return _repository.sendContactCardMessage(
      chatId: chatId,
      payload: payload,
      clientMessageId: clientMessageId,
    );
  }

  Future<SendMessageResult> sendLocation({
    required String chatId,
    required LocationSharePayload payload,
    required String clientMessageId,
  }) {
    return _repository.sendLocationMessage(
      chatId: chatId,
      payload: payload,
      clientMessageId: clientMessageId,
    );
  }

  Future<SendMessageResult> sendSticker({
    required String chatId,
    required StickerPayload payload,
    required String clientMessageId,
  }) {
    return _repository.sendStickerMessage(
      chatId: chatId,
      payload: payload,
      clientMessageId: clientMessageId,
    );
  }
}
