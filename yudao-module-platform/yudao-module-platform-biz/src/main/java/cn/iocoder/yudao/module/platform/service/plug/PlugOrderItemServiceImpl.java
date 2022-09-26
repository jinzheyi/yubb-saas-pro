package cn.iocoder.yudao.module.platform.service.plug;

import cn.iocoder.yudao.module.platform.dal.mysql.plug.PlugOrderItemMapper;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;
import org.springframework.validation.annotation.Validated;

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

}
