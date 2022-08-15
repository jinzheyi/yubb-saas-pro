package cn.iocoder.yudao.module.platform.controller.center.sms;

import cn.iocoder.yudao.module.platform.controller.center.sms.vo.log.SmsLogExcelVO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.log.SmsLogExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.log.SmsLogPageReqVO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.log.SmsLogRespVO;
import cn.iocoder.yudao.module.platform.convert.sms.SmsLogConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.sms.SmsLogDO;
import cn.iocoder.yudao.module.platform.service.sms.PlatformSmsLogService;
import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.excel.core.util.ExcelUtils;
import cn.iocoder.yudao.framework.operatelog.core.annotations.OperateLog;
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
import java.util.List;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;
import static cn.iocoder.yudao.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;

@Api(tags = "管理后台 - 短信日志")
@RestController
@RequestMapping("/center/sms-log")
@Validated
public class SmsLogController {

    @Resource
    private PlatformSmsLogService platformSmsLogService;

    @GetMapping("/page")
    @ApiOperation("获得短信日志分页")
    @PreAuthorize("@cs.hasPermission('center:sms-log:query')")
    public CommonResult<PageResult<SmsLogRespVO>> getSmsLogPage(@Valid SmsLogPageReqVO pageVO) {
        PageResult<SmsLogDO> pageResult = platformSmsLogService.getSmsLogPage(pageVO);
        return success(SmsLogConvert.INSTANCE.convertPage(pageResult));
    }

    @GetMapping("/export-excel")
    @ApiOperation("导出短信日志 Excel")
    @PreAuthorize("@cs.hasPermission('center:sms-log:export')")
    @OperateLog(type = EXPORT)
    public void exportSmsLogExcel(@Valid SmsLogExportReqVO exportReqVO,
                                  HttpServletResponse response) throws IOException {
        List<SmsLogDO> list = platformSmsLogService.getSmsLogList(exportReqVO);
        // 导出 Excel
        List<SmsLogExcelVO> datas = SmsLogConvert.INSTANCE.convertList02(list);
        ExcelUtils.write(response, "短信日志.xls", "数据", SmsLogExcelVO.class, datas);
    }

}
