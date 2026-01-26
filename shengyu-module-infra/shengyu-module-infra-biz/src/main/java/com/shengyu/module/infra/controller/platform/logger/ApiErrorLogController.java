package com.shengyu.module.infra.controller.platform.logger;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageParam;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.excel.core.util.ExcelUtils;
import com.shengyu.framework.operatelog.core.annotations.OperateLog;
import com.shengyu.module.infra.controller.platform.logger.vo.apierrorlog.ApiErrorLogPageReqVO;
import com.shengyu.module.infra.controller.platform.logger.vo.apierrorlog.ApiErrorLogRespVO;
import com.shengyu.module.infra.dal.dataobject.logger.ApiErrorLogDO;
import com.shengyu.module.infra.service.logger.ApiErrorLogService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.Parameters;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import java.io.IOException;
import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;
import static com.shengyu.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;
import static com.shengyu.framework.security.core.util.SecurityFrameworkUtils.getPlatformLoginUserId;

@Tag(name = "管理后台 - API 错误日志")
@RestController
@RequestMapping("/infra/api-error-log")
@Validated
public class ApiErrorLogController {

    @Resource
    private ApiErrorLogService apiErrorLogService;

    @PutMapping("/update-status")
    @Operation(summary = "更新 API 错误日志的状态")
    @Parameters({
            @Parameter(name = "id", description = "编号", required = true, example = "1024"),
            @Parameter(name = "processStatus", description = "处理状态", required = true, example = "1")
    })
    @PreAuthorize("@ps.hasPermission('infra:api-error-log:update-status')")
    public CommonResult<Boolean> updateApiErrorLogProcess(@RequestParam("id") Long id,
                                                          @RequestParam("processStatus") Integer processStatus) {
        apiErrorLogService.updateApiErrorLogProcess(id, processStatus, getPlatformLoginUserId());
        return success(true);
    }

    @GetMapping("/get")
    @Operation(summary = "获得 API 错误日志")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('infra:api-error-log:query')")
    public CommonResult<ApiErrorLogRespVO> getApiErrorLog(@RequestParam("id") Long id) {
        ApiErrorLogDO apiErrorLog = apiErrorLogService.getApiErrorLog(id);
        return success(BeanUtils.toBean(apiErrorLog, ApiErrorLogRespVO.class));
    }

    @GetMapping("/page")
    @Operation(summary = "获得 API 错误日志分页")
    @PreAuthorize("@ps.hasPermission('infra:api-error-log:query')")
    public CommonResult<PageResult<ApiErrorLogRespVO>> getApiErrorLogPage(@Valid ApiErrorLogPageReqVO pageReqVO) {
        PageResult<ApiErrorLogDO> pageResult = apiErrorLogService.getApiErrorLogPage(pageReqVO);
        return success(BeanUtils.toBean(pageResult, ApiErrorLogRespVO.class));
    }

    @GetMapping("/export-excel")
    @Operation(summary = "导出 API 错误日志 Excel")
    @PreAuthorize("@ps.hasPermission('infra:api-error-log:export')")
    @OperateLog(type = EXPORT)
    public void exportApiErrorLogExcel(@Valid ApiErrorLogPageReqVO exportReqVO,
              HttpServletResponse response) throws IOException {
        exportReqVO.setPageSize(PageParam.PAGE_SIZE_NONE);
        List<ApiErrorLogDO> list = apiErrorLogService.getApiErrorLogPage(exportReqVO).getList();
        // 导出 Excel
        ExcelUtils.write(response, "API 错误日志.xls", "数据", ApiErrorLogRespVO.class,
                BeanUtils.toBean(list, ApiErrorLogRespVO.class));
    }

}
