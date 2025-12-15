package com.shengyu.framework.common.enums.im;

import com.shengyu.framework.common.core.ArrayValuable;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Arrays;
import java.util.stream.Collectors;

/**
 * 消息场景枚举
 *
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2022/12/5 22:18
 */
@Getter
@AllArgsConstructor
public enum ImChatSceneEnum implements ArrayValuable<String> {

    /**
     * 单聊
     */
    SINGLE_CHAT("user"),

    /**
     * 群聊
     */
    GROUP_CHAT("group"),

    /**
     * 撤回消息
     */
    RECALL_CHAT("recall"),

    ;

    /**
     * 消息场景
     */
    private final String chatScene;

    public static final String[] ARRAYS = Arrays.stream(values()).map(ImChatSceneEnum::getChatScene).collect(Collectors.toList()).toArray(new String[]{});

    @Override
    public String[] array() {
        return ARRAYS;
    }

}
