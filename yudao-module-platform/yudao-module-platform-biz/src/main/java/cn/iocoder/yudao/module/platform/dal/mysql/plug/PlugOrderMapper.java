package cn.iocoder.yudao.module.platform.dal.mysql.plug;

import java.util.*;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.module.platform.dal.dataobject.plug.PlugOrderDO;
import org.apache.ibatis.annotations.Mapper;
import cn.iocoder.yudao.module.platform.controller.center.plug.vo.order.*;

/**
 * 订单 Mapper
 *
 * @author 朱述勇
 */
@Mapper
public interface PlugOrderMapper extends BaseMapperX<PlugOrderDO> {

    default PageResult<PlugOrderDO> selectPage(PlugOrderPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlugOrderDO>()
                .likeIfPresent(PlugOrderDO::getOrderNo, reqVO.getOrderNo())
                .betweenIfPresent(PlugOrderDO::getPayAmount, reqVO.getPayAmount())
                .eqIfPresent(PlugOrderDO::getOrderType, reqVO.getOrderType())
                .eqIfPresent(PlugOrderDO::getOrderStatus, reqVO.getOrderStatus())
                .betweenIfPresent(PlugOrderDO::getExpireTime, reqVO.getExpireTime())
                .betweenIfPresent(PlugOrderDO::getSuccessTime, reqVO.getSuccessTime())
                .betweenIfPresent(PlugOrderDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(PlugOrderDO::getId));
    }

    default List<PlugOrderDO> selectList(PlugOrderExportReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<PlugOrderDO>()
                .likeIfPresent(PlugOrderDO::getOrderNo, reqVO.getOrderNo())
                .betweenIfPresent(PlugOrderDO::getPayAmount, reqVO.getPayAmount())
                .eqIfPresent(PlugOrderDO::getOrderType, reqVO.getOrderType())
                .eqIfPresent(PlugOrderDO::getOrderStatus, reqVO.getOrderStatus())
                .betweenIfPresent(PlugOrderDO::getExpireTime, reqVO.getExpireTime())
                .betweenIfPresent(PlugOrderDO::getSuccessTime, reqVO.getSuccessTime())
                .betweenIfPresent(PlugOrderDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(PlugOrderDO::getId));
    }

}
