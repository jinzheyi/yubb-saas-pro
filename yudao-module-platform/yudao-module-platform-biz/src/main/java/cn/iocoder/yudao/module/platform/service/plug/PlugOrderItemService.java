package cn.iocoder.yudao.module.platform.service.plug;

import cn.iocoder.yudao.module.platform.controller.center.plug.vo.order.item.OrderItemCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.plug.vo.order.item.OrderItemUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.plug.PlugOrderItemDO;
import com.baomidou.mybatisplus.extension.service.IService;

import javax.validation.Valid;
import java.util.List;

/**
 * 订单项 Service 接口
 *
 * @author 朱述勇
 */
public interface PlugOrderItemService extends IService<PlugOrderItemDO> {

    /**
     * 创建订单项
     *
     * @param createReqVO 创建信息
     * @return 编号
     */
    Long createOrderItem(@Valid OrderItemCreateReqVO createReqVO);

    /**
     * 更新订单项
     *
     * @param updateReqVOS 更新信息
     */
    void updateOrderItems(@Valid List<OrderItemUpdateReqVO> updateReqVOS);

    /**
     * 根据订单ID查询订单项集合
     * @return 订单项集合
     */
    List<PlugOrderItemDO> getByOrderId(Long orderId);

    /**
     * 校验是否存在
     * @param ids
     */
    void validateOrderItemExists(List<Long> ids);

}
