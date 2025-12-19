package com.shengyu.module.system.controller.admin.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.system.controller.admin.im.vo.message.ImChatMessageRespVO;
import com.shengyu.module.system.controller.admin.im.vo.message.ImChatRecallReqVO;
import com.shengyu.module.system.controller.admin.im.vo.message.ImChatSendReqVO;
import com.shengyu.module.system.service.im.ImChatService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;

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
@RequestMapping("/im/chat")
@Validated
public class ImChatController {

    @Resource
    private ImChatService imChatService;

    /**
     * 发送消息
     *
     * @param reqVO 发送消息请求
     * @return 消息响应
     */
    @PostMapping("/send")
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
    @PostMapping("/getmessage")
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
    @PostMapping("/recall")
    @Operation(summary = "撤回消息")
    public CommonResult<ImChatMessageRespVO> recallMessage(@RequestBody ImChatRecallReqVO reqVO) {
        ImChatMessageRespVO message = imChatService.recallMessage(reqVO);
        return CommonResult.success(message);
    }
}
