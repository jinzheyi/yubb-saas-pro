package com.shengyu.module.system.controller.app.im.vo.call;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(description = "移动端 - 当前可恢复通话 Response VO")
@Data
public class AppCallActiveRespVO {

    private String callSessionId;
    private String callType;
    private String state;
    private Integer eventVersion;
    private String chatId;
    private String groupId;
    private String callMode;
    private String callerId;
    private String calleeId;
    private String callerName;
    private String callerAvatar;
    private Boolean incoming;
    private Long initiateTime;
}
