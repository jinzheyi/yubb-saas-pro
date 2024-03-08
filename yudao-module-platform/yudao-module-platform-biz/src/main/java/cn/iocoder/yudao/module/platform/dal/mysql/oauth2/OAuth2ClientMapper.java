package cn.iocoder.yudao.module.platform.dal.mysql.oauth2;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.platform.oauth2.vo.client.OAuth2ClientPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2ClientDO;
import org.apache.ibatis.annotations.Mapper;


/**
 * OAuth2 客户端 Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface OAuth2ClientMapper extends BaseMapperX<PlatformOAuth2ClientDO> {

    default PageResult<PlatformOAuth2ClientDO> selectPage(OAuth2ClientPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlatformOAuth2ClientDO>()
                .likeIfPresent(PlatformOAuth2ClientDO::getName, reqVO.getName())
                .eqIfPresent(PlatformOAuth2ClientDO::getStatus, reqVO.getStatus())
                .orderByDesc(PlatformOAuth2ClientDO::getId));
    }

    default PlatformOAuth2ClientDO selectByClientId(String clientId) {
        return selectOne(PlatformOAuth2ClientDO::getClientId, clientId);
    }

}
