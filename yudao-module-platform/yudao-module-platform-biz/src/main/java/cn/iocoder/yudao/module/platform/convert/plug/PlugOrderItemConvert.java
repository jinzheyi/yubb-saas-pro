package cn.iocoder.yudao.module.platform.convert.plug;

import cn.iocoder.yudao.module.platform.controller.center.plug.vo.order.item.OrderItemRespVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.plug.PlugOrderItemDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

/**
 * 订单项 Convert
 *
 * @author 朱述勇
 */
@Mapper
public interface PlugOrderItemConvert {

    PlugOrderItemConvert INSTANCE = Mappers.getMapper(PlugOrderItemConvert.class);

    List<OrderItemRespVO> convertList(List<PlugOrderItemDO> list);

}
