package cn.iocoder.yudao.module.platform.service.plug;

import java.util.*;
import javax.validation.*;
import cn.iocoder.yudao.module.plug.controller.admin.orderitem.vo.*;
import cn.iocoder.yudao.module.plug.dal.dataobject.orderitem.PlugOrderItemDO;
import cn.iocoder.yudao.framework.common.pojo.PageResult;

/**
 * 订单项 Service 接口
 *
 * @author 朱述勇
 */
public interface PlugOrderItemService {

    /**
     * 创建订单项
     *
     * @param createReqVO 创建信息
     * @return 编号
     */
    Long createOrderItem(@Valid PlugOrderItemCreateReqVO createReqVO);

    /**
     * 更新订单项
     *
     * @param updateReqVO 更新信息
     */
    void updateOrderItem(@Valid PlugOrderItemUpdateReqVO updateReqVO);

    /**
     * 删除订单项
     *
     * @param id 编号
     */
    void deleteOrderItem(Long id);

    /**
     * 获得订单项
     *
     * @param id 编号
     * @return 订单项
     */
    PlugOrderItemDO getOrderItem(Long id);

    /**
     * 获得订单项列表
     *
     * @param ids 编号
     * @return 订单项列表
     */
    List<PlugOrderItemDO> getOrderItemList(Collection<Long> ids);

    /**
     * 获得订单项分页
     *
     * @param pageReqVO 分页查询
     * @return 订单项分页
     */
    PageResult<PlugOrderItemDO> getOrderItemPage(PlugOrderItemPageReqVO pageReqVO);

    /**
     * 获得订单项列表, 用于 Excel 导出
     *
     * @param exportReqVO 查询条件
     * @return 订单项列表
     */
    List<PlugOrderItemDO> getOrderItemList(PlugOrderItemExportReqVO exportReqVO);

}
