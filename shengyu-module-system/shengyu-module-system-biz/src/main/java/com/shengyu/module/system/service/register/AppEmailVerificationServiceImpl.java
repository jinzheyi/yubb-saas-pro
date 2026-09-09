package com.shengyu.module.system.service.register;

import cn.hutool.core.util.RandomUtil;
import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.enums.UserTypeEnum;
import com.shengyu.module.platform.api.mail.MailSendApi;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import javax.annotation.Resource;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_EMAIL_CODE_FREQUENT;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_EMAIL_CODE_INVALID;

@Service
public class AppEmailVerificationServiceImpl implements AppEmailVerificationService {

    private static final String CODE_KEY_PREFIX = "system:app-register:email-code:";
    private static final String SEND_LOCK_KEY_PREFIX = "system:app-register:email-code-lock:";
    private static final long CODE_TTL_MINUTES = 10;
    private static final long SEND_INTERVAL_SECONDS = 60;

    @Resource
    private StringRedisTemplate stringRedisTemplate;
    @Resource
    private MailSendApi mailSendApi;

    @Override
    public void sendCode(String email) {
        String normalizedEmail = normalize(email);
        Boolean sent = stringRedisTemplate.opsForValue().setIfAbsent(
                SEND_LOCK_KEY_PREFIX + normalizedEmail, "1", SEND_INTERVAL_SECONDS, TimeUnit.SECONDS);
        if (!Boolean.TRUE.equals(sent)) {
            throw exception(USER_EMAIL_CODE_FREQUENT);
        }
        String code = RandomUtil.randomNumbers(6);
        stringRedisTemplate.opsForValue().set(CODE_KEY_PREFIX + normalizedEmail, code, CODE_TTL_MINUTES, TimeUnit.MINUTES);
        Map<String, Object> params = new HashMap<>();
        params.put("code", code);
        params.put("expireMinutes", CODE_TTL_MINUTES);
        try {
            mailSendApi.sendSingleMail(normalizedEmail, null, UserTypeEnum.ADMIN.getValue(), "app-register-code", params);
        } catch (RuntimeException ex) {
            stringRedisTemplate.delete(CODE_KEY_PREFIX + normalizedEmail);
            stringRedisTemplate.delete(SEND_LOCK_KEY_PREFIX + normalizedEmail);
            throw ex;
        }
    }

    @Override
    public void verifyCode(String email, String code) {
        String normalizedEmail = normalize(email);
        String key = CODE_KEY_PREFIX + normalizedEmail;
        String expected = stringRedisTemplate.opsForValue().get(key);
        if (StrUtil.isBlank(expected) || !StrUtil.equals(expected, StrUtil.trim(code))) {
            throw exception(USER_EMAIL_CODE_INVALID);
        }
        stringRedisTemplate.delete(key);
    }

    private String normalize(String email) {
        return StrUtil.trim(email).toLowerCase();
    }
}
