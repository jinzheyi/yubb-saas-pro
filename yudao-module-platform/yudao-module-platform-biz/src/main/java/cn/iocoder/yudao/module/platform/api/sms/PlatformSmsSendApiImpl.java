package cn.iocoder.yudao.module.platform.api.sms;

import cn.iocoder.yudao.module.platform.api.sms.dto.send.PlatformSmsSendSingleToUserReqDTO;
import cn.iocoder.yudao.module.platform.service.sms.PlatformSmsSendService;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;

/**
 * 短信发送 API 接口
 *
 * @author 芋道源码
 */
@Service
@Validated
public class PlatformSmsSendApiImpl implements PlatformSmsSendApi {

    @Resource
    private PlatformSmsSendService platformSmsSendService;

    @Override
    public Long sendSingleSmsToAdmin(PlatformSmsSendSingleToUserReqDTO reqDTO) {
        return platformSmsSendService.sendSingleSmsToAdmin(reqDTO.getMobile(), reqDTO.getUserId(),
                reqDTO.getTemplateCode(), reqDTO.getTemplateParams());
    }

    @Override
    public Long sendSingleSmsToMember(PlatformSmsSendSingleToUserReqDTO reqDTO) {
        return platformSmsSendService.sendSingleSmsToMember(reqDTO.getMobile(), reqDTO.getUserId(),
                reqDTO.getTemplateCode(), reqDTO.getTemplateParams());
    }

}
