package com.shengyu.framework.websocket.core.service.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Message storage result.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MessageSaveResult {

    private Long messageId;

    private Long chatId;

    private Long sequence;

}
