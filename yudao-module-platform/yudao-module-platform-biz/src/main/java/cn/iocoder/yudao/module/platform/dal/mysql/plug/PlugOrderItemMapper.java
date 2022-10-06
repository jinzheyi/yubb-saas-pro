package cn.iocoder.yudao.module.platform.dal.mysql.plug;

import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.dal.dataobject.plug.PlugOrderItemDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;
import java.util.Objects;

/**
 * 订单项 Mapper
 *
 * @author 朱述勇
 */
@Mapper
public interface PlugOrderItemMapper extends BaseMapperX<PlugOrderItemDO> {

    default List<PlugOrderItemDO> getByOrderId(Long orderId) {
        if (Objects.isNull(orderId)) {
            return null;
        }
        return selectList(new LambdaQueryWrapperX<PlugOrderItemDO>()
                .eq(PlugOrderItemDO::getOrderId, orderId));
    }
}
