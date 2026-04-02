package com.shengyu.framework.websocket.core.netty.handler;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;

import java.util.Locale;

/**
 * Voice message inbound validation support.
 */
final class VoiceMessageValidationSupport {

    private static final long MAX_VOICE_SIZE_BYTES = 10L * 1024 * 1024;
    private static final long MAX_VOICE_DURATION_MS = 60000L;

    private VoiceMessageValidationSupport() {
    }

    static String validate(String extraRaw, Integer bodyDurationSec, Long bodySizeBytes) {
        if (StrUtil.isBlank(extraRaw)) {
            return "VOICE.header.extra cannot be empty";
        }

        final JSONObject extra;
        try {
            extra = JSONUtil.parseObj(extraRaw);
        } catch (Exception ex) {
            return "VOICE.header.extra must be valid JSON";
        }

        Long fileId = readLong(extra.get("fileId"));
        Long durationMs = readLong(extra.get("durationMs"));
        Integer durationSec = readInt(extra.get("duration"));
        Long sizeBytes = readLong(extra.get("size"));
        String format = extra.getStr("format", "");

        if (fileId == null || fileId <= 0L
                || durationMs == null || durationMs <= 0L
                || durationSec == null || durationSec <= 0
                || sizeBytes == null || sizeBytes <= 0L
                || StrUtil.isBlank(format)) {
            return "VOICE.header.extra must contain fileId/duration/durationMs/size/format";
        }
        if (durationMs < 1000L || durationMs > MAX_VOICE_DURATION_MS) {
            return "VOICE duration must be between 1000ms and 60000ms";
        }
        int normalizedDurationSec = (int) Math.max(1L, Math.round(durationMs / 1000.0d));
        if (!durationSec.equals(normalizedDurationSec)) {
            return "VOICE.header.extra.duration does not match durationMs";
        }
        if (sizeBytes > MAX_VOICE_SIZE_BYTES) {
            return "VOICE size must be between 1 byte and 10MB";
        }
        if (bodyDurationSec != null && bodyDurationSec > 0 && !durationSec.equals(bodyDurationSec)) {
            return "VOICE.body.duration does not match header.extra.duration";
        }
        if (bodySizeBytes != null && bodySizeBytes > 0L && !sizeBytes.equals(bodySizeBytes)) {
            return "VOICE.body.size does not match header.extra.size";
        }
        if (!isAllowedVoiceFormat(format)) {
            return "VOICE.format only supports mp3/aac/m4a/amr/wav";
        }

        return null;
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
