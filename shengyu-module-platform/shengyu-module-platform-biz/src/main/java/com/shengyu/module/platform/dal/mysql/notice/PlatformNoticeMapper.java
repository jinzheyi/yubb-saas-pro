package com.shengyu.module.platform.dal.mysql.notice;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.platform.controller.platform.notice.vo.NoticePageReqVO;
import com.shengyu.module.platform.dal.dataobject.notice.PlatformNoticeDO;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface PlatformNoticeMapper extends BaseMapperX<PlatformNoticeDO> {

    default PageResult<PlatformNoticeDO> selectPage(NoticePageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlatformNoticeDO>()
                .likeIfPresent(PlatformNoticeDO::getTitle, reqVO.getTitle())
                .eqIfPresent(PlatformNoticeDO::getStatus, reqVO.getStatus())
                .orderByDesc(PlatformNoticeDO::getCreateTime));
    }

}
