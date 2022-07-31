package cn.iocoder.yudao.module.platform.service.auth;

import cn.iocoder.yudao.module.platform.controller.center.auth.vo.*;
import cn.iocoder.yudao.module.platform.dal.dataobject.user.PlatformUserDO;

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
     * 验证账号 + 密码。如果通过，则返回用户
     *
     * @param username 账号
     * @param password 密码
     * @return 用户
     */
    PlatformUserDO authenticate(String username, String password);

    /**
     * 账号登录
     *
     * @param reqVO 登录信息
     * @return 登录结果
     */
    AuthLoginRespVO login(@Valid AuthLoginReqVO reqVO);

    /**
     * 基于 token 退出登录
     *
     * @param token token
     * @param logType 登出类型
     */
    void logout(String token, Integer logType);

    /**
     * 短信验证码发送
     *
     * @param reqVO 发送请求
     */
    void sendSmsCode(AuthSmsSendReqVO reqVO);

    /**
     * 短信登录
     *
     * @param reqVO 登录信息
     * @return 登录结果
     */
    AuthLoginRespVO smsLogin(AuthSmsLoginReqVO reqVO) ;

//    /**
//     * 社交快捷登录，使用 code 授权码
//     *
//     * @param reqVO 登录信息
//     * @return 登录结果
//     */
//    AuthLoginRespVO socialQuickLogin(@Valid AuthSocialQuickLoginReqVO reqVO);
//
//    /**
//     * 社交绑定登录，使用 code 授权码 + 账号密码
//     *
//     * @param reqVO 登录信息
//     * @return 登录结果
//     */
//    AuthLoginRespVO socialBindLogin(@Valid AuthSocialBindLoginReqVO reqVO);

    /**
     * 刷新访问令牌
     *
     * @param refreshToken 刷新令牌
     * @return 登录结果
     */
    AuthLoginRespVO refreshToken(String refreshToken);

}
