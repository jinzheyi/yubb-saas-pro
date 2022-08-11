package cn.iocoder.yudao.module.platform.service.oauth2;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.lang.Assert;
import cn.iocoder.yudao.framework.common.util.date.DateUtils;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2ApproveDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2ClientDO;
import cn.iocoder.yudao.module.platform.dal.mysql.oauth2.PlatformOAuth2ApproveMapper;
import com.google.common.annotations.VisibleForTesting;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;
import java.util.*;

import static cn.iocoder.yudao.framework.common.util.collection.CollectionUtils.convertSet;

/**
 * OAuth2 批准 Service 实现类
 *
 * @author 芋道源码
 */
@Service
@Validated
public class PlatformOAuth2ApproveServiceImpl implements PlatformOAuth2ApproveService {

    /**
     * 批准的过期时间，默认 30 天
     */
    private static final Integer TIMEOUT = 30 * 24 * 60 * 60; // 单位：秒

    @Resource
    private PlatformOAuth2ClientService oauth2ClientServicePlatform;

    @Resource
    private PlatformOAuth2ApproveMapper oauth2ApproveMapperPlatform;

    @Override
    @Transactional
    public boolean checkForPreApproval(Long userId, Integer userType, String clientId, Collection<String> requestedScopes) {
        // 第一步，基于 Client 的自动授权计算，如果 scopes 都在自动授权中，则返回 true 通过
        PlatformOAuth2ClientDO clientDO = oauth2ClientServicePlatform.validOAuthClientFromCache(clientId);
        Assert.notNull(clientDO, "客户端不能为空"); // 防御性编程
        if (CollUtil.containsAll(clientDO.getAutoApproveScopes(), requestedScopes)) {
            // gh-877 - if all scopes are auto approved, approvals still need to be added to the approval store.
            Date expireTime = DateUtils.addDate(Calendar.SECOND, TIMEOUT);
            for (String scope : requestedScopes) {
                saveApprove(userId, userType, clientId, scope, true, expireTime);
            }
            return true;
        }

        // 第二步，算上用户已经批准的授权。如果 scopes 都包含，则返回 true
        List<PlatformOAuth2ApproveDO> approveDOs = getApproveList(userId, userType, clientId);
        Set<String> scopes = convertSet(approveDOs, PlatformOAuth2ApproveDO::getScope,
                PlatformOAuth2ApproveDO::getApproved); // 只保留未过期的 + 同意的
        return CollUtil.containsAll(scopes, requestedScopes);
    }

    @Override
    @Transactional
    public boolean updateAfterApproval(Long userId, Integer userType, String clientId, Map<String, Boolean> requestedScopes) {
        // 如果 requestedScopes 为空，说明没有要求，则返回 true 通过
        if (CollUtil.isEmpty(requestedScopes)) {
            return true;
        }

        // 更新批准的信息
        boolean success = false; // 需要至少有一个同意
        Date expireTime = DateUtils.addDate(Calendar.SECOND, TIMEOUT);
        for (Map.Entry<String, Boolean> entry :requestedScopes.entrySet()) {
            if (entry.getValue()) {
                success = true;
            }
            saveApprove(userId, userType, clientId, entry.getKey(), entry.getValue(), expireTime);
        }
        return success;
    }

    @Override
    public List<PlatformOAuth2ApproveDO> getApproveList(Long userId, Integer userType, String clientId) {
        List<PlatformOAuth2ApproveDO> approveDOs = oauth2ApproveMapperPlatform.selectListByUserIdAndUserTypeAndClientId(
                userId, userType, clientId);
        approveDOs.removeIf(o -> DateUtils.isExpired(o.getExpiresTime()));
        return approveDOs;
    }

    @VisibleForTesting
    void saveApprove(Long userId, Integer userType, String clientId,
                     String scope, Boolean approved, Date expireTime) {
        // 先更新
        PlatformOAuth2ApproveDO approveDO = new PlatformOAuth2ApproveDO().setUserId(userId).setUserType(userType)
                .setClientId(clientId).setScope(scope).setApproved(approved).setExpiresTime(expireTime);
        if (oauth2ApproveMapperPlatform.update(approveDO) == 1) {
            return;
        }
        // 失败，则说明不存在，进行更新
        oauth2ApproveMapperPlatform.insert(approveDO);
    }

}
