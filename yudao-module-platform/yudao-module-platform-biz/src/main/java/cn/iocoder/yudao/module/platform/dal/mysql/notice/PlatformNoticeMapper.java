package cn.iocoder.yudao.module.platform.dal.mysql.notice;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.center.notice.vo.NoticePageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.notice.PlatformNoticeDO;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface PlatformNoticeMapper extends BaseMapperX<PlatformNoticeDO> {

    default PageResult<PlatformNoticeDO> selectPage(NoticePageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlatformNoticeDO>()
                .likeIfPresent(PlatformNoticeDO::getTitle, reqVO.getTitle())
                .eqIfPresent(PlatformNoticeDO::getStatus, reqVO.getStatus())
                .orderByDesc(PlatformNoticeDO::getId));
    }

}
