package cn.iocoder.yudao.module.platform.dal.mapper.logger;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.QueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.center.logger.vo.loginlog.LoginLogExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.logger.vo.loginlog.LoginLogPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.logger.LoginLogDO;
import cn.iocoder.yudao.module.platform.enums.logger.PlatformLoginResultEnum;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface PlatformLoginLogMapper extends BaseMapperX<LoginLogDO> {

    default PageResult<LoginLogDO> selectPage(LoginLogPageReqVO reqVO) {
        QueryWrapperX<LoginLogDO> query = new QueryWrapperX<LoginLogDO>()
                .likeIfPresent("user_ip", reqVO.getUserIp())
                .likeIfPresent("username", reqVO.getUsername())
                .betweenIfPresent("create_time", reqVO.getBeginTime(), reqVO.getEndTime());
        if (Boolean.TRUE.equals(reqVO.getStatus())) {
            query.eq("result", PlatformLoginResultEnum.SUCCESS.getResult());
        } else if (Boolean.FALSE.equals(reqVO.getStatus())) {
            query.gt("result", PlatformLoginResultEnum.SUCCESS.getResult());
        }
        query.orderByDesc("id"); // 降序
        return selectPage(reqVO, query);
    }

    default List<LoginLogDO> selectList(LoginLogExportReqVO reqVO) {
        QueryWrapperX<LoginLogDO> query = new QueryWrapperX<LoginLogDO>()
                .likeIfPresent("user_ip", reqVO.getUserIp())
                .likeIfPresent("username", reqVO.getUsername())
                .betweenIfPresent("create_time", reqVO.getBeginTime(), reqVO.getEndTime());
        if (Boolean.TRUE.equals(reqVO.getStatus())) {
            query.eq("result", PlatformLoginResultEnum.SUCCESS.getResult());
        } else if (Boolean.FALSE.equals(reqVO.getStatus())) {
            query.gt("result", PlatformLoginResultEnum.SUCCESS.getResult());
        }
        query.orderByDesc("id"); // 降序
        return selectList(query);
    }

}
