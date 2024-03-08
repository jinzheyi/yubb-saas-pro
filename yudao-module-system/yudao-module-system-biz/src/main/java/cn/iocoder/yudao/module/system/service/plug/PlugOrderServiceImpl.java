package cn.iocoder.yudao.module.system.service.plug;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.PLUG_ORDER_NOT_EXISTS;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.PLUG_ORDER_ORDER_NO_PASS_STATUS;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.PLUG_ORDER_ORDER_STATUS;

import cn.iocoder.yudao.framework.common.enums.CommonConstants;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.framework.tenant.core.util.TenantUtils;
import cn.iocoder.yudao.module.platform.api.plug.PlugAppApi;
import cn.iocoder.yudao.module.platform.api.plug.dto.PlugAppSimpleRespDTO;
import cn.iocoder.yudao.module.system.api.plug.dto.order.AuditPlugOrderReqDTO;
import cn.iocoder.yudao.module.system.api.plug.dto.order.PlugOrderPageReqDTO;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.order.PlugOrderCommitReqVO;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.order.PlugOrderDetailRespVO;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.order.PlugOrderPageReqVO;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.orderitem.PlugOrderItemRespVO;
import cn.iocoder.yudao.module.system.convert.plug.PlugOrderConvert;
import cn.iocoder.yudao.module.system.dal.dataobject.plug.PlugOrderDO;
import cn.iocoder.yudao.module.system.dal.dataobject.plug.PlugOrderItemDO;
import cn.iocoder.yudao.module.system.dal.dataobject.plug.PlugTenantDO;
import cn.iocoder.yudao.module.system.dal.mysql.plug.PlugOrderMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

/**
 * 插件订单 Service 实现类
 *
 * @author zhusy
 */
@Service
@Validated
public class PlugOrderServiceImpl extends ServiceImpl<PlugOrderMapper, PlugOrderDO> implements PlugOrderService {

    @Resource
    private PlugOrderMapper orderMapper;

    @Resource
    private PlugOrderItemService orderItemService;

    @Resource
    private PlugTenantService plugTenantService;

    @Resource
    private PlugAppApi plugAppApi;

    @Override
    public PlugOrderDetailRespVO getOrder(Long id) {
        PlugOrderDO orderDO = Optional.ofNullable(orderMapper.selectById(id)).orElseThrow(() -> exception(PLUG_ORDER_NOT_EXISTS));
        PlugOrderDetailRespVO respVO = PlugOrderConvert.INSTANCE.convert1(orderDO);
        //获取订单项
        List<PlugOrderItemDO> itemDOS = orderItemService
                .list(new LambdaQueryWrapperX<PlugOrderItemDO>().eq(PlugOrderItemDO::getOrderNo, respVO.getOrderNo()));
        List<PlugOrderItemRespVO> plugOrderItemRespVOS = BeanUtils.toBean(itemDOS, PlugOrderItemRespVO.class);
        List<Long> appIds = plugOrderItemRespVOS.stream().map(PlugOrderItemRespVO::getPlugAppId).collect(Collectors.toList());
        List<PlugAppSimpleRespDTO> plugAppList = plugAppApi.getPlugAppList(appIds, null);
        plugOrderItemRespVOS.forEach(itemResp -> {
            PlugAppSimpleRespDTO plugAppSimpleRespDTO = plugAppList.stream().filter(app -> app.getId().equals(itemResp.getPlugAppId())).findFirst().orElse(null);
            if (Objects.nonNull(plugAppSimpleRespDTO)) {
                itemResp.setAppSn(plugAppSimpleRespDTO.getAppSn())
                        .setAppName(plugAppSimpleRespDTO.getName())
                        .setAppPic(plugAppSimpleRespDTO.getMainPic());
            }
        });
        respVO.setItemRespVOS(plugOrderItemRespVOS);
        return respVO;
    }

    @Override
    public PageResult<PlugOrderDO> getOrderPage(PlugOrderPageReqVO pageReqVO) {
        return orderMapper.selectPage(pageReqVO);
    }

    @Override
    public PageResult<PlugOrderDO> getOrderPage(PlugOrderPageReqDTO reqDTO) {
        return orderMapper.selectPage(reqDTO);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean auditOrder(AuditPlugOrderReqDTO reqDTO) {
        PlugOrderDO orderDO = Optional.ofNullable(orderMapper.selectById(reqDTO.getId())).orElseThrow(() -> exception(PLUG_ORDER_NOT_EXISTS));
        if (!CommonConstants.PlugOrderStatusEnum.ZERO.getCode().equals(orderDO.getOrderStatus())) {
            throw exception(PLUG_ORDER_ORDER_STATUS);
        }
        TenantUtils.execute(orderDO.getTenantId(), () -> {
            orderDO.setOrderStatus(reqDTO.getOrderStatus());
            orderDO.setAuditNote(reqDTO.getAuditNote());
            //审批通过
            if (CommonConstants.PlugOrderStatusEnum.ONE.getCode().equals(reqDTO.getOrderStatus())) {
                orderDO.setSuccessTime(LocalDateTime.now());
                List<PlugOrderItemDO> itemDOS = orderItemService.list(new LambdaQueryWrapperX<PlugOrderItemDO>().eq(PlugOrderItemDO::getOrderNo, orderDO.getOrderNo()));
                List<PlugTenantDO> plugTenantDOS = itemDOS.stream().map(item -> {
                    PlugTenantDO plugTenantDO = new PlugTenantDO();
                    plugTenantDO.setPlugAppId(item.getPlugAppId());
                    return plugTenantDO;
                }).collect(Collectors.toList());
                plugTenantService.saveBatch(plugTenantDOS);
            }
            orderMapper.updateById(orderDO);
        });
        return true;
    }

    @Override
    public boolean commitOrder(PlugOrderCommitReqVO reqVO) {
        PlugOrderDO orderDO = Optional.ofNullable(orderMapper.selectById(reqVO.getId())).orElseThrow(() -> exception(PLUG_ORDER_NOT_EXISTS));
        if (!CommonConstants.PlugOrderStatusEnum.TWO.getCode().equals(orderDO.getOrderStatus())) {
            throw exception(PLUG_ORDER_ORDER_NO_PASS_STATUS);
        }
        orderDO.setOrderStatus(CommonConstants.PlugOrderStatusEnum.ZERO.getCode());
        orderDO.setNote(reqVO.getNote());
        orderMapper.updateById(orderDO);
        return true;
    }

}
