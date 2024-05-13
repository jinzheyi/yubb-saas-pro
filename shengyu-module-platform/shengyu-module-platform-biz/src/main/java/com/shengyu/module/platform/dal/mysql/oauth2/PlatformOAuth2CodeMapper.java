package com.shengyu.module.platform.dal.mysql.oauth2;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.platform.dal.dataobject.oauth2.PlatformOAuth2CodeDO;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface PlatformOAuth2CodeMapper extends BaseMapperX<PlatformOAuth2CodeDO> {

    default PlatformOAuth2CodeDO selectByCode(String code) {
        return selectOne(PlatformOAuth2CodeDO::getCode, code);
    }

}
