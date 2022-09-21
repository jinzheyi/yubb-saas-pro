package cn.iocoder.yudao.module.platform.convert.plug;

import java.util.*;

import cn.iocoder.yudao.framework.common.pojo.PageResult;

import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;
import cn.iocoder.yudao.module.plug.controller.admin.goods.vo.*;
import cn.iocoder.yudao.module.plug.dal.dataobject.goods.PlugGoodsDO;

/**
 * 应用商品 Convert
 *
 * @author 朱述勇
 */
@Mapper
public interface PlugGoodsConvert {

    PlugGoodsConvert INSTANCE = Mappers.getMapper(PlugGoodsConvert.class);

    PlugGoodsDO convert(PlugGoodsCreateReqVO bean);

    PlugGoodsDO convert(PlugGoodsUpdateReqVO bean);

    PlugGoodsRespVO convert(PlugGoodsDO bean);

    List<PlugGoodsRespVO> convertList(List<PlugGoodsDO> list);

    PageResult<PlugGoodsRespVO> convertPage(PageResult<PlugGoodsDO> page);

    List<PlugGoodsExcelVO> convertList02(List<PlugGoodsDO> list);

}
