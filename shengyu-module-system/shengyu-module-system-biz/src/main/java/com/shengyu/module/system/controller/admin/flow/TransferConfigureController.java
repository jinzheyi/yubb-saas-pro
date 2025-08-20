package com.shengyu.module.system.controller.admin.flow;

import static com.shengyu.framework.common.pojo.CommonResult.success;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.system.controller.admin.flow.dto.TaskTransferConfigureDTO;
import com.shengyu.module.system.controller.admin.flow.vo.TaskTransferConfigureVO;
import com.shengyu.module.system.service.flow.IFlwTransferConfigureService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.AllArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 流程转办配置 前端控制器
 *
 * @author 青苗
 * @since 2025-08-17
 */
@Tag(name = "流程转办配置")
@RestController
@AllArgsConstructor
@RequestMapping("/v1/transfer-configure")
public class TransferConfigureController {
    private IFlwTransferConfigureService flwTransferConfigureService;

    @Operation(summary = "我的流程转办配置")
    @PreAuthorize("@ss.hasPermission('flw:transferConfigure:info')")
    @GetMapping("/info")
    public CommonResult<TaskTransferConfigureVO> getInfoByUserId(@RequestParam("userId") Long userId) {
        return success(flwTransferConfigureService.getInfoByUserId(userId));
    }

    @Operation(summary = "保存我的流程转办配置")
    @PreAuthorize("@ss.hasPermission('flw:transferConfigure:saveInfo')")
    @PostMapping("/save-info")
    public CommonResult<Boolean> saveInfo(@RequestBody TaskTransferConfigureDTO dto) {
        return success(flwTransferConfigureService.saveInfo(dto));
    }

    @Operation(summary = "我的流程转办配置")
    @PreAuthorize("@ss.hasPermission('flw:transferConfigure:my')")
    @GetMapping("/my")
    public CommonResult<TaskTransferConfigureVO> getMyConfigure() {
        return success(flwTransferConfigureService.getMyConfigure());
    }

    @Operation(summary = "保存我的流程转办配置")
    @PreAuthorize("@ss.hasPermission('flw:transferConfigure:save')")
    @PostMapping("/save")
    public CommonResult<Boolean> saveMyConfigure(@RequestBody TaskTransferConfigureDTO dto) {
        return success(flwTransferConfigureService.saveMyConfigure(dto));
    }
}
