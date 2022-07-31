package cn.iocoder.yudao.module.platform.dal.mapper.sms;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.log.SmsLogExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.log.SmsLogPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.sms.PlatformSmsLogDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface PlatformSmsLogMapper extends BaseMapperX<PlatformSmsLogDO> {

    default PageResult<PlatformSmsLogDO> selectPage(SmsLogPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlatformSmsLogDO>()
                .eqIfPresent(PlatformSmsLogDO::getChannelId, reqVO.getChannelId())
                .eqIfPresent(PlatformSmsLogDO::getTemplateId, reqVO.getTemplateId())
                .likeIfPresent(PlatformSmsLogDO::getMobile, reqVO.getMobile())
                .eqIfPresent(PlatformSmsLogDO::getSendStatus, reqVO.getSendStatus())
                .betweenIfPresent(PlatformSmsLogDO::getSendTime, reqVO.getBeginSendTime(), reqVO.getEndSendTime())
                .eqIfPresent(PlatformSmsLogDO::getReceiveStatus, reqVO.getReceiveStatus())
                .betweenIfPresent(PlatformSmsLogDO::getReceiveTime, reqVO.getBeginReceiveTime(), reqVO.getEndReceiveTime())
                .orderByDesc(PlatformSmsLogDO::getId));
    }

    default List<PlatformSmsLogDO> selectList(SmsLogExportReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<PlatformSmsLogDO>()
                .eqIfPresent(PlatformSmsLogDO::getChannelId, reqVO.getChannelId())
                .eqIfPresent(PlatformSmsLogDO::getTemplateId, reqVO.getTemplateId())
                .likeIfPresent(PlatformSmsLogDO::getMobile, reqVO.getMobile())
                .eqIfPresent(PlatformSmsLogDO::getSendStatus, reqVO.getSendStatus())
                .betweenIfPresent(PlatformSmsLogDO::getSendTime, reqVO.getBeginSendTime(), reqVO.getEndSendTime())
                .eqIfPresent(PlatformSmsLogDO::getReceiveStatus, reqVO.getReceiveStatus())
                .betweenIfPresent(PlatformSmsLogDO::getReceiveTime, reqVO.getBeginReceiveTime(), reqVO.getEndReceiveTime())
                .orderByDesc(PlatformSmsLogDO::getId));
    }

}
