package cn.iocoder.yudao.module.platform.dal.mysql.plug;

import java.util.*;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.module.platform.dal.dataobject.plug.PlugGoodsDO;
import org.apache.ibatis.annotations.Mapper;
import cn.iocoder.yudao.module.platform.controller.center.plug.vo.goods.*;

/**
 * 应用商品 Mapper
 *
 * @author 朱述勇
 */
@Mapper
public interface PlugGoodsMapper extends BaseMapperX<PlugGoodsDO> {

    default PageResult<PlugGoodsDO> selectPage(PlugGoodsPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlugGoodsDO>()
                .likeIfPresent(PlugGoodsDO::getAppName, reqVO.getAppName())
                .eqIfPresent(PlugGoodsDO::getAppSn, reqVO.getAppSn())
                .betweenIfPresent(PlugGoodsDO::getAppPrice, reqVO.getAppPrice())
                .betweenIfPresent(PlugGoodsDO::getPayPrice, reqVO.getPayPrice())
                .eqIfPresent(PlugGoodsDO::getAppNum, reqVO.getAppNum())
                .eqIfPresent(PlugGoodsDO::getAppStatus, reqVO.getAppStatus())
                .betweenIfPresent(PlugGoodsDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(PlugGoodsDO::getId));
    }

    default List<PlugGoodsDO> selectList(PlugGoodsExportReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<PlugGoodsDO>()
                .likeIfPresent(PlugGoodsDO::getAppName, reqVO.getAppName())
                .eqIfPresent(PlugGoodsDO::getAppSn, reqVO.getAppSn())
                .betweenIfPresent(PlugGoodsDO::getAppPrice, reqVO.getAppPrice())
                .betweenIfPresent(PlugGoodsDO::getPayPrice, reqVO.getPayPrice())
                .eqIfPresent(PlugGoodsDO::getAppNum, reqVO.getAppNum())
                .eqIfPresent(PlugGoodsDO::getAppStatus, reqVO.getAppStatus())
                .betweenIfPresent(PlugGoodsDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(PlugGoodsDO::getId));
    }

}
