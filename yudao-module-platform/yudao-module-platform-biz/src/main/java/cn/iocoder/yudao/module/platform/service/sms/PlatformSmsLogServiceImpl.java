package cn.iocoder.yudao.module.platform.service.sms;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.log.SmsLogExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.log.SmsLogPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.sms.SmsLogDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.sms.SmsTemplateDO;
import cn.iocoder.yudao.module.platform.dal.mysql.sms.PlatformSmsLogMapper;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.enums.sms.SmsReceiveStatusEnum;
import cn.iocoder.yudao.framework.common.enums.sms.SmsSendStatusEnum;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * 短信日志 Service 实现类
 *
 * @author zzf
 */
@Slf4j
@Service
public class PlatformSmsLogServiceImpl implements PlatformSmsLogService {

    @Resource
    private PlatformSmsLogMapper platformSmsLogMapper;

    @Override
    public Long createSmsLog(String mobile, Long userId, Integer userType, Boolean isSend,
                             SmsTemplateDO template, String templateContent, Map<String, Object> templateParams) {
        SmsLogDO.SmsLogDOBuilder logBuilder = SmsLogDO.builder();
        // 根据是否要发送，设置状态
        logBuilder.sendStatus(Objects.equals(isSend, true) ? SmsSendStatusEnum.INIT.getStatus()
                : SmsSendStatusEnum.IGNORE.getStatus());
        // 设置手机相关字段
        logBuilder.mobile(mobile).userId(userId).userType(userType);
        // 设置模板相关字段
        logBuilder.templateId(template.getId()).templateCode(template.getCode()).templateType(template.getType());
        logBuilder.templateContent(templateContent).templateParams(templateParams)
                .apiTemplateId(template.getApiTemplateId());
        // 设置渠道相关字段
        logBuilder.channelId(template.getChannelId()).channelCode(template.getChannelCode());
        // 设置接收相关字段
        logBuilder.receiveStatus(SmsReceiveStatusEnum.INIT.getStatus());

        // 插入数据库
        SmsLogDO logDO = logBuilder.build();
        platformSmsLogMapper.insert(logDO);
        return logDO.getId();
    }

    @Override
    public void updateSmsSendResult(Long id, Integer sendCode, String sendMsg,
                                    String apiSendCode, String apiSendMsg,
                                    String apiRequestId, String apiSerialNo) {
        SmsSendStatusEnum sendStatus = CommonResult.isSuccess(sendCode) ?
                SmsSendStatusEnum.SUCCESS : SmsSendStatusEnum.FAILURE;
        platformSmsLogMapper.updateById(SmsLogDO.builder().id(id).sendStatus(sendStatus.getStatus())
                .sendTime(new Date()).sendCode(sendCode).sendMsg(sendMsg)
                .apiSendCode(apiSendCode).apiSendMsg(apiSendMsg)
                .apiRequestId(apiRequestId).apiSerialNo(apiSerialNo).build());
    }

    @Override
    public void updateSmsReceiveResult(Long id, Boolean success, Date receiveTime,
                                       String apiReceiveCode, String apiReceiveMsg) {
        SmsReceiveStatusEnum receiveStatus = Objects.equals(success, true) ?
                SmsReceiveStatusEnum.SUCCESS : SmsReceiveStatusEnum.FAILURE;
        platformSmsLogMapper.updateById(SmsLogDO.builder().id(id).receiveStatus(receiveStatus.getStatus())
                .receiveTime(receiveTime).apiReceiveCode(apiReceiveCode).apiReceiveMsg(apiReceiveMsg).build());
    }

    @Override
    public PageResult<SmsLogDO> getSmsLogPage(SmsLogPageReqVO pageReqVO) {
        return platformSmsLogMapper.selectPage(pageReqVO);
    }

    @Override
    public List<SmsLogDO> getSmsLogList(SmsLogExportReqVO exportReqVO) {
        return platformSmsLogMapper.selectList(exportReqVO);
    }

}
