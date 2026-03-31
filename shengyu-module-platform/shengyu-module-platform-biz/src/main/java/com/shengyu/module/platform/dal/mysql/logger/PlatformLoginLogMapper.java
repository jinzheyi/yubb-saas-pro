package com.shengyu.module.platform.dal.mysql.logger;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.platform.controller.platform.logger.vo.loginlog.LoginLogExportReqVO;
import com.shengyu.module.platform.controller.platform.logger.vo.loginlog.LoginLogPageReqVO;
import com.shengyu.module.platform.dal.dataobject.logger.PlatformLoginLogDO;
import com.shengyu.framework.common.enums.logger.LoginResultEnum;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface PlatformLoginLogMapper extends BaseMapperX<PlatformLoginLogDO> {

    default PageResult<PlatformLoginLogDO> selectPage(LoginLogPageReqVO reqVO) {
        LambdaQueryWrapperX<PlatformLoginLogDO> query = new LambdaQueryWrapperX<PlatformLoginLogDO>()
                .likeIfPresent(PlatformLoginLogDO::getUserIp, reqVO.getUserIp())
                .likeIfPresent(PlatformLoginLogDO::getUsername, reqVO.getUsername())
                .betweenIfPresent(PlatformLoginLogDO::getCreateTime, reqVO.getCreateTime());
        if (Boolean.TRUE.equals(reqVO.getStatus())) {
            query.eq(PlatformLoginLogDO::getResult, LoginResultEnum.SUCCESS.getResult());
        } else if (Boolean.FALSE.equals(reqVO.getStatus())) {
            query.gt(PlatformLoginLogDO::getResult, LoginResultEnum.SUCCESS.getResult());
        }
        query.orderByDesc(PlatformLoginLogDO::getCreateTime); // 降序
        return selectPage(reqVO, query);
    }

    default List<PlatformLoginLogDO> selectList(LoginLogExportReqVO reqVO) {
        LambdaQueryWrapperX<PlatformLoginLogDO> query = new LambdaQueryWrapperX<PlatformLoginLogDO>()
                .likeIfPresent(PlatformLoginLogDO::getUserIp, reqVO.getUserIp())
                .likeIfPresent(PlatformLoginLogDO::getUsername, reqVO.getUsername())
                .betweenIfPresent(PlatformLoginLogDO::getCreateTime, reqVO.getCreateTime());
        if (Boolean.TRUE.equals(reqVO.getStatus())) {
            query.eq(PlatformLoginLogDO::getResult, LoginResultEnum.SUCCESS.getResult());
        } else if (Boolean.FALSE.equals(reqVO.getStatus())) {
            query.gt(PlatformLoginLogDO::getResult, LoginResultEnum.SUCCESS.getResult());
        }
        query.orderByDesc(PlatformLoginLogDO::getCreateTime); // 降序
        return selectList(query);
    }

}
