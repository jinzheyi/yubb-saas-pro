package com.shengyu.module.system.controller.admin.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.system.controller.admin.im.vo.apply.ImApplyAddReqVO;
import com.shengyu.module.system.controller.admin.im.vo.apply.ImApplyHandleReqVO;
import com.shengyu.module.system.controller.admin.im.vo.apply.ImApplyListRespVO;
import com.shengyu.module.system.controller.admin.im.vo.group.*;
import com.shengyu.module.system.controller.admin.im.vo.message.ImChatMessageRespVO;
import com.shengyu.module.system.controller.admin.im.vo.message.ImChatRecallReqVO;
import com.shengyu.module.system.controller.admin.im.vo.message.ImChatSendReqVO;
import com.shengyu.module.system.dal.dataobject.im.ImApplyDO;
import com.shengyu.module.system.dal.dataobject.im.ImGroupDO;
import com.shengyu.module.system.service.im.ImApplyService;
import com.shengyu.module.system.service.im.ImChatService;
import com.shengyu.module.system.service.im.ImGroupService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import java.util.List;
import java.util.Map;

/**
 * 聊天相关业务接口
 *
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2022/11/19 15:01
 */
@Tag(name = "聊天相关业务接口")
@RestController
@RequestMapping("/im")
@Validated
public class ImChatController {

    @Resource
    private ImChatService imChatService;

    @Resource
    private ImApplyService imApplyService;

    @Resource
    private ImGroupService imGroupService;

    /**
     * 发送消息
     *
     * @param reqVO 发送消息请求
     * @return 消息响应
     */
    @PostMapping("/chat/send")
    @Operation(summary = "发送消息")
    public CommonResult<ImChatMessageRespVO> sendMessage(@RequestBody ImChatSendReqVO reqVO) {
        ImChatMessageRespVO message = imChatService.sendMessage(reqVO);
        return CommonResult.success(message);
    }

    /**
     * 获取离线消息
     *
     * @return 成功响应
     */
    @PostMapping("/chat/getmessage")
    @Operation(summary = "获取离线消息")
    public CommonResult<Boolean> getOfflineMessage() {
        imChatService.getOfflineMessage();
        return CommonResult.success(true);
    }

    /**
     * 撤回消息
     *
     * @param reqVO 撤回消息请求
     * @return 消息响应
     */
    @PostMapping("/chat/recall")
    @Operation(summary = "撤回消息")
    public CommonResult<ImChatMessageRespVO> recallMessage(@RequestBody ImChatRecallReqVO reqVO) {
        ImChatMessageRespVO message = imChatService.recallMessage(reqVO);
        return CommonResult.success(message);
    }

    /**
     * 申请添加好友
     *
     * @param reqVO 好友申请请求
     * @return 好友申请信息
     */
    @PostMapping("/apply/add")
    @Operation(summary = "申请添加好友")
    public CommonResult<ImApplyDO> addFriend(@RequestBody ImApplyAddReqVO reqVO) {
        ImApplyDO apply = imApplyService.addFriend(reqVO);
        return CommonResult.success(apply);
    }

    /**
     * 获取好友申请列表
     *
     * @param page 页码
     * @param limit 每页数量
     * @return 好友申请列表
     */
    @GetMapping("/apply/list")
    @Operation(summary = "获取好友申请列表")
    public CommonResult<List<ImApplyListRespVO>> getApplyList(
            @Parameter(description = "页码，默认1") @RequestParam(defaultValue = "1") int page,
            @Parameter(description = "每页数量，默认10") @RequestParam(defaultValue = "10") int limit) {
        List<ImApplyListRespVO> applyList = imApplyService.getApplyList(page, limit);
        return CommonResult.success(applyList);
    }

    /**
     * 处理好友申请
     *
     * @param id 申请ID
     * @param reqVO 处理请求
     * @return 处理结果
     */
    @PostMapping("/apply/handle/{id}")
    @Operation(summary = "处理好友申请")
    public CommonResult<Boolean> handleApply(
            @Parameter(description = "申请ID") @PathVariable Long id,
            @RequestBody ImApplyHandleReqVO reqVO) {
        boolean result = imApplyService.handleApply(id, reqVO);
        return CommonResult.success(result);
    }

    // ---------------------------- 群聊相关接口 ----------------------------

    /**
     * 获取群聊列表
     *
     * @param page 页码
     * @param limit 每页数量
     * @return 群聊列表
     */
    @GetMapping("/group/list")
    @Operation(summary = "获取群聊列表")
    public CommonResult<List<ImGroupInfoRespVO>> getGroupList(
            @Parameter(description = "页码，默认1") @RequestParam(defaultValue = "1") int page,
            @Parameter(description = "每页数量，默认10") @RequestParam(defaultValue = "10") int limit) {
        List<ImGroupInfoRespVO> groupList = imGroupService.getGroupList(page, limit);
        return CommonResult.success(groupList);
    }

    /**
     * 创建群聊
     *
     * @param reqVO 群聊创建请求
     * @return 群聊信息
     */
    @PostMapping("/group/create")
    @Operation(summary = "创建群聊")
    public CommonResult<ImGroupDO> createGroup(@RequestBody ImGroupCreateReqVO reqVO) {
        ImGroupDO group = imGroupService.createGroup(reqVO);
        return CommonResult.success(group);
    }

    /**
     * 获取群聊信息
     *
     * @param id 群聊ID
     * @return 群聊信息
     */
    @GetMapping("/group/info/{id}")
    @Operation(summary = "获取群聊信息")
    public CommonResult<ImGroupInfoRespVO> getGroupInfo(
            @Parameter(description = "群聊ID") @PathVariable Long id) {
        ImGroupInfoRespVO groupInfo = imGroupService.getGroupInfo(id);
        return CommonResult.success(groupInfo);
    }

    /**
     * 修改群名称
     *
     * @param reqVO 群聊重命名请求
     * @return 是否成功
     */
    @PostMapping("/group/rename")
    @Operation(summary = "修改群名称")
    public CommonResult<Boolean> renameGroup(@RequestBody ImGroupRenameReqVO reqVO) {
        boolean result = imGroupService.renameGroup(reqVO);
        return CommonResult.success(result);
    }

    /**
     * 更新群公告
     *
     * @param reqVO 群公告更新请求
     * @return 是否成功
     */
    @PostMapping("/group/remark")
    @Operation(summary = "更新群公告")
    public CommonResult<Boolean> updateGroupRemark(@RequestBody ImGroupRemarkReqVO reqVO) {
        boolean result = imGroupService.updateGroupRemark(reqVO);
        return CommonResult.success(result);
    }

    /**
     * 更新群昵称
     *
     * @param reqVO 群昵称更新请求
     * @return 是否成功
     */
    @PostMapping("/group/nickname")
    @Operation(summary = "更新群昵称")
    public CommonResult<Boolean> updateGroupNickname(@RequestBody ImGroupNicknameReqVO reqVO) {
        boolean result = imGroupService.updateGroupNickname(reqVO);
        return CommonResult.success(result);
    }

    /**
     * 退出群聊
     *
     * @param reqVO 群聊退出请求
     * @return 是否成功
     */
    @PostMapping("/group/quit")
    @Operation(summary = "退出群聊")
    public CommonResult<Boolean> quitGroup(@RequestBody ImGroupQuitReqVO reqVO) {
        boolean result = imGroupService.quitGroup(reqVO);
        return CommonResult.success(result);
    }

    /**
     * 踢出群成员
     *
     * @param reqVO 群聊踢人请求
     * @return 是否成功
     */
    @PostMapping("/group/kickoff")
    @Operation(summary = "踢出群成员")
    public CommonResult<Boolean> kickoffGroupMember(@RequestBody ImGroupKickoffReqVO reqVO) {
        boolean result = imGroupService.kickoffGroupMember(reqVO);
        return CommonResult.success(result);
    }

    /**
     * 邀请加入群聊
     *
     * @param reqVO 群聊邀请请求
     * @return 是否成功
     */
    @PostMapping("/group/invite")
    @Operation(summary = "邀请加入群聊")
    public CommonResult<Boolean> inviteToGroup(@RequestBody ImGroupInviteReqVO reqVO) {
        boolean result = imGroupService.inviteToGroup(reqVO);
        return CommonResult.success(result);
    }

    /**
     * 加入群聊
     *
     * @param reqVO 群聊加入请求
     * @return 是否成功
     */
    @PostMapping("/group/join")
    @Operation(summary = "加入群聊")
    public CommonResult<Boolean> joinGroup(@RequestBody ImGroupJoinReqVO reqVO) {
        boolean result = imGroupService.joinGroup(reqVO);
        return CommonResult.success(result);
    }

    /**
     * 检查群聊关系
     *
     * @param id 群聊ID
     * @return 群聊关系
     */
    @PostMapping("/group/checkrelation")
    @Operation(summary = "检查群聊关系")
    public CommonResult<GroupRelationRespVO> checkGroupRelation(@RequestBody Map<String, Long> request) {
        Long id = request.get("id");
        GroupRelationRespVO result = imGroupService.checkGroupRelation(id);
        return CommonResult.success(result);
    }
    
    /**
     * 生成群二维码
     *
     * @param id 群聊ID
     * @return 二维码图片
     */
    @GetMapping("/group/qrcode/{id}")
    @Operation(summary = "生成群二维码")
    public byte[] generateGroupQrcode(
            @Parameter(description = "群聊ID") @PathVariable Long id) {
        return imGroupService.generateGroupQrcode(id);
    }
}
