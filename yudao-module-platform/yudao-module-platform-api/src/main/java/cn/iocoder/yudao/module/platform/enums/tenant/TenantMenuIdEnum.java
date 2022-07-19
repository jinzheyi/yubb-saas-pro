package cn.iocoder.yudao.module.platform.enums.tenant;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * Menu 编号枚举
 */
@Getter
@AllArgsConstructor
public enum TenantMenuIdEnum {

    /**
     * 根节点
     */
    ROOT(0L);

    private final Long id;

}
