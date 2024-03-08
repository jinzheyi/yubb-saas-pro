package cn.iocoder.yudao.module.platform.controller.platform.logger;

import static cn.iocoder.yudao.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.framework.excel.core.util.ExcelUtils;
import cn.iocoder.yudao.framework.operatelog.core.annotations.OperateLog;
import cn.iocoder.yudao.module.platform.controller.platform.logger.vo.loginlog.LoginLogExcelVO;
import cn.iocoder.yudao.module.platform.controller.platform.logger.vo.loginlog.LoginLogExportReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.logger.vo.loginlog.LoginLogPageReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.logger.vo.loginlog.LoginLogRespVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.logger.PlatformLoginLogDO;
import cn.iocoder.yudao.module.platform.service.logger.PlatformLoginLogService;
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
public class PlatformLoginLogController {

    @Resource
    private PlatformLoginLogService platformLoginLogService;

    @GetMapping("/page")
    @Operation(summary = "获得登录日志分页列表")
    @PreAuthorize("@ps.hasPermission('system:login-log:query')")
    public CommonResult<PageResult<LoginLogRespVO>> getLoginLogPage(@Valid LoginLogPageReqVO reqVO) {
        PageResult<PlatformLoginLogDO> page = platformLoginLogService.getLoginLogPage(reqVO);
        return CommonResult.success(BeanUtils.toBean(page, LoginLogRespVO.class));
    }

    @GetMapping("/export")
    @Operation(summary = "导出登录日志 Excel")
    @PreAuthorize("@ps.hasPermission('system:login-log:export')")
    @OperateLog(type = EXPORT)
    public void exportLoginLog(HttpServletResponse response, @Valid LoginLogExportReqVO reqVO) throws IOException {
        List<PlatformLoginLogDO> list = platformLoginLogService.getLoginLogList(reqVO);
        // 拼接数据
        List<LoginLogExcelVO> data = BeanUtils.toBean(list, LoginLogExcelVO.class);
        // 输出
        ExcelUtils.write(response, "登录日志.xls", "数据列表", LoginLogExcelVO.class, data);
    }

}
