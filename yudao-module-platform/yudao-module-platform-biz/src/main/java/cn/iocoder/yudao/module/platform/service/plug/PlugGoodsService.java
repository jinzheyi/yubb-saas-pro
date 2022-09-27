package cn.iocoder.yudao.module.platform.service.plug;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.plug.vo.goods.PlugGoodsCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.plug.vo.goods.PlugGoodsExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.plug.vo.goods.PlugGoodsPageReqVO;
import cn.iocoder.yudao.module.platform.controller.center.plug.vo.goods.PlugGoodsUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.plug.PlugGoodsDO;

import javax.validation.Valid;
import java.util.List;

/**
 * 应用商品 Service 接口
 *
 * @author 朱述勇
 */
public interface PlugGoodsService {

    /**
     * 创建应用商品
     *
     * @param createReqVO 创建信息
     * @return 编号
     */
    Long createGoods(@Valid PlugGoodsCreateReqVO createReqVO);

    /**
     * 更新应用商品
     *
     * @param updateReqVO 更新信息
     */
    void updateGoods(@Valid PlugGoodsUpdateReqVO updateReqVO);

    /**
     * 删除应用商品
     *
     * @param id 编号
     */
    void deleteGoods(Long id);

    /**
     * 获得应用商品
     *
     * @param id 编号
     * @return 应用商品
     */
    PlugGoodsDO getGoods(Long id);

    /**
     * 获得应用商品分页
     *
     * @param pageReqVO 分页查询
     * @return 应用商品分页
     */
    PageResult<PlugGoodsDO> getGoodsPage(PlugGoodsPageReqVO pageReqVO);

    /**
     * 获得应用商品列表, 用于 Excel 导出
     *
     * @param exportReqVO 查询条件
     * @return 应用商品列表
     */
    List<PlugGoodsDO> getGoodsList(PlugGoodsExportReqVO exportReqVO);

}
