package cn.iocoder.yudao.module.platform.dal.mysql.oauth2;

import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2RefreshTokenDO;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface PlatformOAuth2RefreshTokenMapper extends BaseMapperX<PlatformOAuth2RefreshTokenDO> {

    default int deleteByRefreshToken(String refreshToken) {
        return delete(new LambdaQueryWrapperX<PlatformOAuth2RefreshTokenDO>()
                .eq(PlatformOAuth2RefreshTokenDO::getRefreshToken, refreshToken));
    }

    default PlatformOAuth2RefreshTokenDO selectByRefreshToken(String refreshToken) {
        return selectOne(PlatformOAuth2RefreshTokenDO::getRefreshToken, refreshToken);
    }

}
