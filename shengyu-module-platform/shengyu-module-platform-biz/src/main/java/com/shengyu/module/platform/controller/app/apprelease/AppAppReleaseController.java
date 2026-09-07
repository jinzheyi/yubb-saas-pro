package com.shengyu.module.platform.controller.app.apprelease;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import com.shengyu.module.platform.controller.app.apprelease.vo.AppReleaseCheckReqVO;
import com.shengyu.module.platform.controller.app.apprelease.vo.AppReleaseCheckRespVO;
import com.shengyu.module.platform.service.apprelease.PlatformAppReleaseService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import javax.annotation.security.PermitAll;
import javax.validation.Valid;

import static com.shengyu.framework.common.pojo.CommonResult.success;

@Tag(name = "移动端 - 应用版本")
@RestController
@RequestMapping("/system/app-release")
@Validated
@DataPermission(enable = false)
public class AppAppReleaseController {

    @Resource
    private PlatformAppReleaseService appReleaseService;

    @GetMapping("/check")
    @Operation(summary = "检查应用版本更新")
    @PermitAll
    public CommonResult<AppReleaseCheckRespVO> checkAppRelease(@Valid AppReleaseCheckReqVO reqVO) {
        return success(appReleaseService.checkAppRelease(reqVO));
    }

}
