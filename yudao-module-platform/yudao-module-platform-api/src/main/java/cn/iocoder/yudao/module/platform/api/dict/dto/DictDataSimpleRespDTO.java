package cn.iocoder.yudao.module.platform.api.dict.dto;

import lombok.Data;

/**
 * 字典数据 Response DTO
 *
 * @author 芋道源码
 */
@Data
public class DictDataSimpleRespDTO {

    /**
     * 字典类型
     */
    private String dictType;

    /**
     * 字典键值
     */
    private String value;

    /**
     * 字典标签
     */
    private String label;

    /**
     * 颜色类型
     */
    private String colorType;

    /**
     * css 样式
     */
    private String cssClass;

}
