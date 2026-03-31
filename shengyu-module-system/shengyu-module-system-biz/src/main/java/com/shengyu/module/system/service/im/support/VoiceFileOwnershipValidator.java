package com.shengyu.module.system.service.im.support;

import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.shengyu.module.infra.api.file.dto.FileDTO;

/**
 * 语音文件归属校验。
 *
 * 约束：
 * 1. 文件必须由当前发送者上传
 * 2. 文件必须位于当前会话的 voice 目录下
 */
public final class VoiceFileOwnershipValidator {

    private VoiceFileOwnershipValidator() {
    }

    public static void validate(FileDTO fileDTO, Long senderId, Long chatId, Long groupId) {
        if (fileDTO == null || fileDTO.getId() == null || fileDTO.getId() <= 0L) {
            throw ServiceExceptionUtil.invalidParamException("VOICE 消息 fileId 不存在");
        }
        if (senderId == null || senderId <= 0L) {
            throw ServiceExceptionUtil.invalidParamException("VOICE 消息 senderId 非法");
        }

        String creator = StrUtil.trim(fileDTO.getCreator());
        if (StrUtil.isBlank(creator) || !StrUtil.equals(creator, String.valueOf(senderId))) {
            throw ServiceExceptionUtil.invalidParamException("VOICE 消息 fileId 不属于当前发送者");
        }

        String path = normalizePath(fileDTO.getPath());
        if (StrUtil.isBlank(path)) {
            throw ServiceExceptionUtil.invalidParamException("VOICE 消息文件路径为空");
        }

        String expectedPrefix;
        if (groupId != null && groupId > 0L) {
            expectedPrefix = "im/group/" + groupId + "/voice/";
        } else {
            if (chatId == null || chatId <= 0L) {
                throw ServiceExceptionUtil.invalidParamException("VOICE 消息 chatId 非法");
            }
            expectedPrefix = "im/chat/" + chatId + "/voice/";
        }

        if (!path.startsWith(expectedPrefix)) {
            throw ServiceExceptionUtil.invalidParamException("VOICE 消息文件目录与当前会话不匹配");
        }
    }

    private static String normalizePath(String path) {
        if (StrUtil.isBlank(path)) {
            return "";
        }
        String normalized = path.trim();
        while (normalized.startsWith("/")) {
            normalized = normalized.substring(1);
        }
        return normalized;
    }
}
