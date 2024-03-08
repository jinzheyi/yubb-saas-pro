package cn.iocoder.yudao.module.platform.controller.platform.oauth2;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.module.platform.controller.platform.oauth2.vo.client.OAuth2ClientCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.oauth2.vo.client.OAuth2ClientPageReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.oauth2.vo.client.OAuth2ClientRespVO;
import cn.iocoder.yudao.module.platform.controller.platform.oauth2.vo.client.OAuth2ClientUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2ClientDO;
import cn.iocoder.yudao.module.platform.service.oauth2.PlatformOAuth2ClientService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.annotation.Resource;
import javax.validation.Valid;
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

@Tag(name = "管理后台 - OAuth2 客户端")
@RestController
@RequestMapping("/system/oauth2-client")
@Validated
public class PlatformOAuth2ClientController {

    @Resource
    private PlatformOAuth2ClientService platformOAuth2ClientService;

    @PostMapping("/create")
    @Operation(summary = "创建 OAuth2 客户端")
    @PreAuthorize("@ps.hasPermission('system:oauth2-client:create')")
    public CommonResult<Long> createOAuth2Client(@Valid @RequestBody OAuth2ClientCreateReqVO createReqVO) {
        return success(platformOAuth2ClientService.createOAuth2Client(createReqVO));
    }

    @PutMapping("/update")
    @Operation(summary = "更新 OAuth2 客户端")
    @PreAuthorize("@ps.hasPermission('system:oauth2-client:update')")
    public CommonResult<Boolean> updateOAuth2Client(@Valid @RequestBody OAuth2ClientUpdateReqVO updateReqVO) {
        platformOAuth2ClientService.updateOAuth2Client(updateReqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除 OAuth2 客户端")
    @Parameter(name = "id", description = "编号", required = true)
    @PreAuthorize("@ps.hasPermission('system:oauth2-client:delete')")
    public CommonResult<Boolean> deleteOAuth2Client(@RequestParam("id") Long id) {
        platformOAuth2ClientService.deleteOAuth2Client(id);
        return success(true);
    }

    @GetMapping("/get")
    @Operation(summary = "获得 OAuth2 客户端")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('system:oauth2-client:query')")
    public CommonResult<OAuth2ClientRespVO> getOAuth2Client(@RequestParam("id") Long id) {
        PlatformOAuth2ClientDO oAuth2Client = platformOAuth2ClientService.getOAuth2Client(id);
        return success(BeanUtils.toBean(oAuth2Client, OAuth2ClientRespVO.class));
    }

    @GetMapping("/page")
    @Operation(summary = "获得OAuth2 客户端分页")
    @PreAuthorize("@ps.hasPermission('system:oauth2-client:query')")
    public CommonResult<PageResult<OAuth2ClientRespVO>> getOAuth2ClientPage(@Valid OAuth2ClientPageReqVO pageVO) {
        PageResult<PlatformOAuth2ClientDO> pageResult = platformOAuth2ClientService.getOAuth2ClientPage(pageVO);
        return success(BeanUtils.toBean(pageResult, OAuth2ClientRespVO.class));
    }

}
