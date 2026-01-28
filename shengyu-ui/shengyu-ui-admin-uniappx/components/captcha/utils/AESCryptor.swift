/**
 * iOS AES 加密工具类
 * 使用 CommonCrypto 实现 AES-ECB-PKCS7 加密
 * 
 * 这个文件需要添加到 iOS 项目中
 * 并在 Bridging-Header.h 中导入 CommonCrypto
 */

import Foundation
import CommonCrypto

@objc public class AESCryptor: NSObject {
    
    /**
     * AES 加密
     * @param plainText 明文
     * @param key 密钥（16 字节）
     * @return Base64 编码的密文
     */
    @objc public static func encrypt(_ plainText: String, withKey key: String) -> String? {
        guard let plainData = plainText.data(using: .utf8),
              let keyData = key.data(using: .utf8) else {
            return nil
        }
        
        return encrypt(data: plainData, key: keyData)
    }
    
    /**
     * AES 解密
     * @param cipherText Base64 编码的密文
     * @param key 密钥（16 字节）
     * @return 明文
     */
    @objc public static func decrypt(_ cipherText: String, withKey key: String) -> String? {
        guard let cipherData = Data(base64Encoded: cipherText),
              let keyData = key.data(using: .utf8) else {
            return nil
        }
        
        guard let decryptedData = decrypt(data: cipherData, key: keyData) else {
            return nil
        }
        
        return String(data: decryptedData, encoding: .utf8)
    }
    
    // MARK: - Private Methods
    
    /**
     * 加密 Data
     */
    private static func encrypt(data: Data, key: Data) -> String? {
        guard let cryptData = crypt(data: data, key: key, operation: CCOperation(kCCEncrypt)) else {
            return nil
        }
        return cryptData.base64EncodedString()
    }
    
    /**
     * 解密 Data
     */
    private static func decrypt(data: Data, key: Data) -> Data? {
        return crypt(data: data, key: key, operation: CCOperation(kCCDecrypt))
    }
    
    /**
     * 核心加密/解密方法
     * 使用 AES-ECB-PKCS7
     */
    private static func crypt(data: Data, key: Data, operation: CCOperation) -> Data? {
        // 准备输出缓冲区
        let dataLength = data.count
        let cryptLength = dataLength + kCCBlockSizeAES128
        var cryptData = Data(count: cryptLength)
        
        var numBytesEncrypted: size_t = 0
        
        let cryptStatus = cryptData.withUnsafeMutableBytes { cryptBytes in
            data.withUnsafeBytes { dataBytes in
                key.withUnsafeBytes { keyBytes in
                    CCCrypt(
                        operation,                          // 操作：加密或解密
                        CCAlgorithm(kCCAlgorithmAES),       // 算法：AES
                        CCOptions(kCCOptionECBMode | kCCOptionPKCS7Padding), // 选项：ECB 模式 + PKCS7 填充
                        keyBytes.baseAddress,               // 密钥
                        key.count,                          // 密钥长度
                        nil,                                // IV（ECB 模式不需要）
                        dataBytes.baseAddress,              // 输入数据
                        dataLength,                         // 输入数据长度
                        cryptBytes.baseAddress,             // 输出缓冲区
                        cryptLength,                        // 输出缓冲区大小
                        &numBytesEncrypted                  // 实际输出长度
                    )
                }
            }
        }
        
        // 检查加密/解密是否成功
        guard cryptStatus == kCCSuccess else {
            print("AES 加密/解密失败: \(cryptStatus)")
            return nil
        }
        
        // 截取实际加密/解密的数据
        cryptData.count = numBytesEncrypted
        return cryptData
    }
}

// MARK: - Extension for Objective-C Compatibility

extension AESCryptor {
    /**
     * Objective-C 兼容方法：加密
     */
    @objc public static func encryptString(_ plainText: String, withKey key: String) -> String? {
        return encrypt(plainText, withKey: key)
    }
    
    /**
     * Objective-C 兼容方法：解密
     */
    @objc public static func decryptString(_ cipherText: String, withKey key: String) -> String? {
        return decrypt(cipherText, withKey: key)
    }
}
