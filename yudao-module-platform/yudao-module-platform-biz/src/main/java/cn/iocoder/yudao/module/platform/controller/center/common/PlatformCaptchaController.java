package cn.iocoder.yudao.module.platform.controller.center.common;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.module.platform.controller.center.common.vo.CaptchaImageRespVO;
import cn.iocoder.yudao.module.platform.service.common.PlatformCaptchaService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;

@Api(tags = "平台管理后台 - 验证码")
@RestController
@RequestMapping("/platform/captcha")
public class PlatformCaptchaController {

    @Resource
    private PlatformCaptchaService platformCaptchaService;

    @GetMapping("/get-image")
    @ApiOperation("生成图片验证码")
    public CommonResult<CaptchaImageRespVO> getCaptchaImage() {
        return success(platformCaptchaService.getCaptchaImage());
    }

}
