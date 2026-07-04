# Flutter IM 租户切换功能 - AI 指导设计文档

## 一、需求概述

### 1.1 业务背景
当前 Web 管理端已实现租户切换功能，用户可在多个租户间切换。现需在 Flutter IM 移动端实现类似飞书"切换企业"的功能。

### 1.2 核心需求
- 用户点击租户名称/头像，弹出租户列表
- 显示当前租户标识、租户 Logo、租户名称
- 支持切换租户，切换后刷新所有数据
- 禁用租户显示灰色且不可点击
- 显示最近登录时间
- 切换成功后返回主页

### 1.3 参考实现
- Web 端：`MyTenant.vue`
- 飞书：企业切换 UX

---

## 二、现有架构分析

### 2.1 Web 端实现分析

**核心文件**：
- `MyTenant.vue` - 租户切换组件
- `AuthController.java` - 后端认证控制器
- `AdminAuthServiceImpl.java` - 认证服务实现

**关键接口**：
```java
// 获取租户列表
GET /system/user/get-myTenant-list

// 切换租户
POST /system/auth/toTenant
```

**切换流程**：
1. 调用 `toTenant` 接口（传入目标租户 ID）
2. 后端注销旧 token，生成新 token
3. 前端保存新 token 到 localStorage
4. 刷新页面重新加载数据

### 2.2 Flutter IM 架构分析

**核心文件**：
- `auth_session.dart` - 认证会话管理
- `auth_session_provider.dart` - 认证会话 Provider
- `auth_remote_data_source.dart` - API 调用
- `session_cleanup_service.dart` - 会话清理服务
- `conversation_list_page.dart` - 会话列表页（租户切换入口）
- `im_socket_client.dart` - WebSocket 客户端
- `im_database.dart` - 本地数据库

**状态管理**：Riverpod
**本地存储**：SharedPreferences + SQLite（drift）
**WebSocket**：自定义 Socket 客户端（基于 web_socket_channel）

---

## 三、后端接口设计

### 3.1 移动端接口需求

**重要**：Flutter IM 使用 `/app-api` 前缀（`app_config.dart` L26），需要在移动端 Controller 中新增接口。

### 3.2 后端实现分析（基于 Web 端）

**后端 toTenant 流程**（`AdminAuthServiceImpl.java` L275-307）：
1. 校验目标租户状态（是否存在、是否禁用、是否过期）
2. 校验用户是否有权切换到目标租户（`getToTenantAdminUser`）
3. 注销旧 token（`logout(token, LOGOUT_TO_TENANT)`）
4. 更新 SaaS 用户信息（`setSaasUserInfo`）
5. 创建新 token（`createTokenAfterLoginSuccess`）

**关键点**：
- ✅ 后端会自动注销旧 token，前端无需手动调用 logout
- ✅ 新 token 包含新的 tenantId
- ✅ 切换失败时旧 token 仍然有效

**WebSocket 认证流程**（`AuthHandler.java` L328-429）：
1. 客户端发送 AUTH_REQ 消息（包含 accessToken）
2. 服务端验证 token（`authService.validateToken(accessToken)`）
3. 从 token 中提取 tenantId（`authService.getTenantId(loginUser)`）
4. 创建 NettySession 并设置 tenantId（L394-414）
5. 将 session 添加到 sessionManager（L416）

**关键发现**：
- ✅ WebSocket 认证时 tenantId 从 token 自动提取，无需客户端显式传递
- ✅ 但显式传递 tenantId 可用于服务端校验（防止 token 伪造）
- ✅ 切换租户后必须断开重连，因为 NettySession 的 tenantId 创建后不可变

**Token 过滤器**（`TokenAuthenticationFilter.java` L82-102）：
- 从 token 中提取 tenantId：`accessToken.getTenantId()`
- 构建 LoginUser 对象：`LoginUser.builder().tenantId(accessToken.getTenantId())...build()`
- 所有 HTTP 请求的租户隔离通过此机制实现

**Web 端前端流程**（`MyTenant.vue` + `user.ts`）：
1. 调用 `toTenant(id)` API（L28）
2. 调用 `userStore.loginToTenantOut()` 清理本地状态（L33）
   - 移除旧 token（`removeToken()`）
   - 删除用户缓存（`deleteUserCache()`）
   - 重置状态（`resetState()`）
3. 设置新 token（`authUtil.setToken(res)`，L35）
4. 刷新页面（`location.reload()`，L40）

**关键发现**：
- ⚠️ Web 端使用 `location.reload()` 强制刷新，Flutter 端需要手动清理状态
- ⚠️ Web 端先清理旧状态再设置新 token，Flutter 端应遵循相同顺序

**后端 logout() 触发 IM 会话撤销**（`AdminAuthServiceImpl.java` L339-349）：
```java
// 通知 IM 网关撤销会话，立即断开连接
ImSessionRevokeMessage revokeMessage = new ImSessionRevokeMessage()
    .setUserId(accessTokenDO.getUserId())
    .setUserType(accessTokenDO.getUserType())
    .setTenantId(accessTokenDO.getTenantId())
    .setClientId(accessTokenDO.getClientId())
    .setAccessToken(token)
    .setAction("LOGOUT")
    .setReason("用户登出");
imSessionRevokeProducer.send(revokeMessage);
```

**关键发现**：
- ⚠️ toTenant 调用 logout() 会触发 IM 网关撤销会话
- ⚠️ Flutter 客户端会收到 WebSocket 关闭消息（action: "LOGOUT"）
- ⚠️ 客户端需要处理这个断开事件，避免误判为网络故障

**后端 getToTenantAdminUser 校验逻辑**（`AdminAuthServiceImpl.java` L456-480）：
1. 切换到目标租户上下文（`TenantContextHolder.setTenantId(tenantId)`）
2. 查询用户在目标租户的 AdminUserDO
3. 检查用户是否存在（可能被删除）
4. 检查用户状态（是否被禁用）
5. 恢复原租户上下文

**关键发现**：
- ✅ 后端会校验用户在目标租户是否有权访问
- ✅ 如果用户在目标租户被删除或禁用，会返回 null，切换失败
- ✅ 切换失败时旧 token 仍然有效

### 3.3 新增移动端接口

#### 3.3.1 AppAuthController 新增 toTenant 接口

**文件**：`shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/app/auth/AppAuthController.java`

**位置**：L176 之后添加（在 `sendLoginSmsCode` 方法之后）

```java
@PostMapping("/to-tenant")
@Operation(summary = "切换租户（移动端）")
public CommonResult<AuthLoginRespVO> toTenant(
        @RequestBody @Valid ToTenantReqVO reqVO,
        HttpServletRequest request) {
    String token = SecurityFrameworkUtils.obtainAuthorization(request,
            securityProperties.getTokenHeader(), securityProperties.getTokenParameter());
    if (StrUtil.isBlank(token)) {
        throw exception(AUTH_TOKEN_EXPIRED);
    }
    return success(adminAuthService.toTenant(reqVO, token));
}
```

**注意**：需要添加 import：
```java
import com.shengyu.module.system.controller.admin.auth.vo.ToTenantReqVO;
import static com.shengyu.framework.common.exception.enums.GlobalErrorCodeConstants.AUTH_TOKEN_EXPIRED;
import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
```

**现有 Controller 结构**（L1-178）：
- L66: `public class AppAuthController {`
- L81-92: `login` 方法
- L94-105: `logout` 方法
- L107-114: `refreshToken` 方法
- L116-152: `getPermissionInfo` 方法
- L156-166: `smsLogin` 方法
- L168-176: `sendLoginSmsCode` 方法
- **L178: 新增 `toTenant` 方法**

#### 3.3.2 AppUserController 新增 getMyTenantList 接口

**文件**：`shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/app/user/AppUserController.java`

**位置**：L226 之后添加（在 `buildDeptPath` 方法之后）

```java
@GetMapping("/get-my-tenant-list")
@Operation(summary = "获取当前用户的租户列表（移动端）")
public CommonResult<List<MyTenantRespVO>> getMyTenantList() {
    return success(userService.getMyTenantList());
}
```

**注意**：需要添加 import：
```java
import com.shengyu.module.system.controller.admin.user.vo.user.MyTenantRespVO;
```

**现有 Controller 结构**（L1-228）：
- L45: `public class AppUserController {`
- L56-103: `getUserDetail` 方法
- L105-110: `getCurrentUserDetail` 方法
- L112-120: `updateCurrentUserAvatar` 方法
- L122-127: `clearCurrentUserAvatar` 方法
- L129-201: `getUserList` 方法
- L207-226: `buildDeptPath` 方法（私有辅助方法）
- **L228: 新增 `getMyTenantList` 方法**

### 3.4 前端 API 调用

**文件**：`lib/core/auth/auth_remote_data_source.dart`

**位置**：在现有方法后添加

```dart
/// 获取租户列表
Future<List<TenantListItemDto>> getMyTenantList() async {
  final response = await _dio.get('/system/user/get-my-tenant-list');
  final result = ApiResult.fromJson<List<TenantListItemDto>>(
    response.data as Map<String, dynamic>,
    dataParser: (raw) {
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => TenantListItemDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    },
  );
  return result.requireData();
}

/// 切换租户
Future<AuthTokenDto> toTenant({required int tenantId}) async {
  final response = await _dio.post(
    '/system/auth/to-tenant',
    data: {'id': tenantId},
  );
  final result = ApiResult.fromJson<AuthTokenDto>(
    response.data as Map<String, dynamic>,
    dataParser: (raw) {
      return AuthTokenDto.fromJson(raw as Map<String, dynamic>? ?? const {});
    },
  );
  return result.requireData();
}
```

---

## 四、DTO 设计

### 4.1 TenantListItemDto

**文件**：`lib/core/auth/tenant_list_item_dto.dart`（新建文件）

**说明**：字段与后端 `MyTenantRespVO` 保持一致

```dart
/// 租户列表项 DTO（对应后端 MyTenantRespVO）
class TenantListItemDto {
  const TenantListItemDto({
    required this.id,
    required this.tenantName,
    required this.status,
    this.loginDate,
  });

  final int id;
  final String tenantName;
  final String status; // "0"=开启，"1"=关闭
  final DateTime? loginDate;

  factory TenantListItemDto.fromJson(Map<String, dynamic> json) {
    return TenantListItemDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tenantName: json['tenantName']?.toString().trim() ?? '',
      status: json['status']?.toString() ?? '',
      loginDate: json['loginDate'] != null
          ? DateTime.tryParse(json['loginDate'].toString())
          : null,
    );
  }

  /// 是否可切换（基于租户状态判断）
  bool get isSwitchable => status == '0';
}
```

---

## 五、AuthSession 扩展

### 5.1 现有结构说明

**文件**：`lib/core/auth/auth_session.dart`

**现有字段**（L1-33）：
```dart
class AuthSession {
  const AuthSession({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.tenantId,
    required this.deviceId,
    required this.deviceType,
    required this.deviceName,
    required this.clientVersion,
    required this.locale,
  });

  final String userId;
  final String accessToken;
  final String refreshToken;
  final String tenantId;
  final String deviceId;
  final int deviceType;  // 注意：是 int 类型
  final String deviceName;
  final String clientVersion;
  final String locale;
}
```

**说明**：
- ✅ 现有 AuthSession 已包含 tenantId，无需新增
- ✅ 无需新增 deptId 字段（后端 toTenant 返回的 AuthLoginRespVO 不包含 deptId）
- ✅ 无需新增 tokenExpireTime 字段（现有代码未使用）

### 5.2 copyWith 方法

**现有实现**（L37-59）已支持 tenantId，无需修改：

```dart
AuthSession copyWith({
  String? userId,
  String? accessToken,
  String? refreshToken,
  String? tenantId,
  String? deviceId,
  int? deviceType,
  String? deviceName,
  String? clientVersion,
  String? locale,
}) {
  return AuthSession(
    userId: userId ?? this.userId,
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    tenantId: tenantId ?? this.tenantId,
    deviceId: deviceId ?? this.deviceId,
    deviceType: deviceType ?? this.deviceType,
    deviceName: deviceName ?? this.deviceName,
    clientVersion: clientVersion ?? this.clientVersion,
    locale: locale ?? this.locale,
  );
}
```

### 5.3 存储机制说明

**重要**：AuthSession 本身不包含 `toStorageMap`/`fromStorageMap` 方法。实际的存储逻辑在 `TokenStorage` 类中（使用 flutter_secure_storage）。

**文件**：`lib/core/auth/token_storage.dart`

**说明**：
- ✅ TokenStorage 负责将 AuthSession 序列化/反序列化到安全存储
- ✅ AuthSession 通过 `copyWith` 方法更新字段
- ✅ AuthSessionController.saveSession() 方法会自动处理设备信息并保存

### 5.4 结论

**无需修改 AuthSession**：
- ✅ 现有 AuthSession 已包含所有必需字段
- ✅ copyWith 方法已支持 tenantId
- ✅ 存储逻辑由 TokenStorage 处理，无需修改
- ✅ 无需新增 deptId、tokenExpireTime 等字段

---

## 六、TenantSwitchService 设计

### 6.1 核心职责

1. 获取租户列表
2. 执行租户切换
3. 清理租户数据
4. 管理切换状态

### 6.2 状态定义

**文件**：`lib/features/profile/domain/services/tenant_switch_service.dart`

```dart
/// 租户切换状态
enum TenantSwitchState {
  idle,      // 空闲
  loading,   // 切换中
  success,   // 成功
  failed,    // 失败
}

/// 切换结果
class TenantSwitchResult {
  const TenantSwitchResult({
    required this.success,
    this.message = '',
  });

  final bool success;
  final String message;

  factory TenantSwitchResult.success() => 
      const TenantSwitchResult(success: true);
  
  factory TenantSwitchResult.failure(String message) => 
      TenantSwitchResult(success: false, message: message);
}
```

### 6.3 完整实现

**文件**：`lib/features/profile/domain/services/tenant_switch_service.dart`

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/auth/tenant_list_item_dto.dart';
import 'package:shengyu_ui_admin_im/core/storage/storage_key_registry.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/active_conversation_service.dart';
import 'package:shengyu_ui_admin_im/features/im/badge/badge_service.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_realtime_binding.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/features/profile/presentation/providers/profile_providers.dart';
import 'package:shengyu_ui_admin_im/infrastructure/database/im_database.dart';

/// 租户切换状态
enum TenantSwitchState {
  idle,
  loading,
  success,
  failed,
}

/// 切换结果
class TenantSwitchResult {
  const TenantSwitchResult({
    required this.success,
    this.message = '',
  });

  final bool success;
  final String message;

  factory TenantSwitchResult.success() => 
      const TenantSwitchResult(success: true);
  
  factory TenantSwitchResult.failure(String message) => 
      TenantSwitchResult(success: false, message: message);
}

/// 租户切换服务
class TenantSwitchService extends StateNotifier<TenantSwitchState> {
  TenantSwitchService({
    required this.ref,
    required this.remoteDataSource,
    required this.imSocketClient,
  }) : super(TenantSwitchState.idle);

  final Ref ref;
  final AuthRemoteDataSource remoteDataSource;
  final ImSocketClient imSocketClient;

  List<TenantListItemDto> _tenantList = [];
  TenantSwitchState _switchState = TenantSwitchState.idle;
  String _errorMessage = '';

  // Getters
  List<TenantListItemDto> get tenantList => List.unmodifiable(_tenantList);
  TenantSwitchState get switchState => _switchState;
  String get errorMessage => _errorMessage;
  String get currentTenantId => ref.read(authSessionProvider).tenantId;
  String get currentTenantName {
    final tenantId = currentTenantId;
    if (tenantId.isEmpty) return '';
    final tenant = _tenantList.firstWhere(
      (t) => t.id.toString() == tenantId,
      orElse: () => TenantListItemDto(id: 0, tenantName: '', status: '1'),
    );
    return tenant.tenantName;
  }

  /// 加载租户列表
  Future<void> loadTenantList() async {
    try {
      _tenantList = await remoteDataSource.getMyTenantList();
      
      state = TenantSwitchState.idle;
    } catch (e) {
      debugPrint('[TenantSwitchService] 加载租户列表失败: $e');
      _errorMessage = '加载租户列表失败: $e';
      state = TenantSwitchState.failed;
    }
  }

  /// 切换租户
  Future<TenantSwitchResult> switchTenant({
    required int targetTenantId,
  }) async {
    // 互斥锁：防止并发切换
    if (_switchState == TenantSwitchState.loading) {
      return TenantSwitchResult.failure('正在切换中，请稍候');
    }

    final oldSession = ref.read(authSessionProvider);
    if (!oldSession.isAuthenticated) {
      return TenantSwitchResult.failure('未登录');
    }

    // 校验：不能切换到当前租户
    if (targetTenantId.toString() == oldSession.tenantId) {
      return TenantSwitchResult.failure('已在当前企业');
    }

    // 校验：目标租户必须可切换
    final targetTenant = _tenantList.firstWhere(
      (t) => t.id == targetTenantId,
      orElse: () => TenantListItemDto(id: 0, tenantName: '', status: '1'),
    );
    if (!targetTenant.isSwitchable) {
      return TenantSwitchResult.failure('该企业不可切换');
    }

    _switchState = TenantSwitchState.loading;
    state = TenantSwitchState.loading;

    try {
      // [1] 调用后端接口切换租户
      final tokenDto = await remoteDataSource.toTenant(tenantId: targetTenantId);

      // [2] 构造新的 AuthSession（使用 copyWith 保留设备信息）
      final newSession = oldSession.copyWith(
        accessToken: tokenDto.accessToken,
        refreshToken: tokenDto.refreshToken,
        tenantId: targetTenantId.toString(),
      );

      // [3] 清理旧租户数据
      await _clearTenantScopedData(oldSession);

      // [4] 保存新 session
      await ref.read(authSessionProvider.notifier).saveSession(newSession);

      // [5] 重新连接 WebSocket
      await _reconnectWebSocket(newSession);

      // [6] 刷新 Provider 状态
      _invalidateProviders();

      _switchState = TenantSwitchState.success;
      state = TenantSwitchState.success;
      
      return TenantSwitchResult.success();
    } catch (e) {
      _switchState = TenantSwitchState.failed;
      _errorMessage = e.toString();
      state = TenantSwitchState.failed;
      
      // 区分 401 错误，引导用户重新登录
      if (e.toString().contains('401')) {
        return TenantSwitchResult.failure('登录已过期，请重新登录');
      }
      
      return TenantSwitchResult.failure('切换失败: $e');
    }
  }

  /// 清理租户作用域数据
  Future<void> _clearTenantScopedData(AuthSession oldSession) async {
    // [0] 清理本地数据库（关键：防止跨租户数据泄露）
    try {
      final database = ImDatabase.instance;
      await database.clearAllTables();
      debugPrint('[TenantSwitchService] 本地数据库已清理');
    } catch (e) {
      debugPrint('[TenantSwitchService] 清理本地数据库失败: $e');
    }

    // [1] 清空内存缓存
    try {
      final cacheManager = ref.read(unifiedCacheManagerProvider);
      cacheManager.clearMemoryCacheForUser(oldSession.userId);
      debugPrint('[TenantSwitchService] 内存缓存已清理');
    } catch (e) {
      debugPrint('[TenantSwitchService] 清理内存缓存失败: $e');
    }

    // [2] 清理 SharedPreferences（保留设备信息）
    try {
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = [
        StorageKeyRegistry.imBadgeSnapshot,
        StorageKeyRegistry.conversationCursorVersion,
      ];
      
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
      
      debugPrint('[TenantSwitchService] SharedPreferences 已清理');
    } catch (e) {
      debugPrint('[TenantSwitchService] 清理 SharedPreferences 失败: $e');
    }

    // [3] 重置角标服务
    try {
      ref.read(badgeServiceProvider.notifier).reset();
      debugPrint('[TenantSwitchService] 角标服务已重置');
    } catch (e) {
      debugPrint('[TenantSwitchService] 重置角标服务失败: $e');
    }

    // [4] 重置 ActiveConversationService
    try {
      ref.read(activeConversationServiceProvider.notifier).deactivateChat();
      debugPrint('[TenantSwitchService] ActiveConversationService 已重置');
    } catch (e) {
      debugPrint('[TenantSwitchService] 重置 ActiveConversationService 失败: $e');
    }

    // [5] 断开 WebSocket
    try {
      await imSocketClient.disconnect();
      debugPrint('[TenantSwitchService] WebSocket 已断开');
    } catch (e) {
      debugPrint('[TenantSwitchService] 断开 WebSocket 失败: $e');
    }
  }

  /// 重新连接 WebSocket
  Future<void> _reconnectWebSocket(AuthSession newSession) async {
    try {
      await imSocketClient.connect();
      await imSocketClient.auth(newSession);
      debugPrint('[TenantSwitchService] WebSocket 已重连');
    } catch (e) {
      debugPrint('[TenantSwitchService] WebSocket 重连失败: $e');
    }
  }

  /// 刷新 Provider 状态
  /// 
  /// 注意：必须与 SessionCleanupService._clearAllUserScopes() 保持一致
  void _invalidateProviders() {
    // ========== 用户资料 ==========
    ref.invalidate(currentUserProfileProvider);
    
    // ========== 会话相关 ==========
    ref.invalidate(conversationListControllerProvider);
    ref.invalidate(conversationRealtimeBindingProvider);
    
    // ========== 聊天相关 ==========
    ref.invalidate(chatControllerProvider);
    ref.invalidate(chatTimelineControllerProvider);
    
    // ========== 通讯录相关 ==========
    ref.invalidate(contactsPageControllerProvider);
    ref.invalidate(myDepartmentTreeProvider);
    ref.invalidate(organizationTreeProvider);
    ref.invalidate(starContactsProvider);
    ref.invalidate(myGroupsProvider);
    
    // ========== 群组设置相关 ==========
    ref.invalidate(groupSettingsRepositoryProvider);
    ref.invalidate(groupMemberRemovedSignalProvider);
    
    // ========== 角标相关 ==========
    ref.invalidate(badgeServiceProvider);
    ref.read(badgeServiceProvider.notifier).reset();
    
    debugPrint('[TenantSwitchService] Provider 状态已刷新');
  }

  @override
  void dispose() {
    _tenantList.clear();
    super.dispose();
  }
}

// ============================================================
// Riverpod Provider
// ============================================================

final tenantSwitchServiceProvider = StateNotifierProvider<TenantSwitchService, TenantSwitchState>((ref) {
  return TenantSwitchService(
    ref: ref,
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    imSocketClient: ref.watch(imSocketClientProvider),
  );
});
```

---

## 七、租户切换页面 UI（飞书风格）

### 7.1 入口位置：会话列表页顶部

**文件**：`lib/features/im/conversation/presentation/pages/conversation_list_page.dart`

**位置**：在 `build` 方法的 `Column` 顶部添加租户切换栏（在搜索框上方）

**实现说明**：
- 入口位于会话列表页顶部，而非 Profile 页面
- 符合飞书企业切换 UX：左上角企业名称可点击
- 降低复杂度，避免在多个页面维护入口

```dart
// 在 _ConversationListPageState.build() 中，Column 的第一个子元素
Widget _buildTenantSwitcher(BuildContext context, WidgetRef ref) {
  final service = ref.watch(tenantSwitchServiceProvider);
  final tenantName = service.currentTenantName;

  return GestureDetector(
    onTap: () => TenantSwitchPage.showAsBottomSheet(context),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF1677FF),
            child: Text(
              tenantName.isNotEmpty ? tenantName[0] : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tenantName.isNotEmpty ? tenantName : '加载中...',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
        ],
      ),
    ),
  );
}
```

### 7.2 租户切换 BottomSheet（飞书风格）

**文件**：`lib/features/profile/presentation/pages/tenant_switch_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/features/profile/domain/services/tenant_switch_service.dart';

class TenantSwitchPage extends ConsumerStatefulWidget {
  const TenantSwitchPage({super.key});

  /// 以 BottomSheet 形式显示
  static Future<void> showAsBottomSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: const TenantSwitchPage(),
        ),
      ),
    );
  }

  @override
  ConsumerState<TenantSwitchPage> createState() => _TenantSwitchPageState();
}

class _TenantSwitchPageState extends ConsumerState<TenantSwitchPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(tenantSwitchServiceProvider);
    final state = ref.watch(tenantSwitchServiceProvider);

    return Column(
      children: [
        _buildHeader(context),
        _buildSearchBar(),
        Expanded(
          child: state == TenantSwitchState.loading
              ? _buildLoading()
              : _buildTenantList(context, ref, service),
        ),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '切换企业',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 24),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索企业',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim().toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('切换中...'),
        ],
      ),
    );
  }

  Widget _buildTenantList(
    BuildContext context,
    WidgetRef ref,
    TenantSwitchService service,
  ) {
    final tenantList = service.tenantList;
    final currentTenantId = service.currentTenantId;

    // 过滤搜索结果
    final filteredList = _searchQuery.isEmpty
        ? tenantList
        : tenantList.where((t) => t.tenantName.toLowerCase().contains(_searchQuery)).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Text(_searchQuery.isEmpty ? '暂无企业' : '未找到匹配的企业'),
      );
    }

    return ListView.builder(
      controller: ScrollController(),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final tenant = filteredList[index];
        final isCurrent = tenant.id.toString() == currentTenantId;
        final canSwitch = tenant.isSwitchable && !isCurrent;

        return _TenantListTile(
          tenant: tenant,
          isCurrent: isCurrent,
          canSwitch: canSwitch,
          onTap: canSwitch
              ? () => _handleTenantSwitch(context, ref, service, tenant.id)
              : null,
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 跳转到创建/加入企业页面
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('创建/加入企业功能待实现')),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('创建/加入企业'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1677FF)),
              foregroundColor: const Color(0xFF1677FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTenantSwitch(
    BuildContext context,
    WidgetRef ref,
    TenantSwitchService service,
    int tenantId,
  ) async {
    final result = await service.switchTenant(targetTenantId: tenantId);

    if (!context.mounted) return;

    if (result.success) {
      Navigator.pop(context);
      
      // 显示切换成功提示（带遮罩效果）
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('切换成功'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      
      // 切换成功后导航到会话列表页（根页面）
      // 确保用户不会停留在旧租户的聊天页
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }
}

class _TenantListTile extends StatelessWidget {
  const _TenantListTile({
    required this.tenant,
    required this.isCurrent,
    required this.canSwitch,
    this.onTap,
  });

  final TenantListItemDto tenant;
  final bool isCurrent;
  final bool canSwitch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrent ? const Color(0xFFF0F7FF) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFE5E5E5),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tenant.tenantName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                            color: canSwitch || isCurrent ? null : Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1677FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '当前',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1677FF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (tenant.loginDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '上次登录: ${_formatTime(tenant.loginDate!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check, color: Color(0xFF1677FF), size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 20,
      backgroundColor: isCurrent ? const Color(0xFF1677FF) : Colors.grey,
      child: Text(
        tenant.tenantName.isNotEmpty ? tenant.tenantName[0] : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    
    return '${time.month}-${time.day}';
  }
}
```

---

## 八、WebSocket 认证 Payload 扩展

### 8.1 添加 tenantId（可选优化）

**文件**：`lib/core/websocket/socket_auth_payload_builder.dart`

**修改位置**：L31-47（`buildAuthEnvelope` 方法）

**现有代码**（L31-47）：
```dart
Map<String, Object?> buildAuthEnvelope(AuthSession session) {
  return {
    'header': {
      'messageId': _uuid.v4(),
      'messageType': SocketMessageType.authReq,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    },
    'body': {
      'accessToken': session.accessToken,
      'deviceType': session.deviceType,
      'deviceId': session.deviceId,
      'deviceName': session.deviceName,
      'clientVersion': session.clientVersion,
      'locale': session.locale,
    },
  };
}
```

**修改后**：
```dart
Map<String, Object?> buildAuthEnvelope(AuthSession session) {
  return {
    'header': {
      'messageId': _uuid.v4(),
      'messageType': SocketMessageType.authReq,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    },
    'body': {
      'accessToken': session.accessToken,
      'tenantId': session.tenantId,  // 新增：显式传递 tenantId
      'deviceType': session.deviceType,
      'deviceId': session.deviceId,
      'deviceName': session.deviceName,
      'clientVersion': session.clientVersion,
      'locale': session.locale,
    },
  };
}
```

**说明**：
- 虽然服务端可以从 token 中提取 tenantId，但显式传递有以下好处：
  - 服务端可以快速校验 token 和 tenantId 是否一致（防止伪造）
  - 便于日志追踪和审计
  - 提高代码可读性和维护性

---

## 十、数据库清理支持

### 10.1 ImDatabase 添加 clearAllTables 方法

**文件**：`lib/infrastructure/database/im_database.dart`

**位置**：L100 之后添加

**说明**：ImDatabase 只包含 Messages 和 Conversations 两张表，需要添加清理方法

```dart
/// 清理所有表数据（租户切换时调用）
Future<void> clearAllTables() async {
  try {
    // 清理消息表（drift 语法）
    await delete(messages).go();
    debugPrint('[ImDatabase] messages 表已清理');
    
    // 清理会话表（drift 语法）
    await delete(conversations).go();
    debugPrint('[ImDatabase] conversations 表已清理');
    
    debugPrint('[ImDatabase] 所有表已清理');
  } catch (e) {
    debugPrint('[ImDatabase] 清理表失败: $e');
    rethrow;
  }
}
```

**Drift 语法说明**：
- `delete(messages).go()` 是 drift 的标准删除语法
- `messages` 和 `conversations` 是 `@DriftDatabase` 注解中定义的表
- 也可以使用 `messages.delete().go()` 的链式调用语法

---

## 十一、路由配置

### 11.1 路由说明

**重要**：租户切换页面使用 `BottomSheet` 形式展示，**不需要**在路由中注册独立路由。

**原因**：
- BottomSheet 是模态对话框，从当前页面弹出
- 不需要改变路由栈
- 切换完成后直接关闭 BottomSheet 即可

**使用方式**：
```dart
// 在会话列表页顶部点击时调用
TenantSwitchPage.showAsBottomSheet(context);
```

**无需修改**：`lib/app/router/app_router.dart`

---

## 十二、国际化配置

### 12.1 添加租户切换相关文案

**文件**：`lib/core/i18n/app_strings.dart`

**添加**：

```dart
// 中文
'tenantSwitchTitle': '切换企业',
'tenantCurrent': '当前',
'tenantSwitching': '切换中...',
'tenantSwitchSuccess': '切换成功',
'tenantSwitchFailed': '切换失败',
'tenantAlreadyCurrent': '已在当前企业',
'tenantNotSwitchable': '该企业不可切换',
'tenantLoadingFailed': '加载租户列表失败',

// 英文
'tenantSwitchTitle': 'Switch Organization',
'tenantCurrent': 'Current',
'tenantSwitching': 'Switching...',
'tenantSwitchSuccess': 'Switched successfully',
'tenantSwitchFailed': 'Switch failed',
'tenantAlreadyCurrent': 'Already in current organization',
'tenantNotSwitchable': 'This organization is not switchable',
'tenantLoadingFailed': 'Failed to load tenant list',
```

---

## 十三、预加载优化

### 13.1 在 AppBootstrap 中预加载租户列表

**文件**：`lib/app/bootstrap/app_bootstrap_provider.dart`

**位置**：在 `_preloadImCache` 函数后添加

**说明**：租户列表预加载应该在 IM 缓存预加载之后执行，确保用户登录后能快速打开租户切换面板

```dart
/// Phase 6: 预加载租户列表（可选优化）
///
/// 在用户登录后，异步预加载租户列表，使得打开租户切换面板时无需等待
Future<void> _preloadTenantList(Ref ref) async {
  try {
    final session = ref.read(authSessionProvider);
    if (!session.isAuthenticated) {
      debugPrint('[Bootstrap] Tenant list preload skipped: user not logged in');
      return;
    }

    final service = ref.read(tenantSwitchServiceProvider.notifier);
    await service.loadTenantList();
    debugPrint('[Bootstrap] Tenant list preloaded: ${service.tenantList.length} tenants');
  } catch (e, stack) {
    debugPrint('[Bootstrap] Tenant list preload error: $e\n$stack');
  }
}
```

**调用位置**：在 `appBootstrapProvider` 的 `Future.wait` 中添加

```dart
await Future.wait<void>([
  _safeBootstrap(ref, 'auth', () => ref.read(authBootstrapCoordinatorProvider).bootstrap()),
  _safeBootstrap(ref, 'locale', () => ref.read(appLocaleControllerProvider.notifier).load()),
  _safeBootstrap(ref, 'theme', () => ref.read(appThemeControllerProvider.notifier).load()),
  _safeBootstrap(ref, 'im-cache', () => _preloadImCache(ref)),
  _safeBootstrap(ref, 'tenant-list', () => _preloadTenantList(ref)),  // 新增
]);
```

**注意**：
- 租户列表预加载是**可选优化**，不影响核心功能
- 如果预加载失败，用户打开租户切换面板时会自动触发加载
- 预加载不会阻塞应用启动

---

## 十四、测试用例

### 14.1 功能测试

| # | 测试场景 | 预期结果 |
|---|----------|----------|
| 1 | 点击租户名称弹出切换页面 | 显示租户列表 BottomSheet |
| 2 | 当前租户显示"当前"标签 | 蓝色高亮 + 勾选图标 |
| 3 | 禁用租户不可点击 | 灰色显示，点击无反应 |
| 4 | 切换到其他租户 | Loading → 成功提示 → 返回主页 |
| 5 | 切换后检查数据 | 旧租户数据已清理，新租户数据已加载 |
| 6 | 切换后检查 WebSocket | 自动重连，认证 payload 包含正确的 tenantId |
| 7 | 切换后检查角标 | 旧租户角标已清理，新租户角标正确显示 |
| 8 | 快速连续切换 | 仅响应第一次，后续点击被 Loading 状态阻止 |
| 9 | 切换过程中网络断开 | 显示错误提示，保持原租户状态 |
| 10 | 切换后检查 API 请求 | 所有请求携带正确的 tenantId 头 |

### 14.2 边界测试

| # | 测试场景 | 预期结果 |
|---|----------|----------|
| 1 | 未登录状态点击租户切换 | 不显示切换页面 |
| 2 | 只有一个租户 | 显示"当前"标签，不可切换 |
| 3 | 所有租户都禁用 | 全部灰色，无法切换 |
| 4 | 切换过程中退出应用 | 重新进入后保持原租户状态 |
| 5 | 切换后检查本地存储 | 旧租户的 SharedPreferences 数据已清理 |
| 6 | 切换后检查本地数据库 | 旧租户的 SQLite 数据已清理 |
| 7 | Token 过期时切换 | 提示"登录已过期，请重新登录" |
| 8 | 正在发送消息时切换 | 提示等待消息发送完成（需额外检查） |

---

## 十五、文件变更清单

| 操作 | 文件路径 | 变更说明 |
|------|----------|----------|
| **后端新增** | `AppAuthController.java` L178 | 新增 `toTenant` 接口 |
| **后端新增** | `AppUserController.java` L228 | 新增 `getMyTenantList` 接口 |
| 修改 | `lib/core/auth/auth_remote_data_source.dart` | 新增 `getMyTenantList`、`toTenant` 方法 |
| **新增** | `lib/core/auth/tenant_list_item_dto.dart` | 租户列表项 DTO |
| **新增** | `lib/features/profile/domain/services/tenant_switch_service.dart` | 租户切换服务（包含完整的 provider invalidation） |
| **新增** | `lib/features/profile/presentation/pages/tenant_switch_page.dart` | 租户切换页面（BottomSheet） |
| 修改 | `lib/features/im/conversation/presentation/pages/conversation_list_page.dart` | 添加租户切换入口（顶部） |
| 修改 | `lib/core/websocket/socket_auth_payload_builder.dart` L31-47 | 添加 tenantId 到认证 payload |
| 修改 | `lib/infrastructure/database/im_database.dart` L100 之后 | 添加 `clearAllTables()` 方法 |
| 修改 | `lib/app/bootstrap/app_bootstrap_provider.dart` | 预加载租户列表（可选优化） |
| 修改 | `lib/core/i18n/app_strings.dart` | 添加国际化文案（可选） |

**注意**：
- ✅ **无需修改** `lib/app/router/app_router.dart`（BottomSheet 不需要独立路由）
- ✅ **无需修改** `lib/app/bootstrap/app_bootstrap.dart`（预加载逻辑在 provider 层）
- ✅ **无需修改** `lib/core/auth/auth_session.dart`（已包含 tenantId 字段）

---

## 十六、实施顺序

```
Phase 0 (后端准备): ✅ 已完成
  ✅ - 后端新增 AppAuthController.toTenant 接口（L178）
  ✅ - 后端新增 AppUserController.getMyTenantList 接口（L228）
  ✅ - 验证 AdminAuthServiceImpl.toTenant 方法可用性

Phase 1 (基础层): ✅ 已完成
  ✅ T1 (DTO) → tenant_list_item_dto.dart
  ✅ T2 (API) → auth_remote_data_source.dart 新增方法
  ✅ T3 (数据库) → im_database.dart 添加 clearAllTables()

Phase 2 (服务层): ✅ 已完成
  ✅ T4 (核心服务) → tenant_switch_service.dart
    ✅ - 实现 switchTenant 方法
    ✅ - 实现 _clearTenantScopedData 方法
    ✅ - 实现 _invalidateProviders 方法（必须与 SessionCleanupService 保持一致）
    ✅ - 实现 WebSocket 断开重连逻辑

Phase 3 (UI 层): ✅ 已完成
  ✅ T5 (切换页面) → tenant_switch_page.dart（BottomSheet）
  ✅ T6 (入口集成) → conversation_list_page.dart 顶部添加租户切换栏

Phase 4 (优化): ✅ 已完成
  ✅ T7 (WebSocket) → socket_auth_payload_builder.dart 添加 tenantId
  ✅ T8 (预加载) → app_bootstrap_provider.dart 预加载租户列表
  ✅ T9 (国际化) → app_zh.arb 和 app_en.arb 添加文案

Phase 5 (验证): ⏳ 待执行
  - 功能测试：切换流程、数据清理、WebSocket 重连
  - 边界测试：并发切换、网络异常、Token 过期
  - 数据隔离验证：确保旧租户数据完全清理
  - Provider 验证：确保所有业务数据正确刷新
```

---

## 十七、关键设计决策

### 17.1 为什么租户切换时必须清理本地数据库？

**问题**：本地数据库表（conversations_table、messages_table）只有 `userId` 字段，没有 `tenantId` 字段。

**风险**：如果不清理数据库，切换租户后会看到旧租户的数据，造成数据泄露。

**方案选择**：
- 方案 A：租户切换时清理数据库（推荐）
- 方案 B：为数据库表添加 tenantId 字段（需要数据库迁移）

**选择理由**：
1. 方案 A 实现简单，风险低
2. 租户切换是低频操作，重新同步的开销可接受
3. 避免数据库迁移的复杂性
4. 与飞书设计一致（飞书切换企业也是重新加载）

### 17.2 为什么在会话列表页顶部添加租户切换入口？

**问题**：用户需要快速切换租户，入口应该明显且易于访问。

**方案选择**：
- 方案 A：在会话列表页顶部添加（推荐）
- 方案 B：在 Profile 页面添加

**选择理由**：
1. 会话列表页是 IM 应用的首页，用户最常访问
2. 符合飞书企业切换 UX：左上角企业名称可点击
3. 降低复杂度，避免在多个页面维护入口
4. 提高功能可见性，用户无需进入 Profile 页面即可切换

### 17.3 为什么切换成功后要导航到根页面？

**问题**：用户可能在聊天页面内触发切换，切换后聊天页的数据属于旧租户。

**解决方案**：切换成功后调用 `Navigator.of(context).popUntil((route) => route.isFirst)`，确保用户回到会话列表页。

---

## 十八、WebSocket+Netty 中间件层影响分析

### 18.1 现有架构分析

#### 18.1.1 会话管理层（NettySessionManager）

**关键发现**：
- ✅ 已有 `tenantId` 字段（`NettySession.java` L33）
- ✅ 已有 `tenantChannelMap`（`NettySessionManager.java` L82）：按租户维度管理会话
- ✅ 已有 `getSessionsByTenantId` 方法（L622-637）：支持按租户查询
- ✅ `addSession` 和 `removeSession` 已正确维护租户映射

**结论**：会话管理层已原生支持多租户，无需修改。

#### 18.1.2 认证层（AuthService）

**关键发现**：
- ✅ `validateToken` 方法验证 token 时会自动获取 tenantId
- ✅ `getTenantId` 方法从 LoginUser 获取租户ID
- ✅ 认证流程已支持租户隔离

**结论**：认证层已原生支持多租户，无需修改。

#### 18.1.3 消息处理层（JsonWebSocketMessageHandler）

**关键发现**：
- ✅ 消息处理时使用 `TenantUtils.execute(tenantId, ...)` 确保租户上下文正确（L88-89）
- ✅ tenantId 从 session 获取，确保消息路由到正确的租户

**结论**：消息处理层已原生支持多租户，无需修改。

### 18.2 租户切换影响点

#### 18.2.1 关键问题：租户切换时必须断开重连

**问题描述**：
- `NettySession` 的 `tenantId` 在会话创建时设置，之后**不会更新**
- 如果租户切换时不断开 WebSocket，旧连接的 `tenantId` 仍然是旧租户
- 消息会路由到错误的租户，造成数据泄露

**解决方案**：
```dart
// TenantSwitchService._clearTenantScopedData() 中已包含：
await imSocketClient.disconnect();  // ✅ 断开旧连接

// _reconnectWebSocket() 中：
await imSocketClient.connect();     // ✅ 建立新连接
await imSocketClient.auth(newSession);  // ✅ 使用新 session 认证（包含新 tenantId）
```

**验证点**：
- ✅ 设计文档已正确实现断开重连流程
- ✅ 新连接的 `NettySession` 会包含新的 `tenantId`

#### 18.2.2 多端登录互踢策略

**现有策略**（`NettySessionManager.java` L169-184）：
- 同一设备类型只允许一个设备在线
- 不同设备类型可以同时在线

**租户切换场景**：
- 用户在同一设备（如 iOS）切换租户
- 旧连接会被互踢策略踢掉（`kickOffDevice` 方法 L386-396）
- 新连接会建立

**结论**：互踢策略在租户切换场景下行为正确，无需修改。

#### 18.2.3 残留连接清理

**潜在问题**：
- 如果客户端异常断开（如网络中断、应用崩溃），服务端可能残留旧连接
- 残留连接的 `tenantId` 仍然是旧租户

**现有机制**：
- ✅ 心跳检测（`IdleStateHandler` + `HeartbeatHandler`）：检测空闲连接
- ✅ 认证租约监控（`NettyAuthLeaseMonitor`）：扫描过期会话
- ✅ 僵尸连接清理（`NettyAuthLeaseMonitor.java` L86-93）：清理不活跃连接

**优化建议**：
```java
// NettyAuthLeaseMonitor.java 中已有僵尸连接清理逻辑
if (!session.isActive()) {
    Channel ch = session.getChannel();
    if (ch != null) {
        sessionManager.removeSession(ch);  // ✅ 清理残留连接
        cleanedCount++;
    }
    continue;
}
```

**结论**：现有机制已能处理残留连接，无需额外修改。

### 18.3 优化设计点

#### 18.3.1 WebSocket 认证 Payload 显式传递 tenantId

**现状**：
- `socket_auth_payload_builder.dart` 的 `buildAuthEnvelope` 方法没有显式传递 tenantId
- 虽然 token 包含租户信息，但显式传递更清晰

**优化方案**（已在设计文档第九章实现）：
```dart
Map<String, Object?> buildAuthEnvelope(AuthSession session) {
  return {
    'header': {...},
    'body': {
      'accessToken': session.accessToken,
      'tenantId': session.tenantId,  // ✅ 新增：显式传递 tenantId
      'deviceType': session.deviceType,
      // ...
    },
  };
}
```

**好处**：
- 服务端可以快速校验 token 和 tenantId 是否一致
- 便于日志追踪和审计

#### 18.3.2 服务端校验 tenantId 一致性

**建议新增**：
```java
// AuthHandler.java 中新增校验逻辑
public void channelRead(ChannelHandlerContext ctx, Object msg) {
    // 解析认证消息
    AuthRequest authRequest = parseAuthRequest(msg);
    
    // 验证 token
    LoginBase loginUser = authService.validateToken(authRequest.getAccessToken());
    if (loginUser == null) {
        sendAuthError(ctx, "Invalid token");
        return;
    }
    
    // 校验 tenantId 一致性（如果客户端传递了 tenantId）
    Long tokenTenantId = authService.getTenantId(loginUser);
    Long clientTenantId = authRequest.getTenantId();
    if (clientTenantId != null && !clientTenantId.equals(tokenTenantId)) {
        log.warn("[AuthHandler] TenantId mismatch: token={}, client={}", 
                 tokenTenantId, clientTenantId);
        sendAuthError(ctx, "TenantId mismatch");
        return;
    }
    
    // 构建 NettySession
    NettySession session = NettySession.builder()
        .channel(ctx.channel())
        .userId(loginUser.getId())
        .tenantId(tokenTenantId)  // 使用 token 中的 tenantId
        // ...
        .build();
    
    sessionManager.addSession(session);
}
```

**好处**：
- 防止客户端伪造 tenantId
- 提前发现租户切换异常

#### 18.3.3 租户切换审计日志

**建议新增**：
```java
// NettySessionLifecycleListener 实现类
public class TenantSwitchAuditListener implements NettySessionLifecycleListener {
    
    @Override
    public void onSessionRemoved(NettySession session) {
        // 记录会话移除原因（租户切换、正常登出、被踢等）
        if (session.getRemoveReason() == RemoveReason.TENANT_SWITCH) {
            auditLogPublisher.publish(AuditLogBuilder.builder()
                .eventType("TENANT_SWITCH")
                .eventName("租户切换")
                .userId(session.getUserId())
                .tenantId(session.getTenantId())
                .deviceId(session.getDeviceId())
                .deviceType(session.getDeviceType())
                .timestamp(System.currentTimeMillis())
                .build());
        }
    }
}
```

**好处**：
- 追踪租户切换行为
- 便于安全审计

#### 18.3.4 租户切换时的消息缓冲

**潜在问题**：
- 租户切换时，WebSocket 断开重连需要时间
- 期间可能有消息丢失

**解决方案**：
- ✅ 服务端已有离线消息机制（`OfflinePushService`）
- ✅ 客户端重连后会从服务端同步最新消息
- ✅ 设计文档已包含数据清理和重新同步逻辑

**结论**：现有机制已能处理消息缓冲，无需额外修改。

### 18.4 关键检查清单

| # | 检查项 | 状态 | 说明 |
|---|--------|------|------|
| 1 | NettySession 包含 tenantId | ✅ | 已原生支持 |
| 2 | 会话管理器支持按租户查询 | ✅ | tenantChannelMap 已实现 |
| 3 | 消息处理使用正确的租户上下文 | ✅ | TenantUtils.execute 已实现 |
| 4 | 租户切换时断开重连 | ✅ | 设计文档已实现 |
| 5 | 多端登录互踢策略正确 | ✅ | 已验证 |
| 6 | 残留连接清理机制 | ✅ | 心跳 + 租约监控已实现 |
| 7 | WebSocket payload 显式传递 tenantId | ✅ | 设计文档第九章已实现 |
| 8 | 服务端校验 tenantId 一致性 | ⚠️ | 建议新增（可选优化） |
| 9 | 租户切换审计日志 | ⚠️ | 建议新增（可选优化） |
| 10 | 消息缓冲机制 | ✅ | 离线消息 + 重连同步已实现 |

### 18.5 结论

**核心结论**：WebSocket+Netty 中间件层已原生支持多租户，租户切换功能的影响可控。

**必须实现**：
1. ✅ 租户切换时断开重连（设计文档已实现）
2. ✅ WebSocket payload 显式传递 tenantId（设计文档第九章已实现）

**可选优化**：
1. ⚠️ 服务端校验 tenantId 一致性（建议后续版本实现）
2. ⚠️ 租户切换审计日志（建议后续版本实现）

**无需修改**：
1. ✅ 会话管理层（NettySessionManager）
2. ✅ 认证层（AuthService）
3. ✅ 消息处理层（JsonWebSocketMessageHandler）
4. ✅ 心跳和租约监控机制

---

## 十九、附录

### 附录 A: 飞书企业切换 UX 参考

| 设计要素 | 飞书实现 | 本项目实现 |
|----------|----------|------------|
| 入口位置 | 左上角企业名称 | 会话列表页顶部企业名称栏 |
| 弹出方式 | BottomSheet | BottomSheet (DraggableScrollableSheet) |
| 当前企业标识 | 蓝色高亮 + 勾选 | 蓝色高亮 + "当前" 标签 + 勾选图标 |
| 切换动画 | 平滑过渡 | Loading + SnackBar 成功提示 |
| 企业 Logo | 企业自定义 Logo | 首字母头像（与 Web 端一致） |
| 禁用企业 | 灰色 + 不可点击 | 灰色 + 不可点击 |
| 最近登录 | 显示上次登录时间 | 显示上次登录时间 |
| 数据保留 | 切换回原企业数据完整 | 本地 DB 按 userId 隔离 + 租户切换时清理 |
