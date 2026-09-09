package com.shengyu.module.system.service.register;

import com.shengyu.module.system.controller.admin.auth.vo.AuthLoginRespVO;
import com.shengyu.module.system.controller.app.register.vo.AppTrialTenantRegisterReqVO;

/**
 * App 注册 Service 接口
 *
 * @author 圣钰科技
 */
public interface AppRegisterService {

    /**
     * 创建企业并返回登录态。
     *
     * @param reqVO 注册信息
     * @return 登录结果
     */
    AuthLoginRespVO registerTenant(AppTrialTenantRegisterReqVO reqVO);

}
