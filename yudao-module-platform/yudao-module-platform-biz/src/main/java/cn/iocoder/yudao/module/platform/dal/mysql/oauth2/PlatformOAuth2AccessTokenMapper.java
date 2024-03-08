package cn.iocoder.yudao.module.platform.dal.mysql.oauth2;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.platform.oauth2.vo.token.OAuth2AccessTokenPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2AccessTokenDO;
import org.apache.ibatis.annotations.Mapper;

import java.time.LocalDateTime;
import java.util.List;

@Mapper
public interface PlatformOAuth2AccessTokenMapper extends BaseMapperX<PlatformOAuth2AccessTokenDO> {

    default PlatformOAuth2AccessTokenDO selectByAccessToken(String accessToken) {
        return selectOne(PlatformOAuth2AccessTokenDO::getAccessToken, accessToken);
    }

    default List<PlatformOAuth2AccessTokenDO> selectListByRefreshToken(String refreshToken) {
        return selectList(PlatformOAuth2AccessTokenDO::getRefreshToken, refreshToken);
    }

    default PageResult<PlatformOAuth2AccessTokenDO> selectPage(OAuth2AccessTokenPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlatformOAuth2AccessTokenDO>()
                .eqIfPresent(PlatformOAuth2AccessTokenDO::getUserId, reqVO.getUserId())
                .eqIfPresent(PlatformOAuth2AccessTokenDO::getUserType, reqVO.getUserType())
                .likeIfPresent(PlatformOAuth2AccessTokenDO::getClientId, reqVO.getClientId())
                .gt(PlatformOAuth2AccessTokenDO::getExpiresTime, LocalDateTime.now())
                .orderByDesc(PlatformOAuth2AccessTokenDO::getId));
    }

}
