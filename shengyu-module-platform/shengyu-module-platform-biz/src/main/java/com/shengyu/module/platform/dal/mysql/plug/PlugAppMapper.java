package com.shengyu.module.platform.dal.mysql.plug;

import java.util.*;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.platform.dal.dataobject.plug.PlugAppDO;
import org.apache.ibatis.annotations.Mapper;
import com.shengyu.module.platform.controller.platform.plug.vo.app.*;

/**
 * 插件应用 Mapper
 *
 * @author zhusy
 */
@Mapper
public interface PlugAppMapper extends BaseMapperX<PlugAppDO> {

    default PageResult<PlugAppDO> selectPage(PlugAppPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlugAppDO>()
                .likeIfPresent(PlugAppDO::getName, reqVO.getName())
                .eqIfPresent(PlugAppDO::getAppSn, reqVO.getAppSn())
                .eqIfPresent(PlugAppDO::getStatus, reqVO.getStatus())
                .eqIfPresent(PlugAppDO::getEnable, reqVO.getEnable())
                .betweenIfPresent(PlugAppDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(PlugAppDO::getId));
    }

    default List<PlugAppDO> selectList(PlugAppExportReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<PlugAppDO>()
                .likeIfPresent(PlugAppDO::getName, reqVO.getName())
                .eqIfPresent(PlugAppDO::getAppSn, reqVO.getAppSn())
                .eqIfPresent(PlugAppDO::getStatus, reqVO.getStatus())
                .eqIfPresent(PlugAppDO::getEnable, reqVO.getEnable())
                .betweenIfPresent(PlugAppDO::getCreateTime, reqVO.getCreateTime())
                .eqIfPresent(PlugAppDO::getMainPic, reqVO.getMainPic())
                .orderByDesc(PlugAppDO::getId));
    }

}
