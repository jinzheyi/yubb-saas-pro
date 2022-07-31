package cn.iocoder.yudao.module.platform.controller.center.sms.vo.channel;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

import javax.validation.constraints.NotNull;

@ApiModel("管理后台 - 短信渠道创建 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
@ToString(callSuper = true)
public class SmsChannelCreateReqVO extends SmsChannelBaseVO {

    @ApiModelProperty(value = "渠道编码", required = true, example = "YUN_PIAN", notes = "参见 PlatformSmsChannelEnum 枚举类")
    @NotNull(message = "渠道编码不能为空")
    private String code;

}
