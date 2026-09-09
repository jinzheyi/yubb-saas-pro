package com.shengyu.module.system.service.tenant;

import cn.hutool.core.util.IdUtil;
import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.module.system.dal.dataobject.tenant.TenantInviteDO;
import com.shengyu.module.system.dal.dataobject.tenant.TenantJoinApplyDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.tenant.TenantInviteMapper;
import com.shengyu.module.system.dal.mysql.tenant.TenantJoinApplyMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.platform.api.tenant.TenantApi;
import java.time.LocalDateTime;
import java.util.List;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_TENANT_INVITE_INVALID;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_TENANT_JOIN_APPLY_INVALID;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_TENANT_JOIN_PENDING;

@Service
public class TenantJoinService {
    @Resource private TenantInviteMapper inviteMapper;
    @Resource private TenantJoinApplyMapper applyMapper;
    @Resource private AdminUserMapper userMapper;
    @Resource private TenantApi tenantApi;

    @Transactional(rollbackFor = Exception.class)
    public TenantInviteDO createInvite(String name, Integer maxUseCount, LocalDateTime expireTime, Boolean autoApprove) {
        TenantInviteDO invite = new TenantInviteDO();
        invite.setTenantId(TenantContextHolder.getRequiredTenantId());
        invite.setInviteCode(IdUtil.fastSimpleUUID().substring(0, 10).toUpperCase());
        invite.setName(name == null ? "企业邀请" : name.trim());
        invite.setStatus(CommonStatusEnum.ENABLE.getStatus());
        invite.setMaxUseCount(maxUseCount == null ? 0 : Math.max(maxUseCount, 0));
        invite.setUsedCount(0); invite.setExpireTime(expireTime); invite.setAutoApprove(!Boolean.FALSE.equals(autoApprove));
        inviteMapper.insert(invite); return invite;
    }

    public List<TenantInviteDO> getInviteList() {
        return inviteMapper.selectList(TenantInviteDO::getTenantId, TenantContextHolder.getRequiredTenantId());
    }

    public List<TenantJoinApplyDO> getApplyList() {
        return applyMapper.selectList(TenantJoinApplyDO::getTenantId, TenantContextHolder.getRequiredTenantId());
    }

    public void disableInvite(Long id) {
        TenantInviteDO invite = inviteMapper.selectById(id);
        if (invite == null || !invite.getTenantId().equals(TenantContextHolder.getRequiredTenantId())) throw exception(USER_TENANT_INVITE_INVALID);
        invite.setStatus(CommonStatusEnum.DISABLE.getStatus()); inviteMapper.updateById(invite);
    }

    @Transactional(rollbackFor = Exception.class)
    public TenantJoinApplyDO joinByInviteCode(String inviteCode, Long saasUserId, String nickname) {
        TenantInviteDO invite = inviteMapper.selectByCode(inviteCode == null ? null : inviteCode.trim().toUpperCase());
        if (invite == null || !CommonStatusEnum.ENABLE.getStatus().equals(invite.getStatus())
                || (invite.getExpireTime() != null && invite.getExpireTime().isBefore(LocalDateTime.now()))
                || (invite.getMaxUseCount() > 0 && invite.getUsedCount() >= invite.getMaxUseCount())) {
            throw exception(USER_TENANT_INVITE_INVALID);
        }
        // 审核通过前先阻断已删除、停用或到期企业，避免用户收到“通过”后才在切换时失败。
        tenantApi.validateTenant(invite.getTenantId());
        if (hasTenantMember(invite.getTenantId(), saasUserId)) {
            throw exception(com.shengyu.module.system.enums.ErrorCodeConstants.USER_INVITED_TENANT_EXISTS);
        }
        TenantJoinApplyDO existingApply = applyMapper.selectByTenantAndSaasUser(invite.getTenantId(), saasUserId);
        if (existingApply != null) {
            if (existingApply.getStatus() == 0) {
                throw exception(USER_TENANT_JOIN_PENDING);
            }
            if (existingApply.getStatus() == 1) {
                throw exception(com.shengyu.module.system.enums.ErrorCodeConstants.USER_INVITED_TENANT_EXISTS);
            }
            // 已拒绝申请可以使用有效邀请码重新提交，不删除旧记录，避免产生重复成员身份。
            boolean autoApprove = Boolean.TRUE.equals(invite.getAutoApprove());
            existingApply.setInviteId(invite.getId());
            existingApply.setSource("invite");
            existingApply.setRemark(nickname == null ? "" : nickname.trim());
            existingApply.setStatus(autoApprove ? 1 : 0);
            existingApply.setAuditorId(null);
            existingApply.setAuditTime(autoApprove ? LocalDateTime.now() : null);
            applyMapper.updateById(existingApply);
            if (autoApprove) {
                createPendingMember(invite.getTenantId(), saasUserId, nickname);
            }
            return existingApply;
        }
        TenantJoinApplyDO apply = new TenantJoinApplyDO();
        apply.setTenantId(invite.getTenantId()); apply.setSaasUserId(saasUserId); apply.setInviteId(invite.getId());
        apply.setSource("invite");
        // 审批发生在稍后，先保留申请人昵称以便通过时创建正确的员工身份。
        apply.setRemark(nickname == null ? "" : nickname.trim());
        boolean autoApprove = Boolean.TRUE.equals(invite.getAutoApprove());
        apply.setStatus(autoApprove ? 1 : 0);
        if (autoApprove) { apply.setAuditTime(LocalDateTime.now()); createPendingMember(invite.getTenantId(), saasUserId, nickname); }
        applyMapper.insert(apply);
        invite.setUsedCount(invite.getUsedCount() + 1); inviteMapper.updateById(invite);
        return apply;
    }

    @Transactional(rollbackFor = Exception.class)
    public void approve(Long applyId, boolean approved) {
        TenantJoinApplyDO apply = applyMapper.selectById(applyId);
        if (apply == null || !apply.getTenantId().equals(TenantContextHolder.getRequiredTenantId()) || apply.getStatus() != 0) {
            throw exception(USER_TENANT_JOIN_APPLY_INVALID);
        }
        apply.setStatus(approved ? 1 : 2); apply.setAuditTime(LocalDateTime.now()); applyMapper.updateById(apply);
        if (approved) createPendingMember(apply.getTenantId(), apply.getSaasUserId(), apply.getRemark());
    }

    private void createPendingMember(Long tenantId, Long saasUserId, String nickname) {
        Long oldTenantId = TenantContextHolder.getTenantId(); Boolean oldIgnore = TenantContextHolder.isIgnore();
        try {
            TenantContextHolder.setTenantId(tenantId); TenantContextHolder.setIgnore(false);
            if (userMapper.selectByTenantIdAndSaasUserId(tenantId, saasUserId) != null) return;
            AdminUserDO user = new AdminUserDO(); user.setTenantId(tenantId); user.setSaasUserId(saasUserId);
            user.setNickname(nickname == null || nickname.trim().isEmpty() ? "新成员" : nickname.trim());
            user.setStatus(CommonStatusEnum.AWAIT.getStatus()); userMapper.insert(user);
        } finally { TenantContextHolder.setTenantId(oldTenantId); TenantContextHolder.setIgnore(oldIgnore); }
    }

    private boolean hasTenantMember(Long tenantId, Long saasUserId) {
        Long oldTenantId = TenantContextHolder.getTenantId();
        Boolean oldIgnore = TenantContextHolder.isIgnore();
        try {
            TenantContextHolder.setTenantId(tenantId);
            TenantContextHolder.setIgnore(false);
            return userMapper.selectByTenantIdAndSaasUserId(tenantId, saasUserId) != null;
        } finally {
            TenantContextHolder.setTenantId(oldTenantId);
            TenantContextHolder.setIgnore(oldIgnore);
        }
    }
}
