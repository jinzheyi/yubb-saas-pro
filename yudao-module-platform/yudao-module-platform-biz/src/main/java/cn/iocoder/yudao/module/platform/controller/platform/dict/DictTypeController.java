package cn.iocoder.yudao.module.platform.controller.platform.dict;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;
import static cn.iocoder.yudao.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.framework.excel.core.util.ExcelUtils;
import cn.iocoder.yudao.framework.operatelog.core.annotations.OperateLog;
import cn.iocoder.yudao.module.platform.controller.platform.dict.vo.type.DictTypeCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.dict.vo.type.DictTypeExcelVO;
import cn.iocoder.yudao.module.platform.controller.platform.dict.vo.type.DictTypeExportReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.dict.vo.type.DictTypePageReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.dict.vo.type.DictTypeRespVO;
import cn.iocoder.yudao.module.platform.controller.platform.dict.vo.type.DictTypeSimpleRespVO;
import cn.iocoder.yudao.module.platform.controller.platform.dict.vo.type.DictTypeUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.dict.DictTypeDO;
import cn.iocoder.yudao.module.platform.service.dict.DictTypeService;
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

@Tag(name = "管理后台 - 字典类型")
@RestController
@RequestMapping("/system/dict-type")
@Validated
public class DictTypeController {

    @Resource
    private DictTypeService dictTypeService;

    @PostMapping("/create")
    @Operation(summary = "创建字典类型")
    @PreAuthorize("@ps.hasPermission('system:dict:create')")
    public CommonResult<Long> createDictType(@Valid @RequestBody DictTypeCreateReqVO reqVO) {
        Long dictTypeId = dictTypeService.createDictType(reqVO);
        return success(dictTypeId);
    }

    @PutMapping("/update")
    @Operation(summary = "修改字典类型")
    @PreAuthorize("@ps.hasPermission('system:dict:update')")
    public CommonResult<Boolean> updateDictType(@Valid @RequestBody DictTypeUpdateReqVO reqVO) {
        dictTypeService.updateDictType(reqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除字典类型")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('system:dict:delete')")
    public CommonResult<Boolean> deleteDictType(Long id) {
        dictTypeService.deleteDictType(id);
        return success(true);
    }

    @Operation(summary = "/获得字典类型的分页列表")
    @GetMapping("/page")
    @PreAuthorize("@ps.hasPermission('system:dict:query')")
    public CommonResult<PageResult<DictTypeRespVO>> pageDictTypes(@Valid DictTypePageReqVO reqVO) {
        return success(BeanUtils.toBean(dictTypeService.getDictTypePage(reqVO), DictTypeRespVO.class));
    }

    @Operation(summary = "/查询字典类型详细")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @GetMapping(value = "/get")
    @PreAuthorize("@ps.hasPermission('system:dict:query')")
    public CommonResult<DictTypeRespVO> getDictType(@RequestParam("id") Long id) {
        return success(BeanUtils.toBean(dictTypeService.getDictType(id), DictTypeRespVO.class));
    }

    @GetMapping("/list-all-simple")
    @Operation(summary = "获得全部字典类型列表", description = "包括开启 + 禁用的字典类型，主要用于前端的下拉选项")
    // 无需添加权限认证，因为前端全局都需要
    public CommonResult<List<DictTypeSimpleRespVO>> getSimpleDictTypeList() {
        List<DictTypeDO> list = dictTypeService.getDictTypeList();
        return success(BeanUtils.toBean(list, DictTypeSimpleRespVO.class));
    }

    @Operation(summary = "导出数据类型")
    @GetMapping("/export")
    @PreAuthorize("@ps.hasPermission('system:dict:query')")
    @OperateLog(type = EXPORT)
    public void export(HttpServletResponse response, @Valid DictTypeExportReqVO reqVO) throws IOException {
        List<DictTypeDO> list = dictTypeService.getDictTypeList(reqVO);
        List<DictTypeExcelVO> data = BeanUtils.toBean(list, DictTypeExcelVO.class);
        // 输出
        ExcelUtils.write(response, "字典类型.xls", "类型列表", DictTypeExcelVO.class, data);
    }

}
