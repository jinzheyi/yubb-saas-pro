package com.shengyu.module.system.service.register;

import com.shengyu.module.system.controller.app.register.vo.AppTrialTenantRegisterReqVO;
import com.shengyu.module.system.controller.app.register.vo.AppRegisterResultRespVO;
import com.shengyu.module.system.controller.app.register.vo.AppTenantJoinByInviteReqVO;

/**
 * App 注册 Service 接口
 *
 * @author 圣钰科技
 */
public interface AppRegisterService {

    /**
     * 邮箱验证后创建企业。首次账号的初始密码由邮件发送，已有账号不会被改密。
     *
     * @param reqVO 注册信息
     * @return 登录结果
     */
    AppRegisterResultRespVO registerTenant(AppTrialTenantRegisterReqVO reqVO);

    /** 通过邀请码和邮箱验证码加入企业。 */
    AppRegisterResultRespVO joinByInvite(AppTenantJoinByInviteReqVO reqVO);

}
