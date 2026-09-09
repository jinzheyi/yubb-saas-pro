package com.shengyu.module.system.service.register;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_OWNED_TENANT_EXISTS;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_REGISTER_DISABLED;

import cn.hutool.core.util.StrUtil;
import com.shengyu.module.platform.api.tenant.TenantApi;
import com.shengyu.module.platform.api.tenant.dto.tenant.TenantRespDTO;
import com.shengyu.module.platform.api.tenant.dto.tenant.TenantTrialCreateReqDTO;
import com.shengyu.module.system.controller.admin.auth.vo.AuthLoginReqVO;
import com.shengyu.module.system.controller.admin.auth.vo.AuthLoginRespVO;
import com.shengyu.module.system.controller.app.register.vo.AppTrialTenantRegisterReqVO;
import com.shengyu.module.system.dal.dataobject.user.SaasUserDO;
import com.shengyu.module.system.service.auth.AdminAuthService;
import com.shengyu.module.system.service.user.SaasUserService;
import java.time.LocalDateTime;
import javax.annotation.Resource;
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

    @Value("${shengyu.app-register.trial-days:0}")
    private Integer tenantValidDays;

    @Value("${shengyu.app-register.account-count:10}")
    private Integer accountCount;

    @Resource
    private SaasUserService saasUserService;
    @Resource
    private TenantApi tenantApi;
    @Resource
    private AdminAuthService adminAuthService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AuthLoginRespVO registerTenant(AppTrialTenantRegisterReqVO reqVO) {
        if (!Boolean.TRUE.equals(registerEnabled)) {
            throw exception(USER_REGISTER_DISABLED);
        }

        String email = StrUtil.trim(reqVO.getUsername()).toLowerCase();
        SaasUserDO saasUser = saasUserService.registerOrValidateEmailUser(email, reqVO.getPassword(), reqVO.getMobile());
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
        if (tenantValidDays != null && tenantValidDays > 0) {
            createReqDTO.setExpireTime(LocalDateTime.now().plusDays(tenantValidDays));
        }
        createReqDTO.setAccountCount(accountCount == null ? 10 : accountCount);
        Long tenantId = tenantApi.createTrialTenant(createReqDTO);
        saasUserService.updateUserDefaultTenant(saasUser.getId(), tenantId);
        log.info("[registerTenant][saasUserId({}) tenantId({}) email({})]", saasUser.getId(), tenantId, email);

        AuthLoginReqVO loginReqVO = new AuthLoginReqVO();
        loginReqVO.setUsername(email);
        loginReqVO.setPassword(reqVO.getPassword());
        return adminAuthService.appLogin(loginReqVO);
    }

}
