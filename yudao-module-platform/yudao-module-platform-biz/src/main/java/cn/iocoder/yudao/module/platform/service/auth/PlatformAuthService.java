package cn.iocoder.yudao.module.platform.service.auth;

import cn.iocoder.yudao.module.platform.controller.center.auth.vo.AuthLoginReqVO;
import cn.iocoder.yudao.module.platform.controller.center.auth.vo.AuthLoginRespVO;

import javax.validation.Valid;

/**
 * 平台管理的认证 Service 接口
 *
 * @author 朱述勇
 * @since 2022/7/7 2:13 PM
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
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
