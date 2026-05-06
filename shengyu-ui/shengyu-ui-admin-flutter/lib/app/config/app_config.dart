/// Flutter IM 统一配置文件
///
/// 重要约束：
/// 1. 后期需要人工修改的配置，统一放在本文件。
/// 2. 网络地址、WebSocket 地址、请求头键名、租户白名单，不允许散落硬编码。
/// 3. 修改配置时先改本文件，再改依赖代码。
/// 4. 本文件注释使用中文，降低后续维护成本。
///
/// 参考来源：
/// - `shengyu-ui/shengyu-ui-admin-uniappx/config/app.config.uts`
/// - `shengyu-ui/shengyu-ui-admin-uniappx/utils/request.uts`
/// - `shengyu-ui/shengyu-ui-admin-uniappx/utils/websocket.uts`
abstract final class AppConfig {
  /// 公司名称。
  static const String companyName = '圣钰科技';

  /// 应用展示名称。
  static const String appName = '圣钰科技 IM';

  /// App 端 HTTP 地址。
  ///
  /// 当前移动端统一走 `/app-api` 前缀。
  static const String apiBaseUrl = 'http://127.0.0.1:48080/app-api';

  /// IM WebSocket 地址。
  static const String socketUrl = 'ws://127.0.0.1:9000/ws';

  /// 文件上传与预览相关接口路径。
  ///
  /// 统一收口到配置，避免业务代码散落硬编码。
  static const String fileUploadAndReturnIdPath =
      '/infra/file/upload-and-return-id';
  static const String fileOpenStrategyPath = '/infra/file/open-strategy';
  static const String filePresignedGetUrlPath = '/infra/file/presigned-get-url';
  static const String fileUploadFieldName = 'file';
  static const int filePreviewExpirationSeconds = 600;

  /// WebSocket 心跳与连接治理配置。
  ///
  /// 说明：
  /// 1. 心跳频率不宜过高，避免移动端无效耗电。
  /// 2. 超时时间应明显大于服务端正常响应抖动。
  /// 3. 重连采用指数退避，避免服务端故障时形成雪崩重试。
  static const Duration socketHeartbeatInterval = Duration(seconds: 25);
  static const Duration socketHeartbeatTimeout = Duration(seconds: 10);
  static const Duration socketAuthTimeout = Duration(seconds: 8);
  static const Duration socketReconnectBaseDelay = Duration(seconds: 2);
  static const Duration socketReconnectMaxDelay = Duration(seconds: 30);
  static const int socketMaxReconnectAttempts = 10;

  /// 是否启用租户头。
  static const bool tenantEnabled = true;

  /// HTTP 超时配置。
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// 统一请求头键名。
  static const String authorizationHeader = 'Authorization';
  static const String tenantIdHeader = 'tenant-id';
  static const String deviceIdHeader = 'device-id';
  static const String localeHeader = 'Accept-Language';
  static const String requestIdHeader = 'X-Request-Id';

  /// 鉴权头白名单。
  ///
  /// 这些接口不拼接 `Authorization`。
  static const List<String> authorizationHeaderWhiteList = <String>[
    '/system/captcha/',
    '/system/auth/login',
    '/system/auth/sms-login',
    '/system/auth/refresh-token',
    '/system/tenant/get-id-by-name',
  ];

  /// 租户头白名单。
  ///
  /// 这些接口不拼接 `tenant-id`。
  static const List<String> tenantHeaderWhiteList = <String>[
    '/system/captcha/',
    '/system/auth/login',
    '/system/auth/sms-login',
    '/system/auth/refresh-token',
    '/system/tenant/get-id-by-name',
  ];

  /// Bearer Token 统一拼接方式。
  static String formatAuthorization(String token) {
    return 'Bearer $token';
  }

  /// 是否应该拼接鉴权头。
  static bool shouldAttachAuthorizationHeader(String? path) {
    if (path == null || path.isEmpty) {
      return false;
    }
    for (final item in authorizationHeaderWhiteList) {
      if (path.contains(item)) {
        return false;
      }
    }
    return true;
  }

  /// 是否应该拼接租户头。
  static bool shouldAttachTenantHeader(String? path) {
    if (!tenantEnabled || path == null || path.isEmpty) {
      return false;
    }
    for (final item in tenantHeaderWhiteList) {
      if (path.contains(item)) {
        return false;
      }
    }
    return true;
  }

  /// 统一判断请求头是否已存在。
  ///
  /// Dio 中 header key 可能出现大小写差异，这里做一次规范化判断。
  static bool containsHeader(Map<String, dynamic> headers, String headerName) {
    final expected = headerName.toLowerCase();
    for (final key in headers.keys) {
      if (key.toLowerCase() == expected) {
        return true;
      }
    }
    return false;
  }

  /// 统一写入请求头，避免出现大小写不同导致的重复键。
  static void putHeader(
    Map<String, dynamic> headers,
    String headerName,
    String value,
  ) {
    final expected = headerName.toLowerCase();
    final duplicatedKeys = headers.keys
        .where((key) => key.toLowerCase() == expected)
        .toList(growable: false);
    for (final key in duplicatedKeys) {
      headers.remove(key);
    }
    headers[headerName] = value;
  }
}
