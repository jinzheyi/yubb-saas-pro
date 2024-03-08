package cn.iocoder.yudao.module.platform.convert.logger;

import cn.iocoder.yudao.framework.common.util.collection.CollectionUtils;
import cn.iocoder.yudao.framework.common.util.collection.MapUtils;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.module.platform.controller.platform.logger.vo.operatelog.OperateLogRespVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.logger.PlatformOperateLogDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.user.PlatformUserDO;
import java.util.List;
import java.util.Map;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

@Mapper
public interface OperateLogConvert {

    OperateLogConvert INSTANCE = Mappers.getMapper(OperateLogConvert.class);

    default List<OperateLogRespVO> convertList(List<PlatformOperateLogDO> list, Map<Long, PlatformUserDO> userMap) {
        return CollectionUtils.convertList(list, log -> {
            OperateLogRespVO logVO = BeanUtils.toBean(log, OperateLogRespVO.class);
            MapUtils.findAndThen(userMap, log.getUserId(), user -> logVO.setUserNickname(user.getNickname()));
            return logVO;
        });
    }

}
