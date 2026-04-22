# uni-im Harmony Microphone Bridge

## 作用

- 为 `shengyu-ui-admin-uniappx` 的 HarmonyOS 产物补齐语音录制相关麦克风权限声明。
- 它本身不替代 `uni.getRecorderManager()`，只负责通过 Harmony `module.json5` 将权限声明编入产物，并提供一个可显式加载的桥接入口。

## 当前职责

- 声明 `ohos.permission.MICROPHONE`
- 提供 `ensureLoaded()` 供业务层在 `App.uvue` 启动时显式拉起

## 说明

- 这是与摄像头、定位桥接插件相同的治理方式，目的是把 Harmony 权限声明收敛到独立插件，避免散落在业务代码里。
- 真机是否弹出授权、授权后 `uni.getRecorderManager()` 的具体行为，仍以 uni-app x 和 Harmony 运行时为准。
