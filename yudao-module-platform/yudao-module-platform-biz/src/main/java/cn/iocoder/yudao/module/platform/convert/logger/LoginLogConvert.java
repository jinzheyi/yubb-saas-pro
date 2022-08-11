package cn.iocoder.yudao.module.platform.convert.logger;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.api.logger.dto.LoginLogCreateReqDTO;
import cn.iocoder.yudao.module.platform.controller.center.logger.vo.loginlog.LoginLogExcelVO;
import cn.iocoder.yudao.module.platform.controller.center.logger.vo.loginlog.LoginLogRespVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.logger.PlatformLoginLogDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface LoginLogConvert {

    LoginLogConvert INSTANCE = Mappers.getMapper(LoginLogConvert.class);

    PageResult<LoginLogRespVO> convertPage(PageResult<PlatformLoginLogDO> page);

    List<LoginLogExcelVO> convertList(List<PlatformLoginLogDO> list);

    PlatformLoginLogDO convert(LoginLogCreateReqDTO bean);

}
