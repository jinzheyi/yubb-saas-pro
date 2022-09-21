package cn.iocoder.yudao.module.platform.convert.plug;

import java.util.*;

import cn.iocoder.yudao.framework.common.pojo.PageResult;

import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;
import cn.iocoder.yudao.module.plug.controller.admin.order.vo.*;
import cn.iocoder.yudao.module.plug.dal.dataobject.order.PlugOrderDO;

/**
 * 订单 Convert
 *
 * @author 朱述勇
 */
@Mapper
public interface PlugOrderConvert {

    PlugOrderConvert INSTANCE = Mappers.getMapper(PlugOrderConvert.class);

    PlugOrderDO convert(PlugOrderCreateReqVO bean);

    PlugOrderDO convert(PlugOrderUpdateReqVO bean);

    PlugOrderRespVO convert(PlugOrderDO bean);

    List<PlugOrderRespVO> convertList(List<PlugOrderDO> list);

    PageResult<PlugOrderRespVO> convertPage(PageResult<PlugOrderDO> page);

    List<PlugOrderExcelVO> convertList02(List<PlugOrderDO> list);

}
