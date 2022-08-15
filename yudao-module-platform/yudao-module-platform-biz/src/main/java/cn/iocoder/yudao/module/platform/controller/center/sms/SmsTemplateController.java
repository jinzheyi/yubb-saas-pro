package cn.iocoder.yudao.module.platform.controller.center.sms;

import cn.iocoder.yudao.module.platform.controller.center.sms.vo.template.*;
import cn.iocoder.yudao.module.platform.convert.sms.SmsTemplateConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.sms.SmsTemplateDO;
import cn.iocoder.yudao.module.platform.service.sms.PlatformSmsTemplateService;
import cn.iocoder.yudao.module.platform.service.sms.PlatformSmsSendService;
import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.excel.core.util.ExcelUtils;
import cn.iocoder.yudao.framework.operatelog.core.annotations.OperateLog;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiImplicitParam;
import io.swagger.annotations.ApiOperation;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import java.io.IOException;
import java.util.List;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;
import static cn.iocoder.yudao.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;

@Api(tags = "管理后台 - 短信模板")
@RestController
@RequestMapping("/center/sms-template")
public class SmsTemplateController {

    @Resource
    private PlatformSmsTemplateService platformSmsTemplateService;
    @Resource
    private PlatformSmsSendService platformSmsSendService;

    @PostMapping("/create")
    @ApiOperation("创建短信模板")
    @PreAuthorize("@cs.hasPermission('center:sms-template:create')")
    public CommonResult<Long> createSmsTemplate(@Valid @RequestBody SmsTemplateCreateReqVO createReqVO) {
        return success(platformSmsTemplateService.createSmsTemplate(createReqVO));
    }

    @PutMapping("/update")
    @ApiOperation("更新短信模板")
    @PreAuthorize("@cs.hasPermission('center:sms-template:update')")
    public CommonResult<Boolean> updateSmsTemplate(@Valid @RequestBody SmsTemplateUpdateReqVO updateReqVO) {
        platformSmsTemplateService.updateSmsTemplate(updateReqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @ApiOperation("删除短信模板")
    @ApiImplicitParam(name = "id", value = "编号", required = true, dataTypeClass = Long.class)
    @PreAuthorize("@cs.hasPermission('center:sms-template:delete')")
    public CommonResult<Boolean> deleteSmsTemplate(@RequestParam("id") Long id) {
        platformSmsTemplateService.deleteSmsTemplate(id);
        return success(true);
    }

    @GetMapping("/get")
    @ApiOperation("获得短信模板")
    @ApiImplicitParam(name = "id", value = "编号", required = true, example = "1024", dataTypeClass = Long.class)
    @PreAuthorize("@cs.hasPermission('system:sms-template:query')")
    public CommonResult<SmsTemplateRespVO> getSmsTemplate(@RequestParam("id") Long id) {
        SmsTemplateDO smsTemplate = platformSmsTemplateService.getSmsTemplate(id);
        return success(SmsTemplateConvert.INSTANCE.convert(smsTemplate));
    }

    @GetMapping("/page")
    @ApiOperation("获得短信模板分页")
    @PreAuthorize("@cs.hasPermission('system:sms-template:query')")
    public CommonResult<PageResult<SmsTemplateRespVO>> getSmsTemplatePage(@Valid SmsTemplatePageReqVO pageVO) {
        PageResult<SmsTemplateDO> pageResult = platformSmsTemplateService.getSmsTemplatePage(pageVO);
        return success(SmsTemplateConvert.INSTANCE.convertPage(pageResult));
    }

    @GetMapping("/export-excel")
    @ApiOperation("导出短信模板 Excel")
    @PreAuthorize("@cs.hasPermission('system:sms-template:export')")
    @OperateLog(type = EXPORT)
    public void exportSmsTemplateExcel(@Valid SmsTemplateExportReqVO exportReqVO,
                                       HttpServletResponse response) throws IOException {
        List<SmsTemplateDO> list = platformSmsTemplateService.getSmsTemplateList(exportReqVO);
        // 导出 Excel
        List<SmsTemplateExcelVO> datas = SmsTemplateConvert.INSTANCE.convertList02(list);
        ExcelUtils.write(response, "短信模板.xls", "数据", SmsTemplateExcelVO.class, datas);
    }

    @PostMapping("/send-sms")
    @ApiOperation("发送短信")
    @PreAuthorize("@ss.hasPermission('system:sms-template:send-sms')")
    public CommonResult<Long> sendSms(@Valid @RequestBody SmsTemplateSendReqVO sendReqVO) {
        return success(platformSmsSendService.sendSingleSmsToAdmin(sendReqVO.getMobile(), null,
                sendReqVO.getTemplateCode(), sendReqVO.getTemplateParams()));
    }

}
