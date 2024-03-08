package cn.iocoder.yudao.module.platform.dal.mysql.plug;

import java.util.*;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.module.platform.dal.dataobject.plug.PlugAppDO;
import org.apache.ibatis.annotations.Mapper;
import cn.iocoder.yudao.module.platform.controller.platform.plug.vo.app.*;

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
