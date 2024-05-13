package com.shengyu.module.system.dal.mysql.user;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.user.SaasUserDO;
import org.apache.ibatis.annotations.Mapper;

/**
 * @author zhusy
 * @description: 所属SaaS用户持久层
 * @date 2024/3/17 23:02
 */
@Mapper
public interface SaasUserMapper extends BaseMapperX<SaasUserDO> {

    default SaasUserDO selectByUsername(String username) {
        return selectOne(SaasUserDO::getUsername, username);
    }

    default SaasUserDO selectByMobile(String mobile) {
        return selectOne(SaasUserDO::getMobile, mobile);
    }

}
