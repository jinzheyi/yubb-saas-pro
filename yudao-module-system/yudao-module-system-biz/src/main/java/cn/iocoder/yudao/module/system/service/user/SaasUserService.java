package cn.iocoder.yudao.module.system.service.user;

import cn.iocoder.yudao.module.system.dal.dataobject.user.SaasUserDO;

/**
 * @author zhusy
 * @description: 后台SaaS用户接口
 * @date 2024/3/17 23:24
 */
public interface SaasUserService {

    /**
     * 通过用户名查询用户
     *
     * @param account 账户名
     * @return 用户对象信息
     */
    SaasUserDO getUserByAccount(String account);

    /**
     * 判断密码是否匹配
     *
     * @param rawPassword 未加密的密码
     * @param encodedPassword 加密后的密码
     * @return 是否匹配
     */
    boolean isPasswordMatch(String rawPassword, String encodedPassword);

    /**
     * 通过用户 ID 查询用户
     *
     * @param id 用户ID
     * @return 用户对象信息
     */
    SaasUserDO getUser(Long id);

}
