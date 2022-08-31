package cn.iocoder.yudao.module.system.convert.config;

import cn.iocoder.yudao.module.system.api.config.dto.ConfigurationCreateReqDTO;
import cn.iocoder.yudao.module.system.controller.admin.config.vo.ConfigCreateReqVO;
import cn.iocoder.yudao.module.system.dal.dataobject.config.ConfigurationDO;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface ConfigurationConvert {

    ConfigurationConvert INSTANCE = Mappers.getMapper(ConfigurationConvert.class);

    List<ConfigCreateReqVO> convertList(List<ConfigurationCreateReqDTO> list);

    @Mapping(source = "key", target = "configKey")
    ConfigurationDO convert(ConfigCreateReqVO bean);

}
