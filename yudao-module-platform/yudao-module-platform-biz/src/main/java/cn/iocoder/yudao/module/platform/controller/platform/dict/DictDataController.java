package cn.iocoder.yudao.module.platform.controller.platform.dict;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;
import static cn.iocoder.yudao.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.framework.excel.core.util.ExcelUtils;
import cn.iocoder.yudao.framework.operatelog.core.annotations.OperateLog;
import cn.iocoder.yudao.module.platform.controller.platform.dict.vo.data.DictDataCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.dict.vo.data.DictDataExcelVO;
import cn.iocoder.yudao.module.platform.controller.platform.dict.vo.data.DictDataExportReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.dict.vo.data.DictDataPageReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.dict.vo.data.DictDataRespVO;
import cn.iocoder.yudao.module.platform.controller.platform.dict.vo.data.DictDataSimpleRespVO;
import cn.iocoder.yudao.module.platform.controller.platform.dict.vo.data.DictDataUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.dict.DictDataDO;
import cn.iocoder.yudao.module.platform.service.dict.DictDataService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.io.IOException;
import java.util.List;
import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "管理后台 - 字典数据")
@RestController
@RequestMapping("/system/dict-data")
@Validated
public class DictDataController {

    @Resource
    private DictDataService dictDataService;

    @PostMapping("/create")
    @Operation(summary = "新增字典数据")
    @PreAuthorize("@ps.hasPermission('system:dict:create')")
    public CommonResult<Long> createDictData(@Valid @RequestBody DictDataCreateReqVO reqVO) {
        Long dictDataId = dictDataService.createDictData(reqVO);
        return success(dictDataId);
    }

    @PutMapping("/update")
    @Operation(summary = "修改字典数据")
    @PreAuthorize("@ps.hasPermission('system:dict:update')")
    public CommonResult<Boolean> updateDictData(@Valid @RequestBody DictDataUpdateReqVO reqVO) {
        dictDataService.updateDictData(reqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除字典数据")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('system:dict:delete')")
    public CommonResult<Boolean> deleteDictData(Long id) {
        dictDataService.deleteDictData(id);
        return success(true);
    }

    @GetMapping("/list-all-simple")
    @Operation(summary = "获得全部字典数据列表", description = "一般用于管理后台缓存字典数据在本地")
    // 无需添加权限认证，因为前端全局都需要
    public CommonResult<List<DictDataSimpleRespVO>> getSimpleDictDataList() {
        List<DictDataDO> list = dictDataService.getDictDataList();
        return success(BeanUtils.toBean(list, DictDataSimpleRespVO.class));
    }

    @GetMapping("/page")
    @Operation(summary = "/获得字典类型的分页列表")
    @PreAuthorize("@ps.hasPermission('system:dict:query')")
    public CommonResult<PageResult<DictDataRespVO>> getDictTypePage(@Valid DictDataPageReqVO reqVO) {
        return success(BeanUtils.toBean(dictDataService.getDictDataPage(reqVO), DictDataRespVO.class));
    }

    @GetMapping(value = "/get")
    @Operation(summary = "/查询字典数据详细")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('system:dict:query')")
    public CommonResult<DictDataRespVO> getDictData(@RequestParam("id") Long id) {
        return success(BeanUtils.toBean(dictDataService.getDictData(id), DictDataRespVO.class));
    }

    @GetMapping("/export")
    @Operation(summary = "导出字典数据")
    @PreAuthorize("@ps.hasPermission('system:dict:export')")
    @OperateLog(type = EXPORT)
    public void export(HttpServletResponse response, @Valid DictDataExportReqVO reqVO) throws IOException {
        List<DictDataDO> list = dictDataService.getDictDataList(reqVO);
        List<DictDataExcelVO> data = BeanUtils.toBean(list, DictDataExcelVO.class);
        // 输出
        ExcelUtils.write(response, "字典数据.xls", "数据列表", DictDataExcelVO.class, data);
    }

}
