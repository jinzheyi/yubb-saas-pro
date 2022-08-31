package cn.iocoder.yudao.module.system.api.config.dto;

import lombok.Data;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

/**
 * 参数配置 Base VO，提供给添加、修改、详细的子 VO 使用
 * 如果子 VO 存在差异的字段，请不要添加到这里，影响 Swagger 文档生成
 */
@Data
public class ConfigurationCreateReqDTO {

    @NotNull(message = "平台参数id不能为空")
    private Long configId;

    @NotEmpty(message = "参数分组不能为空")
    @Size(max = 50, message = "参数名称不能超过50个字符")
    private String category;

    @NotBlank(message = "参数名称不能为空")
    @Size(max = 100, message = "参数名称不能超过100个字符")
    private String name;

    @NotBlank(message = "参数键名长度不能为空")
    @Size(max = 100, message = "参数键名长度不能超过100个字符")
    private String configKey;

    @NotBlank(message = "参数键值不能为空")
    @Size(max = 500, message = "参数键值长度不能超过500个字符")
    private String value;

    @NotNull(message = "参数类型不能为空")
    private Integer type;

    @NotNull(message = "是否敏感不能为空")
    private Boolean visible;

    private String remark;

    @NotNull(message = "删除状态不能为空")
    private Boolean deleted;

}
