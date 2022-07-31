package cn.iocoder.yudao.module.platform.convert.sms;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.template.SmsTemplateCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.template.SmsTemplateExcelVO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.template.SmsTemplateRespVO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.template.SmsTemplateUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.sms.PlatformSmsTemplateDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface SmsTemplateConvert {

    SmsTemplateConvert INSTANCE = Mappers.getMapper(SmsTemplateConvert.class);

    PlatformSmsTemplateDO convert(SmsTemplateCreateReqVO bean);

    PlatformSmsTemplateDO convert(SmsTemplateUpdateReqVO bean);

    SmsTemplateRespVO convert(PlatformSmsTemplateDO bean);

    List<SmsTemplateRespVO> convertList(List<PlatformSmsTemplateDO> list);

    PageResult<SmsTemplateRespVO> convertPage(PageResult<PlatformSmsTemplateDO> page);

    List<SmsTemplateExcelVO> convertList02(List<PlatformSmsTemplateDO> list);

}
