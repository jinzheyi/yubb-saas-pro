package com.shengyu.framework.common.exception.util;

import com.shengyu.framework.common.exception.ErrorCode;
import com.shengyu.framework.common.exception.ServiceException;
import com.shengyu.framework.common.exception.enums.GlobalErrorCodeConstants;
import com.google.common.annotations.VisibleForTesting;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.ObjectUtils;
import org.springframework.context.MessageSource;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.lang.Nullable;

import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

/**
 * {@link ServiceException} 工具类
 *
 * 目的在于，格式化异常信息提示。
 * 考虑到 String.format 在参数不正确时会报错，因此使用 {} 作为占位符，并使用 {@link #doFormat(int, String, Object...)} 方法来格式化
 *
 * 因为 {@link #MESSAGES} 里面默认是没有异常信息提示的模板的，所以需要使用方自己初始化进去。目前想到的有几种方式：
 *
 * 1. 异常提示信息，写在枚举类中，例如说，cn.iocoder.oceans.user.api.constants.ErrorCodeEnum 类 + ServiceExceptionConfiguration
 * 2. 异常提示信息，写在 .properties 等等配置文件
 * 3. 异常提示信息，写在 Apollo 等等配置中心中，从而实现可动态刷新
 * 4. 异常提示信息，存储在 db 等等数据库中，从而实现可动态刷新
 */
@Slf4j
public class ServiceExceptionUtil {

    private static volatile MessageSource messageSource;

    /**
     * 错误码提示模板
     */
    private static final ConcurrentMap<Integer, String> MESSAGES = new ConcurrentHashMap<>();

    public static void setMessageSource(@Nullable MessageSource source) {
        ServiceExceptionUtil.messageSource = source;
    }

    public static void putAll(Map<Integer, String> messages) {
        ServiceExceptionUtil.MESSAGES.putAll(messages);
    }

    public static void put(Integer code, String message) {
        ServiceExceptionUtil.MESSAGES.put(code, message);
    }

    public static void delete(Integer code, String message) {
        ServiceExceptionUtil.MESSAGES.remove(code, message);
    }

    // ========== 和 ServiceException 的集成 ==========

    public static ServiceException exception(ErrorCode errorCode) {
        String messagePattern = resolveMessagePattern(errorCode.getCode(), errorCode.getMsg());
        return exception0(errorCode.getCode(), messagePattern);
    }

    public static ServiceException exception(ErrorCode errorCode, Object... params) {
        String messagePattern = resolveMessagePattern(errorCode.getCode(), errorCode.getMsg());
        return exception0(errorCode.getCode(), messagePattern, params);
    }

    public static void fail(boolean condition, ErrorCode errorCode, Object... params) {
        if (condition) {
            fail(errorCode, params);
        }
    }

    public static void fail(ErrorCode errorCode, Object... params) {
        String messagePattern = resolveMessagePattern(errorCode.getCode(), errorCode.getMsg());
        throw exception0(errorCode.getCode(), messagePattern, params);
    }

    public static void isEmpty(Object obj, ErrorCode errorCode, Object... params) {
        fail(ObjectUtils.isEmpty(obj), errorCode, params);
    }

    public static void nonEmpty(Object obj, ErrorCode errorCode, Object... params) {
        fail(!ObjectUtils.isEmpty(obj), errorCode, params);
    }

    public static void equals(Object a, Object b, ErrorCode errorCode, Object... params) {
        fail(Objects.equals(a, b), errorCode, params);
    }

    public static void nonEquals(Object a, Object b, ErrorCode errorCode, Object... params) {
        fail(!Objects.equals(a, b), errorCode, params);
    }

    /**
     * 创建指定编号的 ServiceException 的异常
     *
     * @param code 编号
     * @return 异常
     */
    public static ServiceException exception(Integer code) {
        return exception0(code, resolveMessagePattern(code, MESSAGES.get(code)));
    }

    /**
     * 创建指定编号的 ServiceException 的异常
     *
     * @param code 编号
     * @param params 消息提示的占位符对应的参数
     * @return 异常
     */
    public static ServiceException exception(Integer code, Object... params) {
        return exception0(code, resolveMessagePattern(code, MESSAGES.get(code)), params);
    }

    public static ServiceException exception0(Integer code, String messagePattern, Object... params) {
        String message = doFormat(code, messagePattern, params);
        return new ServiceException(code, message);
    }

    public static ServiceException invalidParamException(String messagePattern, Object... params) {
        return exception0(GlobalErrorCodeConstants.BAD_REQUEST.getCode(), messagePattern, params);
    }

    public static String getOrDefault(String key, String defaultMessage, Object... args) {
        try {
            if (messageSource == null) {
                return defaultMessage;
            }
            return messageSource.getMessage(key, args, defaultMessage, LocaleContextHolder.getLocale());
        } catch (Exception e) {
            return defaultMessage;
        }
    }

    private static String resolveMessagePattern(Integer code, String defaultMessage) {
        String messagePattern = MESSAGES.get(code);
        if (messagePattern == null || messagePattern.trim().isEmpty()) {
            messagePattern = defaultMessage;
        }
        return getOrDefault("error.code." + code, messagePattern);
    }

    // ========== 格式化方法 ==========

    /**
     * 将错误编号对应的消息使用 params 进行格式化。
     *
     * @param code           错误编号
     * @param messagePattern 消息模版
     * @param params         参数
     * @return 格式化后的提示
     */
    @VisibleForTesting
    public static String doFormat(int code, String messagePattern, Object... params) {
        StringBuilder sbuf = new StringBuilder(messagePattern.length() + 50);
        int i = 0;
        int j;
        int l;
        for (l = 0; l < params.length; l++) {
            j = messagePattern.indexOf("{}", i);
            if (j == -1) {
                log.error("[doFormat][参数过多：错误码({})|错误内容({})|参数({})", code, messagePattern, params);
                if (i == 0) {
                    return messagePattern;
                } else {
                    sbuf.append(messagePattern.substring(i));
                    return sbuf.toString();
                }
            } else {
                sbuf.append(messagePattern, i, j);
                sbuf.append(params[l]);
                i = j + 2;
            }
        }
        if (messagePattern.indexOf("{}", i) != -1) {
            log.error("[doFormat][参数过少：错误码({})|错误内容({})|参数({})", code, messagePattern, params);
        }
        sbuf.append(messagePattern.substring(i));
        return sbuf.toString();
    }

}
