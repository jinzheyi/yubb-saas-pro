package com.shengyu.framework.websocket.core.security;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;

/**
 * 消息签名/验证工具
 * 使用 HMAC-SHA256（开发环境）/ HMAC-SM3（生产环境）确保消息完整性
 * 等保三级要求：数据完整性保障
 *
 * @author 圣钰科技
 */
public class MessageSignature {

    /**
     * HMAC 算法名称
     * 开发环境使用 HmacSHA256（JDK 内置），生产环境可切换为 HmacSM3
     */
    private static final String HMAC_ALGORITHM = "HmacSHA256";

    /**
     * 签名长度（SM3/SHA256 都是 32 字节）
     */
    private static final int SIGNATURE_LENGTH = 32;

    /**
     * 生成消息签名
     *
     * @param data       待签名的数据（Header + Payload 的字节数组）
     * @param sessionKey 会话密钥
     * @return 签名结果（32 字节）
     */
    public static byte[] sign(byte[] data, String sessionKey) {
        try {
            Mac mac = Mac.getInstance(HMAC_ALGORITHM);
            SecretKeySpec keySpec = new SecretKeySpec(
                    sessionKey.getBytes(StandardCharsets.UTF_8), HMAC_ALGORITHM);
            mac.init(keySpec);
            return mac.doFinal(data);
        } catch (Exception e) {
            throw new IllegalStateException("Failed to sign message", e);
        }
    }

    /**
     * 验证消息签名
     *
     * @param data              原始数据
     * @param sessionKey        会话密钥
     * @param expectedSignature 期望的签名
     * @return 签名是否有效
     */
    public static boolean verify(byte[] data, String sessionKey, byte[] expectedSignature) {
        byte[] computedSignature = sign(data, sessionKey);
        // 使用常量时间比较，防止时序攻击
        return MessageDigest.isEqual(computedSignature, expectedSignature);
    }

    /**
     * 生成会话密钥（基于 Token 和时间戳）
     *
     * @param token     认证 Token
     * @param timestamp 时间戳
     * @return Base64 编码的会话密钥
     */
    public static String generateSessionKey(String token, long timestamp) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            md.update((token + timestamp).getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(md.digest());
        } catch (Exception e) {
            throw new IllegalStateException("Failed to generate session key", e);
        }
    }

    /**
     * 获取签名长度
     *
     * @return 签名长度（字节）
     */
    public static int getSignatureLength() {
        return SIGNATURE_LENGTH;
    }

    private MessageSignature() {
        // 工具类禁止实例化
    }
}
