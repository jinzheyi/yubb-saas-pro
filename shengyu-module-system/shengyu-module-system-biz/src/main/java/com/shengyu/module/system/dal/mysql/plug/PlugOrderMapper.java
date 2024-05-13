package com.shengyu.module.system.dal.mysql.plug;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.api.plug.dto.order.PlugOrderPageReqDTO;
import com.shengyu.module.system.controller.admin.plug.vo.order.PlugOrderPageReqVO;
import com.shengyu.module.system.dal.dataobject.plug.PlugOrderDO;
import org.apache.ibatis.annotations.Mapper;

/**
 * 插件订单 Mapper
 *
 * @author zhusy
 */
@Mapper
public interface PlugOrderMapper extends BaseMapperX<PlugOrderDO> {

    default PageResult<PlugOrderDO> selectPage(PlugOrderPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlugOrderDO>()
                .eqIfPresent(PlugOrderDO::getOrderNo, reqVO.getOrderNo())
                .eqIfPresent(PlugOrderDO::getOrderStatus, reqVO.getOrderStatus())
                .eqIfPresent(PlugOrderDO::getUserIp, reqVO.getUserIp())
                .eqIfPresent(PlugOrderDO::getUserId, reqVO.getUserId())
                .betweenIfPresent(PlugOrderDO::getSuccessTime, reqVO.getSuccessTime())
                .betweenIfPresent(PlugOrderDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(PlugOrderDO::getId));
    }

    default PageResult<PlugOrderDO> selectPage(PlugOrderPageReqDTO reqDTO) {
        return selectPage(reqDTO, new LambdaQueryWrapperX<PlugOrderDO>()
                .eqIfPresent(PlugOrderDO::getOrderNo, reqDTO.getOrderNo())
                .eqIfPresent(PlugOrderDO::getOrderStatus, reqDTO.getOrderStatus())
                .eqIfPresent(PlugOrderDO::getTenantId, reqDTO.getTenantId())
                .betweenIfPresent(PlugOrderDO::getCreateTime, reqDTO.getCreateTime())
                .orderByDesc(PlugOrderDO::getId));
    }

}
