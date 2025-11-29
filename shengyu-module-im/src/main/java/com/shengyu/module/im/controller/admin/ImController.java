package com.shengyu.module.im.controller.admin;

import static com.shengyu.framework.common.pojo.CommonResult.success;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.im.controller.admin.vo.group.*;
import com.shengyu.module.im.controller.admin.vo.message.*;
import com.shengyu.module.im.controller.admin.vo.user.ImUserCreateOrUpdateReqVO;
import com.shengyu.module.im.controller.admin.vo.user.ImUserUpdateStatusReqVO;
import com.shengyu.module.im.dal.dataobject.ImGroupDO;
import com.shengyu.module.im.dal.dataobject.ImGroupMemberDO;
import com.shengyu.module.im.dal.dataobject.ImMessageDO;
import com.shengyu.module.im.dal.dataobject.ImUserDO;
import com.shengyu.module.im.netty.ConnectionManager;
import com.shengyu.module.im.service.ImGroupService;
import com.shengyu.module.im.service.ImMessageService;
import com.shengyu.module.im.service.ImUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;

/**
 * IM管理控制器
 * 暂时注释掉所有Spring注解，避免Spring自动扫描
 *
 * @author 圣钰科技
 */
@Tag(name = "管理后台 - IM管理")
@RestController
@RequestMapping("/admin-api/im")
@Validated
@Slf4j
public class ImController {

    @Autowired
    private ConnectionManager connectionManager;

    @Autowired
    private ImMessageService imMessageService;

    @Autowired
    private ImGroupService imGroupService;

    @Autowired
    private ImUserService imUserService;

    @GetMapping("/online-count")
    @Operation(summary = "获取在线用户数量")
    public CommonResult<Integer> getOnlineUserCount() {
        return success(connectionManager.getOnlineUserCount());
    }

    @GetMapping("/user/is-online")
    @Operation(summary = "获取用户在线状态")
    public CommonResult<Boolean> getUserIsOnline(
            @Parameter(description = "用户ID", required = true) @RequestParam Long userId) {
        return success(connectionManager.isOnline(userId));
    }

    @GetMapping("/current-user")
    @Operation(summary = "获取当前登录用户信息")
    public CommonResult<Long> getCurrentUser() {
        return success(SecurityFrameworkUtils.getLoginUserId());
    }

    @GetMapping("/history/single")
    @Operation(summary = "获取单聊历史消息")
    public CommonResult<List<ImMessageDO>> getSingleChatHistory(@Valid ImSingleChatHistoryReqVO reqVO) {
        return success(imMessageService.getSingleChatHistory(reqVO.getSenderId(), reqVO.getReceiverId(), reqVO.getLimit(), reqVO.getOffset()));
    }

    @GetMapping("/history/group")
    @Operation(summary = "获取群聊历史消息")
    public CommonResult<List<ImMessageDO>> getGroupChatHistory(@Valid ImGroupChatHistoryReqVO reqVO) {
        return success(imMessageService.getGroupChatHistory(reqVO.getGroupId(), reqVO.getLimit(), reqVO.getOffset()));
    }

    @GetMapping("/unread")
    @Operation(summary = "获取未读消息")
    public CommonResult<List<ImMessageDO>> getUnreadMessages() {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(imMessageService.getUnreadMessages(userId));
    }

    @PostMapping("/message/ack")
    @Operation(summary = "确认消息已读")
    public CommonResult<Boolean> acknowledgeMessage(@Valid @RequestBody ImMessageAckReqVO reqVO) {
        return success(imMessageService.updateMessageStatus(reqVO.getMessageId(), 1));
    }

    @PostMapping("/message/recall")
    @Operation(summary = "撤回消息")
    public CommonResult<Boolean> recallMessage(@Valid @RequestBody ImMessageRecallReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(imMessageService.recallMessage(reqVO.getMessageId(), userId));
    }

    @PostMapping("/message/delete")
    @Operation(summary = "删除消息")
    public CommonResult<Boolean> deleteMessage(@Valid @RequestBody ImMessageRecallReqVO reqVO) {
        return success(imMessageService.deleteMessage(reqVO.getMessageId()));
    }

    // 群组管理相关接口
    @PostMapping("/group/create")
    @Operation(summary = "创建群组")
    public CommonResult<Long> createGroup(@Valid @RequestBody ImGroupCreateReqVO reqVO) {
        Long ownerId = SecurityFrameworkUtils.getLoginUserId();
        return success(imGroupService.createGroup(reqVO.getName(), reqVO.getAvatar(), reqVO.getDescription(), ownerId));
    }

    @PostMapping("/group/join")
    @Operation(summary = "加入群组")
    public CommonResult<Boolean> joinGroup(@Valid @RequestBody ImGroupJoinReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(imGroupService.joinGroup(reqVO.getGroupId(), userId));
    }

    @PostMapping("/group/exit")
    @Operation(summary = "退出群组")
    public CommonResult<Boolean> exitGroup(@Valid @RequestBody ImGroupExitReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(imGroupService.exitGroup(reqVO.getGroupId(), userId));
    }

    @GetMapping("/group/info")
    @Operation(summary = "获取群组信息")
    public CommonResult<ImGroupDO> getGroupInfo(
            @Parameter(description = "群组ID", required = true) @RequestParam Long groupId) {
        return success(imGroupService.getGroupInfo(groupId));
    }

    @GetMapping("/group/members")
    @Operation(summary = "获取群组成员列表")
    public CommonResult<List<ImGroupMemberDO>> getGroupMembers(
            @Parameter(description = "群组ID", required = true) @RequestParam Long groupId) {
        return success(imGroupService.getGroupMembers(groupId));
    }

    @GetMapping("/group/my-groups")
    @Operation(summary = "获取用户加入的群组列表")
    public CommonResult<List<ImGroupDO>> getUserGroups() {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(imGroupService.getUserGroups(userId));
    }

    @PostMapping("/group/update")
    @Operation(summary = "更新群组信息")
    public CommonResult<Boolean> updateGroup(@Valid @RequestBody ImGroupUpdateReqVO reqVO) {
        Long ownerId = SecurityFrameworkUtils.getLoginUserId();
        return success(imGroupService.updateGroup(reqVO.getGroupId(), reqVO.getName(), reqVO.getAvatar(), reqVO.getDescription(), ownerId));
    }

    @PostMapping("/group/dissolve")
    @Operation(summary = "解散群组")
    public CommonResult<Boolean> dissolveGroup(@Valid @RequestBody ImGroupDissolveReqVO reqVO) {
        Long ownerId = SecurityFrameworkUtils.getLoginUserId();
        return success(imGroupService.dissolveGroup(reqVO.getGroupId(), ownerId));
    }

    @PostMapping("/group/remove-member")
    @Operation(summary = "移除群组成员")
    public CommonResult<Boolean> removeMember(@Valid @RequestBody ImGroupRemoveMemberReqVO reqVO) {
        Long operator = SecurityFrameworkUtils.getLoginUserId();
        return success(imGroupService.removeMember(reqVO.getGroupId(), reqVO.getUserId(), operator));
    }

    @PostMapping("/group/set-role")
    @Operation(summary = "设置群成员角色")
    public CommonResult<Boolean> setMemberRole(@Valid @RequestBody ImGroupSetMemberRoleReqVO reqVO) {
        Long operator = SecurityFrameworkUtils.getLoginUserId();
        return success(imGroupService.setMemberRole(reqVO.getGroupId(), reqVO.getUserId(), reqVO.getRole(), operator));
    }

    // 用户状态管理相关接口
    @GetMapping("/user/status")
    @Operation(summary = "获取用户在线状态")
    public CommonResult<Integer> getUserOnlineStatus(
            @Parameter(description = "用户ID", required = true) @RequestParam Long userId) {
        return success(imUserService.getOnlineStatus(userId));
    }

    @PostMapping("/user/status/update")
    @Operation(summary = "更新用户在线状态")
    public CommonResult<Boolean> updateUserOnlineStatus(@Valid @RequestBody ImUserUpdateStatusReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(imUserService.updateOnlineStatus(userId, reqVO.getOnlineStatus()));
    }

    @GetMapping("/user/info")
    @Operation(summary = "获取IM用户信息")
    public CommonResult<ImUserDO> getImUserInfo(
            @Parameter(description = "用户ID", required = true) @RequestParam Long userId) {
        return success(imUserService.getImUserByUserId(userId));
    }

    @PostMapping("/user/create-or-update")
    @Operation(summary = "创建或更新IM用户")
    public CommonResult<Long> createOrUpdateImUser(@Valid @RequestBody ImUserCreateOrUpdateReqVO reqVO) {
        return success(imUserService.createOrUpdateImUser(reqVO.getUserId(), reqVO.getNickname(), reqVO.getAvatar()));
    }

    @PostMapping("/user/disable")
    @Operation(summary = "禁用用户")
    public CommonResult<Boolean> disableUser(
            @Parameter(description = "用户ID", required = true) @RequestParam Long userId) {
        return success(imUserService.disableUser(userId));
    }

    @PostMapping("/user/enable")
    @Operation(summary = "启用用户")
    public CommonResult<Boolean> enableUser(
            @Parameter(description = "用户ID", required = true) @RequestParam Long userId) {
        return success(imUserService.enableUser(userId));
    }

}
