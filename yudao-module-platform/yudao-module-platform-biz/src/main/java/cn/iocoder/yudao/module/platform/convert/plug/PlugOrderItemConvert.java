package cn.iocoder.yudao.module.platform.convert.plug;

import java.util.*;

import cn.iocoder.yudao.framework.common.pojo.PageResult;

import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;
import cn.iocoder.yudao.module.plug.controller.admin.orderitem.vo.*;
import cn.iocoder.yudao.module.plug.dal.dataobject.orderitem.PlugOrderItemDO;

/**
 * 订单项 Convert
 *
 * @author 朱述勇
 */
@Mapper
public interface PlugOrderItemConvert {

    PlugOrderItemConvert INSTANCE = Mappers.getMapper(PlugOrderItemConvert.class);

    PlugOrderItemDO convert(PlugOrderItemCreateReqVO bean);

    PlugOrderItemDO convert(PlugOrderItemUpdateReqVO bean);

    PlugOrderItemRespVO convert(PlugOrderItemDO bean);

    List<PlugOrderItemRespVO> convertList(List<PlugOrderItemDO> list);

    PageResult<PlugOrderItemRespVO> convertPage(PageResult<PlugOrderItemDO> page);

    List<PlugOrderItemExcelVO> convertList02(List<PlugOrderItemDO> list);

}
