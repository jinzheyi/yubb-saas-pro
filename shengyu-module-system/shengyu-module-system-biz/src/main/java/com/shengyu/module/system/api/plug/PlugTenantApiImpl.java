package com.shengyu.module.system.api.plug;

import com.shengyu.module.system.api.plug.dto.tenant.PlugAppEnableReqDTO;
import com.shengyu.module.system.service.plug.PlugTenantService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

/**
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2023/4/15 15:28
 */
@Service
public class PlugTenantApiImpl implements PlugTenantApi {

    @Resource
    private PlugTenantService plugTenantService;

    @Override
    public boolean hasAllPlugApp(Long userId, String... plugAppSn) {
        return plugTenantService.hasAllPlugApp(userId, plugAppSn);
    }

    @Override
    public boolean enableTenantApp(PlugAppEnableReqDTO reqDTO) {
        return plugTenantService.enableTenantApp(reqDTO);
    }

}
