package cn.iocoder.yudao.module.platform.convert.notice;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.notice.vo.NoticeCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.notice.vo.NoticeRespVO;
import cn.iocoder.yudao.module.platform.controller.center.notice.vo.NoticeUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.notice.PlatformNoticeDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

@Mapper
public interface NoticeConvert {

    NoticeConvert INSTANCE = Mappers.getMapper(NoticeConvert.class);

    PageResult<NoticeRespVO> convertPage(PageResult<PlatformNoticeDO> page);

    NoticeRespVO convert(PlatformNoticeDO bean);

    PlatformNoticeDO convert(NoticeUpdateReqVO bean);

    PlatformNoticeDO convert(NoticeCreateReqVO bean);

}
