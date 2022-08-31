package cn.iocoder.yudao.module.system.convert.config;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.system.api.config.dto.ConfigurationCreateReqDTO;
import cn.iocoder.yudao.module.system.controller.admin.config.vo.ConfigCreateOrDelReqVO;
import cn.iocoder.yudao.module.system.controller.admin.config.vo.ConfigRespVO;
import cn.iocoder.yudao.module.system.controller.admin.config.vo.ConfigUpdateReqVO;
import cn.iocoder.yudao.module.system.dal.dataobject.config.ConfigurationDO;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface ConfigurationConvert {

    ConfigurationConvert INSTANCE = Mappers.getMapper(ConfigurationConvert.class);

    List<ConfigCreateOrDelReqVO> convertList(List<ConfigurationCreateReqDTO> list);

    ConfigurationDO convert(ConfigCreateOrDelReqVO bean);

    ConfigurationDO convert(ConfigUpdateReqVO bean);

    PageResult<ConfigRespVO> convertPage(PageResult<ConfigurationDO> page);

    @Mapping(source = "configKey", target = "key")
    ConfigRespVO convert(ConfigurationDO bean);

}
