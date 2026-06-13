// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'im_database.dart';

// ignore_for_file: type=lint
class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientMessageIdMeta = const VerificationMeta(
    'clientMessageId',
  );
  @override
  late final GeneratedColumn<String> clientMessageId = GeneratedColumn<String>(
    'client_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
    'chat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MessageTypeDb, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<MessageTypeDb>($MessagesTable.$convertertype);
  @override
  late final GeneratedColumnWithTypeConverter<MessageStatusDb, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<MessageStatusDb>($MessagesTable.$converterstatus);
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
    'sender_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderNameMeta = const VerificationMeta(
    'senderName',
  );
  @override
  late final GeneratedColumn<String> senderName = GeneratedColumn<String>(
    'sender_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderAvatarMeta = const VerificationMeta(
    'senderAvatar',
  );
  @override
  late final GeneratedColumn<String> senderAvatar = GeneratedColumn<String>(
    'sender_avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<String> sequence = GeneratedColumn<String>(
    'sequence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isOutgoingMeta = const VerificationMeta(
    'isOutgoing',
  );
  @override
  late final GeneratedColumn<bool> isOutgoing = GeneratedColumn<bool>(
    'is_outgoing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_outgoing" IN (0, 1))',
    ),
  );
  static const VerificationMeta _extraJsonMeta = const VerificationMeta(
    'extraJson',
  );
  @override
  late final GeneratedColumn<String> extraJson = GeneratedColumn<String>(
    'extra_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    messageId,
    clientMessageId,
    chatId,
    type,
    status,
    content,
    senderId,
    senderName,
    senderAvatar,
    sentAt,
    sequence,
    isOutgoing,
    extraJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('client_message_id')) {
      context.handle(
        _clientMessageIdMeta,
        clientMessageId.isAcceptableOrUnknown(
          data['client_message_id']!,
          _clientMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('sender_name')) {
      context.handle(
        _senderNameMeta,
        senderName.isAcceptableOrUnknown(data['sender_name']!, _senderNameMeta),
      );
    } else if (isInserting) {
      context.missing(_senderNameMeta);
    }
    if (data.containsKey('sender_avatar')) {
      context.handle(
        _senderAvatarMeta,
        senderAvatar.isAcceptableOrUnknown(
          data['sender_avatar']!,
          _senderAvatarMeta,
        ),
      );
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    }
    if (data.containsKey('is_outgoing')) {
      context.handle(
        _isOutgoingMeta,
        isOutgoing.isAcceptableOrUnknown(data['is_outgoing']!, _isOutgoingMeta),
      );
    } else if (isInserting) {
      context.missing(_isOutgoingMeta);
    }
    if (data.containsKey('extra_json')) {
      context.handle(
        _extraJsonMeta,
        extraJson.isAcceptableOrUnknown(data['extra_json']!, _extraJsonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      clientMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_message_id'],
      ),
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chat_id'],
      )!,
      type: $MessagesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      status: $MessagesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_id'],
      )!,
      senderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_name'],
      )!,
      senderAvatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_avatar'],
      ),
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sequence'],
      ),
      isOutgoing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_outgoing'],
      )!,
      extraJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MessageTypeDb, int, int> $convertertype =
      const EnumIndexConverter<MessageTypeDb>(MessageTypeDb.values);
  static JsonTypeConverter2<MessageStatusDb, int, int> $converterstatus =
      const EnumIndexConverter<MessageStatusDb>(MessageStatusDb.values);
}

class Message extends DataClass implements Insertable<Message> {
  /// 主键，消息ID（服务器生成）
  final String messageId;

  /// 客户端消息ID（用于去重）
  final String? clientMessageId;

  /// 会话ID（索引，用于查询特定聊天的消息）
  final String chatId;

  /// 消息类型
  final MessageTypeDb type;

  /// 消息状态
  final MessageStatusDb status;

  /// 消息内容（文本或JSON序列化数据）
  final String content;

  /// 发送者ID
  final String senderId;

  /// 发送者名称
  final String senderName;

  /// 发送者头像URL（可选）
  final String? senderAvatar;

  /// 发送时间
  final DateTime sentAt;

  /// 服务器序列号（可选）
  final String? sequence;

  /// 是否是自己发送的
  final bool isOutgoing;

  /// MessageExtra序列化JSON
  final String? extraJson;

  /// 本地创建时间戳
  final DateTime createdAt;
  const Message({
    required this.messageId,
    this.clientMessageId,
    required this.chatId,
    required this.type,
    required this.status,
    required this.content,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.sentAt,
    this.sequence,
    required this.isOutgoing,
    this.extraJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    if (!nullToAbsent || clientMessageId != null) {
      map['client_message_id'] = Variable<String>(clientMessageId);
    }
    map['chat_id'] = Variable<String>(chatId);
    {
      map['type'] = Variable<int>($MessagesTable.$convertertype.toSql(type));
    }
    {
      map['status'] = Variable<int>(
        $MessagesTable.$converterstatus.toSql(status),
      );
    }
    map['content'] = Variable<String>(content);
    map['sender_id'] = Variable<String>(senderId);
    map['sender_name'] = Variable<String>(senderName);
    if (!nullToAbsent || senderAvatar != null) {
      map['sender_avatar'] = Variable<String>(senderAvatar);
    }
    map['sent_at'] = Variable<DateTime>(sentAt);
    if (!nullToAbsent || sequence != null) {
      map['sequence'] = Variable<String>(sequence);
    }
    map['is_outgoing'] = Variable<bool>(isOutgoing);
    if (!nullToAbsent || extraJson != null) {
      map['extra_json'] = Variable<String>(extraJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      messageId: Value(messageId),
      clientMessageId: clientMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientMessageId),
      chatId: Value(chatId),
      type: Value(type),
      status: Value(status),
      content: Value(content),
      senderId: Value(senderId),
      senderName: Value(senderName),
      senderAvatar: senderAvatar == null && nullToAbsent
          ? const Value.absent()
          : Value(senderAvatar),
      sentAt: Value(sentAt),
      sequence: sequence == null && nullToAbsent
          ? const Value.absent()
          : Value(sequence),
      isOutgoing: Value(isOutgoing),
      extraJson: extraJson == null && nullToAbsent
          ? const Value.absent()
          : Value(extraJson),
      createdAt: Value(createdAt),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      messageId: serializer.fromJson<String>(json['messageId']),
      clientMessageId: serializer.fromJson<String?>(json['clientMessageId']),
      chatId: serializer.fromJson<String>(json['chatId']),
      type: $MessagesTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      status: $MessagesTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      content: serializer.fromJson<String>(json['content']),
      senderId: serializer.fromJson<String>(json['senderId']),
      senderName: serializer.fromJson<String>(json['senderName']),
      senderAvatar: serializer.fromJson<String?>(json['senderAvatar']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
      sequence: serializer.fromJson<String?>(json['sequence']),
      isOutgoing: serializer.fromJson<bool>(json['isOutgoing']),
      extraJson: serializer.fromJson<String?>(json['extraJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'clientMessageId': serializer.toJson<String?>(clientMessageId),
      'chatId': serializer.toJson<String>(chatId),
      'type': serializer.toJson<int>(
        $MessagesTable.$convertertype.toJson(type),
      ),
      'status': serializer.toJson<int>(
        $MessagesTable.$converterstatus.toJson(status),
      ),
      'content': serializer.toJson<String>(content),
      'senderId': serializer.toJson<String>(senderId),
      'senderName': serializer.toJson<String>(senderName),
      'senderAvatar': serializer.toJson<String?>(senderAvatar),
      'sentAt': serializer.toJson<DateTime>(sentAt),
      'sequence': serializer.toJson<String?>(sequence),
      'isOutgoing': serializer.toJson<bool>(isOutgoing),
      'extraJson': serializer.toJson<String?>(extraJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Message copyWith({
    String? messageId,
    Value<String?> clientMessageId = const Value.absent(),
    String? chatId,
    MessageTypeDb? type,
    MessageStatusDb? status,
    String? content,
    String? senderId,
    String? senderName,
    Value<String?> senderAvatar = const Value.absent(),
    DateTime? sentAt,
    Value<String?> sequence = const Value.absent(),
    bool? isOutgoing,
    Value<String?> extraJson = const Value.absent(),
    DateTime? createdAt,
  }) => Message(
    messageId: messageId ?? this.messageId,
    clientMessageId: clientMessageId.present
        ? clientMessageId.value
        : this.clientMessageId,
    chatId: chatId ?? this.chatId,
    type: type ?? this.type,
    status: status ?? this.status,
    content: content ?? this.content,
    senderId: senderId ?? this.senderId,
    senderName: senderName ?? this.senderName,
    senderAvatar: senderAvatar.present ? senderAvatar.value : this.senderAvatar,
    sentAt: sentAt ?? this.sentAt,
    sequence: sequence.present ? sequence.value : this.sequence,
    isOutgoing: isOutgoing ?? this.isOutgoing,
    extraJson: extraJson.present ? extraJson.value : this.extraJson,
    createdAt: createdAt ?? this.createdAt,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      clientMessageId: data.clientMessageId.present
          ? data.clientMessageId.value
          : this.clientMessageId,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      type: data.type.present ? data.type.value : this.type,
      status: data.status.present ? data.status.value : this.status,
      content: data.content.present ? data.content.value : this.content,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      senderName: data.senderName.present
          ? data.senderName.value
          : this.senderName,
      senderAvatar: data.senderAvatar.present
          ? data.senderAvatar.value
          : this.senderAvatar,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      isOutgoing: data.isOutgoing.present
          ? data.isOutgoing.value
          : this.isOutgoing,
      extraJson: data.extraJson.present ? data.extraJson.value : this.extraJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('messageId: $messageId, ')
          ..write('clientMessageId: $clientMessageId, ')
          ..write('chatId: $chatId, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('content: $content, ')
          ..write('senderId: $senderId, ')
          ..write('senderName: $senderName, ')
          ..write('senderAvatar: $senderAvatar, ')
          ..write('sentAt: $sentAt, ')
          ..write('sequence: $sequence, ')
          ..write('isOutgoing: $isOutgoing, ')
          ..write('extraJson: $extraJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    messageId,
    clientMessageId,
    chatId,
    type,
    status,
    content,
    senderId,
    senderName,
    senderAvatar,
    sentAt,
    sequence,
    isOutgoing,
    extraJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.messageId == this.messageId &&
          other.clientMessageId == this.clientMessageId &&
          other.chatId == this.chatId &&
          other.type == this.type &&
          other.status == this.status &&
          other.content == this.content &&
          other.senderId == this.senderId &&
          other.senderName == this.senderName &&
          other.senderAvatar == this.senderAvatar &&
          other.sentAt == this.sentAt &&
          other.sequence == this.sequence &&
          other.isOutgoing == this.isOutgoing &&
          other.extraJson == this.extraJson &&
          other.createdAt == this.createdAt);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> messageId;
  final Value<String?> clientMessageId;
  final Value<String> chatId;
  final Value<MessageTypeDb> type;
  final Value<MessageStatusDb> status;
  final Value<String> content;
  final Value<String> senderId;
  final Value<String> senderName;
  final Value<String?> senderAvatar;
  final Value<DateTime> sentAt;
  final Value<String?> sequence;
  final Value<bool> isOutgoing;
  final Value<String?> extraJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MessagesCompanion({
    this.messageId = const Value.absent(),
    this.clientMessageId = const Value.absent(),
    this.chatId = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.content = const Value.absent(),
    this.senderId = const Value.absent(),
    this.senderName = const Value.absent(),
    this.senderAvatar = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.sequence = const Value.absent(),
    this.isOutgoing = const Value.absent(),
    this.extraJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String messageId,
    this.clientMessageId = const Value.absent(),
    required String chatId,
    required MessageTypeDb type,
    required MessageStatusDb status,
    required String content,
    required String senderId,
    required String senderName,
    this.senderAvatar = const Value.absent(),
    required DateTime sentAt,
    this.sequence = const Value.absent(),
    required bool isOutgoing,
    this.extraJson = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       chatId = Value(chatId),
       type = Value(type),
       status = Value(status),
       content = Value(content),
       senderId = Value(senderId),
       senderName = Value(senderName),
       sentAt = Value(sentAt),
       isOutgoing = Value(isOutgoing),
       createdAt = Value(createdAt);
  static Insertable<Message> custom({
    Expression<String>? messageId,
    Expression<String>? clientMessageId,
    Expression<String>? chatId,
    Expression<int>? type,
    Expression<int>? status,
    Expression<String>? content,
    Expression<String>? senderId,
    Expression<String>? senderName,
    Expression<String>? senderAvatar,
    Expression<DateTime>? sentAt,
    Expression<String>? sequence,
    Expression<bool>? isOutgoing,
    Expression<String>? extraJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (clientMessageId != null) 'client_message_id': clientMessageId,
      if (chatId != null) 'chat_id': chatId,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (content != null) 'content': content,
      if (senderId != null) 'sender_id': senderId,
      if (senderName != null) 'sender_name': senderName,
      if (senderAvatar != null) 'sender_avatar': senderAvatar,
      if (sentAt != null) 'sent_at': sentAt,
      if (sequence != null) 'sequence': sequence,
      if (isOutgoing != null) 'is_outgoing': isOutgoing,
      if (extraJson != null) 'extra_json': extraJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? messageId,
    Value<String?>? clientMessageId,
    Value<String>? chatId,
    Value<MessageTypeDb>? type,
    Value<MessageStatusDb>? status,
    Value<String>? content,
    Value<String>? senderId,
    Value<String>? senderName,
    Value<String?>? senderAvatar,
    Value<DateTime>? sentAt,
    Value<String?>? sequence,
    Value<bool>? isOutgoing,
    Value<String?>? extraJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      messageId: messageId ?? this.messageId,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      chatId: chatId ?? this.chatId,
      type: type ?? this.type,
      status: status ?? this.status,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      sentAt: sentAt ?? this.sentAt,
      sequence: sequence ?? this.sequence,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      extraJson: extraJson ?? this.extraJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (clientMessageId.present) {
      map['client_message_id'] = Variable<String>(clientMessageId.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $MessagesTable.$convertertype.toSql(type.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $MessagesTable.$converterstatus.toSql(status.value),
      );
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (senderName.present) {
      map['sender_name'] = Variable<String>(senderName.value);
    }
    if (senderAvatar.present) {
      map['sender_avatar'] = Variable<String>(senderAvatar.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<String>(sequence.value);
    }
    if (isOutgoing.present) {
      map['is_outgoing'] = Variable<bool>(isOutgoing.value);
    }
    if (extraJson.present) {
      map['extra_json'] = Variable<String>(extraJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('clientMessageId: $clientMessageId, ')
          ..write('chatId: $chatId, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('content: $content, ')
          ..write('senderId: $senderId, ')
          ..write('senderName: $senderName, ')
          ..write('senderAvatar: $senderAvatar, ')
          ..write('sentAt: $sentAt, ')
          ..write('sequence: $sequence, ')
          ..write('isOutgoing: $isOutgoing, ')
          ..write('extraJson: $extraJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, Conversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
    'chat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ConversationTypeDb, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ConversationTypeDb>($ConversationsTable.$convertertype);
  static const VerificationMeta _targetNameMeta = const VerificationMeta(
    'targetName',
  );
  @override
  late final GeneratedColumn<String> targetName = GeneratedColumn<String>(
    'target_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetAvatarMeta = const VerificationMeta(
    'targetAvatar',
  );
  @override
  late final GeneratedColumn<String> targetAvatar = GeneratedColumn<String>(
    'target_avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageIdMeta = const VerificationMeta(
    'lastMessageId',
  );
  @override
  late final GeneratedColumn<String> lastMessageId = GeneratedColumn<String>(
    'last_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessagePreviewMeta =
      const VerificationMeta('lastMessagePreview');
  @override
  late final GeneratedColumn<String> lastMessagePreview =
      GeneratedColumn<String>(
        'last_message_preview',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastMessageTimeMeta = const VerificationMeta(
    'lastMessageTime',
  );
  @override
  late final GeneratedColumn<DateTime> lastMessageTime =
      GeneratedColumn<DateTime>(
        'last_message_time',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isMutedMeta = const VerificationMeta(
    'isMuted',
  );
  @override
  late final GeneratedColumn<bool> isMuted = GeneratedColumn<bool>(
    'is_muted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_muted" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    chatId,
    type,
    targetName,
    targetAvatar,
    lastMessageId,
    lastMessagePreview,
    lastMessageTime,
    unreadCount,
    isPinned,
    isMuted,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Conversation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('target_name')) {
      context.handle(
        _targetNameMeta,
        targetName.isAcceptableOrUnknown(data['target_name']!, _targetNameMeta),
      );
    } else if (isInserting) {
      context.missing(_targetNameMeta);
    }
    if (data.containsKey('target_avatar')) {
      context.handle(
        _targetAvatarMeta,
        targetAvatar.isAcceptableOrUnknown(
          data['target_avatar']!,
          _targetAvatarMeta,
        ),
      );
    }
    if (data.containsKey('last_message_id')) {
      context.handle(
        _lastMessageIdMeta,
        lastMessageId.isAcceptableOrUnknown(
          data['last_message_id']!,
          _lastMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('last_message_preview')) {
      context.handle(
        _lastMessagePreviewMeta,
        lastMessagePreview.isAcceptableOrUnknown(
          data['last_message_preview']!,
          _lastMessagePreviewMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastMessagePreviewMeta);
    }
    if (data.containsKey('last_message_time')) {
      context.handle(
        _lastMessageTimeMeta,
        lastMessageTime.isAcceptableOrUnknown(
          data['last_message_time']!,
          _lastMessageTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastMessageTimeMeta);
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unreadCountMeta);
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    } else if (isInserting) {
      context.missing(_isPinnedMeta);
    }
    if (data.containsKey('is_muted')) {
      context.handle(
        _isMutedMeta,
        isMuted.isAcceptableOrUnknown(data['is_muted']!, _isMutedMeta),
      );
    } else if (isInserting) {
      context.missing(_isMutedMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chatId};
  @override
  Conversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conversation(
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chat_id'],
      )!,
      type: $ConversationsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      targetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_name'],
      )!,
      targetAvatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_avatar'],
      ),
      lastMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_id'],
      ),
      lastMessagePreview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_preview'],
      )!,
      lastMessageTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_message_time'],
      )!,
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      isMuted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_muted'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ConversationTypeDb, int, int> $convertertype =
      const EnumIndexConverter<ConversationTypeDb>(ConversationTypeDb.values);
}

class Conversation extends DataClass implements Insertable<Conversation> {
  /// 主键，会话ID
  final String chatId;

  /// 会话类型
  final ConversationTypeDb type;

  /// 会话名称
  final String targetName;

  /// 会话头像URL
  final String? targetAvatar;

  /// 最后一条消息ID
  final String? lastMessageId;

  /// 最后一条消息预览文本
  final String lastMessagePreview;

  /// 最后一条消息时间
  final DateTime lastMessageTime;

  /// 未读数
  final int unreadCount;

  /// 是否置顶
  final bool isPinned;

  /// 是否免打扰
  final bool isMuted;

  /// 更新时间
  final DateTime updatedAt;
  const Conversation({
    required this.chatId,
    required this.type,
    required this.targetName,
    this.targetAvatar,
    this.lastMessageId,
    required this.lastMessagePreview,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isPinned,
    required this.isMuted,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chat_id'] = Variable<String>(chatId);
    {
      map['type'] = Variable<int>(
        $ConversationsTable.$convertertype.toSql(type),
      );
    }
    map['target_name'] = Variable<String>(targetName);
    if (!nullToAbsent || targetAvatar != null) {
      map['target_avatar'] = Variable<String>(targetAvatar);
    }
    if (!nullToAbsent || lastMessageId != null) {
      map['last_message_id'] = Variable<String>(lastMessageId);
    }
    map['last_message_preview'] = Variable<String>(lastMessagePreview);
    map['last_message_time'] = Variable<DateTime>(lastMessageTime);
    map['unread_count'] = Variable<int>(unreadCount);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['is_muted'] = Variable<bool>(isMuted);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      chatId: Value(chatId),
      type: Value(type),
      targetName: Value(targetName),
      targetAvatar: targetAvatar == null && nullToAbsent
          ? const Value.absent()
          : Value(targetAvatar),
      lastMessageId: lastMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageId),
      lastMessagePreview: Value(lastMessagePreview),
      lastMessageTime: Value(lastMessageTime),
      unreadCount: Value(unreadCount),
      isPinned: Value(isPinned),
      isMuted: Value(isMuted),
      updatedAt: Value(updatedAt),
    );
  }

  factory Conversation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Conversation(
      chatId: serializer.fromJson<String>(json['chatId']),
      type: $ConversationsTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      targetName: serializer.fromJson<String>(json['targetName']),
      targetAvatar: serializer.fromJson<String?>(json['targetAvatar']),
      lastMessageId: serializer.fromJson<String?>(json['lastMessageId']),
      lastMessagePreview: serializer.fromJson<String>(
        json['lastMessagePreview'],
      ),
      lastMessageTime: serializer.fromJson<DateTime>(json['lastMessageTime']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      isMuted: serializer.fromJson<bool>(json['isMuted']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chatId': serializer.toJson<String>(chatId),
      'type': serializer.toJson<int>(
        $ConversationsTable.$convertertype.toJson(type),
      ),
      'targetName': serializer.toJson<String>(targetName),
      'targetAvatar': serializer.toJson<String?>(targetAvatar),
      'lastMessageId': serializer.toJson<String?>(lastMessageId),
      'lastMessagePreview': serializer.toJson<String>(lastMessagePreview),
      'lastMessageTime': serializer.toJson<DateTime>(lastMessageTime),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'isPinned': serializer.toJson<bool>(isPinned),
      'isMuted': serializer.toJson<bool>(isMuted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Conversation copyWith({
    String? chatId,
    ConversationTypeDb? type,
    String? targetName,
    Value<String?> targetAvatar = const Value.absent(),
    Value<String?> lastMessageId = const Value.absent(),
    String? lastMessagePreview,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
    DateTime? updatedAt,
  }) => Conversation(
    chatId: chatId ?? this.chatId,
    type: type ?? this.type,
    targetName: targetName ?? this.targetName,
    targetAvatar: targetAvatar.present ? targetAvatar.value : this.targetAvatar,
    lastMessageId: lastMessageId.present
        ? lastMessageId.value
        : this.lastMessageId,
    lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    unreadCount: unreadCount ?? this.unreadCount,
    isPinned: isPinned ?? this.isPinned,
    isMuted: isMuted ?? this.isMuted,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Conversation copyWithCompanion(ConversationsCompanion data) {
    return Conversation(
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      type: data.type.present ? data.type.value : this.type,
      targetName: data.targetName.present
          ? data.targetName.value
          : this.targetName,
      targetAvatar: data.targetAvatar.present
          ? data.targetAvatar.value
          : this.targetAvatar,
      lastMessageId: data.lastMessageId.present
          ? data.lastMessageId.value
          : this.lastMessageId,
      lastMessagePreview: data.lastMessagePreview.present
          ? data.lastMessagePreview.value
          : this.lastMessagePreview,
      lastMessageTime: data.lastMessageTime.present
          ? data.lastMessageTime.value
          : this.lastMessageTime,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      isMuted: data.isMuted.present ? data.isMuted.value : this.isMuted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conversation(')
          ..write('chatId: $chatId, ')
          ..write('type: $type, ')
          ..write('targetName: $targetName, ')
          ..write('targetAvatar: $targetAvatar, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('lastMessageTime: $lastMessageTime, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('isPinned: $isPinned, ')
          ..write('isMuted: $isMuted, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    chatId,
    type,
    targetName,
    targetAvatar,
    lastMessageId,
    lastMessagePreview,
    lastMessageTime,
    unreadCount,
    isPinned,
    isMuted,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conversation &&
          other.chatId == this.chatId &&
          other.type == this.type &&
          other.targetName == this.targetName &&
          other.targetAvatar == this.targetAvatar &&
          other.lastMessageId == this.lastMessageId &&
          other.lastMessagePreview == this.lastMessagePreview &&
          other.lastMessageTime == this.lastMessageTime &&
          other.unreadCount == this.unreadCount &&
          other.isPinned == this.isPinned &&
          other.isMuted == this.isMuted &&
          other.updatedAt == this.updatedAt);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<String> chatId;
  final Value<ConversationTypeDb> type;
  final Value<String> targetName;
  final Value<String?> targetAvatar;
  final Value<String?> lastMessageId;
  final Value<String> lastMessagePreview;
  final Value<DateTime> lastMessageTime;
  final Value<int> unreadCount;
  final Value<bool> isPinned;
  final Value<bool> isMuted;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.chatId = const Value.absent(),
    this.type = const Value.absent(),
    this.targetName = const Value.absent(),
    this.targetAvatar = const Value.absent(),
    this.lastMessageId = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.lastMessageTime = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isMuted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String chatId,
    required ConversationTypeDb type,
    required String targetName,
    this.targetAvatar = const Value.absent(),
    this.lastMessageId = const Value.absent(),
    required String lastMessagePreview,
    required DateTime lastMessageTime,
    required int unreadCount,
    required bool isPinned,
    required bool isMuted,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : chatId = Value(chatId),
       type = Value(type),
       targetName = Value(targetName),
       lastMessagePreview = Value(lastMessagePreview),
       lastMessageTime = Value(lastMessageTime),
       unreadCount = Value(unreadCount),
       isPinned = Value(isPinned),
       isMuted = Value(isMuted),
       updatedAt = Value(updatedAt);
  static Insertable<Conversation> custom({
    Expression<String>? chatId,
    Expression<int>? type,
    Expression<String>? targetName,
    Expression<String>? targetAvatar,
    Expression<String>? lastMessageId,
    Expression<String>? lastMessagePreview,
    Expression<DateTime>? lastMessageTime,
    Expression<int>? unreadCount,
    Expression<bool>? isPinned,
    Expression<bool>? isMuted,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chatId != null) 'chat_id': chatId,
      if (type != null) 'type': type,
      if (targetName != null) 'target_name': targetName,
      if (targetAvatar != null) 'target_avatar': targetAvatar,
      if (lastMessageId != null) 'last_message_id': lastMessageId,
      if (lastMessagePreview != null)
        'last_message_preview': lastMessagePreview,
      if (lastMessageTime != null) 'last_message_time': lastMessageTime,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (isPinned != null) 'is_pinned': isPinned,
      if (isMuted != null) 'is_muted': isMuted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith({
    Value<String>? chatId,
    Value<ConversationTypeDb>? type,
    Value<String>? targetName,
    Value<String?>? targetAvatar,
    Value<String?>? lastMessageId,
    Value<String>? lastMessagePreview,
    Value<DateTime>? lastMessageTime,
    Value<int>? unreadCount,
    Value<bool>? isPinned,
    Value<bool>? isMuted,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ConversationsCompanion(
      chatId: chatId ?? this.chatId,
      type: type ?? this.type,
      targetName: targetName ?? this.targetName,
      targetAvatar: targetAvatar ?? this.targetAvatar,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $ConversationsTable.$convertertype.toSql(type.value),
      );
    }
    if (targetName.present) {
      map['target_name'] = Variable<String>(targetName.value);
    }
    if (targetAvatar.present) {
      map['target_avatar'] = Variable<String>(targetAvatar.value);
    }
    if (lastMessageId.present) {
      map['last_message_id'] = Variable<String>(lastMessageId.value);
    }
    if (lastMessagePreview.present) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview.value);
    }
    if (lastMessageTime.present) {
      map['last_message_time'] = Variable<DateTime>(lastMessageTime.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (isMuted.present) {
      map['is_muted'] = Variable<bool>(isMuted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('chatId: $chatId, ')
          ..write('type: $type, ')
          ..write('targetName: $targetName, ')
          ..write('targetAvatar: $targetAvatar, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('lastMessageTime: $lastMessageTime, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('isPinned: $isPinned, ')
          ..write('isMuted: $isMuted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ImDatabase extends GeneratedDatabase {
  _$ImDatabase(QueryExecutor e) : super(e);
  $ImDatabaseManager get managers => $ImDatabaseManager(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final Index idxMessagesChatId = Index(
    'idx_messages_chat_id',
    'CREATE INDEX idx_messages_chat_id ON messages (chat_id)',
  );
  late final Index idxMessagesClientMessageId = Index(
    'idx_messages_client_message_id',
    'CREATE UNIQUE INDEX idx_messages_client_message_id ON messages (client_message_id)',
  );
  late final MessageDao messageDao = MessageDao(this as ImDatabase);
  late final ConversationDao conversationDao = ConversationDao(
    this as ImDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    messages,
    conversations,
    idxMessagesChatId,
    idxMessagesClientMessageId,
  ];
}

typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String messageId,
      Value<String?> clientMessageId,
      required String chatId,
      required MessageTypeDb type,
      required MessageStatusDb status,
      required String content,
      required String senderId,
      required String senderName,
      Value<String?> senderAvatar,
      required DateTime sentAt,
      Value<String?> sequence,
      required bool isOutgoing,
      Value<String?> extraJson,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> messageId,
      Value<String?> clientMessageId,
      Value<String> chatId,
      Value<MessageTypeDb> type,
      Value<MessageStatusDb> status,
      Value<String> content,
      Value<String> senderId,
      Value<String> senderName,
      Value<String?> senderAvatar,
      Value<DateTime> sentAt,
      Value<String?> sequence,
      Value<bool> isOutgoing,
      Value<String?> extraJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$ImDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientMessageId => $composableBuilder(
    column: $table.clientMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MessageTypeDb, MessageTypeDb, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<MessageStatusDb, MessageStatusDb, int>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderAvatar => $composableBuilder(
    column: $table.senderAvatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOutgoing => $composableBuilder(
    column: $table.isOutgoing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extraJson => $composableBuilder(
    column: $table.extraJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$ImDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientMessageId => $composableBuilder(
    column: $table.clientMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderAvatar => $composableBuilder(
    column: $table.senderAvatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOutgoing => $composableBuilder(
    column: $table.isOutgoing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extraJson => $composableBuilder(
    column: $table.extraJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$ImDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get clientMessageId => $composableBuilder(
    column: $table.clientMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MessageTypeDb, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MessageStatusDb, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get senderAvatar => $composableBuilder(
    column: $table.senderAvatar,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<String> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<bool> get isOutgoing => $composableBuilder(
    column: $table.isOutgoing,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extraJson =>
      $composableBuilder(column: $table.extraJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$ImDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, BaseReferences<_$ImDatabase, $MessagesTable, Message>),
          Message,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$ImDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<String?> clientMessageId = const Value.absent(),
                Value<String> chatId = const Value.absent(),
                Value<MessageTypeDb> type = const Value.absent(),
                Value<MessageStatusDb> status = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> senderId = const Value.absent(),
                Value<String> senderName = const Value.absent(),
                Value<String?> senderAvatar = const Value.absent(),
                Value<DateTime> sentAt = const Value.absent(),
                Value<String?> sequence = const Value.absent(),
                Value<bool> isOutgoing = const Value.absent(),
                Value<String?> extraJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                messageId: messageId,
                clientMessageId: clientMessageId,
                chatId: chatId,
                type: type,
                status: status,
                content: content,
                senderId: senderId,
                senderName: senderName,
                senderAvatar: senderAvatar,
                sentAt: sentAt,
                sequence: sequence,
                isOutgoing: isOutgoing,
                extraJson: extraJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                Value<String?> clientMessageId = const Value.absent(),
                required String chatId,
                required MessageTypeDb type,
                required MessageStatusDb status,
                required String content,
                required String senderId,
                required String senderName,
                Value<String?> senderAvatar = const Value.absent(),
                required DateTime sentAt,
                Value<String?> sequence = const Value.absent(),
                required bool isOutgoing,
                Value<String?> extraJson = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                messageId: messageId,
                clientMessageId: clientMessageId,
                chatId: chatId,
                type: type,
                status: status,
                content: content,
                senderId: senderId,
                senderName: senderName,
                senderAvatar: senderAvatar,
                sentAt: sentAt,
                sequence: sequence,
                isOutgoing: isOutgoing,
                extraJson: extraJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$ImDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, BaseReferences<_$ImDatabase, $MessagesTable, Message>),
      Message,
      PrefetchHooks Function()
    >;
typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      required String chatId,
      required ConversationTypeDb type,
      required String targetName,
      Value<String?> targetAvatar,
      Value<String?> lastMessageId,
      required String lastMessagePreview,
      required DateTime lastMessageTime,
      required int unreadCount,
      required bool isPinned,
      required bool isMuted,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<String> chatId,
      Value<ConversationTypeDb> type,
      Value<String> targetName,
      Value<String?> targetAvatar,
      Value<String?> lastMessageId,
      Value<String> lastMessagePreview,
      Value<DateTime> lastMessageTime,
      Value<int> unreadCount,
      Value<bool> isPinned,
      Value<bool> isMuted,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ConversationsTableFilterComposer
    extends Composer<_$ImDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ConversationTypeDb, ConversationTypeDb, int>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get targetName => $composableBuilder(
    column: $table.targetName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetAvatar => $composableBuilder(
    column: $table.targetAvatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageId => $composableBuilder(
    column: $table.lastMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastMessageTime => $composableBuilder(
    column: $table.lastMessageTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMuted => $composableBuilder(
    column: $table.isMuted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$ImDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetName => $composableBuilder(
    column: $table.targetName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetAvatar => $composableBuilder(
    column: $table.targetAvatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageId => $composableBuilder(
    column: $table.lastMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastMessageTime => $composableBuilder(
    column: $table.lastMessageTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMuted => $composableBuilder(
    column: $table.isMuted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$ImDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ConversationTypeDb, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get targetName => $composableBuilder(
    column: $table.targetName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetAvatar => $composableBuilder(
    column: $table.targetAvatar,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageId => $composableBuilder(
    column: $table.lastMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastMessageTime => $composableBuilder(
    column: $table.lastMessageTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<bool> get isMuted =>
      $composableBuilder(column: $table.isMuted, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ConversationsTableTableManager
    extends
        RootTableManager<
          _$ImDatabase,
          $ConversationsTable,
          Conversation,
          $$ConversationsTableFilterComposer,
          $$ConversationsTableOrderingComposer,
          $$ConversationsTableAnnotationComposer,
          $$ConversationsTableCreateCompanionBuilder,
          $$ConversationsTableUpdateCompanionBuilder,
          (
            Conversation,
            BaseReferences<_$ImDatabase, $ConversationsTable, Conversation>,
          ),
          Conversation,
          PrefetchHooks Function()
        > {
  $$ConversationsTableTableManager(_$ImDatabase db, $ConversationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> chatId = const Value.absent(),
                Value<ConversationTypeDb> type = const Value.absent(),
                Value<String> targetName = const Value.absent(),
                Value<String?> targetAvatar = const Value.absent(),
                Value<String?> lastMessageId = const Value.absent(),
                Value<String> lastMessagePreview = const Value.absent(),
                Value<DateTime> lastMessageTime = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isMuted = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion(
                chatId: chatId,
                type: type,
                targetName: targetName,
                targetAvatar: targetAvatar,
                lastMessageId: lastMessageId,
                lastMessagePreview: lastMessagePreview,
                lastMessageTime: lastMessageTime,
                unreadCount: unreadCount,
                isPinned: isPinned,
                isMuted: isMuted,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String chatId,
                required ConversationTypeDb type,
                required String targetName,
                Value<String?> targetAvatar = const Value.absent(),
                Value<String?> lastMessageId = const Value.absent(),
                required String lastMessagePreview,
                required DateTime lastMessageTime,
                required int unreadCount,
                required bool isPinned,
                required bool isMuted,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion.insert(
                chatId: chatId,
                type: type,
                targetName: targetName,
                targetAvatar: targetAvatar,
                lastMessageId: lastMessageId,
                lastMessagePreview: lastMessagePreview,
                lastMessageTime: lastMessageTime,
                unreadCount: unreadCount,
                isPinned: isPinned,
                isMuted: isMuted,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$ImDatabase,
      $ConversationsTable,
      Conversation,
      $$ConversationsTableFilterComposer,
      $$ConversationsTableOrderingComposer,
      $$ConversationsTableAnnotationComposer,
      $$ConversationsTableCreateCompanionBuilder,
      $$ConversationsTableUpdateCompanionBuilder,
      (
        Conversation,
        BaseReferences<_$ImDatabase, $ConversationsTable, Conversation>,
      ),
      Conversation,
      PrefetchHooks Function()
    >;

class $ImDatabaseManager {
  final _$ImDatabase _db;
  $ImDatabaseManager(this._db);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
}
