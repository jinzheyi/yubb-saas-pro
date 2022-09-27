package cn.iocoder.yudao.module.platform.service.plug;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.plug.vo.goods.PlugGoodsCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.plug.vo.goods.PlugGoodsExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.plug.vo.goods.PlugGoodsPageReqVO;
import cn.iocoder.yudao.module.platform.controller.center.plug.vo.goods.PlugGoodsUpdateReqVO;
import cn.iocoder.yudao.module.platform.convert.plug.PlugGoodsConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.plug.PlugGoodsDO;
import cn.iocoder.yudao.module.platform.dal.mysql.plug.PlugGoodsMapper;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;
import java.util.List;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.GOODS_NOT_EXISTS;

/**
 * 应用商品 Service 实现类
 *
 * @author 朱述勇
 */
@Service
@Validated
public class PlugGoodsServiceImpl implements PlugGoodsService {

    @Resource
    private PlugGoodsMapper goodsMapper;

    @Override
    public Long createGoods(PlugGoodsCreateReqVO createReqVO) {
        // 插入
        PlugGoodsDO goods = PlugGoodsConvert.INSTANCE.convert(createReqVO);
        goodsMapper.insert(goods);
        // 返回
        return goods.getId();
    }

    @Override
    public void updateGoods(PlugGoodsUpdateReqVO updateReqVO) {
        // 校验存在
        this.validateGoodsExists(updateReqVO.getId());
        // 更新
        PlugGoodsDO updateObj = PlugGoodsConvert.INSTANCE.convert(updateReqVO);
        goodsMapper.updateById(updateObj);
    }

    @Override
    public void deleteGoods(Long id) {
        // 校验存在
        this.validateGoodsExists(id);
        // 删除
        goodsMapper.deleteById(id);
    }

    private void validateGoodsExists(Long id) {
        if (goodsMapper.selectById(id) == null) {
            throw exception(GOODS_NOT_EXISTS);
        }
    }

    @Override
    public PlugGoodsDO getGoods(Long id) {
        return goodsMapper.selectById(id);
    }

    @Override
    public PageResult<PlugGoodsDO> getGoodsPage(PlugGoodsPageReqVO pageReqVO) {
        return goodsMapper.selectPage(pageReqVO);
    }

    @Override
    public List<PlugGoodsDO> getGoodsList(PlugGoodsExportReqVO exportReqVO) {
        return goodsMapper.selectList(exportReqVO);
    }

}
