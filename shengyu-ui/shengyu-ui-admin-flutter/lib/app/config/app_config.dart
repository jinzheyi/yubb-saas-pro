import 'package:shengyu_ui_admin_im/core/platform/video_compression_config.dart';

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
  /// 生产环境使用正式域名或 IP，真机调试时使用开发机 IP 地址。
  /// mDNS (.local) 域名在部分安卓机型（如小米 HyperOS）上解析不稳定，
  /// 建议生产环境使用 HTTPS 域名，开发环境使用 IP 直连。
  /// TODO: 生产环境替换为正式 HTTPS 域名，如 https://im.yourdomain.com/app-api
  static const String apiBaseUrl = 'http://MacBook-Pro-3.local:48080/app-api';

  /// IM WebSocket 地址。
  ///
  /// 同上，生产环境使用 wss:// 协议 + 正式域名。
  /// TODO: 生产环境替换为 wss://im.yourdomain.com/ws
  static const String socketUrl = 'ws://MacBook-Pro-3.local:9000/ws';

  /// 网络延迟探测目标地址（Web 平台使用 HTTP 请求）。
  ///
  /// 开发环境默认使用 API 服务器地址（HTTP 方式探测，避免 DNS 解析失败），
  /// 生产环境可替换为 CDN 节点、健康检查端点或外部探测服务。
  /// 如果不需要网络探测，可设置为空字符串，此时探测直接返回 9999ms。
  static const String networkProbeUrl = 'http://MacBook-Pro-3.local:48080/app-api';

  /// 网络延迟探测目标主机（非 Web 平台使用 Socket 连接）。
  static const String networkProbeHost = 'MacBook-Pro-3.local';

  /// 网络延迟探测目标端口（非 Web 平台使用 Socket 连接）。
  static const int networkProbePort = 48080;

  /// 文件上传与预览相关接口路径。
  ///
  /// 统一收口到配置，避免业务代码散落硬编码。
  static const String fileUploadAndReturnIdPath =
      '/infra/file/upload-and-return-id';
  static const String fileOpenStrategyPath = '/infra/file/open-strategy';
  static const String filePresignedGetUrlPath = '/infra/file/presigned-get-url';
  static const String filePresignedUploadUrlPath = '/infra/file/presigned-url';
  static const String fileCreatePath = '/infra/file/create';
  static const String fileUploadFieldName = 'file';
  static const int filePreviewExpirationSeconds = 600;

  /// 文件上传大小限制（字节）。
  ///
  /// 对标企业微信/钉钉：
  /// - 图片：20MB
  /// - 视频：100MB
  /// - 文件：100MB
  /// 超过限制时，客户端直接拦截并提示友好错误信息，避免发送到后端后才报错。
  static const int maxImageUploadSize = 20 * 1024 * 1024; // 20MB
  static const int maxVideoUploadSize = 100 * 1024 * 1024; // 100MB
  static const int maxFileUploadSize = 100 * 1024 * 1024; // 100MB

  /// 自定义相机拍摄配置。
  ///
  /// 对标微信：
  /// - 拍摄视频最大时长 60 秒（长按录制）
  /// - 拍摄文件大小限制复用通用上传配置（maxImageUploadSize/maxVideoUploadSize）
  static const int cameraMaxVideoDurationSeconds = 60;

  /// 分片上传相关接口路径。
  static const String fileMultipartUploadInitPath = '/infra/file/upload-init';
  static const String fileMultipartUploadChunkPath = '/infra/file/upload-chunk';
  static const String fileMultipartUploadMergePath = '/infra/file/upload-merge';
  static const String fileMultipartUploadAbortPath = '/infra/file/upload-abort';
  static const String fileMultipartUploadStatusPath =
      '/infra/file/upload-status';

  /// 视频压缩配置。
  ///
  /// 对标微信/钉钉视频压缩策略：
  /// - 质量等级：medium（平衡画质和文件大小）
  /// - 分辨率：720p（1280x720，适合移动端观看）
  /// - 帧率：30fps（流畅度与文件大小平衡）
  /// - 比特率：2Mbps（720p 视频推荐值）
  /// - 压缩阈值：20MB（超过此大小的视频才进行压缩）
  static const VideoCompressionConfig videoCompressionConfig =
      VideoCompressionConfig(
    quality: VideoCompressionQuality.medium,
    resolution: VideoResolution.hd720,
    frameRate: 30,
    bitrate: 2000000, // 2Mbps
    compressionThreshold: 20 * 1024 * 1024, // 20MB
  );

  /// WebSocket 心跳与连接治理配置。
  ///
  /// 说明：
  /// 1. 心跳对标企业微信/飞书 30s 间隔，避免移动端无效耗电。
  /// 2. 超时时间调整为 90s，兼容弱网抖动场景。
  /// 3. 重连采用指数退避，避免服务端故障时形成雪崩重试。
  static const Duration socketHeartbeatInterval = Duration(seconds: 30);
  static const Duration socketHeartbeatTimeout = Duration(seconds: 90);
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
