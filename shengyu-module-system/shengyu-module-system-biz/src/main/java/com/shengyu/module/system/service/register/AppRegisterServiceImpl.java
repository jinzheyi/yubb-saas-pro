package com.shengyu.module.system.service.register;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_OWNED_TENANT_EXISTS;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_REGISTER_DISABLED;

import cn.hutool.core.util.StrUtil;
import com.shengyu.module.platform.api.tenant.TenantApi;
import com.shengyu.module.platform.api.tenant.dto.tenant.TenantRespDTO;
import com.shengyu.module.platform.api.tenant.dto.tenant.TenantTrialCreateReqDTO;
import com.shengyu.module.system.controller.app.register.vo.AppTrialTenantRegisterReqVO;
import com.shengyu.module.system.controller.app.register.vo.AppRegisterResultRespVO;
import com.shengyu.module.system.controller.app.register.vo.AppTenantJoinByInviteReqVO;
import com.shengyu.module.system.dal.dataobject.user.SaasUserDO;
import com.shengyu.module.system.service.tenant.TenantJoinService;
import com.shengyu.module.system.dal.dataobject.tenant.TenantJoinApplyDO;
import com.shengyu.module.system.service.user.SaasUserService;
import com.shengyu.framework.common.enums.UserTypeEnum;
import com.shengyu.framework.web.core.util.WebFrameworkUtils;
import com.shengyu.module.platform.api.mail.MailSendApi;
import cn.hutool.core.date.DateUtil;
import cn.hutool.core.util.RandomUtil;
import java.time.format.DateTimeParseException;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.time.LocalDateTime;
import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * App 注册 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class AppRegisterServiceImpl implements AppRegisterService {

    @Value("${shengyu.app-register.enabled:true}")
    private Boolean registerEnabled;

    @Value("${shengyu.app-register.default-package-id:1790399764110786000}")
    private Long defaultPackageId;

    @Value("${shengyu.app-register.default-expire-time:2099-12-31T23:59:59}")
    private String defaultTenantExpireTime;

    @Value("${shengyu.app-register.account-count:1000}")
    private Integer accountCount;

    @Resource
    private SaasUserService saasUserService;
    @Resource
    private TenantApi tenantApi;
    @Resource
    private AppEmailVerificationService appEmailVerificationService;
    @Resource
    private TenantJoinService tenantJoinService;
    @Resource
    private MailSendApi mailSendApi;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AppRegisterResultRespVO registerTenant(AppTrialTenantRegisterReqVO reqVO) {
        if (!Boolean.TRUE.equals(registerEnabled)) {
            throw exception(USER_REGISTER_DISABLED);
        }

        String email = StrUtil.trim(reqVO.getUsername()).toLowerCase();
        appEmailVerificationService.verifyCode(email, reqVO.getEmailCode());
        boolean newUser = saasUserService.getUserByUsername(email) == null;
        String initialPassword = newInitialPassword();
        SaasUserDO saasUser = saasUserService.registerOrGetVerifiedEmailUser(email, initialPassword, reqVO.getMobile());
        bindRequestAuditActor(saasUser);
        TenantRespDTO ownedTenant = tenantApi.getTenantByOwnerSaasUserId(saasUser.getId());
        if (ownedTenant != null) {
            throw exception(USER_OWNED_TENANT_EXISTS);
        }

        TenantTrialCreateReqDTO createReqDTO = new TenantTrialCreateReqDTO();
        createReqDTO.setName(StrUtil.trim(reqVO.getTenantName()));
        createReqDTO.setContactName(StrUtil.trim(reqVO.getNickname()));
        createReqDTO.setContactMobile(StrUtil.trim(reqVO.getMobile()));
        createReqDTO.setUsername(email);
        createReqDTO.setOwnerSaasUserId(saasUser.getId());
        createReqDTO.setPackageId(defaultPackageId);
        // 平台层创建租户要求明确的到期时间，App 自助创建企业采用长期默认值。
        createReqDTO.setExpireTime(parseDefaultTenantExpireTime());
        createReqDTO.setAccountCount(accountCount == null ? 1000 : accountCount);
        Long tenantId = tenantApi.createTrialTenant(createReqDTO);
        saasUserService.updateUserDefaultTenant(saasUser.getId(), tenantId);
        if (newUser) {
            sendInitialPassword(email, initialPassword, createReqDTO.getName());
        }
        log.info("[registerTenant][saasUserId({}) tenantId({}) email({})]", saasUser.getId(), tenantId, email);
        return new AppRegisterResultRespVO(newUser, true,
                newUser ? "企业已创建，初始登录密码已发送至邮箱，请使用邮箱和密码登录" : "企业已创建，请使用已有账号密码登录");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AppRegisterResultRespVO joinByInvite(AppTenantJoinByInviteReqVO reqVO) {
        String email = StrUtil.trim(reqVO.getEmail()).toLowerCase();
        appEmailVerificationService.verifyCode(email, reqVO.getEmailCode());
        boolean newUser = saasUserService.getUserByUsername(email) == null;
        String initialPassword = newInitialPassword();
        SaasUserDO saasUser = saasUserService.registerOrGetVerifiedEmailUser(email, initialPassword, null);
        bindRequestAuditActor(saasUser);
        TenantJoinApplyDO apply = tenantJoinService.joinByInviteCode(reqVO.getInviteCode(), saasUser.getId(),
                StrUtil.blankToDefault(StrUtil.trim(reqVO.getNickname()), email));
        if (newUser) {
            sendInitialPassword(email, initialPassword, "受邀企业");
        }
        boolean approved = apply.getStatus() == 1;
        String loginHint = newUser ? "初始登录密码已发送至邮箱" : "请使用已有账号密码登录";
        return new AppRegisterResultRespVO(newUser, approved,
                approved ? "申请已通过，" + loginHint + "后请在企业列表确认进入"
                        : "申请已提交，等待企业管理员审核；审核通过后" + loginHint + "并在企业列表确认进入");
    }

    private String newInitialPassword() {
        return "Sy@" + RandomUtil.randomString(10);
    }

    private LocalDateTime parseDefaultTenantExpireTime() {
        try {
            return LocalDateTime.parse(defaultTenantExpireTime);
        } catch (DateTimeParseException exception) {
            throw new IllegalStateException("shengyu.app-register.default-expire-time 格式必须为 ISO-8601 日期时间", exception);
        }
    }

    /**
     * App 自助创建企业是匿名入口，需在当前请求中明确审计操作者，
     * 使平台租户、租户管理员和初始化模板的 creator/updater 均可正确落库。
     */
    private void bindRequestAuditActor(SaasUserDO saasUser) {
        HttpServletRequest request = WebFrameworkUtils.getRequest();
        if (request != null) {
            WebFrameworkUtils.setLoginUserId(request, saasUser.getId());
        }
    }

    private void sendInitialPassword(String email, String password, String tenantName) {
        Map<String, Object> params = new HashMap<>();
        params.put("mail", email);
        params.put("password", password);
        params.put("registerTime", DateUtil.formatDateTime(new Date()));
        params.put("tenantName", tenantName);
        mailSendApi.sendSingleMail(email, null, UserTypeEnum.ADMIN.getValue(), "tenant-add-user", params);
    }

}
