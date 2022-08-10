package cn.iocoder.yudao.module.platform.convert.sms;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.sms.core.property.SmsChannelProperties;
import cn.iocoder.yudao.module.platform.api.sms.dto.channel.SmsChannelRespDTO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.channel.SmsChannelCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.channel.SmsChannelRespVO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.channel.SmsChannelSimpleRespVO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.channel.SmsChannelUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.sms.SmsChannelDO;
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

    SmsChannelDO convert(SmsChannelCreateReqVO bean);

    SmsChannelDO convert(SmsChannelUpdateReqVO bean);

    SmsChannelRespVO convert(SmsChannelDO bean);

    List<SmsChannelRespVO> convertList(List<SmsChannelDO> list);

    PageResult<SmsChannelRespVO> convertPage(PageResult<SmsChannelDO> page);

    List<SmsChannelProperties> convertList02(List<SmsChannelDO> list);

    List<SmsChannelSimpleRespVO> convertList03(List<SmsChannelDO> list);

    List<SmsChannelRespDTO> convertDTOList(List<SmsChannelDO> list);

}
