package cn.iocoder.yudao.module.platform.service.plug;

import cn.iocoder.yudao.module.platform.controller.center.plug.vo.order.item.OrderItemCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.plug.vo.order.item.OrderItemUpdateReqVO;
import cn.iocoder.yudao.module.platform.convert.plug.PlugOrderItemConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.plug.PlugOrderItemDO;
import cn.iocoder.yudao.module.platform.dal.mysql.plug.PlugOrderItemMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;
import org.springframework.validation.annotation.Validated;

import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.ORDER_ITEM_NOT_EXISTS;

/**
 * 订单项 Service 实现类
 *
 * @author 朱述勇
 */
@Service
@Validated
public class PlugOrderItemServiceImpl extends ServiceImpl<PlugOrderItemMapper, PlugOrderItemDO> implements PlugOrderItemService {

    @Resource
    private PlugOrderItemMapper orderItemMapper;

    @Override
    public Long createOrderItem(OrderItemCreateReqVO createReqVO) {
        // 插入
        PlugOrderItemDO orderItem = PlugOrderItemConvert.INSTANCE.convert(createReqVO);
        orderItemMapper.insert(orderItem);
        // 返回
        return orderItem.getId();
    }

    @Override
    public void updateOrderItems(List<OrderItemUpdateReqVO> updateReqVOS) {
        // 校验存在
        this.validateOrderItemExists(updateReqVOS.stream().map(OrderItemUpdateReqVO::getId).collect(Collectors.toList()));
        // 更新
        List<PlugOrderItemDO> updateObjs = PlugOrderItemConvert.INSTANCE.convertList1(updateReqVOS);
        super.updateBatchById(updateObjs);
    }


    @Override
    public List<PlugOrderItemDO> getByOrderId(Long orderId) {
        return orderItemMapper.getByOrderId(orderId);
    }

    @Override
    public void validateOrderItemExists(List<Long> ids) {
        List<PlugOrderItemDO> orderItemDOS = orderItemMapper.selectBatchIds(ids);
        for (PlugOrderItemDO orderItemDO : orderItemDOS) {
            if (Objects.isNull(orderItemDO)) {
                throw exception(ORDER_ITEM_NOT_EXISTS);
            }
        }
    }

    private void validateOrderItemExists(Long id) {
        if (orderItemMapper.selectById(id) == null) {
            throw exception(ORDER_ITEM_NOT_EXISTS);
        }
    }

}
