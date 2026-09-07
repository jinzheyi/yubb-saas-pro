package com.shengyu.module.platform.dal.mysql.apprelease;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.platform.controller.platform.apprelease.vo.PlatformAppReleasePageReqVO;
import com.shengyu.module.platform.dal.dataobject.apprelease.PlatformAppReleaseDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface PlatformAppReleaseMapper extends BaseMapperX<PlatformAppReleaseDO> {

    default PageResult<PlatformAppReleaseDO> selectPage(PlatformAppReleasePageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlatformAppReleaseDO>()
                .eqIfPresent(PlatformAppReleaseDO::getAppKey, reqVO.getAppKey())
                .eqIfPresent(PlatformAppReleaseDO::getPlatform, reqVO.getPlatform())
                .eqIfPresent(PlatformAppReleaseDO::getChannel, reqVO.getChannel())
                .eqIfPresent(PlatformAppReleaseDO::getUpdateType, reqVO.getUpdateType())
                .eqIfPresent(PlatformAppReleaseDO::getStatus, reqVO.getStatus())
                .likeIfPresent(PlatformAppReleaseDO::getVersionName, reqVO.getVersionName())
                .orderByDesc(PlatformAppReleaseDO::getCreateTime));
    }

    default PlatformAppReleaseDO selectByVersion(String appKey, String platform, String channel, Integer versionCode) {
        return selectOne(new LambdaQueryWrapperX<PlatformAppReleaseDO>()
                .eq(PlatformAppReleaseDO::getAppKey, appKey)
                .eq(PlatformAppReleaseDO::getPlatform, platform)
                .eq(PlatformAppReleaseDO::getChannel, channel)
                .eq(PlatformAppReleaseDO::getVersionCode, versionCode));
    }

    default PlatformAppReleaseDO selectLatestPublished(String appKey, String platform, String channel) {
        List<PlatformAppReleaseDO> releases = selectList(new LambdaQueryWrapperX<PlatformAppReleaseDO>()
                .eq(PlatformAppReleaseDO::getAppKey, appKey)
                .eq(PlatformAppReleaseDO::getPlatform, platform)
                .eq(PlatformAppReleaseDO::getChannel, channel)
                .eq(PlatformAppReleaseDO::getStatus, "PUBLISHED")
                .orderByDesc(PlatformAppReleaseDO::getVersionCode)
                .last("LIMIT 1"));
        return releases.isEmpty() ? null : releases.get(0);
    }

}
