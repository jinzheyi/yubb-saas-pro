package com.shengyu.module.platform.controller.platform.apprelease;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.platform.controller.platform.apprelease.vo.PlatformAppReleaseCreateReqVO;
import com.shengyu.module.platform.controller.platform.apprelease.vo.PlatformAppReleasePageReqVO;
import com.shengyu.module.platform.controller.platform.apprelease.vo.PlatformAppReleaseRespVO;
import com.shengyu.module.platform.controller.platform.apprelease.vo.PlatformAppReleaseUpdateReqVO;
import com.shengyu.module.platform.service.apprelease.PlatformAppReleaseService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import javax.validation.Valid;

import static com.shengyu.framework.common.pojo.CommonResult.success;

@Tag(name = "平台管理后台 - 应用版本")
@RestController
@RequestMapping("/system/app-release")
@Validated
public class PlatformAppReleaseController {

    @Resource
    private PlatformAppReleaseService appReleaseService;

    @PostMapping("/create")
    @Operation(summary = "创建应用版本")
    @PreAuthorize("@ps.hasPermission('system:app-release:create')")
    public CommonResult<Long> createAppRelease(@Valid @RequestBody PlatformAppReleaseCreateReqVO reqVO) {
        return success(appReleaseService.createAppRelease(reqVO));
    }

    @PutMapping("/update")
    @Operation(summary = "更新应用版本")
    @PreAuthorize("@ps.hasPermission('system:app-release:update')")
    public CommonResult<Boolean> updateAppRelease(@Valid @RequestBody PlatformAppReleaseUpdateReqVO reqVO) {
        appReleaseService.updateAppRelease(reqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除应用版本")
    @Parameter(name = "id", description = "编号", required = true, example = "1")
    @PreAuthorize("@ps.hasPermission('system:app-release:delete')")
    public CommonResult<Boolean> deleteAppRelease(@RequestParam("id") Long id) {
        appReleaseService.deleteAppRelease(id);
        return success(true);
    }

    @PutMapping("/publish")
    @Operation(summary = "发布应用版本")
    @Parameter(name = "id", description = "编号", required = true, example = "1")
    @PreAuthorize("@ps.hasPermission('system:app-release:publish')")
    public CommonResult<Boolean> publishAppRelease(@RequestParam("id") Long id) {
        appReleaseService.publishAppRelease(id);
        return success(true);
    }

    @PutMapping("/pause")
    @Operation(summary = "暂停应用版本")
    @Parameter(name = "id", description = "编号", required = true, example = "1")
    @PreAuthorize("@ps.hasPermission('system:app-release:pause')")
    public CommonResult<Boolean> pauseAppRelease(@RequestParam("id") Long id) {
        appReleaseService.pauseAppRelease(id);
        return success(true);
    }

    @GetMapping("/get")
    @Operation(summary = "获得应用版本")
    @Parameter(name = "id", description = "编号", required = true, example = "1")
    @PreAuthorize("@ps.hasPermission('system:app-release:query')")
    public CommonResult<PlatformAppReleaseRespVO> getAppRelease(@RequestParam("id") Long id) {
        return success(BeanUtils.toBean(appReleaseService.getAppRelease(id), PlatformAppReleaseRespVO.class));
    }

    @GetMapping("/page")
    @Operation(summary = "获得应用版本分页")
    @PreAuthorize("@ps.hasPermission('system:app-release:query')")
    public CommonResult<PageResult<PlatformAppReleaseRespVO>> getAppReleasePage(@Valid PlatformAppReleasePageReqVO reqVO) {
        return success(BeanUtils.toBean(appReleaseService.getAppReleasePage(reqVO), PlatformAppReleaseRespVO.class));
    }

}
