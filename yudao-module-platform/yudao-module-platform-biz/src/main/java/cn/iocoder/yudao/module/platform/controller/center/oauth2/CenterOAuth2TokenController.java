package cn.iocoder.yudao.module.platform.controller.center.oauth2;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.token.OAuth2AccessTokenPageReqVO;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.token.OAuth2AccessTokenRespVO;
import cn.iocoder.yudao.module.platform.convert.auth.OAuth2TokenConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2AccessTokenDO;
import cn.iocoder.yudao.framework.common.enums.logger.LoginLogTypeEnum;
import cn.iocoder.yudao.module.platform.service.auth.PlatformAuthService;
import cn.iocoder.yudao.module.platform.service.oauth2.PlatformOAuth2TokenService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiImplicitParam;
import io.swagger.annotations.ApiOperation;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;

@Api(tags = "管理后台 - OAuth2.0 令牌")
@RestController
@RequestMapping("/center/oauth2-token")
public class CenterOAuth2TokenController {

    @Resource
    private PlatformOAuth2TokenService oauth2TokenServicePlatform;
    @Resource
    private PlatformAuthService authService;

    @GetMapping("/page")
    @ApiOperation(value = "获得访问令牌分页", notes = "只返回有效期内的")
    @PreAuthorize("@cs.hasPermission('center:oauth2-token:page')")
    public CommonResult<PageResult<OAuth2AccessTokenRespVO>> getAccessTokenPage(@Valid OAuth2AccessTokenPageReqVO reqVO) {
        PageResult<PlatformOAuth2AccessTokenDO> pageResult = oauth2TokenServicePlatform.getAccessTokenPage(reqVO);
        return success(OAuth2TokenConvert.INSTANCE.convert(pageResult));
    }

    @DeleteMapping("/delete")
    @ApiOperation("删除访问令牌")
    @ApiImplicitParam(name = "accessToken", value = "访问令牌", required = true, dataTypeClass = String.class, example = "tudou")
    @PreAuthorize("@cs.hasPermission('center:oauth2-token:delete')")
    public CommonResult<Boolean> deleteAccessToken(@RequestParam("accessToken") String accessToken) {
        authService.logout(accessToken, LoginLogTypeEnum.LOGOUT_DELETE.getType());
        return success(true);
    }

}
