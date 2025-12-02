/**
 * @word 要加密的内容
 * @keyWord String  服务器随机返回的关键字
 *  */
import CryptoJS from 'crypto-js';

export function aesEncrypt(word, keyWord = "XwKsGlMcdPMEhR1B") {
    // 使用AES-ECB加密模式，与PC端保持一致
    const key = CryptoJS.enc.Utf8.parse(keyWord);
    const srcs = CryptoJS.enc.Utf8.parse(word);
    
    // 加密
    const encrypted = CryptoJS.AES.encrypt(srcs, key, {
        mode: CryptoJS.mode.ECB,
        padding: CryptoJS.pad.Pkcs7
    });
    
    // 返回完整的加密结果，包括salt、iv和密文
    return encrypted.toString();
}