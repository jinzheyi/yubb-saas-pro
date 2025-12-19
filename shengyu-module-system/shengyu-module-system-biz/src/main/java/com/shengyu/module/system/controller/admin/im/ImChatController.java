package com.shengyu.module.system.controller.admin.im;

import com.shengyu.module.system.service.im.ImChatService;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;

/**
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


}
