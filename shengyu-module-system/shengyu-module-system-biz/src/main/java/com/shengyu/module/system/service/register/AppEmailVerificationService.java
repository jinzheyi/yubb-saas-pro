package com.shengyu.module.system.service.register;

/** App 端邮箱所有权验证。 */
public interface AppEmailVerificationService {

    void sendCode(String email);

    void verifyCode(String email, String code);
}
