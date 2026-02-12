package com.shengyu.module.system.controller.app.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.app.im.vo.group.*;
import com.shengyu.module.system.service.im.ImGroupService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
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
public class AppImGroupController {

    @Resource
    private ImGroupService groupService;

    @PostMapping("/create")
    @Operation(summary = "创建群组")
    public CommonResult<Long> createGroup(@Valid @RequestBody AppImGroupCreateReqVO createReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(groupService.createGroup(userId, createReqVO));
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

}
