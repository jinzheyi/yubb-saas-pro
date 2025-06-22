package com.shengyu.module.platform.service.tenant;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.TENANT_DISABLE;
import static com.shengyu.module.system.enums.ErrorCodeConstants.TENANT_EXPIRE;
import static com.shengyu.module.system.enums.ErrorCodeConstants.TENANT_NAME_DUPLICATE;
import static com.shengyu.module.system.enums.ErrorCodeConstants.TENANT_NOT_EXISTS;
import static com.shengyu.module.system.enums.ErrorCodeConstants.TENANT_WEBSITE_DUPLICATE;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.lang.Assert;
import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.enums.CommonConstants;
import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.collection.CollectionUtils;
import com.shengyu.framework.common.util.date.DateUtils;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.tenant.core.util.TenantUtils;
import com.shengyu.module.platform.controller.platform.tenant.vo.tenant.TenantCreateReqVO;
import com.shengyu.module.platform.controller.platform.tenant.vo.tenant.TenantExportReqVO;
import com.shengyu.module.platform.controller.platform.tenant.vo.tenant.TenantPageReqVO;
import com.shengyu.module.platform.controller.platform.tenant.vo.tenant.TenantUpdateReqVO;
import com.shengyu.module.platform.convert.tenant.TenantConvert;
import com.shengyu.module.platform.dal.dataobject.tenant.TenantDO;
import com.shengyu.module.platform.dal.dataobject.tenant.TenantPackageDO;
import com.shengyu.module.platform.dal.mysql.tenant.TenantMapper;
import com.shengyu.module.system.api.notify.NotifyTemplateApi;
import com.shengyu.module.system.api.notify.dto.NotifyTemplateSaveReqDTO;
import com.shengyu.module.system.api.permission.PermissionApi;
import com.shengyu.module.system.api.permission.RoleApi;
import com.shengyu.module.system.api.permission.dto.RoleSimpleRespDTO;
import com.shengyu.module.system.api.user.AdminUserApi;

import java.util.Collection;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import javax.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

/**
 * 租户 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Validated
@Slf4j
public class PlatformTenantServiceImpl implements PlatformTenantService {

    @Resource
    private TenantMapper tenantMapper;

    @Resource
    private TenantPackageService tenantPackageService;

    @Resource
    private AdminUserApi adminUserApi;

    @Resource
    private RoleApi roleApi;

    @Resource
    private PermissionApi permissionApi;
    @Resource
    private NotifyTemplateApi notifyTemplateApi;

    @Override
    public List<Long> getTenantIdList() {
        List<TenantDO> tenants = tenantMapper.selectList();
        return CollectionUtils.convertList(tenants, TenantDO::getId);
    }

    @Override
    public void validTenant(Long id) {
        TenantDO tenant = getTenant(id);
        if (tenant == null) {
            throw exception(TENANT_NOT_EXISTS);
        }
        if (tenant.getStatus().equals(CommonStatusEnum.DISABLE.getStatus())) {
            throw exception(TENANT_DISABLE, tenant.getName());
        }
        if (DateUtils.isExpired(tenant.getExpireTime())) {
            throw exception(TENANT_EXPIRE, tenant.getName());
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createTenant(TenantCreateReqVO createReqVO) {
        // 校验租户名称是否重复
        validTenantNameDuplicate(createReqVO.getName(), null);
        // 校验租户域名是否重复
        validTenantWebsiteDuplicate(createReqVO.getWebsite(), null);
        // 校验套餐被禁用
        TenantPackageDO tenantPackage = tenantPackageService.validTenantPackage(createReqVO.getPackageId());
        // 创建租户
        TenantDO tenant = BeanUtils.toBean(createReqVO, TenantDO.class);
        tenant.setContactUserName(createReqVO.getUsername());
        tenantMapper.insert(tenant);

        TenantUtils.execute(tenant.getId(), () -> {
            //创建租户系统通知模版
            notifyTemplateApi.createNotifyTemplate(NotifyTemplateSaveReqDTO.getTenantNewAdminUser());
            notifyTemplateApi.createNotifyTemplate(NotifyTemplateSaveReqDTO.getTenantAdminUser());
            notifyTemplateApi.createNotifyTemplate(NotifyTemplateSaveReqDTO.getTenantSuperAdminUser());
            // 创建用户
            Long userId = createUser(createReqVO);
            // 修改租户的管理员
            tenantMapper.updateById(new TenantDO().setId(tenant.getId()).setContactUserId(userId));
        });
        return tenant.getId();
    }

    private Long createUser(TenantCreateReqVO createReqVO) {
        // 创建用户
        return adminUserApi.createUser(TenantConvert.INSTANCE.convert02(createReqVO), CommonConstants.TENANT_ADMIN);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateTenant(TenantUpdateReqVO updateReqVO) {
        // 校验存在
        TenantDO tenant = validateUpdateTenant(updateReqVO.getId());
        // 校验租户名称是否重复
        validTenantNameDuplicate(updateReqVO.getName(), updateReqVO.getId());
        // 校验租户域名是否重复
        validTenantWebsiteDuplicate(updateReqVO.getWebsite(), updateReqVO.getId());
        // 校验套餐被禁用
        TenantPackageDO tenantPackage = tenantPackageService.validTenantPackage(updateReqVO.getPackageId());

        // 更新租户
        TenantDO updateObj = BeanUtils.toBean(updateReqVO, TenantDO.class);
        tenantMapper.updateById(updateObj);
        // 如果套餐发生变化，则修改其角色的权限
        if (ObjectUtil.notEqual(tenant.getPackageId(), updateReqVO.getPackageId())) {
            updateTenantRoleMenu(tenant.getId(), tenantPackage.getMenuIds());
        }
    }

    private void validTenantNameDuplicate(String name, Long id) {
        TenantDO tenant = tenantMapper.selectByName(name);
        if (tenant == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同名字的租户
        if (id == null) {
            throw exception(TENANT_NAME_DUPLICATE, name);
        }
        if (!tenant.getId().equals(id)) {
            throw exception(TENANT_NAME_DUPLICATE, name);
        }
    }

    private void validTenantWebsiteDuplicate(String website, Long id) {
        if (StrUtil.isEmpty(website)) {
            return;
        }
        TenantDO tenant = tenantMapper.selectByWebsite(website);
        if (tenant == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同名字的租户
        if (id == null) {
            throw exception(TENANT_WEBSITE_DUPLICATE, website);
        }
        if (!tenant.getId().equals(id)) {
            throw exception(TENANT_WEBSITE_DUPLICATE, website);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateTenantRoleMenu(Long tenantId, Set<Long> menuIds) {
        TenantUtils.execute(tenantId, () -> {
            // 获得所有角色
            List<RoleSimpleRespDTO> roles = roleApi.getRoleListByStatus(null);
            roles.forEach(role -> Assert.isTrue(tenantId.equals(role.getTenantId()), "角色({}/{}) 租户不匹配",
                    role.getId(), role.getTenantId(), tenantId)); // 兜底校验
            // 重新分配每个角色的权限
            roles.forEach(role -> {
                // 去掉超过套餐的权限
                Set<Long> roleMenuIds = permissionApi.getRoleMenuListByRoleId(role.getId());
                roleMenuIds = CollUtil.intersectionDistinct(roleMenuIds, menuIds);
                permissionApi.assignRoleMenu(role.getId(), roleMenuIds);
                log.info("[updateTenantRoleMenu][角色({}/{}) 的权限修改为({})]", role.getId(), role.getTenantId(), roleMenuIds);
            });
        });
    }

    @Override
    public void deleteTenant(Long id) {
        // 校验存在
        validateUpdateTenant(id);
        // 删除
        tenantMapper.deleteById(id);
    }

    private TenantDO validateUpdateTenant(Long id) {
        TenantDO tenant = tenantMapper.selectById(id);
        if (tenant == null) {
            throw exception(TENANT_NOT_EXISTS);
        }
        return tenant;
    }

    @Override
    public TenantDO getTenant(Long id) {
        return tenantMapper.selectById(id);
    }

    @Override
    public List<TenantDO> getTenantList(Collection<Long> ids) {
        return tenantMapper.selectBatchIds(ids);
    }

    @Override
    public PageResult<TenantDO> getTenantPage(TenantPageReqVO pageReqVO) {
        return tenantMapper.selectPage(pageReqVO);
    }

    @Override
    public List<TenantDO> getTenantList(TenantExportReqVO exportReqVO) {
        return tenantMapper.selectList(exportReqVO);
    }

    @Override
    public TenantDO getTenantByName(String name) {
        return tenantMapper.selectByName(name);
    }

    @Override
    public TenantDO getTenantByWebsite(String website) {
        return tenantMapper.selectByWebsite(website);
    }

    @Override
    public Long getTenantCountByPackageId(Long packageId) {
        return tenantMapper.selectCountByPackageId(packageId);
    }

    @Override
    public List<TenantDO> getTenantListByPackageId(Long packageId) {
        return tenantMapper.selectListByPackageId(packageId);
    }

}
