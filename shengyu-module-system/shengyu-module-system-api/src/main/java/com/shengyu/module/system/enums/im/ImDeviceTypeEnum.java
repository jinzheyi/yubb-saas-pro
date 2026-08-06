package com.shengyu.module.system.enums.im;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * IM 设备类型枚举
 *
 * @author 圣钰科技
 */
@Getter
@AllArgsConstructor
public enum ImDeviceTypeEnum {

    WEB(1, "Web"),
    IOS(2, "iOS"),
    ANDROID(3, "Android"),
    MINI_PROGRAM(4, "小程序"),
    ;

    private final Integer type;
    private final String name;

    /**
     * 根据类型获取枚举
     */
    public static ImDeviceTypeEnum valueOfType(Integer type) {
        if (type == null) {
            return null;
        }
        for (ImDeviceTypeEnum e : values()) {
            if (e.getType().equals(type)) {
                return e;
            }
        }
        return null;
    }

    /**
     * 根据类型获取名称，未知类型返回"未知"
     */
    public static String getNameByType(Integer type) {
        ImDeviceTypeEnum deviceType = valueOfType(type);
        return deviceType != null ? deviceType.getName() : "未知";
    }
}
