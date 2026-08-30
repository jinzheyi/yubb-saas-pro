package com.shengyu.module.system.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "shengyu.im.push.fcm")
public class FcmPushProperties {
    private boolean enabled = false;
    private String projectId;
    private String credentialFile;
    private int connectTimeoutMs = 3000;
    private int readTimeoutMs = 5000;
    private boolean dryRun = false;
    public boolean configured() { return enabled && projectId != null && !projectId.trim().isEmpty() && credentialFile != null && !credentialFile.trim().isEmpty(); }
}
