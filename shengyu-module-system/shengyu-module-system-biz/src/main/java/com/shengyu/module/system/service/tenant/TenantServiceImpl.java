package com.shengyu.module.system.service.tenant;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.BooleanUtil;
import com.shengyu.framework.common.enums.CommonConstants;
import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.module.platform.api.tenant.TenantApi;
import com.shengyu.module.platform.api.tenant.TenantMenuApi;
import com.shengyu.module.platform.api.tenant.TenantPackageApi;
import com.shengyu.module.platform.api.tenant.dto.menu.TenantMenuListReqDTO;
import com.shengyu.module.platform.api.tenant.dto.menu.TenantMenuRespDTO;
import com.shengyu.module.platform.api.tenant.dto.tenant.TenantRespDTO;
import com.shengyu.module.system.dal.dataobject.plug.PlugTenantDO;
import com.shengyu.module.system.dal.mysql.plug.PlugTenantMapper;
import com.shengyu.module.system.service.tenant.handler.TenantInfoHandler;
import com.shengyu.module.system.service.tenant.handler.TenantMenuHandler;

import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;
import java.util.Set;

/**
 * 租户 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Validated
@Slf4j
public class TenantServiceImpl implements TenantService {

    @Resource
    private TenantApi tenantApi;

    @Resource
    private TenantPackageApi tenantPackageApi;

    @Resource
    private PlugTenantMapper plugTenantMapper;

    @Resource
    private TenantMenuApi tenantMenuApi;

    @Override
    public TenantRespDTO getTenantByName(String name) {
        return tenantApi.getTenantByName(name);
    }

    @Override
    public TenantRespDTO getTenantById(Long id) {
        return tenantApi.getTenant(id);
    }

    @Override
    public List<TenantRespDTO> getTenantList(Collection<Long> ids) {
        return tenantApi.getTenantList(ids);
    }

    @Override
    public TenantRespDTO getTenantByWebsite(String website) {
        return tenantApi.getTenantByWebsite(website);
    }

    @Override
    public void handleTenantInfo(TenantInfoHandler handler) {
        // 获得租户
        TenantRespDTO tenant = tenantApi.getTenant(TenantContextHolder.getRequiredTenantId());
        // 执行处理器
        handler.handle(tenant);
    }

    @Override
    public Set<Long> getMentIdList() {
        // 获得租户，然后获得租户的套餐菜单
        TenantRespDTO tenant = tenantApi.getTenant(TenantContextHolder.getRequiredTenantId());
        Set<Long> menuIds = tenantPackageApi.getTenantPackage(tenant.getPackageId()).getMenuIds();
        //查询当前租户自己已上架且平台正常启用的拥有的插件
        List<Long> plugAppIds = plugTenantMapper.selectListStatusAndEnable()
                .stream().map(PlugTenantDO::getPlugAppId).collect(Collectors.toList());
        if (CollUtil.isNotEmpty(plugAppIds)) {
            // 获得插件菜单列表，只要开启状态的
            TenantMenuListReqDTO reqPlugDTO = new TenantMenuListReqDTO();
            reqPlugDTO.setStatus(CommonStatusEnum.ENABLE.getStatus());
            reqPlugDTO.setDimension(CommonConstants.MenuDimensionEnum.PLUG.getCode());
            reqPlugDTO.setPlugIds(plugAppIds);
            menuIds.addAll(tenantMenuApi.getTenantMenuList(reqPlugDTO).stream().map(TenantMenuRespDTO::getId).collect(Collectors.toList()));
        }
        return menuIds;
    }

    @Override
    public void handleTenantMenu(TenantMenuHandler handler) {
        // 执行处理器
        handler.handle(getMentIdList());
    }

}
