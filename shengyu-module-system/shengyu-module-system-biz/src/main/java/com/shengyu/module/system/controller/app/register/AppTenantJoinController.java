package com.shengyu.module.system.controller.app.register;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.dal.dataobject.tenant.TenantJoinApplyDO;
import com.shengyu.module.system.service.tenant.TenantJoinService;
import com.shengyu.module.system.service.user.AdminUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.annotation.Resource;
import javax.validation.Valid;
import javax.validation.constraints.NotBlank;
import lombok.Data;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import static com.shengyu.framework.common.pojo.CommonResult.success;

@Tag(name = "移动端 - 企业加入")
@RestController
@RequestMapping("/system/tenant-join")
@Validated
public class AppTenantJoinController {
    @Resource private TenantJoinService tenantJoinService;
    @Resource private AdminUserService adminUserService;
    @PostMapping("/by-invite")
    @Operation(summary = "通过邀请码申请加入企业")
    public CommonResult<TenantJoinApplyDO> joinByInvite(@Valid @RequestBody JoinReqVO reqVO) {
        UserRespVO user = adminUserService.getUser(SecurityFrameworkUtils.getLoginUserId());
        return success(tenantJoinService.joinByInviteCode(reqVO.getInviteCode(), user.getSaasUserId(), user.getNickname()));
    }
    @Data public static class JoinReqVO { @NotBlank private String inviteCode; }
}
