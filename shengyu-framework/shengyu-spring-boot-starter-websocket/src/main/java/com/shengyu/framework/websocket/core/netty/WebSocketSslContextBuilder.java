package com.shengyu.framework.websocket.core.netty;

import com.shengyu.framework.websocket.config.NettyProperties;
import io.netty.handler.ssl.SslContext;
import io.netty.handler.ssl.SslProvider;

import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLException;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.security.KeyStore;

/**
 * WebSocket SSL/TLS 上下文构建器
 * 用于为 Netty 服务器构建 SslContext，支持 wss:// 协议
 *
 * @author 圣钰科技
 */
public final class WebSocketSslContextBuilder {

    private WebSocketSslContextBuilder() {
    }

    /**
     * 构建 SslContext
     *
     * @param properties Netty 配置属性
     * @return SslContext 实例，如果未启用 SSL 则返回 null
     * @throws IllegalStateException SSL 配置错误或 KeyStore 加载失败时抛出
     */
    public static SslContext buildSslContext(NettyProperties properties) {
        if (!properties.getSslEnabled()) {
            return null;
        }

        String keyStorePath = properties.getSslKeyStore();
        String keyStorePassword = properties.getSslKeyStorePassword();
        String keyStoreType = properties.getSslKeyStoreType();

        // 参数校验
        if (keyStorePath == null || keyStorePath.trim().isEmpty()) {
            throw new IllegalStateException("SSL KeyStore 路径不能为空，请配置 shengyu.netty.ssl-key-store");
        }
        if (keyStorePassword == null || keyStorePassword.trim().isEmpty()) {
            throw new IllegalStateException("SSL KeyStore 密码不能为空，请配置 shengyu.netty.ssl-key-store-password");
        }

        try (InputStream keyStoreStream = loadKeyStoreStream(keyStorePath)) {
            if (keyStoreStream == null) {
                throw new IllegalStateException("SSL KeyStore 文件不存在: " + keyStorePath);
            }

            // 加载 KeyStore
            KeyStore keyStore = KeyStore.getInstance(keyStoreType);
            keyStore.load(keyStoreStream, keyStorePassword.toCharArray());

            // 初始化 KeyManagerFactory
            KeyManagerFactory kmf = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
            kmf.init(keyStore, keyStorePassword.toCharArray());

            // 构建 SslContext（使用 JDK 提供的 SSL 实现）
            return io.netty.handler.ssl.SslContextBuilder.forServer(kmf)
                    .sslProvider(SslProvider.JDK)
                    .protocols("TLSv1.2", "TLSv1.3")
                    .build();
        } catch (SSLException e) {
            throw new IllegalStateException("SSL 配置错误，无法构建 SslContext: " + e.getMessage(), e);
        } catch (Exception e) {
            throw new IllegalStateException("SSL KeyStore 加载失败: " + e.getMessage(), e);
        }
    }

    /**
     * 加载 KeyStore 输入流
     * 支持 classpath: 和 file: 两种路径格式，默认按文件系统路径处理
     *
     * @param path KeyStore 路径
     * @return 输入流
     * @throws IOException 文件读取异常
     */
    private static InputStream loadKeyStoreStream(String path) throws IOException {
        if (path.startsWith("classpath:")) {
            String resourcePath = path.substring("classpath:".length());
            return WebSocketSslContextBuilder.class.getClassLoader().getResourceAsStream(resourcePath);
        } else if (path.startsWith("file:")) {
            return new FileInputStream(path.substring("file:".length()));
        } else {
            return new FileInputStream(path);
        }
    }
}
