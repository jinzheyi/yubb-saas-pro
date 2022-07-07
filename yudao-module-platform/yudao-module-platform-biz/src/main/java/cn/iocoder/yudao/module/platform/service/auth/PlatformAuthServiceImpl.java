package cn.iocoder.yudao.module.platform.service.auth;

import cn.hutool.core.util.StrUtil;
import cn.iocoder.yudao.framework.common.util.validation.ValidationUtils;
import cn.iocoder.yudao.module.platform.controller.center.auth.vo.AuthLoginReqVO;
import cn.iocoder.yudao.module.platform.controller.center.auth.vo.AuthLoginRespVO;
import cn.iocoder.yudao.module.platform.enums.logger.PlatformLoginLogTypeEnum;
import cn.iocoder.yudao.module.platform.service.common.PlatformCaptchaService;
import cn.iocoder.yudao.module.system.enums.logger.LoginLogTypeEnum;
import cn.iocoder.yudao.module.system.enums.logger.LoginResultEnum;
import com.google.common.annotations.VisibleForTesting;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import javax.validation.Validator;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.AUTH_LOGIN_CAPTCHA_CODE_ERROR;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.AUTH_LOGIN_CAPTCHA_NOT_FOUND;

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
    private PlatformCaptchaService platformCaptchaService;

    @Resource
    private Validator validator;

    @Override
    public AuthLoginRespVO login(AuthLoginReqVO reqVO) {
        // 判断验证码是否正确
//        verifyCaptcha(reqVO);

//        // 使用账号密码，进行登录
//        AdminUserDO user = authenticate(reqVO.getUsername(), reqVO.getPassword());
//
//        // 创建 Token 令牌，记录登录日志
//        return createTokenAfterLoginSuccess(user.getId(), reqVO.getUsername(), LoginLogTypeEnum.LOGIN_USERNAME);
        return null;
    }

//    @VisibleForTesting
//    void verifyCaptcha(AuthLoginReqVO reqVO) {
//        // 如果验证码关闭，则不进行校验
//        if (!platformCaptchaService.isCaptchaEnable()) {
//            return;
//        }
//        // 校验验证码传参
//        ValidationUtils.validate(validator, reqVO, AuthLoginReqVO.CodeEnableGroup.class);
//        final PlatformLoginLogTypeEnum logTypeEnum = PlatformLoginLogTypeEnum.LOGIN_USERNAME;
//        // 验证码不存在
//        String code = platformCaptchaService.getCaptchaCode(reqVO.getUuid());
//        if (StrUtil.isBlankOrUndefined(code)) {
//            // 创建登录失败日志（验证码不存在）
//            createLoginLog(null, reqVO.getUsername(), logTypeEnum, LoginResultEnum.CAPTCHA_NOT_FOUND);
//            throw exception(AUTH_LOGIN_CAPTCHA_NOT_FOUND);
//        }
//        // 验证码不正确
//        if (!code.equals(reqVO.getCode())) {
//            // 创建登录失败日志（验证码不正确)
//            createLoginLog(null, reqVO.getUsername(), logTypeEnum, LoginResultEnum.CAPTCHA_CODE_ERROR);
//            throw exception(AUTH_LOGIN_CAPTCHA_CODE_ERROR);
//        }
//        // 正确，所以要删除下验证码
//        captchaService.deleteCaptchaCode(reqVO.getUuid());
//    }

}
