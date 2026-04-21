package com.shengyu.framework.web.config;

import org.springframework.web.servlet.i18n.AcceptHeaderLocaleResolver;

import javax.servlet.http.HttpServletRequest;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;

/**
 * 统一语言解析：
 * - 支持 zh/zh-CN/zh-Hans -> zh_CN
 * - 支持 en/en-US -> en
 * - 其它语言回退到简体中文
 */
public class ShengyuLocaleResolver extends AcceptHeaderLocaleResolver {

    private static final Locale LOCALE_ZH_CN = Locale.SIMPLIFIED_CHINESE;
    private static final Locale LOCALE_EN = Locale.ENGLISH;
    private static final List<Locale> SUPPORTED_LOCALES = Arrays.asList(
            LOCALE_ZH_CN,
            LOCALE_EN
    );

    public ShengyuLocaleResolver() {
        setDefaultLocale(LOCALE_ZH_CN);
        setSupportedLocales(SUPPORTED_LOCALES);
    }

    @Override
    public Locale resolveLocale(HttpServletRequest request) {
        String acceptLanguage = request.getHeader("Accept-Language");
        if (acceptLanguage == null || acceptLanguage.trim().isEmpty()) {
            return getDefaultLocale();
        }
        String normalized = acceptLanguage.trim().toLowerCase(Locale.ROOT);
        if (normalized.startsWith("zh")) {
            return LOCALE_ZH_CN;
        }
        if (normalized.startsWith("en")) {
            return LOCALE_EN;
        }
        return getDefaultLocale();
    }
}
