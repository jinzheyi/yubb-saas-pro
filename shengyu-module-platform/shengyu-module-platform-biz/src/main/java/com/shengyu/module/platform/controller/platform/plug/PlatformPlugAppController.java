package com.shengyu.module.platform.controller.platform.plug;

import static com.shengyu.framework.common.pojo.CommonResult.success;
import static com.shengyu.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;

import com.shengyu.framework.common.enums.CommonConstants;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.excel.core.util.ExcelUtils;
import com.shengyu.framework.operatelog.core.annotations.OperateLog;
import com.shengyu.module.platform.controller.platform.plug.vo.app.PlugAppCreateReqVO;
import com.shengyu.module.platform.controller.platform.plug.vo.app.PlugAppExcelVO;
import com.shengyu.module.platform.controller.platform.plug.vo.app.PlugAppExportReqVO;
import com.shengyu.module.platform.controller.platform.plug.vo.app.PlugAppPageReqVO;
import com.shengyu.module.platform.controller.platform.plug.vo.app.PlugAppRespVO;
import com.shengyu.module.platform.controller.platform.plug.vo.app.PlugAppSimpleRespVO;
import com.shengyu.module.platform.controller.platform.plug.vo.app.PlugAppUpdateEnableReqVO;
import com.shengyu.module.platform.controller.platform.plug.vo.app.PlugAppUpdateReqVO;
import com.shengyu.module.platform.controller.platform.plug.vo.app.PlugAppUpdateStatusReqVO;
import com.shengyu.module.platform.controller.platform.plug.vo.app.SubModuleListRespVO;
import com.shengyu.module.platform.dal.dataobject.plug.PlugAppDO;
import com.shengyu.module.platform.service.plug.PlugAppService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;
import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "管理后台 - 插件应用")
@RestController
@RequestMapping("/plug/plug-app")
@Validated
public class PlatformPlugAppController {

    @Resource
    private PlugAppService plugAppService;

    @PostMapping("/create")
    @Operation(summary = "创建插件应用")
    @PreAuthorize("@ps.hasPermission('plug:plug-app:create')")
    public CommonResult<Long> createPlugApp(@Valid @RequestBody PlugAppCreateReqVO createReqVO) {
        return success(plugAppService.createPlugApp(createReqVO));
    }

    @PutMapping("/update")
    @Operation(summary = "更新插件应用")
    @PreAuthorize("@ps.hasPermission('plug:plug-app:update')")
    public CommonResult<Boolean> updatePlugApp(@Valid @RequestBody PlugAppUpdateReqVO updateReqVO) {
        plugAppService.updatePlugApp(updateReqVO);
        return success(true);
    }

    @PutMapping("/update-status")
    @Operation(summary = "上下架插件应用，影响的是租户不能下单购买")
    @PreAuthorize("@ps.hasPermission('plug:plug-app:update-status')")
    public CommonResult<Boolean> updateStatusPlugApp(@Valid @RequestBody PlugAppUpdateStatusReqVO updateReqVO) {
        plugAppService.updateStatusPlugApp(updateReqVO);
        return success(true);
    }

    @PutMapping("/update-enable")
    @Operation(summary = "停用启用插件应用，停用后租户不能使用该插件")
    @PreAuthorize("@ps.hasPermission('plug:plug-app:update-enable')")
    public CommonResult<Boolean> updateStatusPlugApp(@Valid @RequestBody PlugAppUpdateEnableReqVO updateReqVO) {
        plugAppService.updateEnablePlugApp(updateReqVO);
        return success(true);
    }

    @GetMapping("/get")
    @Operation(summary = "获得插件应用")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('plug:plug-app:query')")
    public CommonResult<PlugAppRespVO> getPlugApp(@RequestParam("id") Long id) {
        PlugAppDO plugApp = plugAppService.getPlugApp(id);
        return success(BeanUtils.toBean(plugApp, PlugAppRespVO.class));
    }

    @GetMapping("/list")
    @Operation(summary = "获得插件应用列表")
    public CommonResult<List<PlugAppSimpleRespVO>> getPlugAppList() {
        List<PlugAppDO> list = plugAppService.getPlugAppList();
        return success(BeanUtils.toBean(list, PlugAppSimpleRespVO.class));
    }

    @GetMapping("/app-sn-sub-module")
    @Operation(summary = "获得模块条码列表")
    public CommonResult<List<SubModuleListRespVO>> getSubModuleList() {
        List<SubModuleListRespVO> moduleListRespVOS = Arrays.stream(CommonConstants.PlugAppSnEnum.values()).map(app -> {
            SubModuleListRespVO moduleListRespVO = new SubModuleListRespVO();
            moduleListRespVO.setCode(app.getCode());
            moduleListRespVO.setName(app.getName());
            return moduleListRespVO;
        }).collect(Collectors.toList());
        return success(moduleListRespVOS);
    }

    @GetMapping("/page")
    @Operation(summary = "获得插件应用分页")
    @PreAuthorize("@ps.hasPermission('plug:plug-app:query')")
    public CommonResult<PageResult<PlugAppSimpleRespVO>> getPlugAppPage(@Valid PlugAppPageReqVO pageVO) {
        PageResult<PlugAppDO> pageResult = plugAppService.getPlugAppPage(pageVO);
        return success(BeanUtils.toBean(pageResult, PlugAppSimpleRespVO.class));
    }

    @GetMapping("/export-excel")
    @Operation(summary = "导出插件应用 Excel")
    @PreAuthorize("@ps.hasPermission('plug:plug-app:export')")
    @OperateLog(type = EXPORT)
    public void exportPlugAppExcel(@Valid PlugAppExportReqVO exportReqVO,
              HttpServletResponse response) throws IOException {
        List<PlugAppDO> list = plugAppService.getPlugAppList(exportReqVO);
        // 导出 Excel
        List<PlugAppExcelVO> datas = BeanUtils.toBean(list, PlugAppExcelVO.class);
        ExcelUtils.write(response, "插件应用.xls", "数据", PlugAppExcelVO.class, datas);
    }

}
