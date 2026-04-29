# IM Flutter 通话测试清单 v1.0

> 文档日期：2026-04-29  
> 文档定位：音视频通话模块的单元测试、集成测试、真机回归与平台验收清单

---

## 1. 目标

通话模块是高状态复杂度专题，必须在代码前就冻结测试范围。

---

## 2. 单元测试

至少覆盖：

1. `CallController.initialize`
2. `startOutgoing -> outgoing/ringing`
3. `accept -> accepting`
4. `reject -> ended`
5. `hangup -> ending -> ended`
6. `call.accepted` 事件进入 `connecting`
7. `call.ended` 事件释放媒体并进入 `ended`
8. 权限拒绝映射为 `permissionDenied`
9. `CallEndReason` 映射正确

---

## 3. 集成测试

至少覆盖：

1. 主叫发起语音通话
2. 被叫接听语音通话
3. 被叫拒绝
4. 主叫取消
5. 通话中挂断
6. 重连后状态恢复
7. 最终生成通话记录消息

---

## 4. 平台专项测试

### 4.1 Android / iOS

1. 麦克风权限
2. 摄像头权限
3. 扬声器切换
4. 前后摄切换
5. 来电页与前后台恢复

### 4.2 Web / Desktop

1. 麦克风 / 摄像头浏览器授权
2. 多窗口或标签切回
3. 页面刷新后的状态恢复

### 4.3 OpenHarmony / HarmonyOS

当前只要求：

1. 不把 RTC 作为首轮阻塞项
2. 若后续进入实现，则必须补独立平台验证清单

---

## 5. 失败场景回归

必须覆盖：

1. 对端忙线
2. 响铃超时
3. 媒体连接失败
4. 中途断网
5. 同账号其他设备抢接
6. 登录态失效强制结束

---

## 6. 放行条件

要把通话模块从 `ready_for_codegen` 升级到可交付，至少要求：

1. 单元测试通过
2. 关键集成测试通过
3. Android / iOS 真机双端至少一轮通过
