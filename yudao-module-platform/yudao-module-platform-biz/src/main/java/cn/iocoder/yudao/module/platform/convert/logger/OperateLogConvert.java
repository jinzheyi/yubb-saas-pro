package cn.iocoder.yudao.module.platform.convert.logger;

import cn.iocoder.yudao.module.platform.controller.center.logger.vo.operatelog.OperateLogExcelVO;
import cn.iocoder.yudao.module.platform.controller.center.logger.vo.operatelog.OperateLogRespVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.logger.PlatformOperateLogDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.user.PlatformUserDO;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.collection.MapUtils;
import cn.iocoder.yudao.module.platform.api.logger.dto.PlatformOperateLogCreateReqDTO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static cn.iocoder.yudao.framework.common.exception.enums.GlobalErrorCodeConstants.SUCCESS;

@Mapper
public interface OperateLogConvert {

    OperateLogConvert INSTANCE = Mappers.getMapper(OperateLogConvert.class);

    PlatformOperateLogDO convert(PlatformOperateLogCreateReqDTO bean);

    PageResult<OperateLogRespVO> convertPage(PageResult<PlatformOperateLogDO> page);

    OperateLogRespVO convert(PlatformOperateLogDO bean);

    default List<OperateLogExcelVO> convertList(List<PlatformOperateLogDO> list, Map<Long, PlatformUserDO> userMap) {
        return list.stream().map(operateLog -> {
            OperateLogExcelVO excelVO = convert02(operateLog);
            MapUtils.findAndThen(userMap, operateLog.getUserId(), user -> excelVO.setUserNickname(user.getNickname()));
            excelVO.setSuccessStr(SUCCESS.getCode().equals(operateLog.getResultCode()) ? "成功" : "失败");
            return excelVO;
        }).collect(Collectors.toList());
    }

    OperateLogExcelVO convert02(PlatformOperateLogDO bean);

}
