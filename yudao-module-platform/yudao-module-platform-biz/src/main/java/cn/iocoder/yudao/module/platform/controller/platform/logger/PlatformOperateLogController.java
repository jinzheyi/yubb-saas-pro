package cn.iocoder.yudao.module.platform.controller.platform.logger;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;
import static cn.iocoder.yudao.framework.common.util.collection.CollectionUtils.convertList;
import static cn.iocoder.yudao.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageParam;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.excel.core.util.ExcelUtils;
import cn.iocoder.yudao.framework.operatelog.core.annotations.OperateLog;
import cn.iocoder.yudao.module.platform.controller.platform.logger.vo.operatelog.OperateLogPageReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.logger.vo.operatelog.OperateLogRespVO;
import cn.iocoder.yudao.module.platform.convert.logger.OperateLogConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.logger.PlatformOperateLogDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.user.PlatformUserDO;
import cn.iocoder.yudao.module.platform.service.logger.PlatformOperateLogService;
import cn.iocoder.yudao.module.platform.service.user.PlatformUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "管理后台 - 操作日志")
@RestController
@RequestMapping("/system/operate-log")
@Validated
public class PlatformOperateLogController {

    @Resource
    private PlatformOperateLogService platformOperateLogService;
    @Resource
    private PlatformUserService platformUserService;

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
