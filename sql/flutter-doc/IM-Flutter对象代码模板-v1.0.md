# IM Flutter 对象代码模板 v1.0

> 文档日期：2026-04-29  
> 文档定位：Entity、DTO、State、Command、Result、Provider 的示例代码模板  

---

## 1. 目标

统一常见对象的代码写法，减少后续生成代码时的风格漂移。

---

## 2. Entity 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation.freezed.dart';

@freezed
class Conversation with _$Conversation {
  const factory Conversation({
    required String chatId,
    required int conversationType,
    required String targetId,
    required String targetName,
    required String targetAvatar,
    required String lastMessageSequence,
    required String lastReadSequence,
    required int unreadCount,
    required bool isPinned,
    required bool noDisturb,
    required String conversationVersion,
  }) = _Conversation;
}
```

---

## 3. DTO 模板

```dart
import 'package:json_annotation/json_annotation.dart';

part 'conversation_dto.g.dart';

@JsonSerializable()
class ConversationDto {
  const ConversationDto({
    required this.chatId,
    required this.conversationType,
    required this.targetId,
    required this.targetName,
    required this.targetAvatar,
    required this.lastMessageSequence,
    required this.lastReadSequence,
    required this.unreadCount,
    required this.isPinned,
    required this.noDisturb,
    required this.conversationVersion,
  });

  final String chatId;
  final int conversationType;
  final String targetId;
  final String targetName;
  final String targetAvatar;
  final String lastMessageSequence;
  final String lastReadSequence;
  final int unreadCount;
  final bool isPinned;
  final bool noDisturb;
  final String conversationVersion;

  factory ConversationDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationDtoToJson(this);
}
```

---

## 4. State 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'global_search_state.freezed.dart';

@freezed
class GlobalSearchState with _$GlobalSearchState {
  const factory GlobalSearchState({
    @Default('') String keyword,
    @Default(SearchTab.all) SearchTab activeTab,
    @Default(LoadStatus.initial) LoadStatus status,
    @Default([]) List<SearchResultUiModel> results,
    @Default(false) bool hasMore,
    @Default(false) bool isLoadingMore,
    AppError? error,
  }) = _GlobalSearchState;
}
```

---

## 5. Command 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_message_command.freezed.dart';

@freezed
class SendMessageCommand with _$SendMessageCommand {
  const factory SendMessageCommand({
    required String chatId,
    required MessageType type,
    required MessageBody body,
    String? quoteMessageId,
    required String clientTempId,
  }) = _SendMessageCommand;
}
```

---

## 6. Result 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_message_result.freezed.dart';

@freezed
class SendMessageResult with _$SendMessageResult {
  const factory SendMessageResult({
    required String messageId,
    required String sequence,
    required String rev,
  }) = _SendMessageResult;
}
```

---

## 7. Mapper 模板

```dart
class ConversationDtoMapper {
  const ConversationDtoMapper._();

  static Conversation toEntity(ConversationDto dto) {
    return Conversation(
      chatId: dto.chatId,
      conversationType: dto.conversationType,
      targetId: dto.targetId,
      targetName: dto.targetName,
      targetAvatar: dto.targetAvatar,
      lastMessageSequence: dto.lastMessageSequence,
      lastReadSequence: dto.lastReadSequence,
      unreadCount: dto.unreadCount,
      isPinned: dto.isPinned,
      noDisturb: dto.noDisturb,
      conversationVersion: dto.conversationVersion,
    );
  }
}
```

---

## 8. Provider 模板

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepositoryImpl(
    remoteDataSource: ref.watch(conversationRemoteDataSourceProvider),
    localDataSource: ref.watch(conversationLocalDataSourceProvider),
  );
});

final conversationListControllerProvider =
    StateNotifierProvider<ConversationListController, ConversationListState>((ref) {
  return ConversationListController(
    ref.watch(loadConversationListUseCaseProvider),
  );
});
```

---

## 9. UseCase 模板

```dart
class SearchGlobalUseCase {
  const SearchGlobalUseCase(this._repository);

  final SearchRepository _repository;

  Future<GlobalSearchResult> call(SearchGlobalCommand command) {
    return _repository.searchGlobal(command);
  }
}
```

---

## 10. Repository Impl 模板

```dart
class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl({
    required ConversationRemoteDataSource remoteDataSource,
    required ConversationLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final ConversationRemoteDataSource _remoteDataSource;
  final ConversationLocalDataSource _localDataSource;

  @override
  Future<List<Conversation>> getConversationList() async {
    final dtos = await _remoteDataSource.getConversationList();
    return dtos.map(ConversationDtoMapper.toEntity).toList();
  }
}
```

---

## 11. Controller 模板

```dart
class GlobalSearchController extends StateNotifier<GlobalSearchState> {
  GlobalSearchController(this._searchGlobalUseCase)
      : super(const GlobalSearchState());

  final SearchGlobalUseCase _searchGlobalUseCase;

  Future<void> search(String keyword) async {
    state = state.copyWith(
      keyword: keyword,
      status: LoadStatus.loading,
      error: null,
    );

    try {
      final result = await _searchGlobalUseCase(
        SearchGlobalCommand(keyword: keyword),
      );
      state = state.copyWith(
        status: LoadStatus.ready,
        results: result.items,
        hasMore: result.hasMore,
      );
    } catch (e, st) {
      state = state.copyWith(
        status: LoadStatus.failed,
        error: AppErrorMapper.map(e, st),
      );
    }
  }
}
```

---

## 12. 统一要求

1. Entity/State/Command/Result 优先使用不可变对象。
2. DTO 必须单独保留 `fromJson/toJson`。
3. Mapper 不允许混入业务副作用。
4. Provider 只负责装配，不写业务逻辑。

