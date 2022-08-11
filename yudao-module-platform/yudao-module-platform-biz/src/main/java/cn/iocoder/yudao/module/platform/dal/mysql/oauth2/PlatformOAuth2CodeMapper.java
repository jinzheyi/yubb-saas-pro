package cn.iocoder.yudao.module.platform.dal.mysql.oauth2;

import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2CodeDO;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface PlatformOAuth2CodeMapper extends BaseMapperX<PlatformOAuth2CodeDO> {

    default PlatformOAuth2CodeDO selectByCode(String code) {
        return selectOne(PlatformOAuth2CodeDO::getCode, code);
    }

}
