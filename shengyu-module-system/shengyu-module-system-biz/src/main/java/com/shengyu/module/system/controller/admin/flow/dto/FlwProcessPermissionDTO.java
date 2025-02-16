package com.shengyu.module.system.controller.admin.flow.dto;

import com.aizuda.boot.modules.flw.entity.FlwProcessPermission;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

/**
 * 流程定义权限DTO
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Getter
@Setter
public class FlwProcessPermissionDTO {

    @Schema(description = "用户ID")
    private Long userId;

    @Schema(description = "用户名")
    private String userName;

    @Schema(description = "允许编辑/停用/删除审批 0，否 1，是")
    private Integer operateApproval;

    @Schema(description = "允许添加/移除审批负责人 0，否 1，是")
    private Integer operateOwner;

    @Schema(description = "允许审批数据查询与操作 0，否 1，是")
    private Integer operateData;

    public static FlwProcessPermissionDTO of(FlwProcessPermission flwProcessPermission) {
        FlwProcessPermissionDTO dto = new FlwProcessPermissionDTO();
        dto.setUserId(flwProcessPermission.getUserId());
        dto.setUserName(flwProcessPermission.getUserName());
        dto.setOperateApproval(flwProcessPermission.getOperateApproval());
        dto.setOperateOwner(flwProcessPermission.getOperateOwner());
        dto.setOperateData(flwProcessPermission.getOperateData());
        return dto;
    }

    public FlwProcessPermission toFlwProcessPermission(Long processId) {
        FlwProcessPermission fpp = new FlwProcessPermission();
        fpp.setProcessId(processId);
        fpp.setUserId(this.userId);
        fpp.setUserName(this.userName);
        fpp.setOperateApproval(this.operateApproval);
        fpp.setOperateOwner(this.operateOwner);
        fpp.setOperateData(this.operateData);
        return fpp;
    }

}
