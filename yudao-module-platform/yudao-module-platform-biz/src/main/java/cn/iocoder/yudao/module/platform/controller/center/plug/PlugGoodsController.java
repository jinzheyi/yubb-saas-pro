package cn.iocoder.yudao.module.platform.controller.center.plug;

import org.springframework.web.bind.annotation.*;
import javax.annotation.Resource;
import org.springframework.validation.annotation.Validated;
import org.springframework.security.access.prepost.PreAuthorize;
import io.swagger.annotations.*;

import javax.validation.constraints.*;
import javax.validation.*;
import javax.servlet.http.*;
import java.util.*;
import java.io.IOException;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;

import cn.iocoder.yudao.framework.excel.core.util.ExcelUtils;

import cn.iocoder.yudao.framework.operatelog.core.annotations.OperateLog;
import static cn.iocoder.yudao.framework.operatelog.core.enums.OperateTypeEnum.*;

import cn.iocoder.yudao.module.plug.controller.admin.goods.vo.*;
import cn.iocoder.yudao.module.plug.dal.dataobject.goods.PlugGoodsDO;
import cn.iocoder.yudao.module.plug.convert.goods.PlugGoodsConvert;
import cn.iocoder.yudao.module.plug.service.goods.PlugGoodsService;

@Api(tags = "管理后台 - 应用商品")
@RestController
@RequestMapping("/plug/goods")
@Validated
public class PlugGoodsController {

    @Resource
    private PlugGoodsService goodsService;

    @PostMapping("/create")
    @ApiOperation("创建应用商品")
    @PreAuthorize("@ss.hasPermission('plug:goods:create')")
    public CommonResult<Long> createGoods(@Valid @RequestBody PlugGoodsCreateReqVO createReqVO) {
        return success(goodsService.createGoods(createReqVO));
    }

    @PutMapping("/update")
    @ApiOperation("更新应用商品")
    @PreAuthorize("@ss.hasPermission('plug:goods:update')")
    public CommonResult<Boolean> updateGoods(@Valid @RequestBody PlugGoodsUpdateReqVO updateReqVO) {
        goodsService.updateGoods(updateReqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @ApiOperation("删除应用商品")
    @ApiImplicitParam(name = "id", value = "编号", required = true, dataTypeClass = Long.class)
    @PreAuthorize("@ss.hasPermission('plug:goods:delete')")
    public CommonResult<Boolean> deleteGoods(@RequestParam("id") Long id) {
        goodsService.deleteGoods(id);
        return success(true);
    }

    @GetMapping("/get")
    @ApiOperation("获得应用商品")
    @ApiImplicitParam(name = "id", value = "编号", required = true, example = "1024", dataTypeClass = Long.class)
    @PreAuthorize("@ss.hasPermission('plug:goods:query')")
    public CommonResult<PlugGoodsRespVO> getGoods(@RequestParam("id") Long id) {
        PlugGoodsDO goods = goodsService.getGoods(id);
        return success(PlugGoodsConvert.INSTANCE.convert(goods));
    }

    @GetMapping("/list")
    @ApiOperation("获得应用商品列表")
    @ApiImplicitParam(name = "ids", value = "编号列表", required = true, example = "1024,2048", dataTypeClass = List.class)
    @PreAuthorize("@ss.hasPermission('plug:goods:query')")
    public CommonResult<List<PlugGoodsRespVO>> getGoodsList(@RequestParam("ids") Collection<Long> ids) {
        List<PlugGoodsDO> list = goodsService.getGoodsList(ids);
        return success(PlugGoodsConvert.INSTANCE.convertList(list));
    }

    @GetMapping("/page")
    @ApiOperation("获得应用商品分页")
    @PreAuthorize("@ss.hasPermission('plug:goods:query')")
    public CommonResult<PageResult<PlugGoodsRespVO>> getGoodsPage(@Valid PlugGoodsPageReqVO pageVO) {
        PageResult<PlugGoodsDO> pageResult = goodsService.getGoodsPage(pageVO);
        return success(PlugGoodsConvert.INSTANCE.convertPage(pageResult));
    }

    @GetMapping("/export-excel")
    @ApiOperation("导出应用商品 Excel")
    @PreAuthorize("@ss.hasPermission('plug:goods:export')")
    @OperateLog(type = EXPORT)
    public void exportGoodsExcel(@Valid PlugGoodsExportReqVO exportReqVO,
              HttpServletResponse response) throws IOException {
        List<PlugGoodsDO> list = goodsService.getGoodsList(exportReqVO);
        // 导出 Excel
        List<PlugGoodsExcelVO> datas = PlugGoodsConvert.INSTANCE.convertList02(list);
        ExcelUtils.write(response, "应用商品.xls", "数据", PlugGoodsExcelVO.class, datas);
    }

}
