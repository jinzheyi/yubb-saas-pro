package com.shengyu.module.system.controller.admin.logger;

import static com.shengyu.framework.common.pojo.CommonResult.success;
import static com.shengyu.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.excel.core.util.ExcelUtils;
import com.shengyu.framework.operatelog.core.annotations.OperateLog;
import com.shengyu.module.system.controller.admin.logger.vo.loginlog.LoginLogExcelVO;
import com.shengyu.module.system.controller.admin.logger.vo.loginlog.LoginLogExportReqVO;
import com.shengyu.module.system.controller.admin.logger.vo.loginlog.LoginLogPageReqVO;
import com.shengyu.module.system.controller.admin.logger.vo.loginlog.LoginLogRespVO;
import com.shengyu.module.system.dal.dataobject.logger.LoginLogDO;
import com.shengyu.module.system.service.logger.LoginLogService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.io.IOException;
import java.util.List;
import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "管理后台 - 登录日志")
@RestController
@RequestMapping("/system/login-log")
@Validated
public class LoginLogController {

    @Resource
    private LoginLogService loginLogService;

    @GetMapping("/get")
    @Operation(summary = "获得登录日志")
    @PreAuthorize("@ss.hasPermission('system:login-log:query')")
    public CommonResult<LoginLogRespVO> getLoginLog(Long id) {
        LoginLogDO loginLog = loginLogService.getLoginLog(id);
        return success(BeanUtils.toBean(loginLog, LoginLogRespVO.class));
    }

    @GetMapping("/page")
    @Operation(summary = "获得登录日志分页列表")
    @PreAuthorize("@ss.hasPermission('system:login-log:query')")
    public CommonResult<PageResult<LoginLogRespVO>> getLoginLogPage(@Valid LoginLogPageReqVO reqVO) {
        PageResult<LoginLogDO> page = loginLogService.getLoginLogPage(reqVO);
        return success(BeanUtils.toBean(page, LoginLogRespVO.class));
    }

    @GetMapping("/export")
    @Operation(summary = "导出登录日志 Excel")
    @PreAuthorize("@ss.hasPermission('system:login-log:export')")
    @OperateLog(type = EXPORT)
    public void exportLoginLog(HttpServletResponse response, @Valid LoginLogExportReqVO reqVO) throws IOException {
        List<LoginLogDO> list = loginLogService.getLoginLogList(reqVO);
        // 拼接数据
        List<LoginLogExcelVO> data = BeanUtils.toBean(list, LoginLogExcelVO.class);
        // 输出
        ExcelUtils.write(response, "登录日志.xls", "数据列表", LoginLogExcelVO.class, data);
    }

}
