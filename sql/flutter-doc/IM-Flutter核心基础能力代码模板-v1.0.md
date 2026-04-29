# IM Flutter 核心基础能力代码模板 v1.0

> 文档日期：2026-04-29  
> 文档定位：`dict` / `nav-state` / `avatar` 等 `core` 基础能力的合并模板文档  

---

## 1. 结论

`dict`、`nav-state`、`avatar` 都值得进入代码模板层，但不建议拆成三份独立文档。

原因：

1. 都属于 `core` 层基础能力
2. 单份文档更利于 AI 集中生成基础设施代码
3. 这三类能力都有“页面禁止自行实现”的约束

---

## 2. `dict_facade.dart` 模板

```dart
abstract class DictFacade {
  Future<void> warmUp(List<String> dictTypes);
  List<DictOption> getOptions(String dictType);
  String getLabel(String dictType, Object? value);
  DictTagStyle? getTagStyle(String dictType, Object? value);
  void clear();
}
```

---

## 3. `dict_option.dart` 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dict_option.freezed.dart';

@freezed
class DictOption with _$DictOption {
  const factory DictOption({
    required String dictType,
    required String label,
    required String value,
    String? colorType,
    String? cssClass,
  }) = _DictOption;
}
```

---

## 4. `nav_state_store.dart` 模板

```dart
abstract class NavStateStore {
  Future<String> create({
    required Object payload,
    Duration ttl = const Duration(minutes: 5),
  });

  Future<T?> consume<T>(String stateId);
  Future<void> cleanup();
}
```

---

## 5. `avatar_presenter.dart` 模板

```dart
class AvatarPresentation {
  const AvatarPresentation({
    required this.text,
    required this.backgroundColor,
    this.avatarUrl,
  });

  final String text;
  final String backgroundColor;
  final String? avatarUrl;
}

abstract class AvatarPresenter {
  AvatarPresentation forUser({
    required String userId,
    required String name,
    String? avatarUrl,
  });

  AvatarPresentation forGroup({
    required String groupId,
    required String name,
    String? avatarUrl,
  });
}
```

---

## 6. `app_time_formatter.dart` 模板

```dart
abstract class AppTimeFormatter {
  String formatAbsolute(DateTime dateTime);
  String formatRelative(DateTime dateTime);
  String formatConversationTime(DateTime dateTime);
  String? formatChatSeparator({
    required DateTime current,
    DateTime? previous,
  });
}
```

---

## 7. provider 模板

```dart
final dictFacadeProvider = Provider<DictFacade>((ref) {
  throw UnimplementedError();
});

final navStateStoreProvider = Provider<NavStateStore>((ref) {
  throw UnimplementedError();
});

final avatarPresenterProvider = Provider<AvatarPresenter>((ref) {
  throw UnimplementedError();
});

final appTimeFormatterProvider = Provider<AppTimeFormatter>((ref) {
  throw UnimplementedError();
});
```

---

## 8. 适用结论

所以这轮判断结果是：

1. `dict/nav-state/avatar` 需要进入模板层
2. 但不需要拆成三份独立模板文档
3. 合并成一份 `核心基础能力代码模板` 更适合当前文档体系
