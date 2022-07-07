package cn.iocoder.yudao.module.platform.controller.center.auth;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.operatelog.core.annotations.OperateLog;
import cn.iocoder.yudao.module.platform.controller.center.auth.vo.AuthLoginReqVO;
import cn.iocoder.yudao.module.platform.controller.center.auth.vo.AuthLoginRespVO;
import cn.iocoder.yudao.module.platform.service.auth.PlatformAuthService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import javax.validation.Valid;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;

@Api(tags = "平台管理后台 - 认证")
@RestController
@RequestMapping("/platform/auth")
@Validated
@Slf4j
public class AuthController {

    @Resource
    private PlatformAuthService platformAuthService;

    @PostMapping("/login")
    @ApiOperation("使用账号密码登录")
    @OperateLog(enable = false)
    public CommonResult<AuthLoginRespVO> login(@RequestBody @Valid AuthLoginReqVO reqVO) {
        return success(platformAuthService.login(reqVO));
    }

}
