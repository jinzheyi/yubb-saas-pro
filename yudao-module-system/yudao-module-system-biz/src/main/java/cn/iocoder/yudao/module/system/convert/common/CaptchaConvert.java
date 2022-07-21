package cn.iocoder.yudao.module.system.convert.common;

import cn.iocoder.yudao.module.base.api.common.dto.CaptchaImageRespDTO;
import cn.iocoder.yudao.module.system.controller.admin.common.vo.CaptchaImageRespVO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

@Mapper
public interface CaptchaConvert {

    CaptchaConvert INSTANCE = Mappers.getMapper(CaptchaConvert.class);

    CaptchaImageRespVO convert(CaptchaImageRespDTO bean);

}
