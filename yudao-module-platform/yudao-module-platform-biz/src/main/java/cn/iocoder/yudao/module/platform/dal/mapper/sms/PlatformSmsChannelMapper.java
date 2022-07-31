package cn.iocoder.yudao.module.platform.dal.mapper.sms;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.channel.SmsChannelPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.sms.PlatformSmsChannelDO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.Date;

@Mapper
public interface PlatformSmsChannelMapper extends BaseMapperX<PlatformSmsChannelDO> {

    default PageResult<PlatformSmsChannelDO> selectPage(SmsChannelPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlatformSmsChannelDO>()
                .likeIfPresent(PlatformSmsChannelDO::getSignature, reqVO.getSignature())
                .eqIfPresent(PlatformSmsChannelDO::getStatus, reqVO.getStatus())
                .betweenIfPresent(PlatformSmsChannelDO::getCreateTime, reqVO.getBeginCreateTime(), reqVO.getEndCreateTime())
                .orderByDesc(PlatformSmsChannelDO::getId));
    }

    @Select("SELECT COUNT(*) FROM platform_sms_channel WHERE update_time > #{maxUpdateTime}")
    Long selectCountByUpdateTimeGt(Date maxUpdateTime);

}
