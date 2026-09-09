package com.shengyu.module.system.controller.admin.tenant;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.system.dal.dataobject.tenant.TenantInviteDO;
import com.shengyu.module.system.service.tenant.TenantJoinService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.LocalDateTime;
import java.util.List;
import com.shengyu.module.system.dal.dataobject.tenant.TenantJoinApplyDO;
import javax.annotation.Resource;
import javax.validation.Valid;
import lombok.Data;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import static com.shengyu.framework.common.pojo.CommonResult.success;

@Tag(name = "管理后台 - 企业邀请码") @RestController @RequestMapping("/system/tenant-invite") @Validated
public class TenantInviteController {
    @Resource private TenantJoinService tenantJoinService;
    @PostMapping("/create") @Operation(summary = "创建企业邀请码") @PreAuthorize("@ss.hasPermission('system:user:create')")
    public CommonResult<TenantInviteDO> create(@Valid @RequestBody CreateReqVO reqVO) { return success(tenantJoinService.createInvite(reqVO.getName(), reqVO.getMaxUseCount(), reqVO.getExpireTime(), reqVO.getAutoApprove())); }
    @GetMapping("/list") @Operation(summary = "获得企业邀请码列表") @PreAuthorize("@ss.hasPermission('system:user:create')")
    public CommonResult<List<TenantInviteDO>> list() { return success(tenantJoinService.getInviteList()); }
    @GetMapping("/apply-list") @Operation(summary = "获得企业加入申请列表") @PreAuthorize("@ss.hasPermission('system:user:update')")
    public CommonResult<List<TenantJoinApplyDO>> applyList() { return success(tenantJoinService.getApplyList()); }
    @PostMapping("/disable") @Operation(summary = "停用企业邀请码") @PreAuthorize("@ss.hasPermission('system:user:create')")
    public CommonResult<Boolean> disable(@RequestParam Long id) { tenantJoinService.disableInvite(id); return success(true); }
    @PostMapping("/approve") @Operation(summary = "审批企业加入申请") @PreAuthorize("@ss.hasPermission('system:user:update')")
    public CommonResult<Boolean> approve(@RequestParam Long applyId, @RequestParam boolean approved) { tenantJoinService.approve(applyId, approved); return success(true); }
    @Data public static class CreateReqVO { private String name; private Integer maxUseCount; private LocalDateTime expireTime; private Boolean autoApprove; }
}
