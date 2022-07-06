package cn.iocoder.yudao.module.platform.service.auth;

import cn.iocoder.yudao.module.platform.controller.center.auth.vo.AuthLoginReqVO;
import cn.iocoder.yudao.module.platform.controller.center.auth.vo.AuthLoginRespVO;

import javax.validation.Valid;

/**
 * 管理平台的认证 Service 接口
 *
 * 提供平台用户的登录、登出的能力
 * @author 朱述勇
 */
public interface PlatformAuthService {

    /**
     * 账号登录
     *
     * @param reqVO 登录信息
     * @return 登录结果
     */
    AuthLoginRespVO login(@Valid AuthLoginReqVO reqVO);

}
