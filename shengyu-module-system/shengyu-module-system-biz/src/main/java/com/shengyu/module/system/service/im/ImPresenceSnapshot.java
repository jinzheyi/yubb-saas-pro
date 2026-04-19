package com.shengyu.module.system.service.im;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * IM 用户在线状态快照
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImPresenceSnapshot {

    private Boolean online;

    private List<Integer> onlineDeviceTypes;

    private Long lastActiveTime;
}
