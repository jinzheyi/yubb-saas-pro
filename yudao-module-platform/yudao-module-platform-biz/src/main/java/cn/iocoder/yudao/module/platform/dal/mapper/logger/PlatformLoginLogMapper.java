package cn.iocoder.yudao.module.platform.dal.mapper.logger;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.center.logger.vo.loginlog.LoginLogExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.logger.vo.loginlog.LoginLogPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.logger.PlatformLoginLogDO;
import cn.iocoder.yudao.module.platform.enums.logger.PlatformLoginResultEnum;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface PlatformLoginLogMapper extends BaseMapperX<PlatformLoginLogDO> {

    default PageResult<PlatformLoginLogDO> selectPage(LoginLogPageReqVO reqVO) {
        LambdaQueryWrapperX<PlatformLoginLogDO> query = new LambdaQueryWrapperX<PlatformLoginLogDO>()
                .likeIfPresent(PlatformLoginLogDO::getUserIp, reqVO.getUserIp())
                .likeIfPresent(PlatformLoginLogDO::getUsername, reqVO.getUsername())
                .betweenIfPresent(PlatformLoginLogDO::getCreateTime, reqVO.getBeginTime(), reqVO.getEndTime());
        if (Boolean.TRUE.equals(reqVO.getStatus())) {
            query.eq(PlatformLoginLogDO::getResult, PlatformLoginResultEnum.SUCCESS.getResult());
        } else if (Boolean.FALSE.equals(reqVO.getStatus())) {
            query.gt(PlatformLoginLogDO::getResult, PlatformLoginResultEnum.SUCCESS.getResult());
        }
        query.orderByDesc(PlatformLoginLogDO::getId); // 降序
        return selectPage(reqVO, query);
    }

    default List<PlatformLoginLogDO> selectList(LoginLogExportReqVO reqVO) {
        LambdaQueryWrapperX<PlatformLoginLogDO> query = new LambdaQueryWrapperX<PlatformLoginLogDO>()
                .likeIfPresent(PlatformLoginLogDO::getUserIp, reqVO.getUserIp())
                .likeIfPresent(PlatformLoginLogDO::getUsername, reqVO.getUsername())
                .betweenIfPresent(PlatformLoginLogDO::getCreateTime, reqVO.getBeginTime(), reqVO.getEndTime());
        if (Boolean.TRUE.equals(reqVO.getStatus())) {
            query.eq(PlatformLoginLogDO::getResult, PlatformLoginResultEnum.SUCCESS.getResult());
        } else if (Boolean.FALSE.equals(reqVO.getStatus())) {
            query.gt(PlatformLoginLogDO::getResult, PlatformLoginResultEnum.SUCCESS.getResult());
        }
        query.orderByDesc(PlatformLoginLogDO::getId); // 降序
        return selectList(query);
    }

}
