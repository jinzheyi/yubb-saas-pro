package cn.iocoder.yudao.module.system.controller.admin.permission;

import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.module.platform.api.tenant.dto.menu.TenantMenuListReqDTO;
import cn.iocoder.yudao.module.platform.api.tenant.dto.menu.TenantMenuRespDTO;
import cn.iocoder.yudao.module.system.controller.admin.permission.vo.menu.MenuSimpleRespVO;
import cn.iocoder.yudao.module.system.convert.permission.MenuConvert;
import cn.iocoder.yudao.module.system.service.permission.MenuService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import java.util.Comparator;
import java.util.List;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;

@Api(tags = "管理后台 - 菜单")
@RestController
@RequestMapping("/system/menu")
@Validated
public class MenuController {

    @Resource
    private MenuService menuService;
    @GetMapping("/list-all-simple")
    @ApiOperation(value = "获取菜单精简信息列表", notes = "只包含被开启的菜单，用于【角色分配菜单】功能的选项。")
    public CommonResult<List<MenuSimpleRespVO>> getSimpleMenus() {
        // 获得菜单列表，只要开启状态的
        TenantMenuListReqDTO reqDTO = new TenantMenuListReqDTO();
        reqDTO.setStatus(CommonStatusEnum.ENABLE.getStatus());
        List<TenantMenuRespDTO> list = menuService.getTenantMenus(reqDTO);
        // 排序后，返回给前端
        list.sort(Comparator.comparing(TenantMenuRespDTO::getSort));
        return success(MenuConvert.INSTANCE.convertList02(list));
    }

}
