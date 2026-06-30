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
  static const VerificationMeta _quoteInfoJsonMeta = const VerificationMeta(
    'quoteInfoJson',
  );
  @override
  late final GeneratedColumn<String> quoteInfoJson = GeneratedColumn<String>(
    'quote_info_json',
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    quoteInfoJson,
    createdAt,
    userId,
    cachedAt,
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
    if (data.containsKey('quote_info_json')) {
      context.handle(
        _quoteInfoJsonMeta,
        quoteInfoJson.isAcceptableOrUnknown(
          data['quote_info_json']!,
          _quoteInfoJsonMeta,
        ),
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
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
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
      quoteInfoJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quote_info_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
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

  /// 引用信息JSON（对应 QuoteInfo）
  final String? quoteInfoJson;

  /// 本地创建时间戳
  final DateTime createdAt;

  /// === 用户隔离 ===
  final String userId;

  /// === 缓存时间戳（毫秒级） ===
  /// 注意：此字段由 Mapper 显式设置，不使用默认值以避免类加载时固定时间戳
  final int cachedAt;
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
    this.quoteInfoJson,
    required this.createdAt,
    required this.userId,
    required this.cachedAt,
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
    if (!nullToAbsent || quoteInfoJson != null) {
      map['quote_info_json'] = Variable<String>(quoteInfoJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['user_id'] = Variable<String>(userId);
    map['cached_at'] = Variable<int>(cachedAt);
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
      quoteInfoJson: quoteInfoJson == null && nullToAbsent
          ? const Value.absent()
          : Value(quoteInfoJson),
      createdAt: Value(createdAt),
      userId: Value(userId),
      cachedAt: Value(cachedAt),
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
      quoteInfoJson: serializer.fromJson<String?>(json['quoteInfoJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      userId: serializer.fromJson<String>(json['userId']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
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
      'quoteInfoJson': serializer.toJson<String?>(quoteInfoJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'userId': serializer.toJson<String>(userId),
      'cachedAt': serializer.toJson<int>(cachedAt),
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
    Value<String?> quoteInfoJson = const Value.absent(),
    DateTime? createdAt,
    String? userId,
    int? cachedAt,
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
    quoteInfoJson: quoteInfoJson.present
        ? quoteInfoJson.value
        : this.quoteInfoJson,
    createdAt: createdAt ?? this.createdAt,
    userId: userId ?? this.userId,
    cachedAt: cachedAt ?? this.cachedAt,
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
      quoteInfoJson: data.quoteInfoJson.present
          ? data.quoteInfoJson.value
          : this.quoteInfoJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
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
          ..write('quoteInfoJson: $quoteInfoJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('userId: $userId, ')
          ..write('cachedAt: $cachedAt')
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
    quoteInfoJson,
    createdAt,
    userId,
    cachedAt,
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
          other.quoteInfoJson == this.quoteInfoJson &&
          other.createdAt == this.createdAt &&
          other.userId == this.userId &&
          other.cachedAt == this.cachedAt);
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
  final Value<String?> quoteInfoJson;
  final Value<DateTime> createdAt;
  final Value<String> userId;
  final Value<int> cachedAt;
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
    this.quoteInfoJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.cachedAt = const Value.absent(),
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
    this.quoteInfoJson = const Value.absent(),
    required DateTime createdAt,
    this.userId = const Value.absent(),
    required int cachedAt,
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
       createdAt = Value(createdAt),
       cachedAt = Value(cachedAt);
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
    Expression<String>? quoteInfoJson,
    Expression<DateTime>? createdAt,
    Expression<String>? userId,
    Expression<int>? cachedAt,
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
      if (quoteInfoJson != null) 'quote_info_json': quoteInfoJson,
      if (createdAt != null) 'created_at': createdAt,
      if (userId != null) 'user_id': userId,
      if (cachedAt != null) 'cached_at': cachedAt,
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
    Value<String?>? quoteInfoJson,
    Value<DateTime>? createdAt,
    Value<String>? userId,
    Value<int>? cachedAt,
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
      quoteInfoJson: quoteInfoJson ?? this.quoteInfoJson,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      cachedAt: cachedAt ?? this.cachedAt,
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
    if (quoteInfoJson.present) {
      map['quote_info_json'] = Variable<String>(quoteInfoJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
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
          ..write('quoteInfoJson: $quoteInfoJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('userId: $userId, ')
          ..write('cachedAt: $cachedAt, ')
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
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
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
  static const VerificationMeta _lastMessageSequenceMeta =
      const VerificationMeta('lastMessageSequence');
  @override
  late final GeneratedColumn<String> lastMessageSequence =
      GeneratedColumn<String>(
        'last_message_sequence',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastReadSequenceMeta = const VerificationMeta(
    'lastReadSequence',
  );
  @override
  late final GeneratedColumn<String> lastReadSequence = GeneratedColumn<String>(
    'last_read_sequence',
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
  static const VerificationMeta _lastMessageTypeMeta = const VerificationMeta(
    'lastMessageType',
  );
  @override
  late final GeneratedColumn<String> lastMessageType = GeneratedColumn<String>(
    'last_message_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastMessageSenderNameMeta =
      const VerificationMeta('lastMessageSenderName');
  @override
  late final GeneratedColumn<String> lastMessageSenderName =
      GeneratedColumn<String>(
        'last_message_sender_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastMessageIsSelfMeta = const VerificationMeta(
    'lastMessageIsSelf',
  );
  @override
  late final GeneratedColumn<bool> lastMessageIsSelf = GeneratedColumn<bool>(
    'last_message_is_self',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("last_message_is_self" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastMessageStatusMeta = const VerificationMeta(
    'lastMessageStatus',
  );
  @override
  late final GeneratedColumn<String> lastMessageStatus =
      GeneratedColumn<String>(
        'last_message_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('sent'),
      );
  static const VerificationMeta _lastMessageHasAtMeMeta =
      const VerificationMeta('lastMessageHasAtMe');
  @override
  late final GeneratedColumn<bool> lastMessageHasAtMe = GeneratedColumn<bool>(
    'last_message_has_at_me',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("last_message_has_at_me" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_muted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupMemberCountMeta = const VerificationMeta(
    'groupMemberCount',
  );
  @override
  late final GeneratedColumn<int> groupMemberCount = GeneratedColumn<int>(
    'group_member_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _groupMemberStatusMeta = const VerificationMeta(
    'groupMemberStatus',
  );
  @override
  late final GeneratedColumn<int> groupMemberStatus = GeneratedColumn<int>(
    'group_member_status',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    chatId,
    type,
    targetName,
    targetAvatar,
    targetId,
    lastMessageId,
    lastMessageSequence,
    lastReadSequence,
    lastMessagePreview,
    lastMessageType,
    lastMessageSenderName,
    lastMessageIsSelf,
    lastMessageStatus,
    lastMessageHasAtMe,
    lastMessageTime,
    unreadCount,
    isPinned,
    isMuted,
    updatedAt,
    userId,
    cachedAt,
    groupMemberCount,
    groupMemberStatus,
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
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
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
    if (data.containsKey('last_message_sequence')) {
      context.handle(
        _lastMessageSequenceMeta,
        lastMessageSequence.isAcceptableOrUnknown(
          data['last_message_sequence']!,
          _lastMessageSequenceMeta,
        ),
      );
    }
    if (data.containsKey('last_read_sequence')) {
      context.handle(
        _lastReadSequenceMeta,
        lastReadSequence.isAcceptableOrUnknown(
          data['last_read_sequence']!,
          _lastReadSequenceMeta,
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
    if (data.containsKey('last_message_type')) {
      context.handle(
        _lastMessageTypeMeta,
        lastMessageType.isAcceptableOrUnknown(
          data['last_message_type']!,
          _lastMessageTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastMessageTypeMeta);
    }
    if (data.containsKey('last_message_sender_name')) {
      context.handle(
        _lastMessageSenderNameMeta,
        lastMessageSenderName.isAcceptableOrUnknown(
          data['last_message_sender_name']!,
          _lastMessageSenderNameMeta,
        ),
      );
    }
    if (data.containsKey('last_message_is_self')) {
      context.handle(
        _lastMessageIsSelfMeta,
        lastMessageIsSelf.isAcceptableOrUnknown(
          data['last_message_is_self']!,
          _lastMessageIsSelfMeta,
        ),
      );
    }
    if (data.containsKey('last_message_status')) {
      context.handle(
        _lastMessageStatusMeta,
        lastMessageStatus.isAcceptableOrUnknown(
          data['last_message_status']!,
          _lastMessageStatusMeta,
        ),
      );
    }
    if (data.containsKey('last_message_has_at_me')) {
      context.handle(
        _lastMessageHasAtMeMeta,
        lastMessageHasAtMe.isAcceptableOrUnknown(
          data['last_message_has_at_me']!,
          _lastMessageHasAtMeMeta,
        ),
      );
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
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('is_muted')) {
      context.handle(
        _isMutedMeta,
        isMuted.isAcceptableOrUnknown(data['is_muted']!, _isMutedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('group_member_count')) {
      context.handle(
        _groupMemberCountMeta,
        groupMemberCount.isAcceptableOrUnknown(
          data['group_member_count']!,
          _groupMemberCountMeta,
        ),
      );
    }
    if (data.containsKey('group_member_status')) {
      context.handle(
        _groupMemberStatusMeta,
        groupMemberStatus.isAcceptableOrUnknown(
          data['group_member_status']!,
          _groupMemberStatusMeta,
        ),
      );
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
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      ),
      lastMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_id'],
      ),
      lastMessageSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_sequence'],
      ),
      lastReadSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_read_sequence'],
      ),
      lastMessagePreview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_preview'],
      )!,
      lastMessageType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_type'],
      )!,
      lastMessageSenderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_sender_name'],
      ),
      lastMessageIsSelf: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}last_message_is_self'],
      )!,
      lastMessageStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_status'],
      )!,
      lastMessageHasAtMe: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}last_message_has_at_me'],
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
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
      groupMemberCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_member_count'],
      )!,
      groupMemberStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_member_status'],
      ),
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

  /// 对方用户ID（单聊时的 targetId）
  final String? targetId;

  /// 最后一条消息ID
  final String? lastMessageId;

  /// 最后一条消息序列号
  final String? lastMessageSequence;

  /// 最后已读序列号
  final String? lastReadSequence;

  /// 最后一条消息预览文本
  final String lastMessagePreview;

  /// 最后一条消息类型（存储为字符串名称）
  final String lastMessageType;

  /// 最后一条消息发送者名称
  final String? lastMessageSenderName;

  /// 最后一条消息是否自己发送
  final bool lastMessageIsSelf;

  /// 最后一条消息状态（存储为字符串名称）
  final String lastMessageStatus;

  /// 是否有 @我
  final bool lastMessageHasAtMe;

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

  /// === 用户隔离 ===
  final String userId;

  /// === 缓存时间戳（毫秒级） ===
  /// 注意：此字段由 Mapper 显式设置，不使用默认值以避免类加载时固定时间戳
  final int cachedAt;

  /// === 群成员数量 ===
  final int groupMemberCount;

  /// === 群成员状态（1=已退出, 2=已被踢, 3=已解散） ===
  final int? groupMemberStatus;
  const Conversation({
    required this.chatId,
    required this.type,
    required this.targetName,
    this.targetAvatar,
    this.targetId,
    this.lastMessageId,
    this.lastMessageSequence,
    this.lastReadSequence,
    required this.lastMessagePreview,
    required this.lastMessageType,
    this.lastMessageSenderName,
    required this.lastMessageIsSelf,
    required this.lastMessageStatus,
    required this.lastMessageHasAtMe,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isPinned,
    required this.isMuted,
    required this.updatedAt,
    required this.userId,
    required this.cachedAt,
    required this.groupMemberCount,
    this.groupMemberStatus,
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
    if (!nullToAbsent || targetId != null) {
      map['target_id'] = Variable<String>(targetId);
    }
    if (!nullToAbsent || lastMessageId != null) {
      map['last_message_id'] = Variable<String>(lastMessageId);
    }
    if (!nullToAbsent || lastMessageSequence != null) {
      map['last_message_sequence'] = Variable<String>(lastMessageSequence);
    }
    if (!nullToAbsent || lastReadSequence != null) {
      map['last_read_sequence'] = Variable<String>(lastReadSequence);
    }
    map['last_message_preview'] = Variable<String>(lastMessagePreview);
    map['last_message_type'] = Variable<String>(lastMessageType);
    if (!nullToAbsent || lastMessageSenderName != null) {
      map['last_message_sender_name'] = Variable<String>(lastMessageSenderName);
    }
    map['last_message_is_self'] = Variable<bool>(lastMessageIsSelf);
    map['last_message_status'] = Variable<String>(lastMessageStatus);
    map['last_message_has_at_me'] = Variable<bool>(lastMessageHasAtMe);
    map['last_message_time'] = Variable<DateTime>(lastMessageTime);
    map['unread_count'] = Variable<int>(unreadCount);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['is_muted'] = Variable<bool>(isMuted);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['user_id'] = Variable<String>(userId);
    map['cached_at'] = Variable<int>(cachedAt);
    map['group_member_count'] = Variable<int>(groupMemberCount);
    if (!nullToAbsent || groupMemberStatus != null) {
      map['group_member_status'] = Variable<int>(groupMemberStatus);
    }
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
      targetId: targetId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetId),
      lastMessageId: lastMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageId),
      lastMessageSequence: lastMessageSequence == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageSequence),
      lastReadSequence: lastReadSequence == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadSequence),
      lastMessagePreview: Value(lastMessagePreview),
      lastMessageType: Value(lastMessageType),
      lastMessageSenderName: lastMessageSenderName == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageSenderName),
      lastMessageIsSelf: Value(lastMessageIsSelf),
      lastMessageStatus: Value(lastMessageStatus),
      lastMessageHasAtMe: Value(lastMessageHasAtMe),
      lastMessageTime: Value(lastMessageTime),
      unreadCount: Value(unreadCount),
      isPinned: Value(isPinned),
      isMuted: Value(isMuted),
      updatedAt: Value(updatedAt),
      userId: Value(userId),
      cachedAt: Value(cachedAt),
      groupMemberCount: Value(groupMemberCount),
      groupMemberStatus: groupMemberStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(groupMemberStatus),
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
      targetId: serializer.fromJson<String?>(json['targetId']),
      lastMessageId: serializer.fromJson<String?>(json['lastMessageId']),
      lastMessageSequence: serializer.fromJson<String?>(
        json['lastMessageSequence'],
      ),
      lastReadSequence: serializer.fromJson<String?>(json['lastReadSequence']),
      lastMessagePreview: serializer.fromJson<String>(
        json['lastMessagePreview'],
      ),
      lastMessageType: serializer.fromJson<String>(json['lastMessageType']),
      lastMessageSenderName: serializer.fromJson<String?>(
        json['lastMessageSenderName'],
      ),
      lastMessageIsSelf: serializer.fromJson<bool>(json['lastMessageIsSelf']),
      lastMessageStatus: serializer.fromJson<String>(json['lastMessageStatus']),
      lastMessageHasAtMe: serializer.fromJson<bool>(json['lastMessageHasAtMe']),
      lastMessageTime: serializer.fromJson<DateTime>(json['lastMessageTime']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      isMuted: serializer.fromJson<bool>(json['isMuted']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      userId: serializer.fromJson<String>(json['userId']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
      groupMemberCount: serializer.fromJson<int>(json['groupMemberCount']),
      groupMemberStatus: serializer.fromJson<int?>(json['groupMemberStatus']),
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
      'targetId': serializer.toJson<String?>(targetId),
      'lastMessageId': serializer.toJson<String?>(lastMessageId),
      'lastMessageSequence': serializer.toJson<String?>(lastMessageSequence),
      'lastReadSequence': serializer.toJson<String?>(lastReadSequence),
      'lastMessagePreview': serializer.toJson<String>(lastMessagePreview),
      'lastMessageType': serializer.toJson<String>(lastMessageType),
      'lastMessageSenderName': serializer.toJson<String?>(
        lastMessageSenderName,
      ),
      'lastMessageIsSelf': serializer.toJson<bool>(lastMessageIsSelf),
      'lastMessageStatus': serializer.toJson<String>(lastMessageStatus),
      'lastMessageHasAtMe': serializer.toJson<bool>(lastMessageHasAtMe),
      'lastMessageTime': serializer.toJson<DateTime>(lastMessageTime),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'isPinned': serializer.toJson<bool>(isPinned),
      'isMuted': serializer.toJson<bool>(isMuted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'userId': serializer.toJson<String>(userId),
      'cachedAt': serializer.toJson<int>(cachedAt),
      'groupMemberCount': serializer.toJson<int>(groupMemberCount),
      'groupMemberStatus': serializer.toJson<int?>(groupMemberStatus),
    };
  }

  Conversation copyWith({
    String? chatId,
    ConversationTypeDb? type,
    String? targetName,
    Value<String?> targetAvatar = const Value.absent(),
    Value<String?> targetId = const Value.absent(),
    Value<String?> lastMessageId = const Value.absent(),
    Value<String?> lastMessageSequence = const Value.absent(),
    Value<String?> lastReadSequence = const Value.absent(),
    String? lastMessagePreview,
    String? lastMessageType,
    Value<String?> lastMessageSenderName = const Value.absent(),
    bool? lastMessageIsSelf,
    String? lastMessageStatus,
    bool? lastMessageHasAtMe,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
    DateTime? updatedAt,
    String? userId,
    int? cachedAt,
    int? groupMemberCount,
    Value<int?> groupMemberStatus = const Value.absent(),
  }) => Conversation(
    chatId: chatId ?? this.chatId,
    type: type ?? this.type,
    targetName: targetName ?? this.targetName,
    targetAvatar: targetAvatar.present ? targetAvatar.value : this.targetAvatar,
    targetId: targetId.present ? targetId.value : this.targetId,
    lastMessageId: lastMessageId.present
        ? lastMessageId.value
        : this.lastMessageId,
    lastMessageSequence: lastMessageSequence.present
        ? lastMessageSequence.value
        : this.lastMessageSequence,
    lastReadSequence: lastReadSequence.present
        ? lastReadSequence.value
        : this.lastReadSequence,
    lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    lastMessageType: lastMessageType ?? this.lastMessageType,
    lastMessageSenderName: lastMessageSenderName.present
        ? lastMessageSenderName.value
        : this.lastMessageSenderName,
    lastMessageIsSelf: lastMessageIsSelf ?? this.lastMessageIsSelf,
    lastMessageStatus: lastMessageStatus ?? this.lastMessageStatus,
    lastMessageHasAtMe: lastMessageHasAtMe ?? this.lastMessageHasAtMe,
    lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    unreadCount: unreadCount ?? this.unreadCount,
    isPinned: isPinned ?? this.isPinned,
    isMuted: isMuted ?? this.isMuted,
    updatedAt: updatedAt ?? this.updatedAt,
    userId: userId ?? this.userId,
    cachedAt: cachedAt ?? this.cachedAt,
    groupMemberCount: groupMemberCount ?? this.groupMemberCount,
    groupMemberStatus: groupMemberStatus.present
        ? groupMemberStatus.value
        : this.groupMemberStatus,
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
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      lastMessageId: data.lastMessageId.present
          ? data.lastMessageId.value
          : this.lastMessageId,
      lastMessageSequence: data.lastMessageSequence.present
          ? data.lastMessageSequence.value
          : this.lastMessageSequence,
      lastReadSequence: data.lastReadSequence.present
          ? data.lastReadSequence.value
          : this.lastReadSequence,
      lastMessagePreview: data.lastMessagePreview.present
          ? data.lastMessagePreview.value
          : this.lastMessagePreview,
      lastMessageType: data.lastMessageType.present
          ? data.lastMessageType.value
          : this.lastMessageType,
      lastMessageSenderName: data.lastMessageSenderName.present
          ? data.lastMessageSenderName.value
          : this.lastMessageSenderName,
      lastMessageIsSelf: data.lastMessageIsSelf.present
          ? data.lastMessageIsSelf.value
          : this.lastMessageIsSelf,
      lastMessageStatus: data.lastMessageStatus.present
          ? data.lastMessageStatus.value
          : this.lastMessageStatus,
      lastMessageHasAtMe: data.lastMessageHasAtMe.present
          ? data.lastMessageHasAtMe.value
          : this.lastMessageHasAtMe,
      lastMessageTime: data.lastMessageTime.present
          ? data.lastMessageTime.value
          : this.lastMessageTime,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      isMuted: data.isMuted.present ? data.isMuted.value : this.isMuted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      groupMemberCount: data.groupMemberCount.present
          ? data.groupMemberCount.value
          : this.groupMemberCount,
      groupMemberStatus: data.groupMemberStatus.present
          ? data.groupMemberStatus.value
          : this.groupMemberStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conversation(')
          ..write('chatId: $chatId, ')
          ..write('type: $type, ')
          ..write('targetName: $targetName, ')
          ..write('targetAvatar: $targetAvatar, ')
          ..write('targetId: $targetId, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('lastMessageSequence: $lastMessageSequence, ')
          ..write('lastReadSequence: $lastReadSequence, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('lastMessageType: $lastMessageType, ')
          ..write('lastMessageSenderName: $lastMessageSenderName, ')
          ..write('lastMessageIsSelf: $lastMessageIsSelf, ')
          ..write('lastMessageStatus: $lastMessageStatus, ')
          ..write('lastMessageHasAtMe: $lastMessageHasAtMe, ')
          ..write('lastMessageTime: $lastMessageTime, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('isPinned: $isPinned, ')
          ..write('isMuted: $isMuted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('userId: $userId, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('groupMemberCount: $groupMemberCount, ')
          ..write('groupMemberStatus: $groupMemberStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    chatId,
    type,
    targetName,
    targetAvatar,
    targetId,
    lastMessageId,
    lastMessageSequence,
    lastReadSequence,
    lastMessagePreview,
    lastMessageType,
    lastMessageSenderName,
    lastMessageIsSelf,
    lastMessageStatus,
    lastMessageHasAtMe,
    lastMessageTime,
    unreadCount,
    isPinned,
    isMuted,
    updatedAt,
    userId,
    cachedAt,
    groupMemberCount,
    groupMemberStatus,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conversation &&
          other.chatId == this.chatId &&
          other.type == this.type &&
          other.targetName == this.targetName &&
          other.targetAvatar == this.targetAvatar &&
          other.targetId == this.targetId &&
          other.lastMessageId == this.lastMessageId &&
          other.lastMessageSequence == this.lastMessageSequence &&
          other.lastReadSequence == this.lastReadSequence &&
          other.lastMessagePreview == this.lastMessagePreview &&
          other.lastMessageType == this.lastMessageType &&
          other.lastMessageSenderName == this.lastMessageSenderName &&
          other.lastMessageIsSelf == this.lastMessageIsSelf &&
          other.lastMessageStatus == this.lastMessageStatus &&
          other.lastMessageHasAtMe == this.lastMessageHasAtMe &&
          other.lastMessageTime == this.lastMessageTime &&
          other.unreadCount == this.unreadCount &&
          other.isPinned == this.isPinned &&
          other.isMuted == this.isMuted &&
          other.updatedAt == this.updatedAt &&
          other.userId == this.userId &&
          other.cachedAt == this.cachedAt &&
          other.groupMemberCount == this.groupMemberCount &&
          other.groupMemberStatus == this.groupMemberStatus);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<String> chatId;
  final Value<ConversationTypeDb> type;
  final Value<String> targetName;
  final Value<String?> targetAvatar;
  final Value<String?> targetId;
  final Value<String?> lastMessageId;
  final Value<String?> lastMessageSequence;
  final Value<String?> lastReadSequence;
  final Value<String> lastMessagePreview;
  final Value<String> lastMessageType;
  final Value<String?> lastMessageSenderName;
  final Value<bool> lastMessageIsSelf;
  final Value<String> lastMessageStatus;
  final Value<bool> lastMessageHasAtMe;
  final Value<DateTime> lastMessageTime;
  final Value<int> unreadCount;
  final Value<bool> isPinned;
  final Value<bool> isMuted;
  final Value<DateTime> updatedAt;
  final Value<String> userId;
  final Value<int> cachedAt;
  final Value<int> groupMemberCount;
  final Value<int?> groupMemberStatus;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.chatId = const Value.absent(),
    this.type = const Value.absent(),
    this.targetName = const Value.absent(),
    this.targetAvatar = const Value.absent(),
    this.targetId = const Value.absent(),
    this.lastMessageId = const Value.absent(),
    this.lastMessageSequence = const Value.absent(),
    this.lastReadSequence = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.lastMessageType = const Value.absent(),
    this.lastMessageSenderName = const Value.absent(),
    this.lastMessageIsSelf = const Value.absent(),
    this.lastMessageStatus = const Value.absent(),
    this.lastMessageHasAtMe = const Value.absent(),
    this.lastMessageTime = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isMuted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.groupMemberCount = const Value.absent(),
    this.groupMemberStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String chatId,
    required ConversationTypeDb type,
    required String targetName,
    this.targetAvatar = const Value.absent(),
    this.targetId = const Value.absent(),
    this.lastMessageId = const Value.absent(),
    this.lastMessageSequence = const Value.absent(),
    this.lastReadSequence = const Value.absent(),
    required String lastMessagePreview,
    required String lastMessageType,
    this.lastMessageSenderName = const Value.absent(),
    this.lastMessageIsSelf = const Value.absent(),
    this.lastMessageStatus = const Value.absent(),
    this.lastMessageHasAtMe = const Value.absent(),
    required DateTime lastMessageTime,
    this.unreadCount = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isMuted = const Value.absent(),
    required DateTime updatedAt,
    this.userId = const Value.absent(),
    required int cachedAt,
    this.groupMemberCount = const Value.absent(),
    this.groupMemberStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : chatId = Value(chatId),
       type = Value(type),
       targetName = Value(targetName),
       lastMessagePreview = Value(lastMessagePreview),
       lastMessageType = Value(lastMessageType),
       lastMessageTime = Value(lastMessageTime),
       updatedAt = Value(updatedAt),
       cachedAt = Value(cachedAt);
  static Insertable<Conversation> custom({
    Expression<String>? chatId,
    Expression<int>? type,
    Expression<String>? targetName,
    Expression<String>? targetAvatar,
    Expression<String>? targetId,
    Expression<String>? lastMessageId,
    Expression<String>? lastMessageSequence,
    Expression<String>? lastReadSequence,
    Expression<String>? lastMessagePreview,
    Expression<String>? lastMessageType,
    Expression<String>? lastMessageSenderName,
    Expression<bool>? lastMessageIsSelf,
    Expression<String>? lastMessageStatus,
    Expression<bool>? lastMessageHasAtMe,
    Expression<DateTime>? lastMessageTime,
    Expression<int>? unreadCount,
    Expression<bool>? isPinned,
    Expression<bool>? isMuted,
    Expression<DateTime>? updatedAt,
    Expression<String>? userId,
    Expression<int>? cachedAt,
    Expression<int>? groupMemberCount,
    Expression<int>? groupMemberStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chatId != null) 'chat_id': chatId,
      if (type != null) 'type': type,
      if (targetName != null) 'target_name': targetName,
      if (targetAvatar != null) 'target_avatar': targetAvatar,
      if (targetId != null) 'target_id': targetId,
      if (lastMessageId != null) 'last_message_id': lastMessageId,
      if (lastMessageSequence != null)
        'last_message_sequence': lastMessageSequence,
      if (lastReadSequence != null) 'last_read_sequence': lastReadSequence,
      if (lastMessagePreview != null)
        'last_message_preview': lastMessagePreview,
      if (lastMessageType != null) 'last_message_type': lastMessageType,
      if (lastMessageSenderName != null)
        'last_message_sender_name': lastMessageSenderName,
      if (lastMessageIsSelf != null) 'last_message_is_self': lastMessageIsSelf,
      if (lastMessageStatus != null) 'last_message_status': lastMessageStatus,
      if (lastMessageHasAtMe != null)
        'last_message_has_at_me': lastMessageHasAtMe,
      if (lastMessageTime != null) 'last_message_time': lastMessageTime,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (isPinned != null) 'is_pinned': isPinned,
      if (isMuted != null) 'is_muted': isMuted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (userId != null) 'user_id': userId,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (groupMemberCount != null) 'group_member_count': groupMemberCount,
      if (groupMemberStatus != null) 'group_member_status': groupMemberStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith({
    Value<String>? chatId,
    Value<ConversationTypeDb>? type,
    Value<String>? targetName,
    Value<String?>? targetAvatar,
    Value<String?>? targetId,
    Value<String?>? lastMessageId,
    Value<String?>? lastMessageSequence,
    Value<String?>? lastReadSequence,
    Value<String>? lastMessagePreview,
    Value<String>? lastMessageType,
    Value<String?>? lastMessageSenderName,
    Value<bool>? lastMessageIsSelf,
    Value<String>? lastMessageStatus,
    Value<bool>? lastMessageHasAtMe,
    Value<DateTime>? lastMessageTime,
    Value<int>? unreadCount,
    Value<bool>? isPinned,
    Value<bool>? isMuted,
    Value<DateTime>? updatedAt,
    Value<String>? userId,
    Value<int>? cachedAt,
    Value<int>? groupMemberCount,
    Value<int?>? groupMemberStatus,
    Value<int>? rowid,
  }) {
    return ConversationsCompanion(
      chatId: chatId ?? this.chatId,
      type: type ?? this.type,
      targetName: targetName ?? this.targetName,
      targetAvatar: targetAvatar ?? this.targetAvatar,
      targetId: targetId ?? this.targetId,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageSequence: lastMessageSequence ?? this.lastMessageSequence,
      lastReadSequence: lastReadSequence ?? this.lastReadSequence,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageSenderName:
          lastMessageSenderName ?? this.lastMessageSenderName,
      lastMessageIsSelf: lastMessageIsSelf ?? this.lastMessageIsSelf,
      lastMessageStatus: lastMessageStatus ?? this.lastMessageStatus,
      lastMessageHasAtMe: lastMessageHasAtMe ?? this.lastMessageHasAtMe,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      cachedAt: cachedAt ?? this.cachedAt,
      groupMemberCount: groupMemberCount ?? this.groupMemberCount,
      groupMemberStatus: groupMemberStatus ?? this.groupMemberStatus,
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
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (lastMessageId.present) {
      map['last_message_id'] = Variable<String>(lastMessageId.value);
    }
    if (lastMessageSequence.present) {
      map['last_message_sequence'] = Variable<String>(
        lastMessageSequence.value,
      );
    }
    if (lastReadSequence.present) {
      map['last_read_sequence'] = Variable<String>(lastReadSequence.value);
    }
    if (lastMessagePreview.present) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview.value);
    }
    if (lastMessageType.present) {
      map['last_message_type'] = Variable<String>(lastMessageType.value);
    }
    if (lastMessageSenderName.present) {
      map['last_message_sender_name'] = Variable<String>(
        lastMessageSenderName.value,
      );
    }
    if (lastMessageIsSelf.present) {
      map['last_message_is_self'] = Variable<bool>(lastMessageIsSelf.value);
    }
    if (lastMessageStatus.present) {
      map['last_message_status'] = Variable<String>(lastMessageStatus.value);
    }
    if (lastMessageHasAtMe.present) {
      map['last_message_has_at_me'] = Variable<bool>(lastMessageHasAtMe.value);
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
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (groupMemberCount.present) {
      map['group_member_count'] = Variable<int>(groupMemberCount.value);
    }
    if (groupMemberStatus.present) {
      map['group_member_status'] = Variable<int>(groupMemberStatus.value);
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
          ..write('targetId: $targetId, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('lastMessageSequence: $lastMessageSequence, ')
          ..write('lastReadSequence: $lastReadSequence, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('lastMessageType: $lastMessageType, ')
          ..write('lastMessageSenderName: $lastMessageSenderName, ')
          ..write('lastMessageIsSelf: $lastMessageIsSelf, ')
          ..write('lastMessageStatus: $lastMessageStatus, ')
          ..write('lastMessageHasAtMe: $lastMessageHasAtMe, ')
          ..write('lastMessageTime: $lastMessageTime, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('isPinned: $isPinned, ')
          ..write('isMuted: $isMuted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('userId: $userId, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('groupMemberCount: $groupMemberCount, ')
          ..write('groupMemberStatus: $groupMemberStatus, ')
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
  late final Index idxMessagesChatSequence = Index(
    'idx_messages_chat_sequence',
    'CREATE INDEX idx_messages_chat_sequence ON messages (chat_id, sequence)',
  );
  late final Index idxMessagesUserChat = Index(
    'idx_messages_user_chat',
    'CREATE INDEX idx_messages_user_chat ON messages (user_id, chat_id)',
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
    idxMessagesChatSequence,
    idxMessagesUserChat,
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
      Value<String?> quoteInfoJson,
      required DateTime createdAt,
      Value<String> userId,
      required int cachedAt,
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
      Value<String?> quoteInfoJson,
      Value<DateTime> createdAt,
      Value<String> userId,
      Value<int> cachedAt,
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

  ColumnFilters<String> get quoteInfoJson => $composableBuilder(
    column: $table.quoteInfoJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
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

  ColumnOrderings<String> get quoteInfoJson => $composableBuilder(
    column: $table.quoteInfoJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
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

  GeneratedColumn<String> get quoteInfoJson => $composableBuilder(
    column: $table.quoteInfoJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
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
                Value<String?> quoteInfoJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
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
                quoteInfoJson: quoteInfoJson,
                createdAt: createdAt,
                userId: userId,
                cachedAt: cachedAt,
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
                Value<String?> quoteInfoJson = const Value.absent(),
                required DateTime createdAt,
                Value<String> userId = const Value.absent(),
                required int cachedAt,
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
                quoteInfoJson: quoteInfoJson,
                createdAt: createdAt,
                userId: userId,
                cachedAt: cachedAt,
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
      Value<String?> targetId,
      Value<String?> lastMessageId,
      Value<String?> lastMessageSequence,
      Value<String?> lastReadSequence,
      required String lastMessagePreview,
      required String lastMessageType,
      Value<String?> lastMessageSenderName,
      Value<bool> lastMessageIsSelf,
      Value<String> lastMessageStatus,
      Value<bool> lastMessageHasAtMe,
      required DateTime lastMessageTime,
      Value<int> unreadCount,
      Value<bool> isPinned,
      Value<bool> isMuted,
      required DateTime updatedAt,
      Value<String> userId,
      required int cachedAt,
      Value<int> groupMemberCount,
      Value<int?> groupMemberStatus,
      Value<int> rowid,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<String> chatId,
      Value<ConversationTypeDb> type,
      Value<String> targetName,
      Value<String?> targetAvatar,
      Value<String?> targetId,
      Value<String?> lastMessageId,
      Value<String?> lastMessageSequence,
      Value<String?> lastReadSequence,
      Value<String> lastMessagePreview,
      Value<String> lastMessageType,
      Value<String?> lastMessageSenderName,
      Value<bool> lastMessageIsSelf,
      Value<String> lastMessageStatus,
      Value<bool> lastMessageHasAtMe,
      Value<DateTime> lastMessageTime,
      Value<int> unreadCount,
      Value<bool> isPinned,
      Value<bool> isMuted,
      Value<DateTime> updatedAt,
      Value<String> userId,
      Value<int> cachedAt,
      Value<int> groupMemberCount,
      Value<int?> groupMemberStatus,
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

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageId => $composableBuilder(
    column: $table.lastMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageSequence => $composableBuilder(
    column: $table.lastMessageSequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastReadSequence => $composableBuilder(
    column: $table.lastReadSequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageType => $composableBuilder(
    column: $table.lastMessageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageSenderName => $composableBuilder(
    column: $table.lastMessageSenderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lastMessageIsSelf => $composableBuilder(
    column: $table.lastMessageIsSelf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageStatus => $composableBuilder(
    column: $table.lastMessageStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lastMessageHasAtMe => $composableBuilder(
    column: $table.lastMessageHasAtMe,
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupMemberCount => $composableBuilder(
    column: $table.groupMemberCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupMemberStatus => $composableBuilder(
    column: $table.groupMemberStatus,
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

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageId => $composableBuilder(
    column: $table.lastMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageSequence => $composableBuilder(
    column: $table.lastMessageSequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastReadSequence => $composableBuilder(
    column: $table.lastReadSequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageType => $composableBuilder(
    column: $table.lastMessageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageSenderName => $composableBuilder(
    column: $table.lastMessageSenderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lastMessageIsSelf => $composableBuilder(
    column: $table.lastMessageIsSelf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageStatus => $composableBuilder(
    column: $table.lastMessageStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lastMessageHasAtMe => $composableBuilder(
    column: $table.lastMessageHasAtMe,
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupMemberCount => $composableBuilder(
    column: $table.groupMemberCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupMemberStatus => $composableBuilder(
    column: $table.groupMemberStatus,
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

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get lastMessageId => $composableBuilder(
    column: $table.lastMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageSequence => $composableBuilder(
    column: $table.lastMessageSequence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastReadSequence => $composableBuilder(
    column: $table.lastReadSequence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageType => $composableBuilder(
    column: $table.lastMessageType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageSenderName => $composableBuilder(
    column: $table.lastMessageSenderName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lastMessageIsSelf => $composableBuilder(
    column: $table.lastMessageIsSelf,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageStatus => $composableBuilder(
    column: $table.lastMessageStatus,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lastMessageHasAtMe => $composableBuilder(
    column: $table.lastMessageHasAtMe,
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

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<int> get groupMemberCount => $composableBuilder(
    column: $table.groupMemberCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get groupMemberStatus => $composableBuilder(
    column: $table.groupMemberStatus,
    builder: (column) => column,
  );
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
                Value<String?> targetId = const Value.absent(),
                Value<String?> lastMessageId = const Value.absent(),
                Value<String?> lastMessageSequence = const Value.absent(),
                Value<String?> lastReadSequence = const Value.absent(),
                Value<String> lastMessagePreview = const Value.absent(),
                Value<String> lastMessageType = const Value.absent(),
                Value<String?> lastMessageSenderName = const Value.absent(),
                Value<bool> lastMessageIsSelf = const Value.absent(),
                Value<String> lastMessageStatus = const Value.absent(),
                Value<bool> lastMessageHasAtMe = const Value.absent(),
                Value<DateTime> lastMessageTime = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isMuted = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> groupMemberCount = const Value.absent(),
                Value<int?> groupMemberStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion(
                chatId: chatId,
                type: type,
                targetName: targetName,
                targetAvatar: targetAvatar,
                targetId: targetId,
                lastMessageId: lastMessageId,
                lastMessageSequence: lastMessageSequence,
                lastReadSequence: lastReadSequence,
                lastMessagePreview: lastMessagePreview,
                lastMessageType: lastMessageType,
                lastMessageSenderName: lastMessageSenderName,
                lastMessageIsSelf: lastMessageIsSelf,
                lastMessageStatus: lastMessageStatus,
                lastMessageHasAtMe: lastMessageHasAtMe,
                lastMessageTime: lastMessageTime,
                unreadCount: unreadCount,
                isPinned: isPinned,
                isMuted: isMuted,
                updatedAt: updatedAt,
                userId: userId,
                cachedAt: cachedAt,
                groupMemberCount: groupMemberCount,
                groupMemberStatus: groupMemberStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String chatId,
                required ConversationTypeDb type,
                required String targetName,
                Value<String?> targetAvatar = const Value.absent(),
                Value<String?> targetId = const Value.absent(),
                Value<String?> lastMessageId = const Value.absent(),
                Value<String?> lastMessageSequence = const Value.absent(),
                Value<String?> lastReadSequence = const Value.absent(),
                required String lastMessagePreview,
                required String lastMessageType,
                Value<String?> lastMessageSenderName = const Value.absent(),
                Value<bool> lastMessageIsSelf = const Value.absent(),
                Value<String> lastMessageStatus = const Value.absent(),
                Value<bool> lastMessageHasAtMe = const Value.absent(),
                required DateTime lastMessageTime,
                Value<int> unreadCount = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isMuted = const Value.absent(),
                required DateTime updatedAt,
                Value<String> userId = const Value.absent(),
                required int cachedAt,
                Value<int> groupMemberCount = const Value.absent(),
                Value<int?> groupMemberStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion.insert(
                chatId: chatId,
                type: type,
                targetName: targetName,
                targetAvatar: targetAvatar,
                targetId: targetId,
                lastMessageId: lastMessageId,
                lastMessageSequence: lastMessageSequence,
                lastReadSequence: lastReadSequence,
                lastMessagePreview: lastMessagePreview,
                lastMessageType: lastMessageType,
                lastMessageSenderName: lastMessageSenderName,
                lastMessageIsSelf: lastMessageIsSelf,
                lastMessageStatus: lastMessageStatus,
                lastMessageHasAtMe: lastMessageHasAtMe,
                lastMessageTime: lastMessageTime,
                unreadCount: unreadCount,
                isPinned: isPinned,
                isMuted: isMuted,
                updatedAt: updatedAt,
                userId: userId,
                cachedAt: cachedAt,
                groupMemberCount: groupMemberCount,
                groupMemberStatus: groupMemberStatus,
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
