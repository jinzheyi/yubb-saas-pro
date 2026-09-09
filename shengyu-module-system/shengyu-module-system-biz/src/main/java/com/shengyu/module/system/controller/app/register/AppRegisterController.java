package com.shengyu.module.system.controller.app.register;

import static com.shengyu.framework.common.pojo.CommonResult.success;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.operatelog.core.annotations.OperateLog;
import com.shengyu.module.system.controller.admin.auth.vo.AuthLoginRespVO;
import com.shengyu.module.system.controller.app.register.vo.AppTrialTenantRegisterReqVO;
import com.shengyu.module.system.service.register.AppRegisterService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.annotation.Resource;
import javax.annotation.security.PermitAll;
import javax.validation.Valid;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "移动端 - 注册")
@RestController
@RequestMapping("/system/register")
@Validated
public class AppRegisterController {

    @Resource
    private AppRegisterService appRegisterService;

    @PostMapping({"/tenant", "/demo-tenant", "/trial-tenant"})
    @PermitAll
    @Operation(summary = "邮箱注册并创建企业")
    @OperateLog(enable = false)
    public CommonResult<AuthLoginRespVO> registerTenant(@RequestBody @Valid AppTrialTenantRegisterReqVO reqVO) {
        return success(appRegisterService.registerTenant(reqVO));
    }

}
