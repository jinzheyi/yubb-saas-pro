package com.shengyu.module.platform.dal.mysql.oauth2;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.platform.dal.dataobject.oauth2.PlatformOAuth2ApproveDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface PlatformOAuth2ApproveMapper extends BaseMapperX<PlatformOAuth2ApproveDO> {

    default int update(PlatformOAuth2ApproveDO updateObj) {
        return update(updateObj, new LambdaQueryWrapperX<PlatformOAuth2ApproveDO>()
                .eq(PlatformOAuth2ApproveDO::getUserId, updateObj.getUserId())
                .eq(PlatformOAuth2ApproveDO::getUserType, updateObj.getUserType())
                .eq(PlatformOAuth2ApproveDO::getClientId, updateObj.getClientId())
                .eq(PlatformOAuth2ApproveDO::getScope, updateObj.getScope()));
    }

    default List<PlatformOAuth2ApproveDO> selectListByUserIdAndUserTypeAndClientId(Long userId, Integer userType, String clientId) {
        return selectList(new LambdaQueryWrapperX<PlatformOAuth2ApproveDO>()
                .eq(PlatformOAuth2ApproveDO::getUserId, userId)
                .eq(PlatformOAuth2ApproveDO::getUserType, userType)
                .eq(PlatformOAuth2ApproveDO::getClientId, clientId));
    }

}
