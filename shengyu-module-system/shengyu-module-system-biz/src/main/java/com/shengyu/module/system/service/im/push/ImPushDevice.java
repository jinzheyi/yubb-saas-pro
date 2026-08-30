package com.shengyu.module.system.service.im.push;

import lombok.Data;

import java.io.Serializable;

@Data
public class ImPushDevice implements Serializable {
    private String deviceId;
    private String token;
    private String platform;
    private String appVersion;
    private String permissionState;
    private Long updatedAt;
    private Long lastDeliveryAt;
}
