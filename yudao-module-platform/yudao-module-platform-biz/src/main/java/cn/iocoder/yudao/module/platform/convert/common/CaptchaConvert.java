package cn.iocoder.yudao.module.platform.convert.common;

import cn.iocoder.yudao.module.platform.controller.center.common.vo.CaptchaImageRespVO;
import cn.iocoder.yudao.module.system.api.common.dto.CaptchaImageRespDTO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

/**
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2022/7/7 0:08
 */
@Mapper
public interface CaptchaConvert {

    CaptchaConvert INSTANCE = Mappers.getMapper(CaptchaConvert.class);

    CaptchaImageRespVO convert(CaptchaImageRespDTO bean);

}
