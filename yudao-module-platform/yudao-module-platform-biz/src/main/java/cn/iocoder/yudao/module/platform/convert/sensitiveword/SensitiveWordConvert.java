package cn.iocoder.yudao.module.platform.convert.sensitiveword;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.sensitiveword.vo.SensitiveWordCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.sensitiveword.vo.SensitiveWordExcelVO;
import cn.iocoder.yudao.module.platform.controller.center.sensitiveword.vo.SensitiveWordRespVO;
import cn.iocoder.yudao.module.platform.controller.center.sensitiveword.vo.SensitiveWordUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.sensitiveword.SensitiveWordDO;
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

    SensitiveWordDO convert(SensitiveWordCreateReqVO bean);

    SensitiveWordDO convert(SensitiveWordUpdateReqVO bean);

    SensitiveWordRespVO convert(SensitiveWordDO bean);

    List<SensitiveWordRespVO> convertList(List<SensitiveWordDO> list);

    PageResult<SensitiveWordRespVO> convertPage(PageResult<SensitiveWordDO> page);

    List<SensitiveWordExcelVO> convertList02(List<SensitiveWordDO> list);

}
