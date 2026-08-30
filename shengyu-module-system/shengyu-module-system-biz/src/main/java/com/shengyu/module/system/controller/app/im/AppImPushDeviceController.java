package com.shengyu.module.system.controller.app.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import com.shengyu.framework.operatelog.core.annotations.OperateLog;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.module.system.controller.app.im.vo.push.AppImPushTokenRegisterReqVO;
import com.shengyu.module.system.service.im.push.ImPushDeviceRegistry;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import javax.validation.Valid;

import static com.shengyu.framework.common.exception.enums.GlobalErrorCodeConstants.UNAUTHORIZED;
import static com.shengyu.framework.common.pojo.CommonResult.success;

@Tag(name = "移动端 - IM 推送设备")
@RestController
@RequestMapping("/system/im/push/device-token")
@Validated
@DataPermission(enable = false)
@RequiredArgsConstructor
public class AppImPushDeviceController {
    private final ImPushDeviceRegistry registry;

    @PostMapping
    @Operation(summary = "登记当前设备的推送 token")
    @OperateLog(enable = false) // 推送 token 属于凭据，禁止写入操作日志
    public CommonResult<Boolean> register(@Valid @RequestBody AppImPushTokenRegisterReqVO body) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        Long tenantId = TenantContextHolder.getTenantId();
        if (userId == null || tenantId == null) return CommonResult.error(UNAUTHORIZED);
        registry.register(tenantId, userId, body.getProvider(), body.getDeviceId(), body.getPlatform(),
                body.getToken(), body.getAppVersion(), body.getPermissionState());
        return success(true);
    }

    @DeleteMapping
    @Operation(summary = "注销当前设备的推送 token")
    @OperateLog(enable = false)
    public CommonResult<Boolean> unregister(@RequestParam String provider, @RequestParam String deviceId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        Long tenantId = TenantContextHolder.getTenantId();
        if (userId == null || tenantId == null) return CommonResult.error(UNAUTHORIZED);
        registry.unregister(tenantId, userId, provider, deviceId);
        return success(true);
    }
}
