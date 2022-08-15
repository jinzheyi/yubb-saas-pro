package cn.iocoder.yudao.module.platform.controller.center.logger;

import cn.iocoder.yudao.module.platform.controller.center.logger.vo.operatelog.OperateLogExcelVO;
import cn.iocoder.yudao.module.platform.controller.center.logger.vo.operatelog.OperateLogExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.logger.vo.operatelog.OperateLogPageReqVO;
import cn.iocoder.yudao.module.platform.controller.center.logger.vo.operatelog.OperateLogRespVO;
import cn.iocoder.yudao.module.platform.convert.logger.OperateLogConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.logger.PlatformOperateLogDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.user.PlatformUserDO;
import cn.iocoder.yudao.module.platform.service.logger.PlatformOperateLogService;
import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.collection.CollectionUtils;
import cn.iocoder.yudao.framework.common.util.collection.MapUtils;
import cn.iocoder.yudao.framework.excel.core.util.ExcelUtils;
import cn.iocoder.yudao.framework.operatelog.core.annotations.OperateLog;
import cn.iocoder.yudao.module.platform.service.user.PlatformUserService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;
import static cn.iocoder.yudao.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;

@Api(tags = "管理后台 - 操作日志")
@RestController
@RequestMapping("/center/operate-log")
@Validated
public class CenterOperateLogController {

    @Resource
    private PlatformOperateLogService platformOperateLogService;
    @Resource
    private PlatformUserService userService;

    @GetMapping("/page")
    @ApiOperation("查看操作日志分页列表")
    @PreAuthorize("@cs.hasPermission('center:operate-log:query')")
    public CommonResult<PageResult<OperateLogRespVO>> pageOperateLog(@Valid OperateLogPageReqVO reqVO) {
        PageResult<PlatformOperateLogDO> pageResult = platformOperateLogService.getOperateLogPage(reqVO);

        // 获得拼接需要的数据
        Collection<Long> userIds = CollectionUtils.convertList(pageResult.getList(), PlatformOperateLogDO::getUserId);
        Map<Long, PlatformUserDO> userMap = userService.getUserMap(userIds);
        // 拼接数据
        List<OperateLogRespVO> list = new ArrayList<>(pageResult.getList().size());
        pageResult.getList().forEach(operateLog -> {
            OperateLogRespVO respVO = OperateLogConvert.INSTANCE.convert(operateLog);
            list.add(respVO);
            // 拼接用户信息
            MapUtils.findAndThen(userMap, operateLog.getUserId(), user -> respVO.setUserNickname(user.getNickname()));
        });
        return success(new PageResult<>(list, pageResult.getTotal()));
    }

    @ApiOperation("导出操作日志")
    @GetMapping("/export")
    @PreAuthorize("@cs.hasPermission('center:operate-log:export')")
    @OperateLog(type = EXPORT)
    public void exportOperateLog(HttpServletResponse response, @Valid OperateLogExportReqVO reqVO) throws IOException {
        List<PlatformOperateLogDO> list = platformOperateLogService.getOperateLogs(reqVO);

        // 获得拼接需要的数据
        Collection<Long> userIds = CollectionUtils.convertList(list, PlatformOperateLogDO::getUserId);
        Map<Long, PlatformUserDO> userMap = userService.getUserMap(userIds);
        // 拼接数据
        List<OperateLogExcelVO> excelDataList = OperateLogConvert.INSTANCE.convertList(list, userMap);
        // 输出
        ExcelUtils.write(response, "操作日志.xls", "数据列表", OperateLogExcelVO.class, excelDataList);
    }

}
