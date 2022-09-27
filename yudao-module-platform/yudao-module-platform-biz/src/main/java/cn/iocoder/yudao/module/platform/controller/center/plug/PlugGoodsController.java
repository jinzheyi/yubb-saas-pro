package cn.iocoder.yudao.module.platform.controller.center.plug;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.excel.core.util.ExcelUtils;
import cn.iocoder.yudao.framework.operatelog.core.annotations.OperateLog;
import cn.iocoder.yudao.module.platform.controller.center.plug.vo.goods.*;
import cn.iocoder.yudao.module.platform.convert.plug.PlugGoodsConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.plug.PlugGoodsDO;
import cn.iocoder.yudao.module.platform.service.plug.PlugGoodsService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiImplicitParam;
import io.swagger.annotations.ApiOperation;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import java.io.IOException;
import java.util.Collection;
import java.util.List;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;
import static cn.iocoder.yudao.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;

@Api(tags = "管理后台 - 应用商品")
@RestController
@RequestMapping("/center/plug-goods")
@Validated
public class PlugGoodsController {

    @Resource
    private PlugGoodsService goodsService;

    @PostMapping("/create")
    @ApiOperation("创建应用商品")
    @PreAuthorize("@cs.hasPermission('center:plug-goods:create')")
    public CommonResult<Long> createGoods(@Valid @RequestBody PlugGoodsCreateReqVO createReqVO) {
        return success(goodsService.createGoods(createReqVO));
    }

    @PutMapping("/update")
    @ApiOperation("更新应用商品")
    @PreAuthorize("@cs.hasPermission('center:plug-goods:update')")
    public CommonResult<Boolean> updateGoods(@Valid @RequestBody PlugGoodsUpdateReqVO updateReqVO) {
        goodsService.updateGoods(updateReqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @ApiOperation("删除应用商品")
    @ApiImplicitParam(name = "id", value = "编号", required = true, dataTypeClass = Long.class)
    @PreAuthorize("@cs.hasPermission('center:plug-goods:delete')")
    public CommonResult<Boolean> deleteGoods(@RequestParam("id") Long id) {
        goodsService.deleteGoods(id);
        return success(true);
    }

    @GetMapping("/get")
    @ApiOperation("获得应用商品")
    @ApiImplicitParam(name = "id", value = "编号", required = true, example = "1024", dataTypeClass = Long.class)
    @PreAuthorize("@cs.hasPermission('center:plug-goods:query')")
    public CommonResult<PlugGoodsRespVO> getGoods(@RequestParam("id") Long id) {
        PlugGoodsDO goods = goodsService.getGoods(id);
        return success(PlugGoodsConvert.INSTANCE.convert(goods));
    }

    @GetMapping("/page")
    @ApiOperation("获得应用商品分页")
    @PreAuthorize("@cs.hasPermission('center:plug-goods:list')")
    public CommonResult<PageResult<PlugGoodsRespVO>> getGoodsPage(@Valid PlugGoodsPageReqVO pageVO) {
        PageResult<PlugGoodsDO> pageResult = goodsService.getGoodsPage(pageVO);
        return success(PlugGoodsConvert.INSTANCE.convertPage(pageResult));
    }

    @GetMapping("/export-excel")
    @ApiOperation("导出应用商品 Excel")
    @PreAuthorize("@cs.hasPermission('center:plug-goods:export')")
    @OperateLog(type = EXPORT)
    public void exportGoodsExcel(@Valid PlugGoodsExportReqVO exportReqVO,
              HttpServletResponse response) throws IOException {
        List<PlugGoodsDO> list = goodsService.getGoodsList(exportReqVO);
        // 导出 Excel
        List<PlugGoodsExcelVO> datas = PlugGoodsConvert.INSTANCE.convertList02(list);
        ExcelUtils.write(response, "应用商品.xls", "数据", PlugGoodsExcelVO.class, datas);
    }

}
