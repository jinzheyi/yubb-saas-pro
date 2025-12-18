package com.shengyu.module.system.controller.admin.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.system.controller.admin.im.vo.mail.ImMailListRespVO;
import com.shengyu.module.system.service.im.ImMailService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;

import static com.shengyu.framework.common.pojo.CommonResult.success;

/**
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2022/11/19 15:01
 */
@Tag(name = "通讯录相关业务接口")
@RestController
@RequestMapping("/im/mail")
@Validated
public class ImMailController {

    @Resource
    private ImMailService imMailService;

    @GetMapping("/list")
    @Operation(summary = "获取用户通讯录列表")
    public CommonResult<ImMailListRespVO> getMailList() {
        return success(imMailService.list());
    }

}
