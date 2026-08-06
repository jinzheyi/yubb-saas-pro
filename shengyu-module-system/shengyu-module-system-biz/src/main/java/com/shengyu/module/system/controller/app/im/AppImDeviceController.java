package com.shengyu.module.system.controller.app.im;

import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import com.shengyu.framework.security.core.LoginUser;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.framework.websocket.core.session.NettySession;
import com.shengyu.framework.websocket.core.session.NettySessionManager;
import com.shengyu.module.system.controller.app.im.vo.device.LoginDeviceRespVO;
import com.shengyu.module.system.controller.app.im.vo.device.UserOnlineStatusRespVO;
import com.shengyu.module.system.enums.im.ImDeviceTypeEnum;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.exception.enums.GlobalErrorCodeConstants.BAD_REQUEST;
import static com.shengyu.framework.common.exception.enums.GlobalErrorCodeConstants.UNAUTHORIZED;
import static com.shengyu.framework.common.pojo.CommonResult.success;

/**
 * 移动端 - IM 登录设备管理 Controller
 *
 * @author 圣钰科技
 */
@Tag(name = "移动端 - IM 登录设备管理")
@RestController
@RequestMapping("/system/im/device")
@Validated
@Slf4j
@DataPermission(enable = false)
public class AppImDeviceController {

    @Resource
    private NettySessionManager sessionManager;

    @GetMapping("/list")
    @Operation(summary = "获取当前用户登录设备列表")
    public CommonResult<List<LoginDeviceRespVO>> getLoginDevices(HttpServletRequest request) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        if (userId == null) {
            return CommonResult.error(UNAUTHORIZED);
        }

        // 获取当前请求的 access token，用于标记 isCurrentDevice
        String currentAccessToken = SecurityFrameworkUtils.obtainAuthorization(
                request, "Authorization", "token");

        List<NettySession> sessions = sessionManager.getSessionsByUserId(userId);
        List<LoginDeviceRespVO> devices = sessions.stream()
                .map(session -> toDeviceResp(session, currentAccessToken))
                .collect(Collectors.toList());

        return success(devices);
    }

    @PostMapping("/kick")
    @Operation(summary = "踢出指定设备")
    public CommonResult<Boolean> kickDevice(
            @RequestParam("deviceType") Integer deviceType,
            @RequestParam(value = "deviceId", required = false) String deviceId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        if (userId == null) {
            return CommonResult.error(UNAUTHORIZED);
        }

        // 验证设备类型是否有效
        ImDeviceTypeEnum deviceTypeEnum = ImDeviceTypeEnum.valueOfType(deviceType);
        if (deviceTypeEnum == null) {
            return CommonResult.error(BAD_REQUEST.getCode(), "无效的设备类型");
        }

        // 优先按 deviceId 精确踢出，否则按 deviceType 踢出
        if (StrUtil.isNotBlank(deviceId)) {
            NettySession currentSession = sessionManager.getSessionByUserIdAndDevice(userId, deviceType, deviceId);
            if (currentSession == null || !currentSession.isActive()) {
                return success(true); // 设备已离线，视为成功
            }
            sessionManager.kickDeviceByDevice(userId, deviceType, deviceId, "您的账号主动踢出了该设备");
        } else {
            NettySession currentSession = sessionManager.getSessionByUserIdAndDeviceType(userId, deviceType);
            if (currentSession == null || !currentSession.isActive()) {
                return success(true); // 设备已离线，视为成功
            }
            sessionManager.kickDevice(userId, deviceType, "您的账号主动踢出了该设备");
        }
        return success(true);
    }

    @GetMapping("/online-status")
    @Operation(summary = "查询用户在线状态")
    public CommonResult<List<UserOnlineStatusRespVO>> getOnlineStatus(
            @RequestParam("userIds") List<Long> userIds) {
        // 限制查询数量
        if (userIds == null || userIds.isEmpty()) {
            return success(Collections.emptyList());
        }
        if (userIds.size() > 100) {
            return CommonResult.error(BAD_REQUEST.getCode(), "最多查询 100 个用户");
        }

        List<UserOnlineStatusRespVO> result = new ArrayList<>();
        for (Long userId : userIds) {
            boolean online = sessionManager.isUserOnline(userId);
            List<Integer> deviceTypes = online
                    ? sessionManager.getSessionsByUserId(userId).stream()
                    .map(NettySession::getDeviceType)
                    .filter(Objects::nonNull)
                    .distinct()
                    .collect(Collectors.toList())
                    : Collections.emptyList();

            result.add(new UserOnlineStatusRespVO()
                    .setUserId(userId)
                    .setOnline(online)
                    .setDeviceTypes(deviceTypes));
        }

        return success(result);
    }

    private LoginDeviceRespVO toDeviceResp(NettySession session, String currentAccessToken) {
        LoginDeviceRespVO vo = new LoginDeviceRespVO();
        vo.setDeviceType(session.getDeviceType());
        vo.setDeviceName(StrUtil.isNotBlank(session.getDeviceName()) ? session.getDeviceName() : null);
        vo.setDeviceId(StrUtil.isNotBlank(session.getDeviceId()) ? session.getDeviceId() : null);
        vo.setLoginTime(session.getConnectTime());
        vo.setLastActiveTime(session.getLastBizActiveTime());
        vo.setIsActive(session.isActive());

        // 标记是否为当前请求设备（通过 accessToken 匹配）
        vo.setIsCurrentDevice(StrUtil.isNotBlank(currentAccessToken)
                && currentAccessToken.equals(session.getAccessToken()));

        // 设备类型名称
        vo.setDeviceTypeName(getDeviceTypeName(session.getDeviceType()));

        return vo;
    }

    private String getDeviceTypeName(Integer deviceType) {
        return ImDeviceTypeEnum.getNameByType(deviceType);
    }
}
