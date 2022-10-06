package cn.iocoder.yudao.module.platform.service.plug;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.plug.vo.order.*;
import cn.iocoder.yudao.module.platform.controller.center.plug.vo.order.item.OrderItemRespVO;
import cn.iocoder.yudao.module.platform.convert.plug.PlugOrderConvert;
import cn.iocoder.yudao.module.platform.convert.plug.PlugOrderItemConvert;
import cn.iocoder.yudao.module.platform.convert.tenant.TenantConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.plug.PlugOrderDO;
import cn.iocoder.yudao.module.platform.dal.mysql.plug.PlugOrderMapper;
import cn.iocoder.yudao.module.platform.service.tenant.PlatformTenantService;
import cn.iocoder.yudao.module.system.api.user.AdminUserApi;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;
import java.util.List;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.ORDER_NOT_EXISTS;

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

    @Resource
    private PlugOrderItemService orderItemService;

    @Resource
    private PlatformTenantService tenantService;

    @Resource
    private AdminUserApi adminUserApi;

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
    public PlugOrderRespVO getOrder(Long id) {
        // 校验存在
        this.validateOrderExists(id);
        PlugOrderDO order = orderMapper.selectById(id);
        PlugOrderRespVO orderRespVO = PlugOrderConvert.INSTANCE.convert(order);
        List<OrderItemRespVO> itemRespVOS = PlugOrderItemConvert.INSTANCE.convertList(orderItemService.getByOrderId(id));
        orderRespVO.setTenant(TenantConvert.INSTANCE.convert(tenantService.getTenant(order.getTenantId())));
        orderRespVO.setItem(itemRespVOS);
        orderRespVO.setAdminUser(adminUserApi.getUser(order.getUserId()));
        return orderRespVO;
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
