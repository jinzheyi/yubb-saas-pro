package cn.iocoder.yudao.module.platform.convert.sms;

import cn.iocoder.yudao.module.platform.controller.admin.sms.vo.log.SmsLogExcelVO;
import cn.iocoder.yudao.module.platform.controller.admin.sms.vo.log.SmsLogRespVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.sms.SmsLogDO;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

/**
 * 短信日志 Convert
 *
 * @author 芋道源码
 */
@Mapper
public interface SmsLogConvert {

    SmsLogConvert INSTANCE = Mappers.getMapper(SmsLogConvert.class);

    SmsLogRespVO convert(SmsLogDO bean);

    List<SmsLogRespVO> convertList(List<SmsLogDO> list);

    PageResult<SmsLogRespVO> convertPage(PageResult<SmsLogDO> page);

    List<SmsLogExcelVO> convertList02(List<SmsLogDO> list);

}
