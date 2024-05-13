package com.shengyu.module.system.service.plug;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.PLUG_APP_DISABLE;
import static com.shengyu.module.system.enums.ErrorCodeConstants.PLUG_APP_NOT_EXISTS;
import static com.shengyu.module.system.enums.ErrorCodeConstants.PLUG_ORDER_ORDER_STATUS_EXISTS;
import static com.shengyu.module.system.enums.ErrorCodeConstants.PLUG_TENANT_EXISTS;

import cn.hutool.core.util.IdUtil;
import cn.hutool.extra.servlet.ServletUtil;
import com.shengyu.framework.common.enums.CommonConstants;
import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.common.util.servlet.ServletUtils;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.platform.api.plug.PlugAppApi;
import com.shengyu.module.platform.api.plug.dto.PlugAppPageReqDTO;
import com.shengyu.module.platform.api.plug.dto.PlugAppRespDTO;
import com.shengyu.module.system.controller.admin.plug.vo.app.PlugAppBuyReqVO;
import com.shengyu.module.system.controller.admin.plug.vo.app.PlugAppPageReqVO;
import com.shengyu.module.system.controller.admin.plug.vo.app.PlugAppRespVO;
import com.shengyu.module.system.controller.admin.plug.vo.app.PlugAppSimpleRespVO;
import com.shengyu.module.system.dal.dataobject.plug.PlugOrderDO;
import com.shengyu.module.system.dal.dataobject.plug.PlugOrderItemDO;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

/**
 * @Description 插件市场服务接口实现
 * @Author zhusy
 * @Date 2023/4/13 15:26
 * @Version 1.0
 **/
@Service
@Validated
public class PlugAppApiServiceImpl implements PlugAppApiService {

    @Resource
    private PlugAppApi plugAppApi;

    @Resource
    private PlugOrderService orderService;

    @Resource
    private PlugOrderItemService orderItemService;

    @Resource
    private PlugTenantService plugTenantService;

    @Override
    public PlugAppRespVO getPlugApp(Long id) {
        return BeanUtils.toBean(plugAppApi.getPlugApp(id), PlugAppRespVO.class);
    }

    @Override
    public PageResult<PlugAppSimpleRespVO> getPlugAppList(PlugAppPageReqVO reqVO) {
        return BeanUtils.toBean(plugAppApi.getPlugAppPage(BeanUtils.toBean(reqVO, PlugAppPageReqDTO.class)), PlugAppSimpleRespVO.class);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long buyPlugApp(PlugAppBuyReqVO reqVO) {
        List<PlugOrderDO> orderDOList = orderService.list(new LambdaQueryWrapper<PlugOrderDO>()
                .in(PlugOrderDO::getOrderStatus, Arrays.asList(CommonConstants.PlugOrderStatusEnum.ZERO.getCode(), CommonConstants.PlugOrderStatusEnum.TWO.getCode())));
        if (!orderDOList.isEmpty()) {
            throw exception(PLUG_ORDER_ORDER_STATUS_EXISTS);
        }
        String orderNo = IdUtil.getSnowflakeNextIdStr();
        PlugAppRespDTO plugApp = Optional.ofNullable(plugAppApi.getPlugApp(reqVO.getId()))
                .orElseThrow(() -> exception(PLUG_APP_NOT_EXISTS));
        if (CommonStatusEnum.DISABLE.getStatus().equals(plugApp.getStatus())
                || CommonStatusEnum.DISABLE.getStatus().equals(plugApp.getEnable())) {
            throw exception(PLUG_APP_DISABLE);
        }
        if (Objects.nonNull(plugTenantService.getPlugTenant(plugApp.getId()))) {
            throw exception(PLUG_TENANT_EXISTS);
        }
        PlugOrderItemDO itemDO = new PlugOrderItemDO();
        itemDO.setOrderNo(orderNo);
        itemDO.setPlugAppId(plugApp.getId());
        orderItemService.save(itemDO);
        PlugOrderDO orderDO = new PlugOrderDO();
        orderDO.setOrderNo(orderNo);
        orderDO.setOrderStatus(CommonConstants.PlugOrderStatusEnum.ZERO.getCode());
        // 获得 Request 对象
        HttpServletRequest request = ServletUtils.getRequest();
        orderDO.setUserIp(Objects.isNull(request)? null:ServletUtil.getClientIP(request));
        orderDO.setUserId(SecurityFrameworkUtils.getLoginUserId());
        orderDO.setNote(reqVO.getNote());
        orderService.save(orderDO);
        return orderDO.getId();
    }

}
