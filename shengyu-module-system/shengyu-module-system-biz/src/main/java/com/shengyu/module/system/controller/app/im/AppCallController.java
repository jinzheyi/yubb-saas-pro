package com.shengyu.module.system.controller.app.im;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.exception.ErrorCode;
import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.api.user.AdminUserApi;
import com.shengyu.module.system.api.user.dto.AdminUserRespDTO;
import com.shengyu.module.system.controller.app.im.vo.call.*;
import com.shengyu.module.system.dal.dataobject.im.ImCallRecordDO;
import com.shengyu.module.system.dal.dataobject.im.ImCallParticipantDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatDO;
import com.shengyu.module.system.dal.mysql.im.ImCallParticipantMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatMapper;
import com.shengyu.module.system.enums.im.ImCallStatusEnum;
import com.shengyu.module.system.enums.im.ImCallTypeEnum;
import com.shengyu.module.system.service.im.CallTokenService;
import com.shengyu.module.system.service.im.ImCallService;
import com.shengyu.module.system.service.im.GroupCallService;
import com.shengyu.module.system.service.im.vo.CallInviteResultVO;
import com.shengyu.module.system.service.im.vo.GroupInviteResultVO;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Objects;
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
    private GroupCallService groupCallService;

    @Resource
    private CallTokenService callTokenService;

    @Resource
    private AdminUserApi adminUserApi;

    @Resource
    private com.shengyu.module.system.service.im.CallPushService callPushService;

    @Resource
    private ImCallParticipantMapper callParticipantMapper;

    @Resource
    private ImChatMapper chatMapper;

    @Value("${janus.url:}")
    private String janusUrl;

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
            CallInviteResultVO result = callService.createCallInvite(callerId, reqVO.getCalleeId(), reqVO.getChatId(), callType);

            // App 端的通话动作通过 HTTP 发起，单纯落库还不够：
            // 被叫方还必须收到实时的 call.invite 事件。
            publishInvite(result, callerId, reqVO.getCalleeId());

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
    public CommonResult<Boolean> acceptCall(@Valid @RequestBody AppCallSessionReqVO reqVO) {
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
            callService.acceptCall(reqVO.getCallSessionId(), userId, reqVO.getDeviceId());
            publishStateEvent(reqVO.getCallSessionId(), "call.accepted", userId, null);
            publishGroupJoinIfNeeded(reqVO.getCallSessionId(), userId);
            publishMediaTokenEvents(reqVO.getCallSessionId(), userId);
            log.info("[acceptCall] 接听通话, callSessionId={}, userId={}", reqVO.getCallSessionId(), userId);
            return success(true);
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
            callService.rejectCall(reqVO.getCallSessionId(), userId, "REJECT");
            ImCallRecordDO record = callService.getCallRecord(reqVO.getCallSessionId());
            if (record != null && record.getGroupId() != null) {
                publishGroupLeaveIfNeeded(reqVO.getCallSessionId(), userId);
            } else {
                publishStateEvent(reqVO.getCallSessionId(), "call.rejected", userId, "REJECT");
            }
            log.info("[rejectCall] 拒绝通话, callSessionId={}, userId={}", reqVO.getCallSessionId(), userId);
            return success(true);
        } catch (Exception e) {
            log.error("[rejectCall] 拒绝通话失败, callSessionId={}, userId={}, error={}",
                    reqVO.getCallSessionId(), userId, e.getMessage(), e);
            return CommonResult.error(500, "拒绝通话失败: " + e.getMessage());
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
            callService.cancelCall(reqVO.getCallSessionId(), userId, "CANCEL");
            publishStateEvent(reqVO.getCallSessionId(), "call.cancelled", userId, "CANCEL");
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
            callService.hangupCall(reqVO.getCallSessionId(), userId, "HANGUP");
            publishStateEvent(reqVO.getCallSessionId(), "call.ended", userId, "HANGUP");
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
            ImCallRecordDO callRecord = callService.getCallRecord(callSessionId);
            if (callRecord == null) {
                return success(null);
            }
            boolean directParticipant = userId.equals(callRecord.getCallerId()) || userId.equals(callRecord.getCalleeId());
            boolean groupParticipant = callRecord.getGroupId() != null
                    && callParticipantMapper.selectByCallIdAndUserId(callSessionId, userId) != null;
            if (!directParticipant && !groupParticipant) {
                return CommonResult.error(403, "无权查看该通话状态");
            }

            AppCallStateRespVO respVO = buildCallStateRespVO(callRecord);
            return success(respVO);
        } catch (Exception e) {
            log.error("[syncCallState] 同步通话状态失败, callSessionId={}, error={}",
                    callSessionId, e.getMessage(), e);
            return CommonResult.error(500, "同步通话状态失败: " + e.getMessage());
        }
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

    // ==================== Token 管理 ====================

    @PostMapping("/token")
    @Operation(summary = "获取 Janus 通话 Token")
    @Parameter(name = "roomId", description = "Janus 房间ID")
    public CommonResult<String> getCallToken(@RequestParam(value = "roomId", required = false) String roomId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        if (userId == null) {
            return CommonResult.error(401, "用户未登录");
        }
        if (StrUtil.isBlank(roomId)) {
            return CommonResult.error(400, "房间ID不能为空");
        }
        ImCallRecordDO callRecord = callService.getCallRecordByRoomId(roomId);
        if (callRecord == null) {
            return CommonResult.error(404, "通话房间不存在");
        }
        boolean directParticipant = Objects.equals(userId, callRecord.getCallerId())
                || Objects.equals(userId, callRecord.getCalleeId());
        boolean groupParticipant = callRecord.getGroupId() != null
                && callParticipantMapper.selectByCallIdAndUserId(callRecord.getCallId(), userId) != null;
        if (!directParticipant && !groupParticipant) {
            return CommonResult.error(403, "无权获取该通话房间令牌");
        }
        Long tenantId = TenantContextHolder.getTenantId();

        try {
            String token = callTokenService.generateToken(userId, tenantId, roomId);
            log.info("[getCallToken] 生成通话 Token, userId={}, roomId={}", userId, roomId);
            return success(token);
        } catch (Exception e) {
            log.error("[getCallToken] 生成通话 Token 失败, userId={}, roomId={}, error={}",
                    userId, roomId, e.getMessage(), e);
            return CommonResult.error(500, "生成通话 Token 失败: " + e.getMessage());
        }
    }

    // ==================== 群组通话 ====================

    @PostMapping("/group/invite")
    @Operation(summary = "群组通话邀请成员加入")
    public CommonResult<AppCallGroupInviteRespVO> inviteGroupMembers(@Valid @RequestBody AppCallGroupInviteReqVO reqVO) {
        Long inviterId = SecurityFrameworkUtils.getLoginUserId();
        if (inviterId == null) {
            return CommonResult.error(401, "用户未登录");
        }
        if (StrUtil.isBlank(reqVO.getCallSessionId())) {
            return CommonResult.error(400, "通话会话ID不能为空");
        }
        if (StrUtil.isBlank(reqVO.getGroupId())) {
            return CommonResult.error(400, "群组ID不能为空");
        }
        if (reqVO.getInviteeIds() == null || reqVO.getInviteeIds().isEmpty()) {
            return CommonResult.error(400, "邀请成员列表不能为空");
        }

        try {
            GroupInviteResultVO result = callService.inviteGroupMembers(
                    reqVO.getCallSessionId(), reqVO.getGroupId(), inviterId, reqVO.getInviteeIds());

            log.info("[inviteGroupMembers] 群组通话邀请, callSessionId={}, groupId={}, inviterId={}, inviteeIds={}",
                    reqVO.getCallSessionId(), reqVO.getGroupId(), inviterId, reqVO.getInviteeIds());

            return success(convertToGroupInviteRespVO(result));
        } catch (Exception e) {
            log.error("[inviteGroupMembers] 群组通话邀请失败, callSessionId={}, groupId={}, error={}",
                    reqVO.getCallSessionId(), reqVO.getGroupId(), e.getMessage(), e);
            return CommonResult.error(500, "群组通话邀请失败: " + e.getMessage());
        }
    }

    // ==================== 媒体状态同步 ====================

    @PostMapping("/media-state/update")
    @Operation(summary = "更新媒体状态（摄像头/麦克风开关）")
    public CommonResult<Boolean> updateMediaState(@Valid @RequestBody AppCallMediaStateReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        if (userId == null) {
            return CommonResult.error(401, "用户未登录");
        }
        if (StrUtil.isBlank(reqVO.getCallSessionId())) {
            return CommonResult.error(400, "通话会话ID不能为空");
        }

        try {
            callService.updateMediaState(reqVO.getCallSessionId(), userId, reqVO.getCameraEnabled(), reqVO.getMicrophoneEnabled());
            return success(true);
        } catch (Exception e) {
            log.error("[updateMediaState] 更新媒体状态失败, callSessionId={}, userId={}, error={}",
                    reqVO.getCallSessionId(), userId, e.getMessage(), e);
            return CommonResult.error(500, "更新媒体状态失败: " + e.getMessage());
        }
    }

    // ==================== 私有转换方法 ====================

    private void publishInvite(CallInviteResultVO result, Long callerId, Long calleeId) {
        AdminUserRespDTO caller = adminUserApi.getUser(callerId);
        JSONObject callerProfile = JSONUtil.createObj()
                .set("userId", String.valueOf(callerId))
                .set("displayName", caller != null ? caller.getNickname() : "")
                .set("avatarUrl", caller != null ? caller.getAvatar() : null);
        JSONObject payload = JSONUtil.createObj()
                .set("type", "call.invite")
                .set("callSessionId", result.getCallSessionId())
                .set("callId", result.getCallSessionId())
                .set("chatId", result.getChatId())
                .set("callType", result.getCallType())
                .set("callerId", String.valueOf(callerId))
                .set("calleeId", String.valueOf(calleeId))
                .set("callerProfile", callerProfile)
                .set("initiateTime", System.currentTimeMillis());
        callPushService.publishCallEvent(Collections.singleton(calleeId), callerId,
                TenantContextHolder.getTenantId(), payload);
    }

    @PostMapping("/group/create-invite")
    @Operation(summary = "原子创建群组通话邀请")
    public CommonResult<AppCallCreateInviteRespVO> createGroupInvite(@Valid @RequestBody AppCallGroupCreateInviteReqVO reqVO) {
        Long callerId = SecurityFrameworkUtils.getLoginUserId();
        if (callerId == null) return CommonResult.error(401, "用户未登录");
        try {
            Long groupId = Long.valueOf(reqVO.getGroupId());
            Long chatId = Long.valueOf(reqVO.getChatId());
            ImChatDO chat = chatMapper.selectById(chatId);
            if (chat == null || !Objects.equals(chat.getGroupId(), groupId)) {
                return CommonResult.error(400, "会话与群组不匹配");
            }
            if (!"audio".equalsIgnoreCase(reqVO.getCallType())
                    && !"video".equalsIgnoreCase(reqVO.getCallType())) {
                return CommonResult.error(400, "通话类型仅支持 audio 或 video");
            }
            Integer callType = convertCallTypeToInt(reqVO.getCallType());
            String callId = groupCallService.initiateGroupCall(callerId, chatId, groupId,
                    reqVO.getInviteeIds(), callType, reqVO.getDeviceId());
            AppCallCreateInviteRespVO response = new AppCallCreateInviteRespVO();
            response.setCallSessionId(callId);
            response.setInviteId(callId);
            response.setChatId(reqVO.getChatId());
            response.setCallType(reqVO.getCallType());
            response.setStatus("ringing");
            log.info("[createGroupInvite] 原子创建群通话, callId={}, groupId={}, invitees={}", callId, groupId, reqVO.getInviteeIds().size());
            return success(response);
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
        ImCallRecordDO record = callService.getCallRecord(reqVO.getCallSessionId());
        if (record == null || record.getGroupId() == null) {
            return CommonResult.error(400, "不是有效的群组通话");
        }
        groupCallService.leaveGroupCall(reqVO.getCallSessionId(), userId);
        return success(true);
    }

    /** 广播终态/接听态，确保双方以及双方的所有设备状态收敛。 */
    private void publishStateEvent(String callSessionId, String eventType, Long actorId, String reason) {
        ImCallRecordDO record = callService.getCallRecord(callSessionId);
        if (record == null) {
            return;
        }
        // 业务动作使用数据库 CAS；如果本次请求竞争失败，就不要
        // 基于实际胜出的状态再发布本次请求的事件。
        if ("call.accepted".equals(eventType)
                && !com.shengyu.module.system.enums.im.ImCallStateEnum.CONNECTED.getState().equals(record.getState())) {
            return;
        }
        if (("call.rejected".equals(eventType) || "call.cancelled".equals(eventType) || "call.ended".equals(eventType))
                && (!com.shengyu.module.system.enums.im.ImCallStateEnum.ENDED.getState().equals(record.getState())
                || !Objects.equals(reason, record.getEndReason()))) {
            return;
        }
        JSONObject payload = JSONUtil.createObj()
                .set("type", eventType)
                .set("callSessionId", callSessionId)
                .set("callId", callSessionId)
                .set("actorId", String.valueOf(actorId))
                .set("acceptedDeviceId", record.getAcceptedDeviceId())
                .set("duration", record.getDuration())
                .set("reason", reason)
                .set("eventTime", System.currentTimeMillis());
        List<Long> recipients = record.getGroupId() == null
                ? Arrays.asList(record.getCallerId(), record.getCalleeId())
                : callParticipantMapper.selectByCallId(callSessionId).stream()
                .map(ImCallParticipantDO::getUserId).collect(Collectors.toList());
        callPushService.publishCallEvent(recipients, actorId,
                TenantContextHolder.getTenantId(), payload);
    }

    /**
     * 仅在通话被接听后才签发面向接收方的 RTC 令牌。
     * 这样可以把媒体资源分配留在振铃阶段之后，并为双方提供
     * CallController.onMediaTokenIssued() 消费的房间信息包。
     */
    private void publishMediaTokenEvents(String callSessionId, Long acceptedBy) {
        ImCallRecordDO record = callService.getCallRecord(callSessionId);
        Long tenantId = TenantContextHolder.getTenantId();
        if (record == null || tenantId == null || StrUtil.isBlank(record.getRoomId()) || StrUtil.isBlank(janusUrl)) {
            log.error("[publishMediaTokenEvents] RTC 房间配置缺失, callSessionId={}", callSessionId);
            return;
        }
        List<Long> recipients = record.getGroupId() == null
                ? Arrays.asList(record.getCallerId(), record.getCalleeId())
                : Arrays.asList(record.getCallerId(), acceptedBy);
        for (Long recipientId : recipients) {
            if (recipientId == null) {
                continue;
            }
            String token = callTokenService.generateToken(recipientId, tenantId, record.getRoomId());
            JSONObject rtcRoom = JSONUtil.createObj()
                    .set("callSessionId", callSessionId)
                    .set("roomId", record.getRoomId())
                    .set("publisherId", String.valueOf(recipientId))
                    .set("displayName", "")
                    .set("janusUrl", janusUrl)
                    .set("turnUrls", Collections.emptyList())
                    .set("turnUsername", "")
                    .set("turnCredential", "")
                    .set("token", token);
            JSONObject payload = JSONUtil.createObj()
                    .set("type", "call.media-token-issued")
                    .set("callSessionId", callSessionId)
                    .set("callId", callSessionId)
                    .set("acceptedDeviceId", record.getAcceptedDeviceId())
                    .set("rtcRoom", rtcRoom);
            callPushService.publishCallEvent(Collections.singleton(recipientId), acceptedBy, tenantId, payload);
        }
    }

    private void publishGroupJoinIfNeeded(String callSessionId, Long userId) {
        ImCallRecordDO record = callService.getCallRecord(callSessionId);
        if (record == null || record.getGroupId() == null) {
            return;
        }
        AdminUserRespDTO user = adminUserApi.getUser(userId);
        JSONObject payload = JSONUtil.createObj()
                .set("type", "call.group-join")
                .set("callSessionId", callSessionId)
                .set("callId", callSessionId)
                .set("groupId", String.valueOf(record.getGroupId()))
                .set("userId", String.valueOf(userId))
                .set("userName", user != null ? user.getNickname() : "")
                .set("avatarUrl", user != null ? user.getAvatar() : null)
                .set("joinTime", System.currentTimeMillis());
        List<Long> recipients = callParticipantMapper.selectByCallId(callSessionId).stream()
                .map(ImCallParticipantDO::getUserId).collect(Collectors.toList());
        callPushService.publishCallEvent(recipients, userId, TenantContextHolder.getTenantId(), payload);
    }

    /** 群邀请被拒绝时，在成员花名册上的效果等同于“加入前离开”。 */
    private void publishGroupLeaveIfNeeded(String callSessionId, Long userId) {
        ImCallRecordDO record = callService.getCallRecord(callSessionId);
        if (record == null || record.getGroupId() == null) {
            return;
        }
        JSONObject payload = JSONUtil.createObj()
                .set("type", "call.group-leave")
                .set("callSessionId", callSessionId)
                .set("callId", callSessionId)
                .set("groupId", String.valueOf(record.getGroupId()))
                .set("userId", String.valueOf(userId))
                .set("leaveTime", System.currentTimeMillis());
        List<Long> recipients = callParticipantMapper.selectByCallId(callSessionId).stream()
                .map(ImCallParticipantDO::getUserId).collect(Collectors.toList());
        callPushService.publishCallEvent(recipients, userId, TenantContextHolder.getTenantId(), payload);
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
            rtcRoom.setRoomId(rtcRoomInfo.getRoomId());
            rtcRoom.setPublisherId(rtcRoomInfo.getPublisherId());
            rtcRoom.setDisplayName(rtcRoomInfo.getDisplayName());
            rtcRoom.setJanusUrl(rtcRoomInfo.getJanusUrl());
            rtcRoom.setTurnUrls(rtcRoomInfo.getTurnUrls());
            rtcRoom.setTurnUsername(rtcRoomInfo.getTurnUsername());
            rtcRoom.setTurnCredential(rtcRoomInfo.getTurnCredential());
            rtcRoom.setToken(rtcRoomInfo.getToken());
            respVO.setRtcRoom(rtcRoom);
        }

        return respVO;
    }

    /**
     * 转换群组通话邀请结果 VO
     */
    private AppCallGroupInviteRespVO convertToGroupInviteRespVO(GroupInviteResultVO result) {
        AppCallGroupInviteRespVO respVO = new AppCallGroupInviteRespVO();
        respVO.setCallSessionId(result.getCallSessionId());
        respVO.setInviteIds(result.getInviteIds());
        respVO.setInvitedCount(result.getInvitedCount());
        return respVO;
    }

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
