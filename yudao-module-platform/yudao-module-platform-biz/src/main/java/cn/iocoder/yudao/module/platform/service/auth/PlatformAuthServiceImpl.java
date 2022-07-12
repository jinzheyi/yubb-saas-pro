package cn.iocoder.yudao.module.platform.service.auth;

import cn.hutool.core.util.StrUtil;
import cn.iocoder.yudao.framework.common.enums.UserTypeEnum;
import cn.iocoder.yudao.framework.common.util.monitor.TracerUtils;
import cn.iocoder.yudao.framework.common.util.servlet.ServletUtils;
import cn.iocoder.yudao.framework.common.util.validation.ValidationUtils;
import cn.iocoder.yudao.module.platform.api.logger.dto.PlatformLoginLogCreateReqDTO;
import cn.iocoder.yudao.module.platform.controller.center.auth.vo.AuthLoginReqVO;
import cn.iocoder.yudao.module.platform.controller.center.auth.vo.AuthLoginRespVO;
import cn.iocoder.yudao.module.platform.enums.logger.PlatformLoginLogTypeEnum;
import cn.iocoder.yudao.module.platform.enums.logger.PlatformLoginResultEnum;
import cn.iocoder.yudao.module.platform.service.common.PlatformCaptchaService;
import cn.iocoder.yudao.module.platform.service.logger.PlatformLoginLogService;
import cn.iocoder.yudao.module.platform.service.user.PlatformUserService;
import com.google.common.annotations.VisibleForTesting;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import javax.validation.Validator;

import java.util.Objects;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.module.platform.enums.PlatformErrorCodeConstants.*;

/**
 * Auth Service 实现类
 *
 * @author 朱述勇
 * @since 2022/7/6 2:17 PM
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 */
@Slf4j
@Service
public class PlatformAuthServiceImpl implements PlatformAuthService {

    @Resource
    private PlatformUserService userService;
    @Resource
    private PlatformCaptchaService platformCaptchaService;
    @Resource
    private PlatformLoginLogService loginLogService;
    @Resource
    private Validator validator;

    @Override
    public AuthLoginRespVO login(AuthLoginReqVO reqVO) {
        // 判断验证码是否正确
        verifyCaptcha(reqVO);

//        // 使用账号密码，进行登录
//        AdminUserDO user = authenticate(reqVO.getUsername(), reqVO.getPassword());
//
//        // 创建 Token 令牌，记录登录日志
//        return createTokenAfterLoginSuccess(user.getId(), reqVO.getUsername(), LoginLogTypeEnum.LOGIN_USERNAME);
        return null;
    }

    @VisibleForTesting
    void verifyCaptcha(AuthLoginReqVO reqVO) {
        // 如果验证码关闭，则不进行校验
        if (!platformCaptchaService.isCaptchaEnable()) {
            return;
        }
        // 校验验证码传参
        ValidationUtils.validate(validator, reqVO, AuthLoginReqVO.CodeEnableGroup.class);
        final PlatformLoginLogTypeEnum logTypeEnum = PlatformLoginLogTypeEnum.LOGIN_USERNAME;
        // 验证码不存在
        String code = platformCaptchaService.getCaptchaCode(reqVO.getUuid());
        if (StrUtil.isBlankOrUndefined(code)) {
            // 创建登录失败日志（验证码不存在）
            createLoginLog(null, reqVO.getUsername(), logTypeEnum, PlatformLoginResultEnum.CAPTCHA_NOT_FOUND);
            throw exception(AUTH_LOGIN_CAPTCHA_NOT_FOUND);
        }
        // 验证码不正确
        if (!code.equals(reqVO.getCode())) {
            // 创建登录失败日志（验证码不正确)
            createLoginLog(null, reqVO.getUsername(), logTypeEnum, PlatformLoginResultEnum.CAPTCHA_CODE_ERROR);
            throw exception(AUTH_LOGIN_CAPTCHA_CODE_ERROR);
        }
        // 正确，所以要删除下验证码
        platformCaptchaService.deleteCaptchaCode(reqVO.getUuid());
    }

    private void createLoginLog(Long userId, String username,
                                PlatformLoginLogTypeEnum logTypeEnum, PlatformLoginResultEnum loginResult) {
        // 插入登录日志
        PlatformLoginLogCreateReqDTO reqDTO = new PlatformLoginLogCreateReqDTO();
        reqDTO.setLogType(logTypeEnum.getType());
        reqDTO.setTraceId(TracerUtils.getTraceId());
        reqDTO.setUserId(userId);
        reqDTO.setUserType(getUserType().getValue());
        reqDTO.setUsername(username);
        reqDTO.setUserAgent(ServletUtils.getUserAgent());
        reqDTO.setUserIp(ServletUtils.getClientIP());
        reqDTO.setResult(loginResult.getResult());
        loginLogService.createLoginLog(reqDTO);
        // 更新最后登录时间
        if (userId != null && Objects.equals(PlatformLoginResultEnum.SUCCESS.getResult(), loginResult.getResult())) {
            userService.updateUserLogin(userId, ServletUtils.getClientIP());
        }
    }

    private UserTypeEnum getUserType() {
        return UserTypeEnum.PLATFORM_ADMIN;
    }

}
