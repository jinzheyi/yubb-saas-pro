package com.shengyu.module.platform.controller.platform.logger;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageParam;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.excel.core.util.ExcelUtils;
import com.shengyu.framework.operatelog.core.annotations.OperateLog;
import com.shengyu.module.platform.controller.platform.logger.vo.operatelog.OperateLogPageReqVO;
import com.shengyu.module.platform.controller.platform.logger.vo.operatelog.OperateLogRespVO;
import com.shengyu.module.platform.convert.logger.OperateLogConvert;
import com.shengyu.module.platform.dal.dataobject.logger.PlatformOperateLogDO;
import com.shengyu.module.platform.dal.dataobject.user.PlatformUserDO;
import com.shengyu.module.platform.service.logger.PlatformOperateLogService;
import com.shengyu.module.platform.service.user.PlatformUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import java.io.IOException;
import java.util.List;
import java.util.Map;

import static com.shengyu.framework.common.pojo.CommonResult.success;
import static com.shengyu.framework.common.util.collection.CollectionUtils.convertList;
import static com.shengyu.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;

@Tag(name = "管理后台 - 操作日志")
@RestController
@RequestMapping("/system/operate-log")
@Validated
public class PlatformOperateLogController {

    @Resource
    private PlatformOperateLogService platformOperateLogService;
    @Resource
    private PlatformUserService platformUserService;

    @GetMapping("/get")
    @Operation(summary = "查看操作日志")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('system:operate-log:query')")
    public CommonResult<OperateLogRespVO> getOperateLog(@RequestParam("id") Long id) {
        PlatformOperateLogDO operateLog = platformOperateLogService.getOperateLog(id);
        return success(BeanUtils.toBean(operateLog, OperateLogRespVO.class));
    }

    @GetMapping("/page")
    @Operation(summary = "查看操作日志分页列表")
    @PreAuthorize("@ps.hasPermission('system:operate-log:query')")
    public CommonResult<PageResult<OperateLogRespVO>> pageOperateLog(@Valid OperateLogPageReqVO reqVO) {
        PageResult<PlatformOperateLogDO> pageResult = platformOperateLogService.getOperateLogPage(reqVO);
        // 获得拼接需要的数据
        Map<Long, PlatformUserDO> userMap = platformUserService.getUserMap(
            convertList(pageResult.getList(), PlatformOperateLogDO::getUserId));
        return success(new PageResult<>(OperateLogConvert.INSTANCE.convertList(pageResult.getList(), userMap),
            pageResult.getTotal()));
    }

    @Operation(summary = "导出操作日志")
    @GetMapping("/export")
    @PreAuthorize("@ps.hasPermission('system:operate-log:export')")
    @OperateLog(type = EXPORT)
    public void exportOperateLog(HttpServletResponse response, @Valid OperateLogPageReqVO exportReqVO) throws IOException {
        exportReqVO.setPageSize(PageParam.PAGE_SIZE_NONE);
        List<PlatformOperateLogDO> list = platformOperateLogService.getOperateLogPage(exportReqVO).getList();
        // 输出
        Map<Long, PlatformUserDO> userMap = platformUserService.getUserMap(
            convertList(list, PlatformOperateLogDO::getUserId));
        ExcelUtils.write(response, "操作日志.xls", "数据列表", OperateLogRespVO.class,
            OperateLogConvert.INSTANCE.convertList(list, userMap));
    }

}
