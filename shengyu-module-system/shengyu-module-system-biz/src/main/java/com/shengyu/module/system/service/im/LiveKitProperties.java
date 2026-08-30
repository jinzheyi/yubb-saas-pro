package com.shengyu.module.system.service.im;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;
import org.springframework.validation.annotation.Validated;

import javax.annotation.PostConstruct;
import javax.validation.constraints.Max;
import javax.validation.constraints.Min;
import javax.validation.constraints.NotBlank;

/**
 * LiveKit 私有化部署配置。
 *
 * <p>API secret 仅可存在于服务端部署环境，绝不能下发到 Flutter 客户端。</p>
 */
@Component
@ConfigurationProperties(prefix = "im.call.livekit")
@Validated
@Data
public class LiveKitProperties {

    /** 客户环境向客户端公开的 wss 地址，例如 wss://rtc.customer.example。 */
    @NotBlank(message = "im.call.livekit.url 未配置（环境变量 IM_CALL_LIVEKIT_URL）")
    private String url;

    /** LiveKit API key。 */
    @NotBlank(message = "im.call.livekit.api-key 未配置（环境变量 IM_CALL_LIVEKIT_API_KEY）")
    private String apiKey;

    /** LiveKit API secret。 */
    @NotBlank(message = "im.call.livekit.api-secret 未配置（环境变量 IM_CALL_LIVEKIT_API_SECRET）")
    private String apiSecret;

    /** 客户端首次连接 Token 的有效期，默认 10 分钟。 */
    @Min(value = 1, message = "im.call.livekit.token-expire-seconds 不能小于 1")
    @Max(value = 3600, message = "im.call.livekit.token-expire-seconds 不能大于 3600")
    private long tokenExpireSeconds = 600;

    /** 仅 local 调试允许 ws://；生产必须保持 false 并使用 wss://。 */
    private boolean allowInsecure = false;

    /**
     * 在 Spring 完成配置绑定时立即失败，禁止把配置错误延迟到用户发起通话时才暴露。
     */
    @PostConstruct
    public void validateClientUrl() {
        if (url == null || url.trim().isEmpty()
                || apiKey == null || apiKey.trim().isEmpty()
                || apiSecret == null || apiSecret.trim().isEmpty()) {
            throw new IllegalStateException("LiveKit 配置不完整：必须注入 "
                    + "IM_CALL_LIVEKIT_URL/API_KEY/API_SECRET");
        }
        if (tokenExpireSeconds <= 0 || tokenExpireSeconds > 3600) {
            throw new IllegalStateException("IM_CALL_LIVEKIT_TOKEN_EXPIRE_SECONDS 必须在 1 到 3600 秒之间");
        }
        if (url.startsWith("wss://")) {
            return;
        }
        if (allowInsecure && url.startsWith("ws://")) {
            return;
        }
        throw new IllegalStateException("im.call.livekit.url 必须使用 wss://"
                + "（本地联调仅可在 IM_CALL_LIVEKIT_ALLOW_INSECURE=true 时使用 ws://）");
    }
}
