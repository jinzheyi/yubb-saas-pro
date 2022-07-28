package cn.iocoder.yudao.module.platform.service.auth;

import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import cn.iocoder.yudao.framework.common.enums.UserTypeEnum;
import cn.iocoder.yudao.framework.common.util.monitor.TracerUtils;
import cn.iocoder.yudao.framework.common.util.servlet.ServletUtils;
import cn.iocoder.yudao.framework.common.util.validation.ValidationUtils;
import cn.iocoder.yudao.module.platform.api.logger.dto.PlatformLoginLogCreateReqDTO;
import cn.iocoder.yudao.module.platform.controller.center.auth.vo.AuthLoginReqVO;
import cn.iocoder.yudao.module.platform.controller.center.auth.vo.AuthLoginRespVO;
import cn.iocoder.yudao.module.platform.controller.center.auth.vo.AuthSmsSendReqVO;
import cn.iocoder.yudao.module.platform.convert.auth.AuthConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2AccessTokenDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.user.PlatformUserDO;
import cn.iocoder.yudao.module.platform.enums.logger.PlatformLoginLogTypeEnum;
import cn.iocoder.yudao.module.platform.enums.logger.PlatformLoginResultEnum;
import cn.iocoder.yudao.module.platform.enums.oauth2.PlatformOAuth2ClientConstants;
import cn.iocoder.yudao.module.platform.service.common.PlatformCaptchaService;
import cn.iocoder.yudao.module.platform.service.logger.PlatformLoginLogService;
import cn.iocoder.yudao.module.platform.service.oauth2.PlatformOAuth2TokenService;
import cn.iocoder.yudao.module.platform.service.user.PlatformUserService;
import cn.iocoder.yudao.module.system.api.logger.dto.LoginLogCreateReqDTO;
import cn.iocoder.yudao.module.system.enums.logger.LoginLogTypeEnum;
import cn.iocoder.yudao.module.system.enums.logger.LoginResultEnum;
import cn.iocoder.yudao.module.system.enums.oauth2.OAuth2ClientConstants;
import cn.iocoder.yudao.module.system.enums.sms.SmsSceneEnum;
import com.google.common.annotations.VisibleForTesting;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import javax.validation.Validator;
import java.util.Objects;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.framework.common.util.servlet.ServletUtils.getClientIP;
import static cn.iocoder.yudao.module.platform.enums.PlatformErrorCodeConstants.*;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.AUTH_MOBILE_NOT_EXISTS;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.AUTH_THIRD_LOGIN_NOT_BIND;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.USER_NOT_EXISTS;

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
    private PlatformUserService platformUserService;
    @Resource
    private PlatformCaptchaService platformCaptchaService;
    @Resource
    private PlatformLoginLogService platformLoginLogService;
    @Resource
    private PlatformOAuth2TokenService platformOAuth2TokenService;
    @Resource
    private Validator validator;

    @Override
    public PlatformUserDO authenticate(String username, String password) {
        final PlatformLoginLogTypeEnum logTypeEnum = PlatformLoginLogTypeEnum.LOGIN_USERNAME;
        // 校验账号是否存在
        PlatformUserDO user = platformUserService.getUserByUsername(username);
        if (user == null) {
            createLoginLog(null, username, logTypeEnum, PlatformLoginResultEnum.BAD_CREDENTIALS);
            throw exception(AUTH_LOGIN_BAD_CREDENTIALS);
        }
        if (!platformUserService.isPasswordMatch(password, user.getPassword())) {
            createLoginLog(user.getId(), username, logTypeEnum, PlatformLoginResultEnum.BAD_CREDENTIALS);
            throw exception(AUTH_LOGIN_BAD_CREDENTIALS);
        }
        // 校验是否禁用
        if (ObjectUtil.notEqual(user.getStatus(), CommonStatusEnum.ENABLE.getStatus())) {
            createLoginLog(user.getId(), username, logTypeEnum, PlatformLoginResultEnum.USER_DISABLED);
            throw exception(AUTH_LOGIN_USER_DISABLED);
        }
        return user;
    }

    @Override
    public AuthLoginRespVO login(AuthLoginReqVO reqVO) {
        // 判断验证码是否正确
        verifyCaptcha(reqVO);

        // 使用账号密码，进行登录
        PlatformUserDO user = authenticate(reqVO.getUsername(), reqVO.getPassword());

        // 创建 Token 令牌，记录登录日志
        return createTokenAfterLoginSuccess(user.getId(), reqVO.getUsername(), PlatformLoginLogTypeEnum.LOGIN_USERNAME);
    }

    @Override
    public void sendSmsCode(AuthSmsSendReqVO reqVO) {
        // 登录场景，验证是否存在
        if (platformUserService.getUserByMobile(reqVO.getMobile()) == null) {
            throw exception(AUTH_MOBILE_NOT_EXISTS);
        }
        // 发送验证码
        smsCodeApi.sendSmsCode(AuthConvert.INSTANCE.convert(reqVO).setCreateIp(getClientIP()));
    }

    @Override
    public AuthLoginRespVO smsLogin(AuthSmsLoginReqVO reqVO) {
        // 校验验证码
        smsCodeApi.useSmsCode(AuthConvert.INSTANCE.convert(reqVO, SmsSceneEnum.ADMIN_MEMBER_LOGIN.getScene(), getClientIP()));

        // 获得用户信息
        AdminUserDO user = userService.getUserByMobile(reqVO.getMobile());
        if (user == null) {
            throw exception(USER_NOT_EXISTS);
        }

        // 缓存登陆用户到 Redis 中，返回 sessionId 编号
        return createTokenAfterLoginSuccess(user.getId(), reqVO.getMobile(), LoginLogTypeEnum.LOGIN_MOBILE);
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
        platformLoginLogService.createLoginLog(reqDTO);
        // 更新最后登录时间
        if (userId != null && Objects.equals(PlatformLoginResultEnum.SUCCESS.getResult(), loginResult.getResult())) {
            platformUserService.updateUserLogin(userId, ServletUtils.getClientIP());
        }
    }

    @Override
    public AuthLoginRespVO socialQuickLogin(AuthSocialQuickLoginReqVO reqVO) {
        // 使用 code 授权码，进行登录。然后，获得到绑定的用户编号
        Long userId = socialUserService.getBindUserId(UserTypeEnum.ADMIN.getValue(), reqVO.getType(),
                reqVO.getCode(), reqVO.getState());
        if (userId == null) {
            throw exception(AUTH_THIRD_LOGIN_NOT_BIND);
        }

        // 获得用户
        AdminUserDO user = userService.getUser(userId);
        if (user == null) {
            throw exception(USER_NOT_EXISTS);
        }

        // 创建 Token 令牌，记录登录日志
        return createTokenAfterLoginSuccess(user.getId(), user.getUsername(), LoginLogTypeEnum.LOGIN_SOCIAL);
    }

    @Override
    public AuthLoginRespVO socialBindLogin(AuthSocialBindLoginReqVO reqVO) {
        // 使用账号密码，进行登录。
        AdminUserDO user = authenticate(reqVO.getUsername(), reqVO.getPassword());

        // 绑定社交用户
        socialUserService.bindSocialUser(AuthConvert.INSTANCE.convert(user.getId(), getUserType().getValue(), reqVO));

        // 创建 Token 令牌，记录登录日志
        return createTokenAfterLoginSuccess(user.getId(), reqVO.getUsername(), LoginLogTypeEnum.LOGIN_SOCIAL);
    }

    @Override
    public AuthLoginRespVO refreshToken(String refreshToken) {
        OAuth2AccessTokenDO accessTokenDO = oauth2TokenService.refreshAccessToken(refreshToken, OAuth2ClientConstants.CLIENT_ID_DEFAULT);
        return AuthConvert.INSTANCE.convert(accessTokenDO);
    }

    private AuthLoginRespVO createTokenAfterLoginSuccess(Long userId, String username, PlatformLoginLogTypeEnum logType) {
        // 插入登陆日志
        createLoginLog(userId, username, logType, PlatformLoginResultEnum.SUCCESS);
        // 创建访问令牌
        PlatformOAuth2AccessTokenDO accessTokenDO = platformOAuth2TokenService.createAccessToken(userId, getUserType().getValue(),
                PlatformOAuth2ClientConstants.CLIENT_ID_DEFAULT, null);
        // 构建返回结果
        return AuthConvert.INSTANCE.convert(accessTokenDO);
    }

    @Override
    public void logout(String token, Integer logType) {
        // 删除访问令牌
        OAuth2AccessTokenDO accessTokenDO = oauth2TokenService.removeAccessToken(token);
        if (accessTokenDO == null) {
            return;
        }
        // 删除成功，则记录登出日志
        createLogoutLog(accessTokenDO.getUserId(), accessTokenDO.getUserType(), logType);
    }

    private void createLogoutLog(Long userId, Integer userType, Integer logType) {
        LoginLogCreateReqDTO reqDTO = new LoginLogCreateReqDTO();
        reqDTO.setLogType(logType);
        reqDTO.setTraceId(TracerUtils.getTraceId());
        reqDTO.setUserId(userId);
        reqDTO.setUserType(userType);
        if (ObjectUtil.notEqual(getUserType(), userType)) {
            reqDTO.setUsername(getUsername(userId));
        } else {
            reqDTO.setUsername(memberService.getMemberUserMobile(userId));
        }
        reqDTO.setUserAgent(ServletUtils.getUserAgent());
        reqDTO.setUserIp(ServletUtils.getClientIP());
        reqDTO.setResult(LoginResultEnum.SUCCESS.getResult());
        loginLogService.createLoginLog(reqDTO);
    }

    private String getUsername(Long userId) {
        if (userId == null) {
            return null;
        }
        AdminUserDO user = userService.getUser(userId);
        return user != null ? user.getUsername() : null;
    }

    private UserTypeEnum getUserType() {
        return UserTypeEnum.PLATFORM_ADMIN;
    }

}
