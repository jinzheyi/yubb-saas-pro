package cn.iocoder.yudao.module.platform.convert.sms;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.sms.core.property.SmsChannelProperties;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.channel.SmsChannelCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.channel.SmsChannelRespVO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.channel.SmsChannelSimpleRespVO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.channel.SmsChannelUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.sms.PlatformSmsChannelDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

/**
 * 短信渠道 Convert
 *
 * @author 芋道源码
 */
@Mapper
public interface SmsChannelConvert {

    SmsChannelConvert INSTANCE = Mappers.getMapper(SmsChannelConvert.class);

    PlatformSmsChannelDO convert(SmsChannelCreateReqVO bean);

    PlatformSmsChannelDO convert(SmsChannelUpdateReqVO bean);

    SmsChannelRespVO convert(PlatformSmsChannelDO bean);

    List<SmsChannelRespVO> convertList(List<PlatformSmsChannelDO> list);

    PageResult<SmsChannelRespVO> convertPage(PageResult<PlatformSmsChannelDO> page);

    List<SmsChannelProperties> convertList02(List<PlatformSmsChannelDO> list);

    List<SmsChannelSimpleRespVO> convertList03(List<PlatformSmsChannelDO> list);

}
