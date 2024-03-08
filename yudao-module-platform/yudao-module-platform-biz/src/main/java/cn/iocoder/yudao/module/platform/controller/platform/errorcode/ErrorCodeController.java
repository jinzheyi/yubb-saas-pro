package cn.iocoder.yudao.module.platform.controller.platform.errorcode;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;
import static cn.iocoder.yudao.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.framework.excel.core.util.ExcelUtils;
import cn.iocoder.yudao.framework.operatelog.core.annotations.OperateLog;
import cn.iocoder.yudao.module.platform.controller.platform.errorcode.vo.ErrorCodeCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.errorcode.vo.ErrorCodeExcelVO;
import cn.iocoder.yudao.module.platform.controller.platform.errorcode.vo.ErrorCodeExportReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.errorcode.vo.ErrorCodePageReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.errorcode.vo.ErrorCodeRespVO;
import cn.iocoder.yudao.module.platform.controller.platform.errorcode.vo.ErrorCodeUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.errorcode.ErrorCodeDO;
import cn.iocoder.yudao.module.platform.service.errorcode.ErrorCodeService;
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

@Tag(name = "管理后台 - 错误码")
@RestController
@RequestMapping("/system/error-code")
@Validated
public class ErrorCodeController {

    @Resource
    private ErrorCodeService errorCodeService;

    @PostMapping("/create")
    @Operation(summary = "创建错误码")
    @PreAuthorize("@ps.hasPermission('system:error-code:create')")
    public CommonResult<Long> createErrorCode(@Valid @RequestBody ErrorCodeCreateReqVO createReqVO) {
        return success(errorCodeService.createErrorCode(createReqVO));
    }

    @PutMapping("/update")
    @Operation(summary = "更新错误码")
    @PreAuthorize("@ps.hasPermission('system:error-code:update')")
    public CommonResult<Boolean> updateErrorCode(@Valid @RequestBody ErrorCodeUpdateReqVO updateReqVO) {
        errorCodeService.updateErrorCode(updateReqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除错误码")
    @Parameter(name = "id", description = "编号", required = true)
    @PreAuthorize("@ps.hasPermission('system:error-code:delete')")
    public CommonResult<Boolean> deleteErrorCode(@RequestParam("id") Long id) {
        errorCodeService.deleteErrorCode(id);
        return success(true);
    }

    @GetMapping("/get")
    @Operation(summary = "获得错误码")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('system:error-code:query')")
    public CommonResult<ErrorCodeRespVO> getErrorCode(@RequestParam("id") Long id) {
        ErrorCodeDO errorCode = errorCodeService.getErrorCode(id);
        return success(BeanUtils.toBean(errorCode, ErrorCodeRespVO.class));
    }

    @GetMapping("/page")
    @Operation(summary = "获得错误码分页")
    @PreAuthorize("@ps.hasPermission('system:error-code:query')")
    public CommonResult<PageResult<ErrorCodeRespVO>> getErrorCodePage(@Valid ErrorCodePageReqVO pageVO) {
        PageResult<ErrorCodeDO> pageResult = errorCodeService.getErrorCodePage(pageVO);
        return success(BeanUtils.toBean(pageResult, ErrorCodeRespVO.class));
    }

    @GetMapping("/export-excel")
    @Operation(summary = "导出错误码 Excel")
    @PreAuthorize("@ps.hasPermission('system:error-code:export')")
    @OperateLog(type = EXPORT)
    public void exportErrorCodeExcel(@Valid ErrorCodeExportReqVO exportReqVO,
              HttpServletResponse response) throws IOException {
        List<ErrorCodeDO> list = errorCodeService.getErrorCodeList(exportReqVO);
        // 导出 Excel
        List<ErrorCodeExcelVO> datas = BeanUtils.toBean(list, ErrorCodeExcelVO.class);
        ExcelUtils.write(response, "错误码.xls", "数据", ErrorCodeExcelVO.class, datas);
    }

}
