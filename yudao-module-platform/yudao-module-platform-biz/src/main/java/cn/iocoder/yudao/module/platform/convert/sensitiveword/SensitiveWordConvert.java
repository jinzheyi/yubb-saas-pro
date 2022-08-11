package cn.iocoder.yudao.module.platform.convert.sensitiveword;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.sensitiveword.vo.SensitiveWordCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.sensitiveword.vo.SensitiveWordExcelVO;
import cn.iocoder.yudao.module.platform.controller.center.sensitiveword.vo.SensitiveWordRespVO;
import cn.iocoder.yudao.module.platform.controller.center.sensitiveword.vo.SensitiveWordUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.sensitiveword.PlatformSensitiveWordDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

/**
 * 敏感词 Convert
 *
 * @author 永不言败
 */
@Mapper
public interface SensitiveWordConvert {

    SensitiveWordConvert INSTANCE = Mappers.getMapper(SensitiveWordConvert.class);

    PlatformSensitiveWordDO convert(SensitiveWordCreateReqVO bean);

    PlatformSensitiveWordDO convert(SensitiveWordUpdateReqVO bean);

    SensitiveWordRespVO convert(PlatformSensitiveWordDO bean);

    List<SensitiveWordRespVO> convertList(List<PlatformSensitiveWordDO> list);

    PageResult<SensitiveWordRespVO> convertPage(PageResult<PlatformSensitiveWordDO> page);

    List<SensitiveWordExcelVO> convertList02(List<PlatformSensitiveWordDO> list);

}
