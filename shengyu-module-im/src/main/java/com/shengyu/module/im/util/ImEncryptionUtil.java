package com.shengyu.module.im.util;

import org.apache.commons.codec.binary.Base64;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;

/**
 * IM消息加密工具类
 * 使用AES对称加密算法
 *
 * @author 圣钰科技
 */
public class ImEncryptionUtil {

    private static final String ALGORITHM = "AES";
    private static final String TRANSFORMATION = "AES/ECB/PKCS5Padding";
    private static final int KEY_SIZE = 128;

    /**
     * 生成AES密钥
     *
     * @return 密钥字符串（Base64编码）
     * @throws Exception 生成密钥异常
     */
    public static String generateKey() throws Exception {
        KeyGenerator keyGenerator = KeyGenerator.getInstance(ALGORITHM);
        SecureRandom secureRandom = new SecureRandom();
        keyGenerator.init(KEY_SIZE, secureRandom);
        SecretKey secretKey = keyGenerator.generateKey();
        return Base64.encodeBase64String(secretKey.getEncoded());
    }

    /**
     * 加密消息
     *
     * @param content 待加密内容
     * @param key     密钥（Base64编码）
     * @return 加密后的内容（Base64编码）
     * @throws Exception 加密异常
     */
    public static String encrypt(String content, String key) throws Exception {
        SecretKeySpec secretKeySpec = new SecretKeySpec(Base64.decodeBase64(key), ALGORITHM);
        Cipher cipher = Cipher.getInstance(TRANSFORMATION);
        cipher.init(Cipher.ENCRYPT_MODE, secretKeySpec);
        byte[] encryptedBytes = cipher.doFinal(content.getBytes(StandardCharsets.UTF_8));
        return Base64.encodeBase64String(encryptedBytes);
    }

    /**
     * 解密消息
     *
     * @param encryptedContent 加密后的内容（Base64编码）
     * @param key              密钥（Base64编码）
     * @return 解密后的内容
     * @throws Exception 解密异常
     */
    public static String decrypt(String encryptedContent, String key) throws Exception {
        SecretKeySpec secretKeySpec = new SecretKeySpec(Base64.decodeBase64(key), ALGORITHM);
        Cipher cipher = Cipher.getInstance(TRANSFORMATION);
        cipher.init(Cipher.DECRYPT_MODE, secretKeySpec);
        byte[] decryptedBytes = cipher.doFinal(Base64.decodeBase64(encryptedContent));
        return new String(decryptedBytes, StandardCharsets.UTF_8);
    }
}
