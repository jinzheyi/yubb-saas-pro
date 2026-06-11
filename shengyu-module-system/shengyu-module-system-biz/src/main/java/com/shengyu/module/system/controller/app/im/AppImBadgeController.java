package com.shengyu.module.system.controller.app.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.app.im.vo.badge.AppImBadgeRespVO;
import com.shengyu.module.system.service.im.ImBadgeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;

import static com.shengyu.framework.common.pojo.CommonResult.success;

/**
 * 移动端 - IM 角标 Controller
 *
 * @author 圣钰科技
 */
@Tag(name = "移动端 - IM 角标")
@RestController
@RequestMapping("/system/im/badge")
@Validated
@DataPermission(enable = false)
public class AppImBadgeController {

    @Resource
    private ImBadgeService imBadgeService;

    @GetMapping("/get")
    @Operation(summary = "获取角标数据")
    public CommonResult<AppImBadgeRespVO> getBadgeData() {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(imBadgeService.getBadgeDataVO(userId));
    }

}
