package cn.iocoder.yudao.module.platform.api.sms;

import cn.iocoder.yudao.module.platform.api.sms.dto.send.SmsSendSingleToUserReqDTO;

import javax.validation.Valid;
import java.util.Map;

/**
 * 短信发送 API 接口
 *
 * @author 芋道源码
 */
public interface SmsSendApi {

    /**
     * 发送单条短信给 Admin 用户
     *
     * 在 mobile 为空时，使用 userId 加载对应 Admin 的手机号
     *
     * @param reqDTO 发送请求
     * @return 发送日志编号
     */
    Long sendSingleSmsToAdmin(@Valid SmsSendSingleToUserReqDTO reqDTO);

    /**
     * 发送单条短信给用户
     *
     * @param mobile 手机号
     * @param userId 用户编号
     * @param userType 用户类型
     * @param templateCode 短信模板编号
     * @param templateParams 短信模板参数
     * @return 发送日志编号
     */
    Long sendSingleSms(String mobile, Long userId, Integer userType,
                       String templateCode, Map<String, Object> templateParams);

}
