package com.shengyu.module.system.mq.message.im;

import com.shengyu.framework.mq.redis.core.stream.AbstractRedisStreamMessage;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

import java.util.List;

@Data
@EqualsAndHashCode(callSuper = true)
@Accessors(chain = true)
public class ImGroupConversationRefreshMessage extends AbstractRedisStreamMessage {

    private String action;

    private Long operatorUserId;

    private Long groupId;

    private Long chatId;

    private List<Long> memberIds;

    private Integer conversationType;

}
