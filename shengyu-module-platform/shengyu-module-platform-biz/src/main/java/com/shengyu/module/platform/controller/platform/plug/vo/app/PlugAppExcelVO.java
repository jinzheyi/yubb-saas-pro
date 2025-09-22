package com.shengyu.module.platform.controller.platform.plug.vo.app;

import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.excel.core.annotations.DictFormat;
import com.shengyu.framework.excel.core.convert.DictConvert;
import cn.idev.excel.annotation.ExcelProperty;
import lombok.Data;

import java.time.LocalDateTime;


/**
 * 插件应用 Excel VO
 *
 * @author zhusy
 */
@Data
public class PlugAppExcelVO {

    @ExcelProperty("id")
    private Long id;

    @ExcelProperty("应用名称")
    private String name;

    @ExcelProperty("条码")
    private String appSn;

    @ExcelProperty(value = "状态（0上架 1下架）", converter = DictConvert.class)
    @DictFormat("common_status") // TODO 代码优化：建议设置到对应的 XXXDictTypeConstants 枚举类中
    private Integer status;

    /**
     * 状态（0启用 1停用）平台端操作，停用后租户不能使用该插件
     *
     * 枚举 {@link CommonStatusEnum}
     */
    @ExcelProperty(value = "状态（0启用 1停用）", converter = DictConvert.class)
    @DictFormat("common_status") // TODO 代码优化：建议设置到对应的 XXXDictTypeConstants 枚举类中
    private Integer enable;

    @ExcelProperty("创建时间")
    private LocalDateTime createTime;

    @ExcelProperty("应用主图地址")
    private String mainPic;

}
