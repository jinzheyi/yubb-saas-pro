package cn.iocoder.yudao.module.platform.controller.center.socail;

import cn.iocoder.yudao.framework.common.enums.UserTypeEnum;
import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.module.platform.controller.center.socail.vo.SocialUserBindReqVO;
import cn.iocoder.yudao.module.platform.controller.center.socail.vo.SocialUserUnbindReqVO;
import cn.iocoder.yudao.module.platform.convert.social.SocialUserConvert;
import cn.iocoder.yudao.module.platform.service.social.PlatformSocialUserService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;

import static cn.iocoder.yudao.framework.security.core.util.SecurityFrameworkUtils.getLoginUserId;

@Api(tags = "管理后台 - 社交用户")
@RestController
@RequestMapping("/system/social-user")
@Validated
public class SocialUserController {

    @Resource
    private PlatformSocialUserService socialUserService;

    // TODO 这里的getLoginUserId()方法需要增加平台用户，这里是租户的登录用户。UserTypeEnum.ADMIN.getValue()也需要调整
    @PostMapping("/bind")
    @ApiOperation("社交绑定，使用 code 授权码")
    public CommonResult<Boolean> socialBind(@RequestBody @Valid SocialUserBindReqVO reqVO) {
        socialUserService.bindSocialUser(SocialUserConvert.INSTANCE.convert(getLoginUserId(), UserTypeEnum.ADMIN.getValue(), reqVO));
        return CommonResult.success(true);
    }

    // TODO 这里的getLoginUserId()方法需要增加平台用户，这里是租户的登录用户
    @DeleteMapping("/unbind")
    @ApiOperation("取消社交绑定")
    public CommonResult<Boolean> socialUnbind(@RequestBody SocialUserUnbindReqVO reqVO) {
        socialUserService.unbindSocialUser(getLoginUserId(), UserTypeEnum.ADMIN.getValue(), reqVO.getType(), reqVO.getOpenid());
        return CommonResult.success(true);
    }

}
