package com.shengyu.module.system.service.im.support;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import org.springframework.context.MessageSource;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

/**
 * IM 系统消息国际化支持。
 *
 * 约定：
 * 1. 持久化消息仍保留 content 作为旧端/旧数据回退文案
 * 2. extra.i18n 保存 eventKey + params，便于历史系统消息按当前语言重渲染
 * 3. params 使用命名占位符，由服务端和端侧共用
 */
@Component
public class ImSystemMessageI18nSupport {

    public static final String EVENT_GROUP_OWNER_TRANSFERRED = "im.system.group_owner_transferred";
    public static final String EVENT_GROUP_DISBANDED = "im.system.group_disbanded";
    public static final String EVENT_GROUP_MEMBER_ROLE_SET_ADMIN = "im.system.group_member_role_set_admin";
    public static final String EVENT_GROUP_MEMBER_ROLE_SET_MEMBER = "im.system.group_member_role_set_member";
    public static final String EVENT_GROUP_MEMBER_ADDED_ONE = "im.system.group_member_added_one";
    public static final String EVENT_GROUP_MEMBER_ADDED_TWO = "im.system.group_member_added_two";
    public static final String EVENT_GROUP_MEMBER_ADDED_MANY = "im.system.group_member_added_many";
    public static final String EVENT_GROUP_MEMBER_REMOVED = "im.system.group_member_removed";
    public static final String EVENT_GROUP_MEMBER_MUTED = "im.system.group_member_muted";
    public static final String EVENT_GROUP_MEMBER_MUTED_UNTIL = "im.system.group_member_muted_until";
    public static final String EVENT_GROUP_MEMBER_UNMUTED = "im.system.group_member_unmuted";
    public static final String EVENT_GROUP_MUTE_ALL_ENABLED = "im.system.group_mute_all_enabled";
    public static final String EVENT_GROUP_MUTE_ALL_DISABLED = "im.system.group_mute_all_disabled";
    public static final String EVENT_GROUP_NOTICE_UPDATED = "im.system.group_notice_updated";
    public static final String EVENT_RECALL_PREVIEW = "im.recall.preview";

    @Resource
    private MessageSource messageSource;

    public String attachI18n(String rawExtra, String eventKey, Map<String, ?> params) {
        if (StrUtil.isBlank(eventKey)) {
            return rawExtra;
        }
        JSONObject root = parseObject(rawExtra);
        JSONObject i18n = JSONUtil.createObj();
        i18n.set("version", 1);
        i18n.set("eventKey", eventKey);
        i18n.set("params", params != null ? params : Collections.emptyMap());
        root.set("i18n", i18n);
        return root.toString();
    }

    public String render(String fallbackContent, String rawExtra) {
        JSONObject root = parseObject(rawExtra);
        if (root.isEmpty()) {
            if (isRecallPreviewFallback(fallbackContent)) {
                return renderRecallPreview(fallbackContent);
            }
            return fallbackContent;
        }
        JSONObject i18n = root.getJSONObject("i18n");
        if (i18n == null) {
            if (isRecallPreviewFallback(fallbackContent)) {
                return renderRecallPreview(fallbackContent);
            }
            return fallbackContent;
        }
        String eventKey = i18n.getStr("eventKey");
        if (StrUtil.isBlank(eventKey)) {
            return fallbackContent;
        }
        JSONObject paramsObject = i18n.getJSONObject("params");
        Map<String, String> params = new LinkedHashMap<>();
        if (paramsObject != null) {
            for (String key : paramsObject.keySet()) {
                Object value = paramsObject.get(key);
                params.put(key, value != null ? String.valueOf(value) : "");
            }
        }
        Locale locale = LocaleContextHolder.getLocale();
        String template = messageSource.getMessage(eventKey, null, fallbackContent, locale);
        return replaceNamedPlaceholders(template, params, fallbackContent);
    }

    public String renderRecallPreview(String fallbackContent) {
        Locale locale = LocaleContextHolder.getLocale();
        return messageSource.getMessage(EVENT_RECALL_PREVIEW, null,
                StrUtil.nullToDefault(fallbackContent, "[消息已撤回]"), locale);
    }

    public String renderRecallMessage(Long currentUserId, Long recallBy, Long senderId,
                                      String senderName, String recallerName, String fallbackContent) {
        Locale locale = LocaleContextHolder.getLocale();
        if (currentUserId != null && currentUserId.equals(recallBy)) {
            return messageSource.getMessage("im.recall.self", null,
                    StrUtil.nullToDefault(fallbackContent, "你撤回了一条消息"), locale);
        }
        Map<String, String> params = new LinkedHashMap<>();
        String resolvedSenderName = StrUtil.blankToDefault(senderName, "该成员");
        String resolvedRecallerName = StrUtil.blankToDefault(recallerName, resolvedSenderName);
        params.put("senderName", resolvedSenderName);
        params.put("operatorName", resolvedRecallerName);
        String eventKey = recallBy != null && senderId != null && !recallBy.equals(senderId)
                ? "im.recall.other_by_operator"
                : "im.recall.other";
        String template = messageSource.getMessage(eventKey, null,
                StrUtil.nullToDefault(fallbackContent, resolvedRecallerName + " 撤回了一条消息"), locale);
        return replaceNamedPlaceholders(template, params, fallbackContent);
    }

    public boolean isRecallPreviewFallback(String content) {
        return "[消息已撤回]".equals(StrUtil.nullToDefault(content, ""));
    }

    private String replaceNamedPlaceholders(String template, Map<String, String> params, String fallbackContent) {
        String result = StrUtil.nullToDefault(template, fallbackContent);
        if (params == null || params.isEmpty()) {
            return result;
        }
        for (Map.Entry<String, String> entry : params.entrySet()) {
            result = result.replace("{" + entry.getKey() + "}", StrUtil.nullToDefault(entry.getValue(), ""));
        }
        return result;
    }

    private JSONObject parseObject(String rawExtra) {
        if (StrUtil.isBlank(rawExtra)) {
            return JSONUtil.createObj();
        }
        try {
            return JSONUtil.parseObj(rawExtra);
        } catch (Exception ignore) {
            return JSONUtil.createObj();
        }
    }
}
