package com.shengyu.module.system.controller.app.im.vo.push;

import lombok.Data;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

@Data
public class AppImPushTokenRegisterReqVO {
    @NotBlank @Pattern(regexp = "fcm") private String provider;
    @NotBlank @Size(max = 4096) private String token;
    @NotBlank @Pattern(regexp = "[A-Za-z0-9._:-]{1,128}") private String deviceId;
    @NotBlank @Pattern(regexp = "android|ios|web") private String platform;
    @Size(max = 128) private String appVersion;
    @Pattern(regexp = "granted|denied|unknown") private String permissionState;
}
