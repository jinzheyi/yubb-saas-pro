package cn.iocoder.yudao.module.system.service.auth;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.framework.common.util.servlet.ServletUtils.getClientIP;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.AUTH_LOGIN_BAD_CREDENTIALS;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.AUTH_LOGIN_CAPTCHA_CODE_ERROR;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.AUTH_MOBILE_NOT_EXISTS;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.AUTH_TENANT_EXCEPTION;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.AUTH_THIRD_LOGIN_NOT_BIND;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.USER_NOT_EXISTS;

import cn.hutool.core.util.ObjectUtil;
import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import cn.iocoder.yudao.framework.common.enums.UserTypeEnum;
import cn.iocoder.yudao.framework.common.enums.logger.LoginLogTypeEnum;
import cn.iocoder.yudao.framework.common.enums.logger.LoginResultEnum;
import cn.iocoder.yudao.framework.common.enums.oauth2.OAuth2ClientConstants;
import cn.iocoder.yudao.framework.common.enums.sms.SmsSceneEnum;
import cn.iocoder.yudao.framework.common.util.monitor.TracerUtils;
import cn.iocoder.yudao.framework.common.util.servlet.ServletUtils;
import cn.iocoder.yudao.framework.common.util.validation.ValidationUtils;
import cn.iocoder.yudao.framework.tenant.core.context.TenantContextHolder;
import cn.iocoder.yudao.module.system.api.logger.dto.LoginLogCreateReqDTO;
import cn.iocoder.yudao.module.platform.api.sms.SmsCodeApi;
import cn.iocoder.yudao.module.platform.api.social.dto.SocialUserBindReqDTO;
import cn.iocoder.yudao.module.platform.api.social.dto.SocialUserRespDTO;
import cn.iocoder.yudao.module.system.controller.admin.auth.vo.AuthLoginReqVO;
import cn.iocoder.yudao.module.system.controller.admin.auth.vo.AuthLoginRespVO;
import cn.iocoder.yudao.module.system.controller.admin.auth.vo.AuthSmsLoginReqVO;
import cn.iocoder.yudao.module.system.controller.admin.auth.vo.AuthSmsSendReqVO;
import cn.iocoder.yudao.module.system.controller.admin.auth.vo.AuthSocialLoginReqVO;
import cn.iocoder.yudao.module.system.convert.auth.AuthConvert;
import cn.iocoder.yudao.module.system.dal.dataobject.oauth2.OAuth2AccessTokenDO;
import cn.iocoder.yudao.module.system.dal.dataobject.user.AdminUserDO;
import cn.iocoder.yudao.module.system.dal.dataobject.user.SaasUserDO;
import cn.iocoder.yudao.module.system.service.logger.LoginLogService;
import cn.iocoder.yudao.module.system.service.oauth2.OAuth2TokenService;
import cn.iocoder.yudao.module.system.service.social.SocialUserService;
import cn.iocoder.yudao.module.system.service.user.AdminUserService;
import cn.iocoder.yudao.module.system.service.user.SaasUserService;
import com.google.common.annotations.VisibleForTesting;
import com.xingyuv.captcha.model.common.ResponseModel;
import com.xingyuv.captcha.model.vo.CaptchaVO;
import com.xingyuv.captcha.service.CaptchaService;
import java.util.Objects;
import javax.annotation.Resource;
import javax.validation.Validator;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Auth Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class AdminAuthServiceImpl implements AdminAuthService {

    @Resource
    private AdminUserService adminUserService;
    @Resource
    private LoginLogService loginLogService;
    @Resource
    private OAuth2TokenService oauth2TokenService;
    @Resource
    private SocialUserService socialUserService;
    @Resource
    private Validator validator;
    @Resource
    private CaptchaService captchaService;
    @Resource
    private SmsCodeApi smsCodeApi;

    @Resource
    private SaasUserService saasUserService;

    /**
     * 验证码的开关，默认为 true
     */
    @Value("${yudao.captcha.enable}")
    private Boolean captchaEnable;

    @Override
    public AdminUserDO authenticate(String username, String password) {
        final LoginLogTypeEnum logTypeEnum = LoginLogTypeEnum.LOGIN_USERNAME;
        // 校验账号是否存在
        SaasUserDO saasUserDO = saasUserService.getUserByAccount(username);
        if (saasUserDO == null) {
            throw exception(AUTH_LOGIN_BAD_CREDENTIALS);
        }
        if (!saasUserService.isPasswordMatch(password, saasUserDO.getPassword())) {
            throw exception(AUTH_LOGIN_BAD_CREDENTIALS);
        }
        return getAdminUser(saasUserDO, logTypeEnum);
    }

    @Override
    public AuthLoginRespVO login(AuthLoginReqVO reqVO) {
        // 校验验证码
        validateCaptcha(reqVO);

        // 使用账号密码，进行登录
        AdminUserDO user = authenticate(reqVO.getUsername(), reqVO.getPassword());

        // 如果 socialType 非空，说明需要绑定社交用户
        if (reqVO.getSocialType() != null) {
            socialUserService.bindSocialUser(new SocialUserBindReqDTO(user.getId(), getUserType().getValue(),
                    reqVO.getSocialType(), reqVO.getSocialCode(), reqVO.getSocialState()));
        }
        // 创建 Token 令牌，记录登录日志
        return createTokenAfterLoginSuccess(user.getId(), reqVO.getUsername(), LoginLogTypeEnum.LOGIN_USERNAME);
    }

    @Override
    public void sendSmsCode(AuthSmsSendReqVO reqVO) {
        // 登录场景，验证是否存在
        if (saasUserService.getUserByMobile(reqVO.getMobile()) == null) {
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
        SaasUserDO saasUserDO = saasUserService.getUserByMobile(reqVO.getMobile());
        if (saasUserDO == null) {
            throw exception(USER_NOT_EXISTS);
        }
        AdminUserDO adminUser = getAdminUser(saasUserDO, null);
        // 创建 Token 令牌，记录登录日志
        return createTokenAfterLoginSuccess(adminUser.getId(), reqVO.getMobile(), LoginLogTypeEnum.LOGIN_MOBILE);
    }

    private void createLoginLog(Long userId, String username,
                                LoginLogTypeEnum logTypeEnum, LoginResultEnum loginResult) {
        // 插入登录日志
        LoginLogCreateReqDTO reqDTO = new LoginLogCreateReqDTO();
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
        if (userId != null && Objects.equals(LoginResultEnum.SUCCESS.getResult(), loginResult.getResult())) {
            adminUserService.updateUserLogin(userId, ServletUtils.getClientIP());
        }
    }

    @Override
    public AuthLoginRespVO socialLogin(AuthSocialLoginReqVO reqVO) {
        // 使用 code 授权码，进行登录。然后，获得到绑定的用户编号
        SocialUserRespDTO socialUser = socialUserService.getSocialUserByCode(UserTypeEnum.ADMIN.getValue(), reqVO.getType(),
                reqVO.getCode(), reqVO.getState());
        if (socialUser == null || socialUser.getSaasUserId() == null) {
            throw exception(AUTH_THIRD_LOGIN_NOT_BIND);
        }

        // 获得用户
        SaasUserDO saasUserDO = saasUserService.getUser(socialUser.getSaasUserId());
        if (saasUserDO == null) {
            throw exception(USER_NOT_EXISTS);
        }
        AdminUserDO adminUser = getAdminUser(saasUserDO, null);
        // 创建 Token 令牌，记录登录日志
        return createTokenAfterLoginSuccess(adminUser.getId(), saasUserDO.getAccount(), LoginLogTypeEnum.LOGIN_SOCIAL);
    }

    @VisibleForTesting
    void validateCaptcha(AuthLoginReqVO reqVO) {
        // 如果验证码关闭，则不进行校验
        if (!captchaEnable) {
            return;
        }
        // 校验验证码
        ValidationUtils.validate(validator, reqVO, AuthLoginReqVO.CodeEnableGroup.class);
        CaptchaVO captchaVO = new CaptchaVO();
        captchaVO.setCaptchaVerification(reqVO.getCaptchaVerification());
        ResponseModel response = captchaService.verification(captchaVO);
        // 验证不通过
        if (!response.isSuccess()) {
            // 创建登录失败日志（验证码不正确)
            createLoginLog(null, reqVO.getUsername(), LoginLogTypeEnum.LOGIN_USERNAME, LoginResultEnum.CAPTCHA_CODE_ERROR);
            throw exception(AUTH_LOGIN_CAPTCHA_CODE_ERROR, response.getRepMsg());
        }
    }

    private AuthLoginRespVO createTokenAfterLoginSuccess(Long userId, String username, LoginLogTypeEnum logType) {
        // 插入登陆日志
        createLoginLog(userId, username, logType, LoginResultEnum.SUCCESS);
        // 创建访问令牌
        OAuth2AccessTokenDO accessTokenDO = oauth2TokenService.createAccessToken(userId, getUserType().getValue(),
                OAuth2ClientConstants.CLIENT_ID_TENANT, null);
        // 构建返回结果
        return AuthConvert.INSTANCE.convert(accessTokenDO);
    }

    @Override
    public AuthLoginRespVO refreshToken(String refreshToken) {
        OAuth2AccessTokenDO accessTokenDO = oauth2TokenService.refreshAccessToken(refreshToken, OAuth2ClientConstants.CLIENT_ID_TENANT);
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
        if (ObjectUtil.equal(getUserType().getValue(), userType)) {
            reqDTO.setUsername(getUsername(userId));
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
        AdminUserDO user = adminUserService.getUser(userId);
        SaasUserDO saasUserDO = saasUserService.getUser(user.getSaasUserId());
        return saasUserDO != null ? saasUserDO.getAccount() : null;
    }

    private UserTypeEnum getUserType() {
        return UserTypeEnum.ADMIN;
    }

    /**
     * 获取租户用户信心，并更新SaaS用户信息
     * @param saasUserDO saas用户
     * @return 对应租户用户
     */
    private AdminUserDO getAdminUser(SaasUserDO saasUserDO, LoginLogTypeEnum logTypeEnum) {
        //查询当前用户默认的租户id
        AdminUserDO adminUser = getAdminUser(saasUserDO, saasUserDO.getDefaultTenant(), logTypeEnum);
        //如果默认的禁用了，则只能取它自己的所属租户了
        if (Objects.isNull(adminUser)) {
            //这里查询自己的租户不可能为空，如果为空了那肯定是数据的问题
            adminUser = getAdminUser(saasUserDO, saasUserDO.getMyTenant(), logTypeEnum);
        }
        //更新SaaS用户信息
        setSaasUserInfo(saasUserDO, adminUser);
        return adminUser;
    }

    /**
     * 根据SaaS用户查询对应租户的用户信息
     * @param saasUserDO SaaS用户
     * @param tenantId 租户id
     * @param logTypeEnum 登录类型
     * @return 对应租户的用户信息
     */
    private AdminUserDO getAdminUser(SaasUserDO saasUserDO, Long tenantId, LoginLogTypeEnum logTypeEnum) {
        Long oldTenantId = TenantContextHolder.getTenantId();
        Boolean oldIgnore = TenantContextHolder.isIgnore();
        TenantContextHolder.setTenantId(tenantId);
        TenantContextHolder.setIgnore(false);
        AdminUserDO adminUserDO = adminUserService.getUserBySaasUserId(saasUserDO.getId());
        // 检查是否被删除或校验是否禁用
        if (Objects.isNull(adminUserDO) || CommonStatusEnum.isDisable(adminUserDO.getStatus())) {
            if (Objects.nonNull(adminUserDO) && Objects.nonNull(logTypeEnum)) {
                createLoginLog(adminUserDO.getId(), saasUserDO.getAccount(), logTypeEnum, LoginResultEnum.USER_DISABLED);
            }
            TenantContextHolder.setTenantId(oldTenantId);
            TenantContextHolder.setIgnore(oldIgnore);
            return null;
        }
        return adminUserDO;
    }

    /**
     * 更新SaaS用户信息
     * @param saasUserDO SaaS用户
     * @param adminUser SaaS用户对应租户的用户信息
     */
    private void setSaasUserInfo(SaasUserDO saasUserDO, AdminUserDO adminUser) {
        //设置登录的租户id
        if (Objects.isNull(adminUser)) {
            throw exception(AUTH_TENANT_EXCEPTION);
        }
        //设置租户id
        TenantContextHolder.setTenantId(adminUser.getTenantId());
        //设置默认租户
        saasUserService.updateUserDefaultTenant(saasUserDO.getId(), adminUser.getTenantId());
    }

}
