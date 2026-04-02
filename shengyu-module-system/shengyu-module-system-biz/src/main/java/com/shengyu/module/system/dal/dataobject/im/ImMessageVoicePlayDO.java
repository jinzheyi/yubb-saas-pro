package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.mybatis.core.dataobject.BaseDO;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * IM 语音消息播放状态 DO
 *
 * 对应表: im_message_voice_play
 * 功能: 记录用户在会话内对语音消息的首次播放时间（用于多端未听点同步）
 */
@TableName(value = "im_message_voice_play", autoResultMap = true)
@KeySequence("im_message_voice_play_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImMessageVoicePlayDO extends BaseDO {

    @TableId
    private Long id;

    private Long messageId;

    private Long chatId;

    private Long userId;

    private LocalDateTime playedTime;

    private Long tenantId;

}

