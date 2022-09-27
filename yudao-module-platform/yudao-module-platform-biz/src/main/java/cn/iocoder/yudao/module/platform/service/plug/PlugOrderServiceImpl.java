package cn.iocoder.yudao.module.platform.service.plug;

import org.springframework.stereotype.Service;
import javax.annotation.Resource;
import org.springframework.validation.annotation.Validated;

import java.util.*;
import cn.iocoder.yudao.module.platform.controller.center.plug.vo.order.*;
import cn.iocoder.yudao.module.platform.dal.dataobject.plug.PlugOrderDO;
import cn.iocoder.yudao.framework.common.pojo.PageResult;

import cn.iocoder.yudao.module.platform.convert.plug.PlugOrderConvert;
import cn.iocoder.yudao.module.platform.dal.mysql.plug.PlugOrderMapper;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.*;

/**
 * 订单 Service 实现类
 *
 * @author 朱述勇
 */
@Service
@Validated
public class PlugOrderServiceImpl implements PlugOrderService {

    @Resource
    private PlugOrderMapper orderMapper;

    @Override
    public Long createOrder(PlugOrderCreateReqVO createReqVO) {
        // 插入
        PlugOrderDO order = PlugOrderConvert.INSTANCE.convert(createReqVO);
        orderMapper.insert(order);
        // 返回
        return order.getId();
    }

    @Override
    public void updateOrder(PlugOrderUpdateReqVO updateReqVO) {
        // 校验存在
        this.validateOrderExists(updateReqVO.getId());
        // 更新
        PlugOrderDO updateObj = PlugOrderConvert.INSTANCE.convert(updateReqVO);
        orderMapper.updateById(updateObj);
    }

    @Override
    public void deleteOrder(Long id) {
        // 校验存在
        this.validateOrderExists(id);
        // 删除
        orderMapper.deleteById(id);
    }

    private void validateOrderExists(Long id) {
        if (orderMapper.selectById(id) == null) {
            throw exception(ORDER_NOT_EXISTS);
        }
    }

    @Override
    public PlugOrderDO getOrder(Long id) {
        return orderMapper.selectById(id);
    }

    @Override
    public PageResult<PlugOrderDO> getOrderPage(PlugOrderPageReqVO pageReqVO) {
        return orderMapper.selectPage(pageReqVO);
    }

    @Override
    public List<PlugOrderDO> getOrderList(PlugOrderExportReqVO exportReqVO) {
        return orderMapper.selectList(exportReqVO);
    }

}
