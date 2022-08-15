package cn.iocoder.yudao.module.platform.controller.center.oauth2;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.client.OAuth2ClientCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.client.OAuth2ClientPageReqVO;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.client.OAuth2ClientRespVO;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.client.OAuth2ClientUpdateReqVO;
import cn.iocoder.yudao.module.platform.convert.auth.OAuth2ClientConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2ClientDO;
import cn.iocoder.yudao.module.platform.service.oauth2.PlatformOAuth2ClientService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiImplicitParam;
import io.swagger.annotations.ApiOperation;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;

@Api(tags = "管理后台 - OAuth2 客户端")
@RestController
@RequestMapping("/center/oauth2-client")
@Validated
public class CenterOAuth2ClientController {

    @Resource
    private PlatformOAuth2ClientService platformOAuth2ClientService;

    @PostMapping("/create")
    @ApiOperation("创建 OAuth2 客户端")
    @PreAuthorize("@cs.hasPermission('center:oauth2-client:create')")
    public CommonResult<Long> createOAuth2Client(@Valid @RequestBody OAuth2ClientCreateReqVO createReqVO) {
        return success(platformOAuth2ClientService.createOAuth2Client(createReqVO));
    }

    @PutMapping("/update")
    @ApiOperation("更新 OAuth2 客户端")
    @PreAuthorize("@cs.hasPermission('center:oauth2-client:update')")
    public CommonResult<Boolean> updateOAuth2Client(@Valid @RequestBody OAuth2ClientUpdateReqVO updateReqVO) {
        platformOAuth2ClientService.updateOAuth2Client(updateReqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @ApiOperation("删除 OAuth2 客户端")
    @ApiImplicitParam(name = "id", value = "编号", required = true, dataTypeClass = Long.class)
    @PreAuthorize("@cs.hasPermission('center:oauth2-client:delete')")
    public CommonResult<Boolean> deleteOAuth2Client(@RequestParam("id") Long id) {
        platformOAuth2ClientService.deleteOAuth2Client(id);
        return success(true);
    }

    @GetMapping("/get")
    @ApiOperation("获得 OAuth2 客户端")
    @ApiImplicitParam(name = "id", value = "编号", required = true, example = "1024", dataTypeClass = Long.class)
    @PreAuthorize("@cs.hasPermission('center:oauth2-client:query')")
    public CommonResult<OAuth2ClientRespVO> getOAuth2Client(@RequestParam("id") Long id) {
        PlatformOAuth2ClientDO oAuth2Client = platformOAuth2ClientService.getOAuth2Client(id);
        return success(OAuth2ClientConvert.INSTANCE.convert(oAuth2Client));
    }

    @GetMapping("/page")
    @ApiOperation("获得OAuth2 客户端分页")
    @PreAuthorize("@cs.hasPermission('center:oauth2-client:query')")
    public CommonResult<PageResult<OAuth2ClientRespVO>> getOAuth2ClientPage(@Valid OAuth2ClientPageReqVO pageVO) {
        PageResult<PlatformOAuth2ClientDO> pageResult = platformOAuth2ClientService.getOAuth2ClientPage(pageVO);
        return success(OAuth2ClientConvert.INSTANCE.convertPage(pageResult));
    }

}
