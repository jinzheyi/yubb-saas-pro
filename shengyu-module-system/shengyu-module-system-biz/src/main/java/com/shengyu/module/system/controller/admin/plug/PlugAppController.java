package com.shengyu.module.system.controller.admin.plug;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.system.controller.admin.plug.vo.app.PlugAppBuyReqVO;
import com.shengyu.module.system.controller.admin.plug.vo.app.PlugAppPageReqVO;
import com.shengyu.module.system.controller.admin.plug.vo.app.PlugAppRespVO;
import com.shengyu.module.system.controller.admin.plug.vo.app.PlugAppSimpleRespVO;
import com.shengyu.module.system.service.plug.PlugAppApiService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;

import static com.shengyu.framework.common.pojo.CommonResult.success;

/**
 * @Description 管理后台 - 租户插件市场
 * @Author zhusy
 * @Date 2023/4/13 15:04
 * @Version 1.0
 **/
@Tag(name = "管理后台 - 租户插件市场")
@RestController
@RequestMapping("/tenant/plug-app")
@Validated
public class PlugAppController {

    @Resource
    private PlugAppApiService appApiService;

    @GetMapping("/get")
    @Operation(summary = "获得插件信息")
    public CommonResult<PlugAppRespVO> getPlugApp(@RequestParam("id") Long id) {
        return success(appApiService.getPlugApp(id));
    }

    @GetMapping("/page")
    @Operation(summary = "获得插件市场")
    public CommonResult<PageResult<PlugAppSimpleRespVO>> getPlugAppList(PlugAppPageReqVO reqVO) {
        return success(appApiService.getPlugAppList(reqVO));
    }

    @PostMapping("/buy")
    @Operation(summary = "购买插件")
    public CommonResult<Long> buyPlugApp(@Valid @RequestBody PlugAppBuyReqVO reqVO) {
        return success(appApiService.buyPlugApp(reqVO));
    }

}
