package cn.iocoder.yudao.module.platform.enums.tenant;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 菜单类型枚举类
 *
 * @author 芋道源码
 */
@Getter
@AllArgsConstructor
public enum TenantMenuTypeEnum {

    DIR(1), // 目录
    MENU(2), // 菜单
    BUTTON(3) // 按钮
    ;

    /**
     * 类型
     */
    private final Integer type;

}
