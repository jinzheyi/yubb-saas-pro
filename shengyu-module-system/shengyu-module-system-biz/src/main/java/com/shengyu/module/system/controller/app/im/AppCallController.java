package com.shengyu.module.system.controller.app.im;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.exception.ServiceException;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.api.user.AdminUserApi;
import com.shengyu.module.system.api.user.dto.AdminUserRespDTO;
import com.shengyu.module.system.controller.app.im.vo.call.*;
import com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO;
import com.shengyu.module.system.enums.im.ImCallStatusEnum;
import com.shengyu.module.system.enums.im.ImCallTypeEnum;
import com.shengyu.module.system.service.im.ImCallService;
import com.shengyu.module.system.service.im.ImCallApplicationService;
import com.shengyu.module.system.service.im.LiveKitConnectionInfo;
import com.shengyu.module.system.service.im.vo.CallInviteResultVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.pojo.CommonResult.success;

/**
 * 移动端 - IM 通话 Controller
 *
 * @author 圣钰科技
 */
@Tag(name = "移动端 - IM 通话")
@RestController
@RequestMapping("/system/im/call")
@Validated
@DataPermission(enable = false)
@Slf4j
public class AppCallController {

    @Resource
    private ImCallService callService;

    @Resource
    private ImCallApplicationService callApplicationService;

    @Resource
    private AdminUserApi adminUserApi;

    // ==================== 通话基础操作 ====================

    @PostMapping("/create-invite")
    @Operation(summary = "创建通话邀请")
    public CommonResult<AppCallCreateInviteRespVO> createInvite(@Valid @RequestBody AppCallCreateInviteReqVO reqVO) {
        Long callerId = SecurityFrameworkUtils.getLoginUserId();
        if (callerId == null) {
            return CommonResult.error(401, "用户未登录");
        }
        if (reqVO.getCalleeId() == null) {
            return CommonResult.error(400, "被叫用户ID不能为空");
        }
        if (StrUtil.isBlank(reqVO.getCallType())) {
            return CommonResult.error(400, "通话类型不能为空");
        }

        Integer callType = convertCallTypeToInt(reqVO.getCallType());

        try {
            CallInviteResultVO result = callApplicationService.createDirect(
                    callerId, reqVO.getCalleeId(), reqVO.getChatId(), callType, reqVO.getDeviceId());

            log.info("[createInvite] 创建通话邀请成功, callerId={}, calleeId={}, callType={}",
                    callerId, reqVO.getCalleeId(), callType);

            return success(convertToCreateInviteRespVO(result));
        } catch (Exception e) {
            log.error("[createInvite] 创建通话邀请失败, callerId={}, calleeId={}, error={}",
                    callerId, reqVO.getCalleeId(), e.getMessage(), e);
            return CommonResult.error(500, "创建通话邀请失败: " + e.getMessage());
        }
    }

    @PostMapping("/accept")
    @Operation(summary = "接听通话")
    public CommonResult<AppCallJoinRespVO> acceptCall(@Valid @RequestBody AppCallSessionReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        if (userId == null) {
            return CommonResult.error(401, "用户未登录");
        }
        if (StrUtil.isBlank(reqVO.getCallSessionId())) {
            return CommonResult.error(400, "通话会话ID不能为空");
        }
        if (StrUtil.isBlank(reqVO.getDeviceId())) {
            return CommonResult.error(400, "接听设备ID不能为空");
        }

        try {
            LiveKitConnectionInfo connection = callApplicationService.accept(
                    reqVO.getCallSessionId(), userId, reqVO.getDeviceId());
            log.info("[acceptCall] 接听通话, callSessionId={}, userId={}", reqVO.getCallSessionId(), userId);
            return success(convertToJoinRespVO(reqVO.getCallSessionId(), connection));
        } catch (Exception e) {
            log.error("[acceptCall] 接听通话失败, callSessionId={}, userId={}, error={}",
                    reqVO.getCallSessionId(), userId, e.getMessage(), e);
            return CommonResult.error(500, "接听通话失败: " + e.getMessage());
        }
    }

    @PostMapping("/reject")
    @Operation(summary = "拒绝通话")
    public CommonResult<Boolean> rejectCall(@Valid @RequestBody AppCallSessionReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        if (userId == null) {
            return CommonResult.error(401, "用户未登录");
        }
        if (StrUtil.isBlank(reqVO.getCallSessionId())) {
            return CommonResult.error(400, "通话会话ID不能为空");
        }

        try {
            callApplicationService.reject(reqVO.getCallSessionId(), userId);
            log.info("[rejectCall] 拒绝通话, callSessionId={}, userId={}", reqVO.getCallSessionId(), userId);
            return success(true);
        } catch (Exception e) {
            log.error("[rejectCall] 拒绝通话失败, callSessionId={}, userId={}, error={}",
                    reqVO.getCallSessionId(), userId, e.getMessage(), e);
            return CommonResult.error(500, "拒绝通话失败: " + e.getMessage());
        }
    }

    @PostMapping("/connection")
    @Operation(summary = "获取当前参与者的 LiveKit 重连凭据")
    public CommonResult<AppCallJoinRespVO> getLiveKitConnection(@Valid @RequestBody AppCallSessionReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        if (userId == null) return CommonResult.error(401, "用户未登录");
        if (StrUtil.isBlank(reqVO.getCallSessionId()) || StrUtil.isBlank(reqVO.getDeviceId())) {
            return CommonResult.error(400, "通话会话ID和设备ID不能为空");
        }
        try {
            return success(convertToJoinRespVO(reqVO.getCallSessionId(),
                    callApplicationService.connection(reqVO.getCallSessionId(), userId, reqVO.getDeviceId())));
        } catch (Exception e) {
            log.error("[getLiveKitConnection] 获取凭据失败, callSessionId={}, userId={}", reqVO.getCallSessionId(), userId, e);
            return CommonResult.error(500, "获取通话连接凭据失败: " + e.getMessage());
        }
    }

    @PostMapping("/cancel")
    @Operation(summary = "取消通话")
    public CommonResult<Boolean> cancelCall(@Valid @RequestBody AppCallSessionReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        if (userId == null) {
            return CommonResult.error(401, "用户未登录");
        }
        if (StrUtil.isBlank(reqVO.getCallSessionId())) {
            return CommonResult.error(400, "通话会话ID不能为空");
        }

        try {
            callApplicationService.cancel(reqVO.getCallSessionId(), userId);
            log.info("[cancelCall] 取消通话, callSessionId={}, userId={}", reqVO.getCallSessionId(), userId);
            return success(true);
        } catch (Exception e) {
            log.error("[cancelCall] 取消通话失败, callSessionId={}, userId={}, error={}",
                    reqVO.getCallSessionId(), userId, e.getMessage(), e);
            return CommonResult.error(500, "取消通话失败: " + e.getMessage());
        }
    }

    @PostMapping("/hangup")
    @Operation(summary = "挂断通话")
    public CommonResult<Boolean> hangupCall(@Valid @RequestBody AppCallSessionReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        if (userId == null) {
            return CommonResult.error(401, "用户未登录");
        }
        if (StrUtil.isBlank(reqVO.getCallSessionId())) {
            return CommonResult.error(400, "通话会话ID不能为空");
        }

        try {
            callApplicationService.hangup(reqVO.getCallSessionId(), userId);
            log.info("[hangupCall] 挂断通话, callSessionId={}, userId={}", reqVO.getCallSessionId(), userId);
            return success(true);
        } catch (Exception e) {
            log.error("[hangupCall] 挂断通话失败, callSessionId={}, userId={}, error={}",
                    reqVO.getCallSessionId(), userId, e.getMessage(), e);
            return CommonResult.error(500, "挂断通话失败: " + e.getMessage());
        }
    }

    @GetMapping("/state")
    @Operation(summary = "同步通话状态")
    @Parameter(name = "callSessionId", description = "通话会话ID", required = true)
    public CommonResult<AppCallStateRespVO> syncCallState(@RequestParam("callSessionId") String callSessionId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        if (userId == null) {
            return CommonResult.error(401, "用户未登录");
        }
        if (StrUtil.isBlank(callSessionId)) {
            return CommonResult.error(400, "通话会话ID不能为空");
        }

        try {
            ImCallRecordDO callRecord = callApplicationService.getAuthorizedState(callSessionId, userId);
            if (callRecord == null) {
                return success(null);
            }
            AppCallStateRespVO respVO = buildCallStateRespVO(callRecord);
            return success(respVO);
        } catch (Exception e) {
            log.error("[syncCallState] 同步通话状态失败, callSessionId={}, error={}",
                    callSessionId, e.getMessage(), e);
            return CommonResult.error(500, "同步通话状态失败: " + e.getMessage());
        }
    }

    @GetMapping("/active")
    @Operation(summary = "查询当前可恢复通话")
    public CommonResult<AppCallActiveRespVO> getActiveCall() {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        if (userId == null) {
            return CommonResult.error(401, "用户未登录");
        }
        ImCallRecordDO record = callApplicationService.getActiveCall(userId);
        if (record == null) {
            return success(null);
        }
        AppCallActiveRespVO respVO = new AppCallActiveRespVO();
        respVO.setCallSessionId(record.getCallId());
        respVO.setCallType(convertCallTypeToString(record.getCallType()));
        respVO.setState(record.getState() != null ? record.getState().toLowerCase() : "init");
        respVO.setEventVersion(record.getStateVersion());
        respVO.setChatId(record.getChatId() != null ? String.valueOf(record.getChatId()) : "");
        respVO.setGroupId(record.getGroupId() != null ? String.valueOf(record.getGroupId()) : null);
        respVO.setCallMode(record.getCallMode());
        respVO.setCallerId(record.getCallerId() != null ? String.valueOf(record.getCallerId()) : null);
        respVO.setCalleeId(record.getCalleeId() != null ? String.valueOf(record.getCalleeId()) : null);
        // 历史记录可能没有冗余主叫资料。恢复来电时必须返回可展示的用户信息，
        // 否则 WebSocket 短暂断线后虽然能恢复通话，页面却只能显示泛化的“来电”。
        AdminUserRespDTO caller = record.getCallerId() != null
                ? adminUserApi.getUser(record.getCallerId()) : null;
        respVO.setCallerName(StrUtil.isNotBlank(record.getCallerName())
                ? record.getCallerName() : caller != null ? caller.getNickname() : null);
        respVO.setCallerAvatar(StrUtil.isNotBlank(record.getCallerAvatar())
                ? record.getCallerAvatar() : caller != null ? caller.getAvatar() : null);
        respVO.setIncoming(!userId.equals(record.getCallerId()));
        respVO.setInitiateTime(record.getCreateTime() != null
                ? record.getCreateTime().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli()
                : null);
        return success(respVO);
    }

    // ==================== 通话记录查询 ====================

    @GetMapping("/records/page")
    @Operation(summary = "分页查询通话记录")
    public CommonResult<PageResult<AppCallRecordRespVO>> getCallRecordPage(@Valid AppCallRecordPageReqVO pageReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        if (userId == null) {
            return CommonResult.error(401, "用户未登录");
        }

        try {
            PageResult<ImCallRecordDO> pageResult = callService.getCallRecordPageByUserId(
                    userId, pageReqVO.getCallType(), pageReqVO.getStartTime(),
                    pageReqVO.getEndTime(), pageReqVO.getChatId(),
                    pageReqVO.getPageNo(), pageReqVO.getPageSize());

            List<AppCallRecordRespVO> voList = convertToRecordRespVOList(pageResult.getList(), userId);
            return success(new PageResult<>(voList, pageResult.getTotal()));
        } catch (Exception e) {
            log.error("[getCallRecordPage] 分页查询通话记录失败, userId={}, error={}",
                    userId, e.getMessage(), e);
            return CommonResult.error(500, "查询通话记录失败: " + e.getMessage());
        }
    }

    @GetMapping("/records/list")
    @Operation(summary = "查询通话记录列表（不分页，最近N条）")
    @Parameter(name = "limit", description = "返回条数限制", example = "50")
    public CommonResult<List<AppCallRecordRespVO>> getCallRecordList(
            @RequestParam(value = "limit", defaultValue = "50") Integer limit) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        if (userId == null) {
            return CommonResult.error(401, "用户未登录");
        }
        // 限制最大查询条数，防止内存溢出
        if (limit == null || limit <= 0 || limit > 200) {
            return CommonResult.error(400, "limit 参数无效，应在 1-200 之间");
        }

        try {
            List<ImCallRecordDO> records = callService.getCallRecords(userId, limit);
            List<AppCallRecordRespVO> voList = convertToRecordRespVOList(records, userId);
            return success(voList);
        } catch (Exception e) {
            log.error("[getCallRecordList] 查询通话记录列表失败, userId={}, limit={}, error={}",
                    userId, limit, e.getMessage(), e);
            return CommonResult.error(500, "查询通话记录失败: " + e.getMessage());
        }
    }

    @GetMapping("/records/by-chat")
    @Operation(summary = "按会话ID查询通话记录")
    public CommonResult<List<AppCallRecordRespVO>> getCallRecordsByChat(
            @RequestParam("chatId") Long chatId,
            @RequestParam(value = "limit", defaultValue = "50") Integer limit) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        if (userId == null) {
            return CommonResult.error(401, "用户未登录");
        }
        if (chatId == null) {
            return CommonResult.error(400, "chatId 不能为空");
        }
        // 限制最大查询条数，防止内存溢出
        if (limit == null || limit <= 0 || limit > 200) {
            return CommonResult.error(400, "limit 参数无效，应在 1-200 之间");
        }

        try {
            List<ImCallRecordDO> records = callService.getCallRecordsBetweenUsers(userId, chatId, limit);
            List<AppCallRecordRespVO> voList = convertToRecordRespVOList(records, userId);
            return success(voList);
        } catch (Exception e) {
            log.error("[getCallRecordsByChat] 按会话ID查询通话记录失败, userId={}, chatId={}, limit={}, error={}",
                    userId, chatId, limit, e.getMessage(), e);
            return CommonResult.error(500, "查询通话记录失败: " + e.getMessage());
        }
    }

    // ==================== 私有转换方法 ====================

    @PostMapping("/group/create-invite")
    @Operation(summary = "原子创建群组通话邀请")
    public CommonResult<AppCallCreateInviteRespVO> createGroupInvite(@Valid @RequestBody AppCallGroupCreateInviteReqVO reqVO) {
        Long callerId = SecurityFrameworkUtils.getLoginUserId();
        if (callerId == null) return CommonResult.error(401, "用户未登录");
        try {
            Long groupId = Long.valueOf(reqVO.getGroupId());
            Long chatId = Long.valueOf(reqVO.getChatId());
            if (!"audio".equalsIgnoreCase(reqVO.getCallType())
                    && !"video".equalsIgnoreCase(reqVO.getCallType())) {
                return CommonResult.error(400, "通话类型仅支持 audio 或 video");
            }
            Integer callType = convertCallTypeToInt(reqVO.getCallType());
            CallInviteResultVO result = callApplicationService.createGroup(callerId, chatId, groupId,
                    reqVO.getInviteeIds(), callType, reqVO.getDeviceId());
            log.info("[createGroupInvite] 原子创建群通话, callId={}, groupId={}, invitees={}",
                    result.getCallSessionId(), groupId, reqVO.getInviteeIds().size());
            return success(convertToCreateInviteRespVO(result));
        } catch (ServiceException e) {
            log.info("[createGroupInvite] 群通话业务校验未通过, callerId={}, code={}", callerId, e.getCode());
            return CommonResult.error(e.getCode(), e.getMessage());
        } catch (Exception e) {
            log.error("[createGroupInvite] 创建群通话失败, callerId={}, groupId={}", callerId, reqVO.getGroupId(), e);
            return CommonResult.error(500, "创建群通话失败: " + e.getMessage());
        }
    }

    @PostMapping("/group/leave")
    @Operation(summary = "离开群组通话")
    public CommonResult<Boolean> leaveGroupCall(@Valid @RequestBody AppCallSessionReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        if (userId == null) {
            return CommonResult.error(401, "用户未登录");
        }
        try {
            callApplicationService.leaveGroup(reqVO.getCallSessionId(), userId);
            return success(true);
        } catch (Exception e) {
            log.error("[leaveGroupCall] 离开群通话失败, callSessionId={}, userId={}",
                    reqVO.getCallSessionId(), userId, e);
            return CommonResult.error(500, "离开群通话失败: " + e.getMessage());
        }
    }

    /**
     * 通话类型字符串转整数
     * 使用枚举消除魔法值
     */
    private Integer convertCallTypeToInt(String callTypeStr) {
        return "video".equalsIgnoreCase(callTypeStr)
                ? ImCallTypeEnum.VIDEO.getType()
                : ImCallTypeEnum.VOICE.getType();
    }

    /**
     * 构建通话状态响应 VO
     * 使用枚举获取状态名称，消除魔法值
     */
    private AppCallStateRespVO buildCallStateRespVO(ImCallRecordDO callRecord) {
        AppCallStateRespVO respVO = new AppCallStateRespVO();
        respVO.setCallSessionId(callRecord.getCallId());
        respVO.setCallType(convertCallTypeToString(callRecord.getCallType()));
        respVO.setStatus(toClientPageStatus(callRecord));
        respVO.setState(callRecord.getState() != null ? callRecord.getState().toLowerCase() : "init");
        respVO.setDuration(callRecord.getDuration());
        return respVO;
    }

    private String toClientPageStatus(ImCallRecordDO callRecord) {
        if (com.shengyu.module.system.enums.im.ImCallStateEnum.ENDED.getState().equals(callRecord.getState())) {
            return "ended";
        }
        if (com.shengyu.module.system.enums.im.ImCallStateEnum.CONNECTED.getState().equals(callRecord.getState())) {
            return "connected";
        }
        if (com.shengyu.module.system.enums.im.ImCallStateEnum.RINGING.getState().equals(callRecord.getState())) {
            return "ringing";
        }
        return "connecting";
    }

    /**
     * 通话类型整数转字符串
     * 使用枚举消除魔法值
     */
    private String convertCallTypeToString(Integer callType) {
        return ImCallTypeEnum.VIDEO.getType().equals(callType) ? "video" : "audio";
    }

    /**
     * 获取状态名称
     * 使用枚举遍历，消除魔法值
     */
    private String getStatusName(Integer status) {
        if (status == null) {
            return ImCallStatusEnum.MISSED.name().toLowerCase();
        }
        for (ImCallStatusEnum e : ImCallStatusEnum.values()) {
            if (e.getStatus().equals(status)) {
                return e.name().toLowerCase();
            }
        }
        return ImCallStatusEnum.MISSED.name().toLowerCase();
    }

    /**
     * 转换通话邀请结果 VO
     * 从 Service 层强类型 VO 转换为 Controller 层响应 VO
     */
    private AppCallCreateInviteRespVO convertToCreateInviteRespVO(CallInviteResultVO result) {
        AppCallCreateInviteRespVO respVO = new AppCallCreateInviteRespVO();
        respVO.setCallSessionId(result.getCallSessionId());
        respVO.setInviteId(result.getInviteId());
        respVO.setChatId(result.getChatId());
        respVO.setCallType(result.getCallType());
        respVO.setStatus(result.getStatus());

        if (result.getRtcRoom() != null) {
            CallInviteResultVO.RtcRoomInfo rtcRoomInfo = result.getRtcRoom();
            AppCallCreateInviteRespVO.RtcRoomInfo rtcRoom = new AppCallCreateInviteRespVO.RtcRoomInfo();
            rtcRoom.setCallSessionId(rtcRoomInfo.getCallSessionId());
            rtcRoom.setRoomName(rtcRoomInfo.getRoomName());
            rtcRoom.setPublisherId(rtcRoomInfo.getPublisherId());
            rtcRoom.setDisplayName(rtcRoomInfo.getDisplayName());
            rtcRoom.setLivekitUrl(rtcRoomInfo.getLivekitUrl());
            rtcRoom.setToken(rtcRoomInfo.getToken());
            respVO.setRtcRoom(rtcRoom);
        }

        return respVO;
    }

    private AppCallJoinRespVO convertToJoinRespVO(String callSessionId, LiveKitConnectionInfo connection) {
        AppCallJoinRespVO respVO = new AppCallJoinRespVO();
        respVO.setCallSessionId(callSessionId);
        respVO.setRoomName(connection.getRoomName());
        respVO.setLivekitUrl(connection.getServerUrl());
        respVO.setAccessToken(connection.getAccessToken());
        respVO.setExpiresAt(connection.getExpiresAt());
        return respVO;
    }

    /**
     * 转换群组通话邀请结果 VO
     */
    /**
     * 批量转换通话记录响应 VO
     * 将 DO 列表转换为 VO 列表，并填充用户信息
     */
    private List<AppCallRecordRespVO> convertToRecordRespVOList(List<ImCallRecordDO> records, Long currentUserId) {
        return records.stream()
                .map(record -> convertToRecordRespVO(record, currentUserId))
                .collect(Collectors.toList());
    }

    /**
     * 转换单条通话记录响应 VO
     * 使用 BeanUtil 进行属性拷贝，并填充用户信息
     */
    private AppCallRecordRespVO convertToRecordRespVO(ImCallRecordDO record, Long currentUserId) {
        AppCallRecordRespVO vo = BeanUtil.copyProperties(record, AppCallRecordRespVO.class);
        vo.setIsCaller(record.getCallerId().equals(currentUserId));
        fillUserInfo(vo, record);
        return vo;
    }

    /**
     * 填充用户信息（主叫方和被叫方的昵称和头像）
     * 批量查询用户信息，避免循环查询
     */
    private void fillUserInfo(AppCallRecordRespVO vo, ImCallRecordDO record) {
        try {
            List<Long> userIds = Arrays.asList(record.getCallerId(), record.getCalleeId());
            Map<Long, AdminUserRespDTO> userMap = adminUserApi.getUserMap(userIds);

            AdminUserRespDTO caller = userMap.get(record.getCallerId());
            if (caller != null) {
                vo.setCallerName(caller.getNickname());
                vo.setCallerAvatar(caller.getAvatar());
            }

            AdminUserRespDTO callee = userMap.get(record.getCalleeId());
            if (callee != null) {
                vo.setCalleeName(callee.getNickname());
                vo.setCalleeAvatar(callee.getAvatar());
            }
        } catch (Exception e) {
            log.warn("[fillUserInfo] 填充用户信息失败, callId={}", record.getCallId(), e);
        }
    }
}
