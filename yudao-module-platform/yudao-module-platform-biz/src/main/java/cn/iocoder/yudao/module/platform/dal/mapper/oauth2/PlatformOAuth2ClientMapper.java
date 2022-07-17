package cn.iocoder.yudao.module.platform.dal.mapper.oauth2;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.client.OAuth2ClientPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.OAuth2ClientDO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.Date;

/**
 * OAuth2 客户端 Mapper
 *
 * @author 芋道源码
 */
@Mapper
public interface PlatformOAuth2ClientMapper extends BaseMapperX<OAuth2ClientDO> {

    default PageResult<OAuth2ClientDO> selectPage(OAuth2ClientPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<OAuth2ClientDO>()
                .likeIfPresent(OAuth2ClientDO::getName, reqVO.getName())
                .eqIfPresent(OAuth2ClientDO::getStatus, reqVO.getStatus())
                .orderByDesc(OAuth2ClientDO::getId));
    }

    default OAuth2ClientDO selectByClientId(String clientId) {
        return selectOne(OAuth2ClientDO::getClientId, clientId);
    }

    // TODO 改成Java对象形式调用
    //@Select("SELECT COUNT(*) FROM system_oauth2_client WHERE update_time > #{maxUpdateTime}")
    default Long selectCountByUpdateTimeGt(Date maxUpdateTime) {
        return selectCount(new LambdaQueryWrapperX<OAuth2ClientDO>()
                .gt(OAuth2ClientDO::getUpdateTime, maxUpdateTime));
    };

}
