package com.shengyu.module.platform.controller.platform.oauth2;

import static com.shengyu.framework.common.pojo.CommonResult.success;

import com.shengyu.framework.common.enums.logger.LoginLogTypeEnum;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.platform.controller.platform.oauth2.vo.token.OAuth2AccessTokenPageReqVO;
import com.shengyu.module.platform.controller.platform.oauth2.vo.token.OAuth2AccessTokenRespVO;
import com.shengyu.module.platform.dal.dataobject.oauth2.PlatformOAuth2AccessTokenDO;
import com.shengyu.module.platform.service.auth.PlatformAuthService;
import com.shengyu.module.platform.service.oauth2.PlatformOAuth2TokenService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.annotation.Resource;
import javax.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "管理后台 - OAuth2.0 令牌")
@RestController
@RequestMapping("/system/oauth2-token")
public class PlatformOAuth2TokenController {

    @Resource
    private PlatformOAuth2TokenService oauth2TokenServicePlatform;
    @Resource
    private PlatformAuthService authService;

    @GetMapping("/page")
    @Operation(summary = "获得访问令牌分页", description = "只返回有效期内的")
    @PreAuthorize("@ps.hasPermission('system:oauth2-token:page')")
    public CommonResult<PageResult<OAuth2AccessTokenRespVO>> getAccessTokenPage(@Valid OAuth2AccessTokenPageReqVO reqVO) {
        PageResult<PlatformOAuth2AccessTokenDO> pageResult = oauth2TokenServicePlatform.getAccessTokenPage(reqVO);
        return success(BeanUtils.toBean(pageResult, OAuth2AccessTokenRespVO.class));
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除访问令牌")
    @Parameter(name = "accessToken", description = "访问令牌", required = true, example = "tudou")
    @PreAuthorize("@ps.hasPermission('system:oauth2-token:delete')")
    public CommonResult<Boolean> deleteAccessToken(@RequestParam("accessToken") String accessToken) {
        authService.logout(accessToken, LoginLogTypeEnum.LOGOUT_DELETE.getType());
        return success(true);
    }

}
