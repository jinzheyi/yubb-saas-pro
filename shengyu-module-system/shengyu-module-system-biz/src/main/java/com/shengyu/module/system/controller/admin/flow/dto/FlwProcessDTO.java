package com.shengyu.module.system.controller.admin.flow.dto;

import com.shengyu.framework.flowlong.engine.entity.FlwProcess;
import com.shengyu.module.system.dal.dataobject.flow.FlwFormTemplate;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessSetting;
import io.swagger.v3.oas.annotations.media.Schema;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import org.apache.commons.lang3.StringUtils;

import java.util.List;

/**
 * 流程定义DTO
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Getter
@Setter
public class FlwProcessDTO {

    @Schema(description = "流程定义ID")
    private Long processId;

    @Schema(description = "流程定义 key 唯一标识")
    @NotBlank
    private String processKey;

    @Schema(description = "流程定义名称")
    @NotBlank
    private String processName;

    @Schema(description = "流程定义名称")
    private String processIcon;

    @Schema(description = "流程定义类型")
    private String processType;

    @Schema(description = "备注说明")
    private String remark;

    @Schema(description = "流程分类ID")
    @NotNull
    private Long categoryId;

    @Schema(description = "使用范围 0，全员 1，指定人员（业务关联） 2，均不可提交")
    private Integer useScope = 0;

    @Schema(description = "流程状态 0，不可用 1，可用 2，历史版本")
    protected Integer processState;

    @Schema(description = "流程定义权限")
    private List<FlwProcessPermissionDTO> processPermissionList;

    @Schema(description = "流程模型定义JSON内容")
    @NotBlank
    private String modelContent;

    @Schema(description = "流程定义表单")
    private String processForm;

    @Schema(description = "业务流程表单")
    private String businessForm;

    @Schema(description = "流程定义配置")
    private FlwProcessSetting processSetting;

    @Schema(description = "流程表单模板")
    private FlwFormTemplate formTemplate;

    public String getProcessName() {
        if (StringUtils.isBlank(processName)) {
            return "未命名审批";
        }
        return this.processName;
    }

    public static FlwProcessDTO of(FlwProcess flwProcess) {
        FlwProcessDTO dto = new FlwProcessDTO();
        dto.setProcessId(flwProcess.getId());
        dto.setProcessKey(flwProcess.getProcessKey());
        dto.setProcessName(flwProcess.getProcessName());
        dto.setProcessIcon(flwProcess.getProcessIcon());
        dto.setProcessType(flwProcess.getProcessType());
        dto.setUseScope(flwProcess.getUseScope());
        dto.setProcessState(flwProcess.getProcessState());
        dto.setModelContent(flwProcess.getModelContent());
        dto.setRemark(flwProcess.getRemark());
        return dto;
    }
}
