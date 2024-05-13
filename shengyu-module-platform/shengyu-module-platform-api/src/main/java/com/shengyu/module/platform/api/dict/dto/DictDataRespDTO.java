package com.shengyu.module.platform.api.dict.dto;

import com.shengyu.framework.common.enums.CommonStatusEnum;
import lombok.Data;

/**
 * 字典数据 Response DTO
 *
 * @author 圣钰科技
 */
@Data
public class DictDataRespDTO {

    /**
     * 字典数据编号
     */
    private Long id;
    /**
     * 字典排序
     */
    private Integer sort;

    /**
     * 字典标签
     */
    private String label;
    /**
     * 字典值
     */
    private String value;
    /**
     * 字典类型
     */
    private String dictType;
    /**
     * 状态
     * 枚举 {@link CommonStatusEnum}
     */
    private Integer status;
    /**
     * 颜色类型
     * 对应到 element-ui 为 default、primary、success、info、warning、danger
     */
    private String colorType;
    /**
     * css 样式
     */
    private String cssClass;
    /**
     * 备注
     */
    private String remark;

}
