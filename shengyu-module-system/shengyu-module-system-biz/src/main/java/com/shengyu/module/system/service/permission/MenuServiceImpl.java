package com.shengyu.module.system.service.permission;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.BooleanUtil;
import com.shengyu.framework.common.enums.CommonConstants;
import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.module.platform.api.tenant.TenantMenuApi;
import com.shengyu.module.platform.api.tenant.dto.menu.TenantMenuListReqDTO;
import com.shengyu.module.platform.api.tenant.dto.menu.TenantMenuRespDTO;
import com.shengyu.module.system.dal.dataobject.plug.PlugTenantDO;
import com.shengyu.module.system.dal.mysql.plug.PlugTenantMapper;
import com.shengyu.module.system.service.tenant.TenantService;
import java.util.stream.Collectors;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;

/**
 * 菜单 Service 实现
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class MenuServiceImpl implements MenuService {

    @Resource
    private TenantMenuApi tenantMenuApi;

    @Resource
    private TenantService tenantService;

    @Resource
    private PlugTenantMapper plugTenantMapper;

    @Override
    public List<TenantMenuRespDTO> getMenuListByTenant(TenantMenuListReqDTO reqDTO, Boolean allPlug) {
        List<TenantMenuRespDTO> menus = tenantMenuApi.getTenantMenuList(reqDTO);
        // 多租户的情况下，需要过滤掉未开通的菜单，根据套餐会去区分出来，套餐只会包含普通菜单
        tenantService.handleTenantMenu(menuIds -> menus.removeIf(menu -> !CollUtil.contains(menuIds, menu.getId())));
        List<Long> plugAppIds = plugTenantMapper.selectListAll()
            .stream().map(PlugTenantDO::getPlugAppId).collect(Collectors.toList());
        if (BooleanUtil.isTrue(allPlug)) {
            //查询当前租户自己已上架且平台正常启用的拥有的插件
            plugAppIds = plugTenantMapper.selectListStatusAndEnable()
                .stream().map(PlugTenantDO::getPlugAppId).collect(Collectors.toList());
        }
        if (CollUtil.isNotEmpty(plugAppIds)) {
            // 获得插件菜单列表，只要开启状态的
            TenantMenuListReqDTO reqPlugDTO = new TenantMenuListReqDTO();
            reqPlugDTO.setStatus(CommonStatusEnum.ENABLE.getStatus());
            reqPlugDTO.setDimension(CommonConstants.MenuDimensionEnum.PLUG.getCode());
            reqPlugDTO.setPlugIds(plugAppIds);
            menus.addAll(tenantMenuApi.getTenantMenuList(reqPlugDTO));
        }
        return menus;
    }

    @Override
    public List<TenantMenuRespDTO> getMenuListSimpleByTenant(TenantMenuListReqDTO reqDTO) {
        return tenantMenuApi.getTenantMenuList(reqDTO);
    }

}
