package com.shengyu.framework.websocket.config;

import com.shengyu.framework.common.enums.oauth2.OAuth2ClientConstants;
import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

import javax.validation.constraints.NotNull;

/**
 * Netty 配置属性
 *
 * @author 圣钰科技
 */
@Data
@Validated
@ConfigurationProperties(prefix = "shengyu.netty")
public class NettyProperties {

    /**
     * 是否启用 Netty 服务器
     */
    private Boolean enable = true;

    /**
     * 服务器主机地址
     */
    @NotNull(message = "Netty 服务器主机地址不能为空")
    private String host = "0.0.0.0";

    /**
     * 服务器端口
     */
    @NotNull(message = "Netty 服务器端口不能为空")
    private Integer port = 9000;

    /**
     * 是否使用 Epoll（Linux 环境下性能更优）
     */
    private Boolean useEpoll = true;

    /**
     * Boss 线程数（接收连接）
     */
    private Integer bossThreads = 1;

    /**
     * Worker 线程数（处理 IO）
     * 默认为 CPU 核心数 * 2
     */
    private Integer workerThreads = Runtime.getRuntime().availableProcessors() * 2;

    /**
     * TCP 连接队列大小
     */
    private Integer soBacklog = 1024;

    /**
     * TCP 接收缓冲区大小（字节）
     */
    private Integer soRcvbuf = 64 * 1024;

    /**
     * TCP 发送缓冲区大小（字节）
     */
    private Integer soSndbuf = 64 * 1024;

    /**
     * 写缓冲区低水位线（字节）
     */
    private Integer writeBufferLowWaterMark = 32 * 1024;

    /**
     * 写缓冲区高水位线（字节）
     */
    private Integer writeBufferHighWaterMark = 64 * 1024;

    /**
     * 读空闲时间（秒）
     * 超过此时间未收到客户端消息，触发读空闲事件
     */
    private Integer readerIdleTime = 60;

    /**
     * 写空闲时间（秒）
     * 超过此时间未向客户端发送消息，触发写空闲事件
     */
    private Integer writerIdleTime = 0;

    /**
     * 读写空闲时间（秒）
     * 超过此时间既未读也未写，触发读写空闲事件
     */
    private Integer allIdleTime = 0;

    /**
     * 是否启用 WebSocket 协议
     */
    private Boolean enableWebSocket = true;

    /**
     * WebSocket 路径
     */
    private String webSocketPath = "/ws";

    /**
     * WebSocket SubProtocol（Sec-WebSocket-Protocol）协商列表，逗号分隔。
     */
    private String webSocketSubProtocols = "im.json.v1,im.pb.v1";

    /**
     * 严格模式：连接建立后必须在该时间内完成 PROBE（毫秒），否则关闭连接。
     */
    private Long probeTimeoutMs = 3000L;

    /**
     * HTTP 最大内容长度（字节）
     */
    private Integer maxContentLength = 64 * 1024;

    /**
     * 是否启用 Protobuf 协议
     */
    private Boolean enableProtobuf = true;

    /**
     * IM 专用 OAuth2 clientId（用于撤销联动过滤，避免影响其他客户端）
     */
    private String imOAuth2ClientId = OAuth2ClientConstants.CLIENT_ID_TENANT_IM_UNIAPPX;

    /**
     * IM 鉴权租约有效期（秒）
     */
    private Long authLeaseSeconds = 30 * 60L;

    /**
     * IM 租约到期前的续期建议窗口（秒）
     */
    private Long authRenewSuggestSeconds = 5 * 60L;

    /**
     * 业务活跃窗口（秒）。在该窗口内有业务活跃，才触发续期建议。
     */
    private Long bizActiveWindowSeconds = 2 * 60L;

    /**
     * Lease 扫描周期（秒）
     */
    private Long authLeaseMonitorIntervalSeconds = 10L;

    /**
     * 最大 WebSocket 帧大小（字节），默认 1MB
     * 防止超大消息导致 OOM
     */
    private Integer maxFramePayloadLength = 1024 * 1024;

    /**
     * 最大连接数限制，默认 100000
     * 防止连接风暴耗尽服务器资源
     */
    private Integer maxConnections = 100000;

    /**
     * 单 IP 最大连接数，默认 100
     * 防止单 IP 连接耗尽
     */
    private Integer perIpMaxConnections = 100;

    /**
     * JSON 消息最大长度（字节），默认 256KB
     * 防止超大 JSON 导致 GC 压力
     */
    private Integer maxJsonMessageLength = 256 * 1024;

    // ==================== SSL/TLS 配置 ====================

    /**
     * 是否启用 SSL/TLS（wss://）
     * 默认关闭，开发环境使用 ws://；生产环境建议启用以符合等保三级要求
     */
    private Boolean sslEnabled = false;

    /**
     * SSL KeyStore 路径
     * 支持 classpath: 和 file: 两种格式
     */
    private String sslKeyStore = "classpath:keystore.p12";

    /**
     * SSL KeyStore 密码
     */
    private String sslKeyStorePassword = "changeit";

    /**
     * SSL KeyStore 类型
     */
    private String sslKeyStoreType = "PKCS12";

    // ==================== 消息签名配置（等保三级数据完整性） ====================

    /**
     * 是否启用消息签名验证（等保三级要求）
     * 开发环境默认关闭，生产环境建议开启
     * 使用 HMAC-SHA256 对消息进行签名，确保消息在传输过程中未被篡改
     */
    private Boolean messageSignatureEnabled = false;
}
