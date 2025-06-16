package com.shengyu.module.system.service.auth;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.framework.common.util.servlet.ServletUtils.getClientIP;
import static com.shengyu.framework.datapermission.core.util.DataPermissionUtils.getDisableDataPermissionDisable;
import static com.shengyu.framework.security.core.util.SecurityFrameworkUtils.getLoginUserId;
import static com.shengyu.module.system.enums.ErrorCodeConstants.*;
import static com.shengyu.module.system.enums.ErrorCodeConstants.TENANT_EXPIRE;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import com.google.common.annotations.VisibleForTesting;
import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.enums.UserTypeEnum;
import com.shengyu.framework.common.enums.logger.LoginLogTypeEnum;
import com.shengyu.framework.common.enums.logger.LoginResultEnum;
import com.shengyu.framework.common.enums.oauth2.OAuth2ClientConstants;
import com.shengyu.framework.common.enums.sms.SmsSceneEnum;
import com.shengyu.framework.common.util.date.DateUtils;
import com.shengyu.framework.common.util.monitor.TracerUtils;
import com.shengyu.framework.common.util.servlet.ServletUtils;
import com.shengyu.framework.common.util.validation.ValidationUtils;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import com.shengyu.framework.datapermission.core.aop.DataPermissionContextHolder;
import com.shengyu.framework.datapermission.core.util.DataPermissionUtils;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.framework.tenant.core.util.TenantUtils;
import com.shengyu.module.platform.api.sms.SmsCodeApi;
import com.shengyu.module.platform.api.social.TenantSocialUserApi;
import com.shengyu.module.platform.api.social.dto.SocialUserBindReqDTO;
import com.shengyu.module.platform.api.social.dto.SocialUserRespDTO;
import com.shengyu.module.platform.api.tenant.dto.tenant.TenantRespDTO;
import com.shengyu.module.system.api.logger.dto.LoginLogCreateReqDTO;
import com.shengyu.module.system.controller.admin.auth.vo.AuthLoginReqVO;
import com.shengyu.module.system.controller.admin.auth.vo.AuthLoginRespVO;
import com.shengyu.module.system.controller.admin.auth.vo.AuthSmsLoginReqVO;
import com.shengyu.module.system.controller.admin.auth.vo.AuthSmsSendReqVO;
import com.shengyu.module.system.controller.admin.auth.vo.AuthSocialLoginReqVO;
import com.shengyu.module.system.controller.admin.auth.vo.ToDeptReqVO;
import com.shengyu.module.system.controller.admin.auth.vo.ToTenantReqVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.convert.auth.AuthConvert;
import com.shengyu.module.system.dal.dataobject.dept.DeptDO;
import com.shengyu.module.system.dal.dataobject.oauth2.OAuth2AccessTokenDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.dataobject.user.SaasUserDO;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.system.service.dept.DeptService;
import com.shengyu.module.system.service.logger.LoginLogService;
import com.shengyu.module.system.service.oauth2.OAuth2TokenService;
import com.shengyu.module.system.service.tenant.TenantService;
import com.shengyu.module.system.service.user.AdminUserService;
import com.shengyu.module.system.service.user.SaasUserService;
import com.xingyuv.captcha.model.common.ResponseModel;
import com.xingyuv.captcha.model.vo.CaptchaVO;
import com.xingyuv.captcha.service.CaptchaService;

import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicReference;
import java.util.stream.Collectors;
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
    private AdminUserMapper userMapper;
    @Resource
    private LoginLogService loginLogService;
    @Resource
    private OAuth2TokenService oauth2TokenService;
    @Resource
    private TenantSocialUserApi socialUserService;
    @Resource
    private Validator validator;
    @Resource
    private CaptchaService captchaService;
    @Resource
    private SmsCodeApi smsCodeApi;

    @Resource
    private SaasUserService saasUserService;

    @Resource
    private TenantService tenantService;

    @Resource
    private DeptService deptService;

    /**
     * 验证码的开关，默认为 true
     */
    @Value("${shengyu.captcha.enable}")
    private Boolean captchaEnable;

    @Override
    public AdminUserDO authenticate(String username, String password) {
        final LoginLogTypeEnum logTypeEnum = LoginLogTypeEnum.LOGIN_USERNAME;
        // 校验账号是否存在
        SaasUserDO saasUserDO = saasUserService.getUserByUsername(username);
        if (saasUserDO == null) {
            throw exception(AUTH_LOGIN_BAD_CREDENTIALS);
        }
        if (!saasUserService.isPasswordMatch(password, saasUserDO.getPassword())) {
            throw exception(AUTH_LOGIN_BAD_CREDENTIALS);
        }
        return getLoginAdminUser(saasUserDO, logTypeEnum);
    }

    @Override
    public AuthLoginRespVO login(AuthLoginReqVO reqVO) {
        // 校验验证码
        validateCaptcha(reqVO);

        // 使用账号密码，进行登录
        AdminUserDO user = authenticate(reqVO.getUsername(), reqVO.getPassword());

        // 如果 socialType 非空，说明需要绑定社交用户
        if (reqVO.getSocialType() != null) {
            SaasUserDO saasUserDO = saasUserService.getUser(user.getSaasUserId());
            //三方平台绑定用户需要操作的是SaaS用户，因为不可能每个租户都要进行重复的绑定
            socialUserService.bindSocialUser(new SocialUserBindReqDTO(saasUserDO.getId(), getUserType().getValue(),
                    reqVO.getSocialType(), reqVO.getSocialCode(), reqVO.getSocialState()));
        }
        // 创建 Token 令牌需要基于租户用户，因为每个租户的登录逻辑是跟随租户进行的，记录登录日志
        return createTokenAfterLoginSuccess(user, reqVO.getUsername(), LoginLogTypeEnum.LOGIN_USERNAME);
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
        AdminUserDO adminUser = getLoginAdminUser(saasUserDO, null);
        // 创建 Token 令牌，记录登录日志
        return createTokenAfterLoginSuccess(adminUser, reqVO.getMobile(), LoginLogTypeEnum.LOGIN_MOBILE);
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
        reqDTO.setUserIp(getClientIP());
        reqDTO.setResult(loginResult.getResult());
        loginLogService.createLoginLog(reqDTO);
        // 更新最后登录时间
        if (userId != null && Objects.equals(LoginResultEnum.SUCCESS.getResult(), loginResult.getResult())) {
            adminUserService.updateUserLogin(userId, getClientIP());
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
        AdminUserDO adminUser = getLoginAdminUser(saasUserDO, null);
        // 创建 Token 令牌，记录登录日志
        return createTokenAfterLoginSuccess(adminUser, saasUserDO.getUsername(), LoginLogTypeEnum.LOGIN_SOCIAL);
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

    private AuthLoginRespVO createTokenAfterLoginSuccess(AdminUserDO user, String username, LoginLogTypeEnum logType) {
        // 插入登陆日志
        createLoginLog(user.getId(), username, logType, LoginResultEnum.SUCCESS);
        // 创建访问令牌
        OAuth2AccessTokenDO accessTokenDO = oauth2TokenService.createAccessToken(user.getId(), getUserType().getValue(),
                OAuth2ClientConstants.CLIENT_ID_TENANT, null);
        // 构建返回结果
        AuthLoginRespVO loginRespVO = AuthConvert.INSTANCE.convert(accessTokenDO);
        loginRespVO.setDeptId(user.getDeptId());
        return loginRespVO;
    }

    @Override
    public AuthLoginRespVO refreshToken(String refreshToken) {
        OAuth2AccessTokenDO accessTokenDO = oauth2TokenService.refreshAccessToken(refreshToken, OAuth2ClientConstants.CLIENT_ID_TENANT);
        return AuthConvert.INSTANCE.convert(accessTokenDO);
    }

    @Override
    public AuthLoginRespVO toTenant(ToTenantReqVO reqVO, String token) {
        // 关闭数据权限，避免因为没有数据权限，查询不到数据
        DataPermission dataPermission = getDisableDataPermissionDisable();
        DataPermissionContextHolder.add(dataPermission);
        try {
            TenantRespDTO tenantRespDTO = Optional.ofNullable(tenantService.getTenantById(reqVO.getId()))
                .orElseThrow(() -> exception(TENANT_NOT_EXISTS));
            if (tenantRespDTO.getStatus().equals(CommonStatusEnum.DISABLE.getStatus())) {
                throw exception(TENANT_DISABLE, tenantRespDTO.getName());
            }
            if (DateUtils.isExpired(tenantRespDTO.getExpireTime())) {
                throw exception(TENANT_EXPIRE, tenantRespDTO.getName());
            }
            UserRespVO userRespVO = Optional.ofNullable(adminUserService.getUser(getLoginUserId()))
                .orElseThrow(() -> exception(AUTH_TOKEN_EXPIRED));
            SaasUserDO saasUserDO = saasUserService.getUser(userRespVO.getSaasUserId());
            //切换的目标租户是否用户合规
            AdminUserDO adminUser = getToTenantAdminUser(saasUserDO, tenantRespDTO.getId(), null);
            if (adminUser == null) {
                throw exception(AUTH_TO_TENANT_EXCEPTION);
            }
            //清除原來的登录token
            if (StrUtil.isNotBlank(token)) {
                logout(token, LoginLogTypeEnum.LOGOUT_TO_TENANT.getType());
            }
            //更新SaaS用户信息
            setSaasUserInfo(saasUserDO, adminUser);
            // 创建 Token 令牌需要基于租户用户，因为每个租户的登录逻辑是跟随租户进行的，记录登录日志
            return createTokenAfterLoginSuccess(adminUser, saasUserDO.getUsername(), LoginLogTypeEnum.LOGIN_USERNAME);
        } finally {
            DataPermissionContextHolder.remove();
        }
    }

    @Override
    public ToDeptReqVO toDept(ToDeptReqVO reqVO) {
        // 关闭数据权限，避免因为没有数据权限，查询不到数据
        DataPermission dataPermission = getDisableDataPermissionDisable();
        DataPermissionContextHolder.add(dataPermission);
        try {
            DeptDO deptDO = Optional.ofNullable(deptService.getDept(reqVO.getId()))
              .orElseThrow(() -> exception(DEPT_NOT_FOUND));
            //切换的目标部门是否合规
            if (!CommonStatusEnum.ENABLE.getStatus().equals(deptDO.getStatus())) {
                throw exception(DEPT_NOT_ENABLE, deptDO.getName());
            }
            adminUserService.updateUserDeptId(getLoginUserId(), reqVO.getId());
            // 创建 Token 令牌需要基于租户用户，因为每个租户的登录逻辑是跟随租户进行的，记录登录日志
            return reqVO;
        } finally {
            DataPermissionContextHolder.remove();
        }
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
        reqDTO.setUserIp(getClientIP());
        reqDTO.setResult(LoginResultEnum.SUCCESS.getResult());
        loginLogService.createLoginLog(reqDTO);
    }

    private String getUsername(Long userId) {
        if (userId == null) {
            return null;
        }
        UserRespVO user = adminUserService.getUser(userId);
        SaasUserDO saasUserDO = saasUserService.getUser(user.getSaasUserId());
        return saasUserDO != null ? saasUserDO.getUsername() : null;
    }

    private UserTypeEnum getUserType() {
        return UserTypeEnum.ADMIN;
    }

    /**
     * 获取租户用户信息，并更新SaaS用户信息
     * @param saasUserDO saas用户
     * @return 对应租户用户
     */
    private AdminUserDO getLoginAdminUser(SaasUserDO saasUserDO, LoginLogTypeEnum logTypeEnum) {
        //查询当前用户默认的租户id
        AdminUserDO adminUser = getLoginAdminUser(saasUserDO, saasUserDO.getDefaultTenant(), logTypeEnum);
        //如果默认的禁用了，则只能取它自己的所属租户了
        if (Objects.isNull(adminUser)) {
            throw exception(AUTH_LOGIN_EXCEPTION);
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
    private AdminUserDO getLoginAdminUser(SaasUserDO saasUserDO, Long tenantId, LoginLogTypeEnum logTypeEnum) {
        AtomicReference<AdminUserDO> adminUserDO = new AtomicReference<>(null);
        //忽略多租户进行查询
        TenantUtils.executeIgnore(() -> {
            // 关闭数据权限，避免因为没有数据权限，查询不到数据
            DataPermissionUtils.executeIgnore(() -> {
                //对应租户所有用户
                List<AdminUserDO> userDOList = userMapper.selectList(AdminUserDO::getSaasUserId, saasUserDO.getId());
                if (CollUtil.isEmpty(userDOList)) {
                    return;
                }
                List<Long> tenantIdList = userDOList.stream().map(AdminUserDO::getTenantId).collect(Collectors.toList());
                //对应所有租户
                List<TenantRespDTO> respDTOList = tenantService.getTenantList(tenantIdList);
                //租户条件满足，对应租户内部的用户也满足
                TenantRespDTO tenantRespDTO = respDTOList.stream().filter(tenant -> tenant.getId().equals(tenantId)).findFirst().orElse(null);
                if (Objects.nonNull(tenantRespDTO) && tenantRespDTO.getStatus().equals(CommonStatusEnum.ENABLE.getStatus())) {
                    userDOList.stream().filter(userDO -> userDO.getTenantId().equals(tenantId)
                            && userDO.getStatus().equals(CommonStatusEnum.ENABLE.getStatus())).findFirst().ifPresent(adminUserDO::set);
                }
                if (Objects.nonNull(adminUserDO.get())) {
                    return;
                }
                //排除掉禁用的租户和上面已经不满足的租户
                respDTOList = respDTOList.stream()
                        .filter(tenant -> tenant.getStatus().equals(CommonStatusEnum.ENABLE.getStatus()) && !tenant.getId().equals(tenantId))
                        .collect(Collectors.toList());
                for (TenantRespDTO tenant : respDTOList) {
                    userDOList.stream().filter(userDO -> userDO.getTenantId().equals(tenant.getId())
                            && userDO.getStatus().equals(CommonStatusEnum.ENABLE.getStatus())).findFirst().ifPresent(adminUserDO::set);
                    if (Objects.nonNull(adminUserDO.get())) {
                        return;
                    }
                }
            });
        });
        return adminUserDO.get();
    }

    /**
     * 根据SaaS用户查询对应租户的用户信息
     * @param saasUserDO SaaS用户
     * @param tenantId 租户id
     * @param logTypeEnum 登录类型
     * @return 对应租户的用户信息
     */
    private AdminUserDO getToTenantAdminUser(SaasUserDO saasUserDO, Long tenantId, LoginLogTypeEnum logTypeEnum) {
        Long oldTenantId = TenantContextHolder.getTenantId();
        Boolean oldIgnore = TenantContextHolder.isIgnore();
        TenantContextHolder.setTenantId(tenantId);
        TenantContextHolder.setIgnore(false);
        AdminUserDO adminUserDO = adminUserService.getUserBySaasUserId(saasUserDO.getId());
        // 检查是否被删除
        if (Objects.isNull(adminUserDO)) {
            TenantContextHolder.setTenantId(oldTenantId);
            TenantContextHolder.setIgnore(oldIgnore);
            return null;
        }
        // 是否禁用
        if (CommonStatusEnum.isDisable(adminUserDO.getStatus())) {
            if (Objects.nonNull(logTypeEnum)) {
                createLoginLog(adminUserDO.getId(), saasUserDO.getUsername(), logTypeEnum, LoginResultEnum.USER_DISABLED);
            }
            TenantContextHolder.setTenantId(oldTenantId);
            TenantContextHolder.setIgnore(oldIgnore);
            return null;
        }
        TenantContextHolder.setTenantId(oldTenantId);
        TenantContextHolder.setIgnore(oldIgnore);
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
        //如果是对方邀请的该用户，然后该用户又主动点击进入租户，则被视为主动同意，修改租户用户状态为启用
        if (CommonStatusEnum.AWAIT.getStatus().equals(adminUser.getStatus())) {
            //跟新租户用户状态信息
            adminUserService.updateUserStatus(adminUser.getId(), CommonStatusEnum.ENABLE.getStatus());
        }
        //设置SaaS用户默认租户
        saasUserService.updateUserDefaultTenant(saasUserDO.getId(), adminUser.getTenantId());
    }

}
