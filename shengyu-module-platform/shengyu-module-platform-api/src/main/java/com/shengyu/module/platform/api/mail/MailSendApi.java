package com.shengyu.module.platform.api.mail;

import java.util.Map;

/**
 * 邮箱发送 API 接口
 *
 * @author 圣钰科技
 */
public interface MailSendApi {

    /**
     * 发送单条邮件给用户
     *
     * @param mail 邮箱
     * @param userId 用户编码
     * @param userType 用户类型
     * @param templateCode 邮件模版编码
     * @param templateParams 邮件模版参数
     * @return 发送日志编号
     */
    Long sendSingleMail(String mail, Long userId, Integer userType,
        String templateCode, Map<String, Object> templateParams);

}
