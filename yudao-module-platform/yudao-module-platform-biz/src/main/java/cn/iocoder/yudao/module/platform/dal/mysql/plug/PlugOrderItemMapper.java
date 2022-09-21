package cn.iocoder.yudao.module.platform.dal.mysql.plug;

import java.util.*;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.module.plug.dal.dataobject.orderitem.PlugOrderItemDO;
import org.apache.ibatis.annotations.Mapper;
import cn.iocoder.yudao.module.plug.controller.admin.orderitem.vo.*;

/**
 * 订单项 Mapper
 *
 * @author 朱述勇
 */
@Mapper
public interface PlugOrderItemMapper extends BaseMapperX<PlugOrderItemDO> {

    default PageResult<PlugOrderItemDO> selectPage(PlugOrderItemPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlugOrderItemDO>()
                .eqIfPresent(PlugOrderItemDO::getOrderId, reqVO.getOrderId())
                .eqIfPresent(PlugOrderItemDO::getAppId, reqVO.getAppId())
                .eqIfPresent(PlugOrderItemDO::getAppPic, reqVO.getAppPic())
                .likeIfPresent(PlugOrderItemDO::getAppName, reqVO.getAppName())
                .eqIfPresent(PlugOrderItemDO::getAppSn, reqVO.getAppSn())
                .eqIfPresent(PlugOrderItemDO::getAppPrice, reqVO.getAppPrice())
                .eqIfPresent(PlugOrderItemDO::getPayNum, reqVO.getPayNum())
                .eqIfPresent(PlugOrderItemDO::getPromotionAmount, reqVO.getPromotionAmount())
                .eqIfPresent(PlugOrderItemDO::getDiscountAmount, reqVO.getDiscountAmount())
                .eqIfPresent(PlugOrderItemDO::getGiftIntegration, reqVO.getGiftIntegration())
                .eqIfPresent(PlugOrderItemDO::getGiftGrowth, reqVO.getGiftGrowth())
                .eqIfPresent(PlugOrderItemDO::getAppInfo, reqVO.getAppInfo())
                .betweenIfPresent(PlugOrderItemDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(PlugOrderItemDO::getId));
    }

    default List<PlugOrderItemDO> selectList(PlugOrderItemExportReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<PlugOrderItemDO>()
                .eqIfPresent(PlugOrderItemDO::getOrderId, reqVO.getOrderId())
                .eqIfPresent(PlugOrderItemDO::getAppId, reqVO.getAppId())
                .eqIfPresent(PlugOrderItemDO::getAppPic, reqVO.getAppPic())
                .likeIfPresent(PlugOrderItemDO::getAppName, reqVO.getAppName())
                .eqIfPresent(PlugOrderItemDO::getAppSn, reqVO.getAppSn())
                .eqIfPresent(PlugOrderItemDO::getAppPrice, reqVO.getAppPrice())
                .eqIfPresent(PlugOrderItemDO::getPayNum, reqVO.getPayNum())
                .eqIfPresent(PlugOrderItemDO::getPromotionAmount, reqVO.getPromotionAmount())
                .eqIfPresent(PlugOrderItemDO::getDiscountAmount, reqVO.getDiscountAmount())
                .eqIfPresent(PlugOrderItemDO::getGiftIntegration, reqVO.getGiftIntegration())
                .eqIfPresent(PlugOrderItemDO::getGiftGrowth, reqVO.getGiftGrowth())
                .eqIfPresent(PlugOrderItemDO::getAppInfo, reqVO.getAppInfo())
                .betweenIfPresent(PlugOrderItemDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(PlugOrderItemDO::getId));
    }

}
