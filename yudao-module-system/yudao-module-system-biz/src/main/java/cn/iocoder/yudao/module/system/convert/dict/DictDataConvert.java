package cn.iocoder.yudao.module.system.convert.dict;

import cn.iocoder.yudao.module.platform.api.dict.dto.DictDataSimpleRespDTO;
import cn.iocoder.yudao.module.system.controller.admin.dict.vo.data.DictDataSimpleRespVO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface DictDataConvert {

    DictDataConvert INSTANCE = Mappers.getMapper(DictDataConvert.class);

    List<DictDataSimpleRespVO> convertList(List<DictDataSimpleRespDTO> list);

}
