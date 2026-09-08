package com.shengyu.module.platform.controller.platform.apprelease;

import cn.hutool.core.io.FileUtil;
import cn.hutool.core.io.IoUtil;
import cn.hutool.core.util.StrUtil;
import cn.hutool.crypto.digest.DigestUtil;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.infra.api.file.FileApi;
import com.shengyu.module.platform.controller.platform.apprelease.vo.PlatformAppReleaseCreateReqVO;
import com.shengyu.module.platform.controller.platform.apprelease.vo.PlatformAppReleasePageReqVO;
import com.shengyu.module.platform.controller.platform.apprelease.vo.PlatformAppReleasePackageUploadReqVO;
import com.shengyu.module.platform.controller.platform.apprelease.vo.PlatformAppReleasePackageUploadRespVO;
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

import java.util.Arrays;
import java.util.List;
import java.util.Locale;

import static com.shengyu.framework.common.pojo.CommonResult.success;
import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.APP_RELEASE_PACKAGE_TYPE_INVALID;

@Tag(name = "平台管理后台 - 应用版本")
@RestController
@RequestMapping("/system/app-release")
@Validated
public class PlatformAppReleaseController {

    @Resource
    private PlatformAppReleaseService appReleaseService;

    @Resource
    private FileApi fileApi;

    @PostMapping("/upload-package")
    @Operation(summary = "上传应用安装包", description = "按平台校验扩展名，并自动返回下载地址、包大小和 SHA-256")
    @PreAuthorize("@ps.hasAnyPermissions('system:app-release:create', 'system:app-release:update')")
    public CommonResult<PlatformAppReleasePackageUploadRespVO> uploadPackage(
            @Valid PlatformAppReleasePackageUploadReqVO reqVO) throws Exception {
        String platform = normalizeSegment(reqVO.getPlatform());
        String fileName = StrUtil.blankToDefault(reqVO.getFile().getOriginalFilename(), "release-package");
        validatePackageExtension(platform, fileName);

        byte[] content = IoUtil.readBytes(reqVO.getFile().getInputStream());
        String url = fileApi.createFile(content, fileName,
                "app-release/" + normalizeSegment(reqVO.getAppKey()) + "/" + platform
                        + "/" + normalizeSegment(reqVO.getChannel()),
                reqVO.getFile().getContentType());
        PlatformAppReleasePackageUploadRespVO respVO = new PlatformAppReleasePackageUploadRespVO();
        respVO.setPackageUrl(url);
        respVO.setFileName(fileName);
        respVO.setPackageSize((long) content.length);
        respVO.setSha256(DigestUtil.sha256Hex(content));
        return success(respVO);
    }

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

    private void validatePackageExtension(String platform, String fileName) {
        String extension = FileUtil.extName(fileName).toLowerCase(Locale.ROOT);
        List<String> extensions;
        switch (platform) {
            case "android":
                extensions = Arrays.asList("apk");
                break;
            case "ios":
                extensions = Arrays.asList("ipa");
                break;
            case "harmony":
                extensions = Arrays.asList("hap", "app");
                break;
            default:
                throw exception(APP_RELEASE_PACKAGE_TYPE_INVALID);
        }
        if (!extensions.contains(extension)) {
            throw exception(APP_RELEASE_PACKAGE_TYPE_INVALID);
        }
    }

    private String normalizeSegment(String value) {
        return StrUtil.blankToDefault(value, "").trim().toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9_-]", "_");
    }

}
