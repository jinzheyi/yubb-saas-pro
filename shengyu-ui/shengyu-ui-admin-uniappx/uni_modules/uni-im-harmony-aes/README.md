# uni-im Harmony AES

## 作用

- 本插件目录用于承接 `shengyu-ui-admin-uniappx` 在 HarmonyOS 下的 AES 原生实现。
- 当前业务层滑块验证码已经具备 Harmony runtime 挂载入口，这里只负责后续 ArkTS 实现的正式落点。

## 当前状态

- `utssdk/interface.uts` 已定义统一接口。
- `utssdk/app-harmony/index.uts` 目前仅提供未实现占位，默认不会被业务层直接启用。
- `utssdk/app-harmony/module.json5` 与 `resources` 已补基础模板，后续可继续扩展 Harmony 侧配置。
- 后续应由鸿蒙原生同学在本目录内补齐真实 AES ECB/PKCS7/Base64 实现。

## 建议下一步

- 在 `utssdk/app-harmony/index.uts` 内对接官方密码能力。
- 如需额外鸿蒙依赖，可在 `utssdk/app-harmony/config.json` 中声明。
- 如需额外资源字符串或构建配置，可继续扩展 `utssdk/app-harmony/module.json5` 与 `resources`。
