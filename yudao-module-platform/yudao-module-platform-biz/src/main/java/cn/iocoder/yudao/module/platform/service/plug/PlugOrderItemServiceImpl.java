package cn.iocoder.yudao.module.platform.service.plug;

import org.springframework.stereotype.Service;
import javax.annotation.Resource;
import org.springframework.validation.annotation.Validated;

import java.util.*;
import cn.iocoder.yudao.module.plug.controller.admin.orderitem.vo.*;
import cn.iocoder.yudao.module.plug.dal.dataobject.orderitem.PlugOrderItemDO;
import cn.iocoder.yudao.framework.common.pojo.PageResult;

import cn.iocoder.yudao.module.plug.convert.orderitem.PlugOrderItemConvert;
import cn.iocoder.yudao.module.plug.dal.mysql.orderitem.PlugOrderItemMapper;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.module.plug.enums.ErrorCodeConstants.*;

/**
 * 订单项 Service 实现类
 *
 * @author 朱述勇
 */
@Service
@Validated
public class PlugOrderItemServiceImpl implements PlugOrderItemService {

    @Resource
    private PlugOrderItemMapper orderItemMapper;

    @Override
    public Long createOrderItem(PlugOrderItemCreateReqVO createReqVO) {
        // 插入
        PlugOrderItemDO orderItem = PlugOrderItemConvert.INSTANCE.convert(createReqVO);
        orderItemMapper.insert(orderItem);
        // 返回
        return orderItem.getId();
    }

    @Override
    public void updateOrderItem(PlugOrderItemUpdateReqVO updateReqVO) {
        // 校验存在
        this.validateOrderItemExists(updateReqVO.getId());
        // 更新
        PlugOrderItemDO updateObj = PlugOrderItemConvert.INSTANCE.convert(updateReqVO);
        orderItemMapper.updateById(updateObj);
    }

    @Override
    public void deleteOrderItem(Long id) {
        // 校验存在
        this.validateOrderItemExists(id);
        // 删除
        orderItemMapper.deleteById(id);
    }

    private void validateOrderItemExists(Long id) {
        if (orderItemMapper.selectById(id) == null) {
            throw exception(ORDER_ITEM_NOT_EXISTS);
        }
    }

    @Override
    public PlugOrderItemDO getOrderItem(Long id) {
        return orderItemMapper.selectById(id);
    }

    @Override
    public List<PlugOrderItemDO> getOrderItemList(Collection<Long> ids) {
        return orderItemMapper.selectBatchIds(ids);
    }

    @Override
    public PageResult<PlugOrderItemDO> getOrderItemPage(PlugOrderItemPageReqVO pageReqVO) {
        return orderItemMapper.selectPage(pageReqVO);
    }

    @Override
    public List<PlugOrderItemDO> getOrderItemList(PlugOrderItemExportReqVO exportReqVO) {
        return orderItemMapper.selectList(exportReqVO);
    }

}
