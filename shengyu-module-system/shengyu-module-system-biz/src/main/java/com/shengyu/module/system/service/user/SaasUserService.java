package com.shengyu.module.system.service.user;

import com.shengyu.module.system.dal.dataobject.user.SaasUserDO;

/**
 * @author zhusy
 * @description: 后台SaaS用户接口
 * @date 2024/3/17 23:24
 */
public interface SaasUserService {

    /**
     * 通过用户名查询用户
     *
     * @param username 账户名
     * @return 用户对象信息
     */
    SaasUserDO getUserByUsername(String username);

    /**
     * 判断密码是否匹配
     *
     * @param rawPassword 未加密的密码
     * @param encodedPassword 加密后的密码
     * @return 是否匹配
     */
    boolean isPasswordMatch(String rawPassword, String encodedPassword);

    /**
     * 通过用户 ID 查询用户
     *
     * @param id 用户ID
     * @return 用户对象信息
     */
    SaasUserDO getUser(Long id);

    /**
     *
     * @param id
     * @param defaultTenant
     */
    void updateUserDefaultTenant(Long id, Long defaultTenant);

    /**
     * 通过手机号获取用户
     *
     * @param mobile 手机号
     * @return 用户对象信息
     */
    SaasUserDO getUserByMobile(String mobile);

    /**
     * 注册或校验邮箱主账号。
     *
     * 如果邮箱已存在，需要密码匹配，避免别人用同一个邮箱创建企业。
     * 如果邮箱不存在，则创建新的 SaaS 自然人账号。
     *
     * @param username 邮箱账号
     * @param password 明文密码
     * @param mobile 预留手机号
     * @return SaaS 用户
     */
    SaasUserDO registerOrValidateEmailUser(String username, String password, String mobile);

    /**
     * 邮箱已完成验证码校验后，获取已有自然人账号或创建新账号。
     * 新账号使用系统生成的初始密码；已有账号绝不重置密码。
     */
    SaasUserDO registerOrGetVerifiedEmailUser(String username, String generatedPassword, String mobile);

}
