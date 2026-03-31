package com.shengyu.framework.websocket.core.netty.handler;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;

import java.util.Locale;

/**
 * 语音消息入站校验支持。
 *
 * 仅负责 WebSocket 入口的结构校验，避免坏数据继续进入 processor/storage。
 */
final class VoiceMessageValidationSupport {

    private static final long MAX_VOICE_SIZE_BYTES = 10L * 1024 * 1024;
    private static final long MAX_VOICE_DURATION_MS = 60000L;

    private VoiceMessageValidationSupport() {
    }

    static String validate(String extraRaw, Integer bodyDurationSec, Long bodySizeBytes) {
        if (StrUtil.isBlank(extraRaw)) {
            return "请求格式错误：VOICE.header.extra 不能为空";
        }

        final JSONObject extra;
        try {
            extra = JSONUtil.parseObj(extraRaw);
        } catch (Exception ex) {
            return "请求格式错误：VOICE.header.extra 不是合法 JSON";
        }

        Long fileId = readLong(extra.get("fileId"));
        Long durationMs = readLong(extra.get("durationMs"));
        Integer durationSec = readInt(extra.get("duration"));
        Long sizeBytes = readLong(extra.get("size"));
        String format = extra.getStr("format", "");

        if (fileId == null || fileId <= 0L) {
            return "请求格式错误：VOICE.header.extra.fileId 非法";
        }

        long effectiveDurationMs = durationMs != null && durationMs > 0L
                ? durationMs
                : resolveDurationMs(bodyDurationSec, durationSec);
        if (effectiveDurationMs < 1000L || effectiveDurationMs > MAX_VOICE_DURATION_MS) {
            return "请求格式错误：VOICE 时长必须在 1000ms ~ 60000ms 之间";
        }

        long effectiveSizeBytes = sizeBytes != null && sizeBytes > 0L
                ? sizeBytes
                : (bodySizeBytes != null ? bodySizeBytes : 0L);
        if (effectiveSizeBytes <= 0L || effectiveSizeBytes > MAX_VOICE_SIZE_BYTES) {
            return "请求格式错误：VOICE 大小必须在 0 ~ 10MB 之间";
        }

        if (!isAllowedVoiceFormat(format)) {
            return "请求格式错误：VOICE.format 仅支持 mp3/aac/m4a/amr/wav";
        }

        return null;
    }

    private static long resolveDurationMs(Integer bodyDurationSec, Integer extraDurationSec) {
        if (bodyDurationSec != null && bodyDurationSec > 0) {
            return bodyDurationSec * 1000L;
        }
        if (extraDurationSec != null && extraDurationSec > 0) {
            return extraDurationSec * 1000L;
        }
        return 0L;
    }

    private static Long readLong(Object raw) {
        if (raw == null) {
            return null;
        }
        if (raw instanceof Number) {
            return ((Number) raw).longValue();
        }
        try {
            String text = String.valueOf(raw);
            if (StrUtil.isBlank(text)) {
                return null;
            }
            return Long.parseLong(text);
        } catch (Exception ignore) {
            return null;
        }
    }

    private static Integer readInt(Object raw) {
        Long value = readLong(raw);
        return value == null ? null : value.intValue();
    }

    private static boolean isAllowedVoiceFormat(String format) {
        if (StrUtil.isBlank(format)) {
            return false;
        }
        String normalized = format.trim().toLowerCase(Locale.ROOT);
        return "mp3".equals(normalized)
                || "aac".equals(normalized)
                || "m4a".equals(normalized)
                || "amr".equals(normalized)
                || "wav".equals(normalized)
                || "audio/mpeg".equals(normalized)
                || "audio/mp3".equals(normalized)
                || "audio/aac".equals(normalized)
                || "audio/x-aac".equals(normalized)
                || "audio/mp4".equals(normalized)
                || "audio/m4a".equals(normalized)
                || "audio/x-m4a".equals(normalized)
                || "audio/amr".equals(normalized)
                || "audio/wav".equals(normalized)
                || "audio/x-wav".equals(normalized)
                || "audio/wave".equals(normalized);
    }
}
