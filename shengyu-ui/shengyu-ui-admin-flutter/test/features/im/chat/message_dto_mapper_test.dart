import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/message_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/mappers/message_dto_mapper.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

void main() {
  test('maps file metadata from extra json', () {
    final dto = MessageDto.fromJson({
      'messageId': 'm-1',
      'clientMessageId': 'c-1',
      'chatId': 'chat-1',
      'senderId': 'u-1',
      'senderName': 'tester',
      'type': 'file',
      'status': 'sent',
      'content': 'report.pdf',
      'createdAt': '2026-04-30T10:00:00Z',
      'isOutgoing': true,
      'sequence': '10',
      'extra':
          '{"fileId":"f-1","url":"https://example.com/r.pdf","fileName":"report.pdf","fileType":"application/pdf","size":2048}',
    });

    final message = MessageDtoMapper.toEntity(dto);

    expect(message.type, MessageType.file);
    expect(message.extra.fileId, 'f-1');
    expect(message.extra.fileUrl, 'https://example.com/r.pdf');
    expect(message.extra.fileName, 'report.pdf');
    expect(message.extra.fileType, 'application/pdf');
    expect(message.extra.fileSize, 2048);
  });

  test('parses quote info from raw content string fallback', () {
    final dto = MessageDto.fromJson({
      'messageId': 'm-2',
      'chatId': 'chat-1',
      'senderId': 'u-1',
      'senderName': 'tester',
      'type': 'text',
      'status': 'sent',
      'content':
          '{"content":"reply body","quotedMessageId":"q-1","quotedContent":"source body","quotedSenderName":"Alice"}',
      'createdAt': '2026-04-30T10:00:00Z',
      'isOutgoing': true,
      'sequence': '11',
    });

    final message = MessageDtoMapper.toEntity(dto);

    expect(message.quoteInfo, isNotNull);
    expect(message.quoteInfo!.messageId, 'q-1');
    expect(message.quoteInfo!.senderName, 'Alice');
    expect(message.quoteInfo!.preview, 'source body');
  });

  test('maps sticker identifiers from extra json', () {
    final dto = MessageDto.fromJson({
      'messageId': 'm-3',
      'clientMessageId': 'c-3',
      'chatId': 'chat-1',
      'senderId': 'u-1',
      'senderName': 'tester',
      'type': 'custom',
      'status': 'sent',
      'content': '{"type":"STICKER","url":"https://example.com/sticker.gif"}',
      'createdAt': '2026-04-30T10:00:00Z',
      'isOutgoing': true,
      'sequence': '12',
      'extra':
          '{"type":"STICKER","stickerId":"stk-1","fileId":"file-1","thumbFileId":"thumb-1","url":"https://example.com/sticker.gif","thumbUrl":"https://example.com/sticker-thumb.gif"}',
    });

    final message = MessageDtoMapper.toEntity(dto);

    expect(message.type, MessageType.sticker);
    expect(message.extra.stickerId, 'stk-1');
    expect(message.extra.fileId, 'file-1');
    expect(message.extra.thumbFileId, 'thumb-1');
    expect(message.extra.thumbnailUrl, 'https://example.com/sticker-thumb.gif');
  });
}
