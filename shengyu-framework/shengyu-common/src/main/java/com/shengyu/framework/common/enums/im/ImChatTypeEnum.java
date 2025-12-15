package com.shengyu.framework.common.enums.im;

import com.shengyu.framework.common.core.ArrayValuable;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Arrays;
import java.util.stream.Collectors;

/**
 * 消息类型枚举
 *
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2022/12/5 22:18
 */
@Getter
@AllArgsConstructor
public enum ImChatTypeEnum implements ArrayValuable<String> {

    /**
     * 文字
     */
    TEXT("text"),

    /**
     * 表情
     */
    EXPRESSION("emoticon"),

    /**
     * 图片
     */
    PICTURE("image"),

    /**
     * 视频
     */
    VIDEO("video"),

    /**
     * 音频
     */
    AUDIO("audio"),

    /**
     * 卡片
     */
    CARD("card"),

    ;

    /**
     * 消息类型
     */
    private final String chatType;

    public static final String[] ARRAYS = Arrays.stream(values()).map(ImChatTypeEnum::getChatType).collect(Collectors.toList()).toArray(new String[]{});

    @Override
    public String[] array() {
        return ARRAYS;
    }

}
