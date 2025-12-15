package com.shengyu.framework.netty.core.utils;

import com.shengyu.framework.common.util.json.JsonUtils;
import com.shengyu.framework.netty.core.ImChat;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;

/**
 * 发送消息工具类
 * @author zhusy
 * @since 2021/12/4
 */
public class ByteBufUtils {

    /**
     * 系统级别消息格式组装
     * @return TextWebSocketFrame
     */
    public static TextWebSocketFrame getByteBuf(ImChat imChat) {
        return new TextWebSocketFrame(JsonUtils.toJsonString(imChat));
    }

}
