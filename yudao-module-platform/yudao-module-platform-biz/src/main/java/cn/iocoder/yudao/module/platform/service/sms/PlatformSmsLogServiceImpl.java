package cn.iocoder.yudao.module.platform.service.sms;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.log.SmsLogExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.log.SmsLogPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.sms.PlatformSmsLogDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.sms.PlatformSmsTemplateDO;
import cn.iocoder.yudao.module.platform.dal.mapper.sms.PlatformSmsLogMapper;
import cn.iocoder.yudao.module.platform.enums.sms.PlatformSmsReceiveStatusEnum;
import cn.iocoder.yudao.module.platform.enums.sms.PlatformSmsSendStatusEnum;
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
                             PlatformSmsTemplateDO template, String templateContent, Map<String, Object> templateParams) {
        PlatformSmsLogDO.PlatformSmsLogDOBuilder logBuilder = PlatformSmsLogDO.builder();
        // 根据是否要发送，设置状态
        logBuilder.sendStatus(Objects.equals(isSend, true) ? PlatformSmsSendStatusEnum.INIT.getStatus()
                : PlatformSmsSendStatusEnum.IGNORE.getStatus());
        // 设置手机相关字段
        logBuilder.mobile(mobile).userId(userId).userType(userType);
        // 设置模板相关字段
        logBuilder.templateId(template.getId()).templateCode(template.getCode()).templateType(template.getType());
        logBuilder.templateContent(templateContent).templateParams(templateParams)
                .apiTemplateId(template.getApiTemplateId());
        // 设置渠道相关字段
        logBuilder.channelId(template.getChannelId()).channelCode(template.getChannelCode());
        // 设置接收相关字段
        logBuilder.receiveStatus(PlatformSmsReceiveStatusEnum.INIT.getStatus());

        // 插入数据库
        PlatformSmsLogDO logDO = logBuilder.build();
        platformSmsLogMapper.insert(logDO);
        return logDO.getId();
    }

    @Override
    public void updateSmsSendResult(Long id, Integer sendCode, String sendMsg,
                                    String apiSendCode, String apiSendMsg,
                                    String apiRequestId, String apiSerialNo) {
        PlatformSmsSendStatusEnum sendStatus = CommonResult.isSuccess(sendCode) ?
                PlatformSmsSendStatusEnum.SUCCESS : PlatformSmsSendStatusEnum.FAILURE;
        platformSmsLogMapper.updateById(PlatformSmsLogDO.builder().id(id).sendStatus(sendStatus.getStatus())
                .sendTime(new Date()).sendCode(sendCode).sendMsg(sendMsg)
                .apiSendCode(apiSendCode).apiSendMsg(apiSendMsg)
                .apiRequestId(apiRequestId).apiSerialNo(apiSerialNo).build());
    }

    @Override
    public void updateSmsReceiveResult(Long id, Boolean success, Date receiveTime,
                                       String apiReceiveCode, String apiReceiveMsg) {
        PlatformSmsReceiveStatusEnum receiveStatus = Objects.equals(success, true) ?
                PlatformSmsReceiveStatusEnum.SUCCESS : PlatformSmsReceiveStatusEnum.FAILURE;
        platformSmsLogMapper.updateById(PlatformSmsLogDO.builder().id(id).receiveStatus(receiveStatus.getStatus())
                .receiveTime(receiveTime).apiReceiveCode(apiReceiveCode).apiReceiveMsg(apiReceiveMsg).build());
    }

    @Override
    public PageResult<PlatformSmsLogDO> getSmsLogPage(SmsLogPageReqVO pageReqVO) {
        return platformSmsLogMapper.selectPage(pageReqVO);
    }

    @Override
    public List<PlatformSmsLogDO> getSmsLogList(SmsLogExportReqVO exportReqVO) {
        return platformSmsLogMapper.selectList(exportReqVO);
    }

}
