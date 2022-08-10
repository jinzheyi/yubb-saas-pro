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
@RequestMapping("/center/social-user")
@Validated
public class CenterSocialUserController {

    @Resource
    private PlatformSocialUserService platformSocialUserService;

    @PostMapping("/bind")
    @ApiOperation("社交绑定，使用 code 授权码")
    public CommonResult<Boolean> socialBind(@RequestBody @Valid SocialUserBindReqVO reqVO) {
        platformSocialUserService.bindSocialUser(SocialUserConvert.INSTANCE.convert(getLoginUserId(), UserTypeEnum.CENTER.getValue(), reqVO));
        return CommonResult.success(true);
    }

    @DeleteMapping("/unbind")
    @ApiOperation("取消社交绑定")
    public CommonResult<Boolean> socialUnbind(@RequestBody SocialUserUnbindReqVO reqVO) {
        platformSocialUserService.unbindSocialUser(getLoginUserId(), UserTypeEnum.CENTER.getValue(), reqVO.getType(), reqVO.getOpenid());
        return CommonResult.success(true);
    }

}
