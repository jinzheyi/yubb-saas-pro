package com.shengyu.module.system.controller.app.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.util.qrcode.QRCodeUtil;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.app.im.vo.group.*;
import com.shengyu.module.system.service.im.ImGroupService;
import com.shengyu.module.system.service.im.ImGroupOrchestrationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.annotation.security.PermitAll;
import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import java.io.IOException;
import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;

/**
 * 移动端 - IM 群组 Controller
 *
 * @author 圣钰科技
 */
@Tag(name = "移动端 - IM 群组")
@RestController
@RequestMapping("/system/im/group")
@Validated
@DataPermission(enable = false)
public class AppImGroupController {

    @Resource
    private ImGroupService groupService;

    @Resource
    private ImGroupOrchestrationService groupOrchestrationService;

    @PostMapping("/create")
    @Operation(summary = "创建群组")
    public CommonResult<AppImGroupCreateRespVO> createGroup(@Valid @RequestBody AppImGroupCreateReqVO createReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(groupOrchestrationService.createGroupWithConversation(userId, createReqVO));
    }

    @PutMapping("/update")
    @Operation(summary = "更新群组信息")
    public CommonResult<Boolean> updateGroup(@Valid @RequestBody AppImGroupUpdateReqVO updateReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        groupService.updateGroup(userId, updateReqVO);
        return success(true);
    }

    @DeleteMapping("/dissolve")
    @Operation(summary = "解散群组")
    @Parameter(name = "id", description = "群组ID", required = true)
    public CommonResult<Boolean> dissolveGroup(@RequestParam("id") Long id) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        groupService.dissolveGroup(userId, id);
        return success(true);
    }

    @PostMapping("/quit")
    @Operation(summary = "退出群组")
    @Parameter(name = "id", description = "群组ID", required = true)
    public CommonResult<Boolean> quitGroup(@RequestParam("id") Long id) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        groupService.quitGroup(userId, id);
        return success(true);
    }

    @GetMapping("/get")
    @Operation(summary = "获取群组信息")
    @Parameter(name = "id", description = "群组ID", required = true)
    public CommonResult<AppImGroupRespVO> getGroup(@RequestParam("id") Long id) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(groupService.getGroup(userId, id));
    }

    @GetMapping("/list")
    @Operation(summary = "获取用户的群组列表")
    public CommonResult<List<AppImGroupRespVO>> getGroupList() {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(groupService.getGroupList(userId));
    }

    @PostMapping("/member/add")
    @Operation(summary = "添加群成员")
    public CommonResult<Boolean> addGroupMembers(@Valid @RequestBody AppImGroupMemberAddReqVO addReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        groupService.addGroupMembers(userId, addReqVO);
        return success(true);
    }

    @DeleteMapping("/member/remove")
    @Operation(summary = "移除群成员")
    @Parameter(name = "groupId", description = "群组ID", required = true)
    @Parameter(name = "memberUserId", description = "成员用户ID", required = true)
    public CommonResult<Boolean> removeGroupMember(
            @RequestParam("groupId") Long groupId,
            @RequestParam("memberUserId") Long memberUserId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        groupService.removeGroupMember(userId, groupId, memberUserId);
        return success(true);
    }

    @GetMapping("/member/list")
    @Operation(summary = "获取群成员列表")
    @Parameter(name = "groupId", description = "群组ID", required = true)
    public CommonResult<List<AppImGroupMemberRespVO>> getGroupMembers(@RequestParam("groupId") Long groupId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(groupService.getGroupMembers(userId, groupId));
    }

    @PutMapping("/member/set-role")
    @Operation(summary = "设置群成员角色")
    @Parameter(name = "groupId", description = "群组ID", required = true)
    @Parameter(name = "memberUserId", description = "成员用户ID", required = true)
    @Parameter(name = "role", description = "角色(0-普通成员 1-管理员 2-群主)", required = true)
    public CommonResult<Boolean> setGroupMemberRole(
            @RequestParam("groupId") Long groupId,
            @RequestParam("memberUserId") Long memberUserId,
            @RequestParam("role") Integer role) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        groupService.setGroupMemberRole(userId, groupId, memberUserId, role);
        return success(true);
    }

    @PutMapping("/member/set-admin")
    @Operation(summary = "设置管理员", description = "将群成员设置为管理员，仅群主可操作")
    @Parameter(name = "groupId", description = "群组ID", required = true)
    @Parameter(name = "memberUserId", description = "成员用户ID", required = true)
    public CommonResult<Boolean> setAdmin(
            @RequestParam("groupId") Long groupId,
            @RequestParam("memberUserId") Long memberUserId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        groupService.setAdmin(userId, groupId, memberUserId, true);
        return success(true);
    }

    @PutMapping("/member/remove-admin")
    @Operation(summary = "取消管理员", description = "取消群成员的管理员身份，仅群主可操作")
    @Parameter(name = "groupId", description = "群组ID", required = true)
    @Parameter(name = "memberUserId", description = "成员用户ID", required = true)
    public CommonResult<Boolean> removeAdmin(
            @RequestParam("groupId") Long groupId,
            @RequestParam("memberUserId") Long memberUserId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        groupService.setAdmin(userId, groupId, memberUserId, false);
        return success(true);
    }

    @PutMapping("/member/set-muted")
    @Operation(summary = "设置群成员禁言")
    @Parameter(name = "groupId", description = "群组ID", required = true)
    @Parameter(name = "memberUserId", description = "成员用户ID", required = true)
    @Parameter(name = "muted", description = "是否禁言", required = true)
    public CommonResult<Boolean> setGroupMemberMuted(
            @RequestParam("groupId") Long groupId,
            @RequestParam("memberUserId") Long memberUserId,
            @RequestParam("muted") Boolean muted) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        groupService.setGroupMemberMuted(userId, groupId, memberUserId, muted);
        return success(true);
    }

    @PutMapping("/member/set-nickname")
    @Operation(summary = "设置群成员昵称", description = "memberUserId 为空时表示设置自己在本群的昵称")
    public CommonResult<Boolean> setGroupMemberNickname(
            @Valid @RequestBody AppImGroupMemberNicknameUpdateReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        groupService.setMemberNickname(userId, reqVO.getGroupId(), reqVO.getMemberUserId(), reqVO.getNickname());
        return success(true);
    }

    @PutMapping("/transfer-owner")
    @Operation(summary = "转让群主")
    @Parameter(name = "groupId", description = "群组ID", required = true)
    @Parameter(name = "newOwnerId", description = "新群主ID", required = true)
    public CommonResult<Boolean> transferGroupOwner(
            @RequestParam("groupId") Long groupId,
            @RequestParam("newOwnerId") Long newOwnerId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        groupService.transferGroupOwner(userId, groupId, newOwnerId);
        return success(true);
    }

    // ==================== 群邀请码相关接口 ====================

    @PostMapping("/invite/generate")
    @Operation(summary = "生成群邀请码", description = "生成群二维码邀请码，用于分享给他人扫码加入群聊")
    public CommonResult<AppImGroupInviteRespVO> generateInviteCode(
            @Valid @RequestBody AppImGroupInviteGenerateReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(groupService.generateInviteCode(userId, reqVO));
    }

    @GetMapping("/invite/verify")
    @Operation(summary = "验证邀请码", description = "验证邀请码是否有效，返回群组信息")
    @Parameter(name = "code", description = "邀请码", required = true, example = "GRP1A2B3C4D5E6F7G8H")
    public CommonResult<AppImGroupInviteVerifyRespVO> verifyInviteCode(
            @RequestParam("code") String code) {
        return success(groupService.verifyInviteCode(code));
    }

    @PostMapping("/invite/join")
    @Operation(summary = "通过邀请码加入群", description = "扫描群二维码后，通过邀请码加入群聊")
    public CommonResult<AppImGroupInviteJoinRespVO> joinByInviteCode(
            @Valid @RequestBody AppImGroupInviteJoinReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(groupService.joinGroupByInviteCode(userId, reqVO.getInviteCode()));
    }

    @GetMapping("/join-request/list")
    @Operation(summary = "获取群加群申请列表", description = "群主或管理员查看待审批/已处理的加群申请")
    @Parameter(name = "groupId", description = "群组ID", required = true)
    @Parameter(name = "status", description = "状态(1-待审批 2-已通过 3-已拒绝)", required = false)
    public CommonResult<List<AppImGroupJoinRequestRespVO>> getJoinRequests(
            @RequestParam("groupId") Long groupId,
            @RequestParam(value = "status", required = false) Integer status) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(groupService.getJoinRequests(userId, groupId, status));
    }

    @GetMapping("/join-request/pending-count")
    @Operation(summary = "获取群待审批申请数量", description = "群主或管理员查看当前群待审批的加群申请数量")
    @Parameter(name = "groupId", description = "群组ID", required = true)
    public CommonResult<Long> getPendingJoinRequestCount(@RequestParam("groupId") Long groupId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(groupService.getPendingJoinRequestCount(userId, groupId));
    }

    @GetMapping("/join-request/managed-pending-count")
    @Operation(summary = "获取我管理的全部群待审批申请总数", description = "统计当前用户作为群主或管理员时，全部群的待审批入群申请总数")
    public CommonResult<Long> getManagedPendingJoinRequestCount() {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(groupService.getManagedPendingJoinRequestCount(userId));
    }

    @PutMapping("/join-request/approve")
    @Operation(summary = "通过加群申请", description = "群主或管理员审批通过加群申请")
    public CommonResult<Boolean> approveJoinRequest(@Valid @RequestBody AppImGroupJoinRequestProcessReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        groupService.approveJoinRequest(userId, reqVO.getRequestId());
        return success(true);
    }

    @PutMapping("/join-request/reject")
    @Operation(summary = "拒绝加群申请", description = "群主或管理员拒绝加群申请")
    public CommonResult<Boolean> rejectJoinRequest(@Valid @RequestBody AppImGroupJoinRequestProcessReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        groupService.rejectJoinRequest(userId, reqVO.getRequestId(), reqVO.getRejectReason());
        return success(true);
    }

    @GetMapping("/invite/get")
    @Operation(summary = "获取群的有效邀请码", description = "获取群当前有效的邀请码信息")
    @Parameter(name = "groupId", description = "群组ID", required = true, example = "123456")
    public CommonResult<AppImGroupInviteRespVO> getGroupInviteCode(
            @RequestParam("groupId") Long groupId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(groupService.getGroupInviteCode(userId, groupId));
    }

    @GetMapping("/invite/qrcode-image")
    @Operation(summary = "获取群邀请二维码图片", description = "生成群邀请二维码图片，支持跨平台扫码")
    @Parameter(name = "code", description = "邀请码", required = true, example = "GRP1A2B3C4D5E6F7G8H")
    @Parameter(name = "groupId", description = "群组ID", required = false, example = "123456")
    @Parameter(name = "baseUrl", description = "前端应用基础URL", required = true, example = "http://localhost:48080")
    @PermitAll
    public void getInviteQRCodeImage(
            @RequestParam("code") String code,
            @RequestParam(value = "groupId", required = false) Long groupId,
            @RequestParam("baseUrl") String baseUrl,
            HttpServletResponse response) throws IOException {
        
        // 1. 验证邀请码
        AppImGroupInviteVerifyRespVO verifyResult = groupService.verifyInviteCode(code);
        if (!verifyResult.getValid()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "邀请码无效或已过期");
            return;
        }
        
        // 2. 获取相对路径
        String relativePath = groupService.getQRCodeContentByInviteCode(code, groupId);
        
        // 3. 拼接完整 URL
        String qrContent = baseUrl + relativePath;
        
        // 4. 生成二维码图片
        byte[] qrCodeBytes = QRCodeUtil.generateQRCodeBytes(qrContent, 300, 300);
        
        // 5. 设置响应头（浏览器缓存12小时）
        response.setContentType("image/png");
        response.setHeader("Cache-Control", "public, max-age=43200");
        response.setHeader("Pragma", "cache");
        response.setDateHeader("Expires", System.currentTimeMillis() + 43200000L);
        
        // 6. 输出图片
        response.getOutputStream().write(qrCodeBytes);
        response.getOutputStream().flush();
    }

    // ==================== 群公告相关接口 ====================

    @PutMapping("/notice/update")
    @Operation(summary = "更新群公告", description = "更新群公告内容，群主和管理员可操作")
    public CommonResult<Boolean> updateGroupNotice(
            @Valid @RequestBody AppImGroupNoticeUpdateReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        groupService.updateGroupNotice(userId, reqVO);
        return success(true);
    }

}
