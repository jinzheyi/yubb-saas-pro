package cn.iocoder.yudao.module.platform.service.tenant;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.lang.Assert;
import cn.hutool.core.util.ObjectUtil;
import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import cn.iocoder.yudao.framework.common.enums.oauth2.OAuth2ClientConstants;
import cn.iocoder.yudao.framework.common.enums.permission.RoleCodeEnum;
import cn.iocoder.yudao.framework.common.enums.permission.RoleTypeEnum;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.collection.CollectionUtils;
import cn.iocoder.yudao.framework.common.util.date.DateUtils;
import cn.iocoder.yudao.framework.tenant.config.TenantProperties;
import cn.iocoder.yudao.framework.tenant.core.util.TenantUtils;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.tenant.TenantCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.tenant.TenantExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.tenant.TenantPageReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.tenant.TenantUpdateReqVO;
import cn.iocoder.yudao.module.platform.convert.tenant.TenantConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2ClientDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.TenantDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.TenantPackageDO;
import cn.iocoder.yudao.module.platform.dal.mysql.tenant.PlatformTenantMapper;
import cn.iocoder.yudao.module.platform.service.oauth2.PlatformOAuth2ClientService;
import cn.iocoder.yudao.module.system.api.oauth2.OAuth2ClientApi;
import cn.iocoder.yudao.module.system.api.permission.PermissionApi;
import cn.iocoder.yudao.module.system.api.permission.RoleApi;
import cn.iocoder.yudao.module.system.api.permission.dto.RoleCreateReqDTO;
import cn.iocoder.yudao.module.system.api.permission.dto.RoleSimpleRespDTO;
import cn.iocoder.yudao.module.system.api.user.AdminUserApi;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;
import java.util.List;
import java.util.Objects;
import java.util.Set;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.*;
import static java.util.Collections.singleton;

/**
 * 租户 Service 实现类
 *
 * @author 芋道源码
 */
@Service
@Validated
@Slf4j
public class PlatformTenantServiceImpl implements PlatformTenantService {

    @SuppressWarnings("SpringJavaAutowiredFieldsWarningInspection")
    @Autowired(required = false) // 由于 yudao.tenant.enable 配置项，可以关闭多租户的功能，所以这里只能不强制注入
    private TenantProperties tenantProperties;

    @Resource
    private PlatformTenantMapper platformTenantMapper;

    @Resource
    private PlatformTenantPackageService platformTenantPackageService;

    @Resource
    private PlatformOAuth2ClientService platformOAuth2ClientService;

    @Resource
    private AdminUserApi adminUserApi;
    @Resource
    private RoleApi roleApi;

    @Resource
    private PermissionApi permissionApi;

    @Resource
    private OAuth2ClientApi oAuth2ClientApi;

    @Override
    public List<Long> getTenantIds() {
        List<TenantDO> tenants = platformTenantMapper.selectList();
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
        // 校验套餐被禁用
        TenantPackageDO tenantPackage = platformTenantPackageService.validTenantPackage(createReqVO.getPackageId());
        //校验客户端是否可用
        PlatformOAuth2ClientDO auth2Client = platformOAuth2ClientService.getOAuth2Client(OAuth2ClientConstants.CLIENT_ID_DEFAULT);

        // 创建租户
        TenantDO tenant = TenantConvert.INSTANCE.convert(createReqVO);
        platformTenantMapper.insert(tenant);

        TenantUtils.execute(tenant.getId(), () -> {
            // 创建角色
            Long roleId = createRole(tenantPackage);
            // 创建用户，并分配角色
            Long userId = createUser(roleId, createReqVO);
            // 修改租户的管理员
            platformTenantMapper.updateById(new TenantDO().setId(tenant.getId()).setContactUserId(userId));
            //创建租户OAuth2客户端
            createOAuth2Client(auth2Client);
        });
        return tenant.getId();
    }

    private Long createUser(Long roleId, TenantCreateReqVO createReqVO) {
        // 创建用户
        Long userId = adminUserApi.createUser(TenantConvert.INSTANCE.convert02(createReqVO));
        // 分配角色
        permissionApi.assignUserRole(userId, singleton(roleId));
        return userId;
    }

    private Long createRole(TenantPackageDO tenantPackage) {
        // 创建角色
        RoleCreateReqDTO reqDTO = new RoleCreateReqDTO();
        reqDTO.setName(RoleCodeEnum.TENANT_ADMIN.getName()).setCode(RoleCodeEnum.TENANT_ADMIN.getCode())
                .setSort(0).setRemark("系统自动生成").setType(RoleTypeEnum.SYSTEM.getType());
        Long roleId = roleApi.createRole(reqDTO);
        // 分配权限
        permissionApi.assignRoleMenu(roleId, tenantPackage.getMenuIds());
        return roleId;
    }

    private Long createOAuth2Client(PlatformOAuth2ClientDO auth2Client) {
        return oAuth2ClientApi.createOAuth2Client(TenantConvert.INSTANCE.convert03(auth2Client));
    };

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateTenant(TenantUpdateReqVO updateReqVO) {
        // 校验存在
        TenantDO tenant = checkUpdateTenant(updateReqVO.getId());
        // 校验套餐被禁用
        TenantPackageDO tenantPackage = platformTenantPackageService.validTenantPackage(updateReqVO.getPackageId());

        // 更新租户
        TenantDO updateObj = TenantConvert.INSTANCE.convert(updateReqVO);
        platformTenantMapper.updateById(updateObj);
        // 如果套餐发生变化，则修改其角色的权限
        if (ObjectUtil.notEqual(tenant.getPackageId(), updateReqVO.getPackageId())) {
            updateTenantRoleMenu(tenant.getId(), tenantPackage.getMenuIds());
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateTenantRoleMenu(Long tenantId, Set<Long> menuIds) {
        TenantUtils.execute(tenantId, () -> {
            // 获得所有角色
            List<RoleSimpleRespDTO> roles = roleApi.getRoles(null);
            roles.forEach(role -> Assert.isTrue(tenantId.equals(role.getTenantId()), "角色({}/{}) 租户不匹配",
                    role.getId(), role.getTenantId(), tenantId)); // 兜底校验
            // 重新分配每个角色的权限
            roles.forEach(role -> {
                // 如果是租户管理员，重新分配其权限为租户套餐的权限
                if (Objects.equals(role.getCode(), RoleCodeEnum.TENANT_ADMIN.getCode())) {
                    permissionApi.assignRoleMenu(role.getId(), menuIds);
                    log.info("[updateTenantRoleMenu][租户管理员({}/{}) 的权限修改为({})]", role.getId(), role.getTenantId(), menuIds);
                    return;
                }
                // 如果是其他角色，则去掉超过套餐的权限
                Set<Long> roleMenuIds = permissionApi.getRoleMenuIds(role.getId());
                roleMenuIds = CollUtil.intersectionDistinct(roleMenuIds, menuIds);
                permissionApi.assignRoleMenu(role.getId(), roleMenuIds);
                log.info("[updateTenantRoleMenu][角色({}/{}) 的权限修改为({})]", role.getId(), role.getTenantId(), roleMenuIds);
            });
        });
    }

    @Override
    public void deleteTenant(Long id) {
        // 校验存在
        checkUpdateTenant(id);
        // 删除
        platformTenantMapper.deleteById(id);
    }

    private TenantDO checkUpdateTenant(Long id) {
        TenantDO tenant = platformTenantMapper.selectById(id);
        if (tenant == null) {
            throw exception(TENANT_NOT_EXISTS);
        }
        return tenant;
    }

    @Override
    public TenantDO getTenant(Long id) {
        return platformTenantMapper.selectById(id);
    }

    @Override
    public PageResult<TenantDO> getTenantPage(TenantPageReqVO pageReqVO) {
        return platformTenantMapper.selectPage(pageReqVO);
    }

    @Override
    public List<TenantDO> getTenantList(TenantExportReqVO exportReqVO) {
        return platformTenantMapper.selectList(exportReqVO);
    }

    @Override
    public TenantDO getTenantByName(String name) {
        return platformTenantMapper.selectByName(name);
    }

    @Override
    public Long getTenantCountByPackageId(Long packageId) {
        return platformTenantMapper.selectCountByPackageId(packageId);
    }

    @Override
    public List<TenantDO> getTenantListByPackageId(Long packageId) {
        return platformTenantMapper.selectListByPackageId(packageId);
    }

}
