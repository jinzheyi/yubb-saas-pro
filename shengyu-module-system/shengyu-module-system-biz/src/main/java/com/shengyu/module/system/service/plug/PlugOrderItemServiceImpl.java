package com.shengyu.module.system.service.plug;

import com.shengyu.module.system.dal.dataobject.plug.PlugOrderItemDO;
import com.shengyu.module.system.dal.mysql.plug.PlugOrderItemMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

/**
 * 订单项 Service 实现类
 *
 * @author zhusy
 */
@Service
@Validated
public class PlugOrderItemServiceImpl extends ServiceImpl<PlugOrderItemMapper, PlugOrderItemDO> implements PlugOrderItemService {

}
