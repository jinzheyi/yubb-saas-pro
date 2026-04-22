# uni-im Harmony Location Bridge

## 作用

- 该插件不提供地图页面能力。
- 它的职责是为 HarmonyOS 产物补齐位置相关权限声明，并提供一个可显式加载的桥接入口。

## 当前能力

- 通过 `module.json5` 声明：
  - `ohos.permission.LOCATION`
  - `ohos.permission.APPROXIMATELY_LOCATION`
- 通过 `ensureLoaded()` 让业务层可显式引用该插件，避免纯配置插件被遗漏。

## 注意

- 这不是 `uni-openlocation` 的替代品。
- 它只负责权限声明与工程收口。
