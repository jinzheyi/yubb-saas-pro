package com.shengyu.module.platform.controller.platform.tenant.vo.tenant;

import com.shengyu.framework.common.enums.DictTypeConstants;
import lombok.*;
import java.time.LocalDateTime;

import cn.idev.excel.annotation.ExcelProperty;
import com.shengyu.framework.excel.core.annotations.DictFormat;
import com.shengyu.framework.excel.core.convert.DictConvert;


/**
 * 租户 Excel VO
 *
 * @author 圣钰科技
 */
@Data
public class TenantExcelVO {

    @ExcelProperty("租户编号")
    private Long id;

    @ExcelProperty("租户名")
    private String name;

    @ExcelProperty("联系人")
    private String contactName;

    @ExcelProperty("联系手机")
    private String contactMobile;

    @ExcelProperty(value = "状态", converter = DictConvert.class)
    @DictFormat(DictTypeConstants.COMMON_STATUS)
    private Integer status;

    @ExcelProperty("创建时间")
    private LocalDateTime createTime;

}
