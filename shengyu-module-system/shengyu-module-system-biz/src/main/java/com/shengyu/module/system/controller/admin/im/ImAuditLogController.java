package com.shengyu.module.system.controller.admin.im;

import com.fhs.core.trans.anno.TransMethodResult;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageParam;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.excel.core.util.ExcelUtils;
import com.shengyu.framework.operatelog.core.annotations.OperateLog;
import com.shengyu.module.system.controller.admin.im.vo.auditlog.AuditLogPageReqVO;
import com.shengyu.module.system.controller.admin.im.vo.auditlog.AuditLogRespVO;
import com.shengyu.module.system.convert.im.AuditLogConvert;
import com.shengyu.module.system.dal.dataobject.im.audit.ImAuditLogDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.service.im.ImAuditLogService;
import com.shengyu.module.system.service.user.AdminUserService;
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

/**
 * IM 审计日志控制器
 * 等保三级合规要求：提供审计日志查询与管理能力
 *
 * @author 圣钰科技
 */
@Tag(name = "管理后台 - IM 审计日志")
@RestController
@RequestMapping("/system/audit-log")
@Validated
public class ImAuditLogController {

    @Resource
    private ImAuditLogService imAuditLogService;

    @Resource
    private AdminUserService adminUserService;

    @GetMapping("/get")
    @Operation(summary = "查看审计日志详情")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('system:audit-log:query')")
    public CommonResult<AuditLogRespVO> getAuditLog(@RequestParam("id") Long id) {
        ImAuditLogDO auditLog = imAuditLogService.getAuditLog(id);
        return success(BeanUtils.toBean(auditLog, AuditLogRespVO.class));
    }

    @GetMapping("/page")
    @Operation(summary = "查看审计日志分页列表")
    @PreAuthorize("@ss.hasPermission('system:audit-log:query')")
    public CommonResult<PageResult<AuditLogRespVO>> pageAuditLog(@Valid AuditLogPageReqVO pageReqVO) {
        PageResult<ImAuditLogDO> pageResult = imAuditLogService.getAuditLogPage(pageReqVO);
        // 获得拼接需要的数据
        Map<Long, AdminUserDO> userMap = adminUserService.getUserMap(
                convertList(pageResult.getList(), ImAuditLogDO::getUserId));
        return success(new PageResult<>(AuditLogConvert.INSTANCE.convertList(pageResult.getList(), userMap),
                pageResult.getTotal()));
    }

    @Operation(summary = "导出审计日志")
    @GetMapping("/export")
    @PreAuthorize("@ss.hasPermission('system:audit-log:export')")
    @TransMethodResult
    @OperateLog(type = EXPORT)
    public void exportAuditLog(HttpServletResponse response, @Valid AuditLogPageReqVO exportReqVO) throws IOException {
        exportReqVO.setPageSize(PageParam.PAGE_SIZE_NONE);
        List<ImAuditLogDO> list = imAuditLogService.getAuditLogPage(exportReqVO).getList();
        // 输出
        Map<Long, AdminUserDO> userMap = adminUserService.getUserMap(
                convertList(list, ImAuditLogDO::getUserId));
        ExcelUtils.write(response, "IM 审计日志.xls", "数据列表", AuditLogRespVO.class,
                AuditLogConvert.INSTANCE.convertList(list, userMap));
    }
}
