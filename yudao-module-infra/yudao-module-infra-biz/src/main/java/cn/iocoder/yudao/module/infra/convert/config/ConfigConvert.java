package cn.iocoder.yudao.module.infra.convert.config;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.infra.controller.center.config.vo.ConfigCreateReqVO;
import cn.iocoder.yudao.module.infra.controller.center.config.vo.ConfigExcelVO;
import cn.iocoder.yudao.module.infra.controller.center.config.vo.ConfigRespVO;
import cn.iocoder.yudao.module.infra.controller.center.config.vo.ConfigUpdateReqVO;
import cn.iocoder.yudao.module.infra.dal.dataobject.config.ConfigDO;
import cn.iocoder.yudao.module.system.api.config.dto.ConfigurationCreateReqDTO;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface ConfigConvert {

    ConfigConvert INSTANCE = Mappers.getMapper(ConfigConvert.class);

    PageResult<ConfigRespVO> convertPage(PageResult<ConfigDO> page);

    @Mapping(source = "configKey", target = "key")
    ConfigRespVO convert(ConfigDO bean);

    @Mapping(source = "key", target = "configKey")
    ConfigDO convert(ConfigCreateReqVO bean);

    ConfigDO convert(ConfigUpdateReqVO bean);

    @Mapping(source = "configKey", target = "key")
    List<ConfigExcelVO> convertList(List<ConfigDO> list);

    @Mapping(source = "id", target = "configId")
    List<ConfigurationCreateReqDTO> convertListDTO(List<ConfigDO> list);

}
