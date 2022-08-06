package cn.iocoder.yudao.module.platform.api.tenant.dto.menu;

import lombok.Data;

@Data
public class TenantMenuListReqDTO {

    /**
     * 菜单名称，模糊匹配
     */
    private String name;

    /**
     * 展示状态，参见 CommonStatusEnum 枚举类
     */
    private Integer status;

}
