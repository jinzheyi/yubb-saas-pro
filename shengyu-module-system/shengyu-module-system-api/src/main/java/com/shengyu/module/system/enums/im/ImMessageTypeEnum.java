package com.shengyu.module.system.enums.im;

import cn.hutool.core.util.ObjUtil;
import com.shengyu.framework.common.core.ArrayValuable;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Arrays;

/**
 * IM 消息类型枚举
 *
 * @author 圣钰科技
 */
@Getter
@AllArgsConstructor
public enum ImMessageTypeEnum implements ArrayValuable<Integer> {

    TEXT(1, "文本消息"),
    IMAGE(2, "图片消息"),
    VOICE(3, "语音消息"),
    VIDEO(4, "视频消息"),
    FILE(5, "文件消息"),
    LOCATION(6, "位置消息"),
    EMOJI(7, "表情包消息"),
    STICKER(8, "自定义贴纸消息"),
    CUSTOM(9, "自定义消息"),
    SYSTEM(10, "系统消息");

    public static final Integer[] ARRAYS = Arrays.stream(values()).map(ImMessageTypeEnum::getType).toArray(Integer[]::new);

    /**
     * 类型值
     */
    private final Integer type;
    /**
     * 类型名
     */
    private final String name;

    @Override
    public Integer[] array() {
        return ARRAYS;
    }

    public static boolean isText(Integer type) {
        return ObjUtil.equal(TEXT.type, type);
    }

    public static boolean isImage(Integer type) {
        return ObjUtil.equal(IMAGE.type, type);
    }

    public static boolean isVoice(Integer type) {
        return ObjUtil.equal(VOICE.type, type);
    }

    public static boolean isVideo(Integer type) {
        return ObjUtil.equal(VIDEO.type, type);
    }

    public static boolean isFile(Integer type) {
        return ObjUtil.equal(FILE.type, type);
    }

    public static boolean isLocation(Integer type) {
        return ObjUtil.equal(LOCATION.type, type);
    }

    public static boolean isEmoji(Integer type) {
        return ObjUtil.equal(EMOJI.type, type);
    }

    public static boolean isSticker(Integer type) {
        return ObjUtil.equal(STICKER.type, type);
    }

    public static boolean isSystem(Integer type) {
        return ObjUtil.equal(SYSTEM.type, type);
    }

}
