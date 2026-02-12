package com.shengyu.module.system.controller.app.auth;

import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.operatelog.core.annotations.OperateLog;
import com.shengyu.framework.security.config.SecurityProperties;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.platform.api.tenant.dto.menu.TenantMenuListReqDTO;
import com.shengyu.module.platform.api.tenant.dto.menu.TenantMenuRespDTO;
import com.shengyu.module.system.controller.admin.auth.vo.AuthLoginRespVO;
import com.shengyu.module.system.controller.admin.auth.vo.AuthPermissionInfoRespVO;
import com.shengyu.module.system.controller.app.auth.vo.AppAuthLoginReqVO;
import com.shengyu.module.system.controller.app.auth.vo.AppAuthSmsLoginReqVO;
import com.shengyu.module.system.controller.app.auth.vo.AppAuthSmsSendReqVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.convert.auth.AuthConvert;
import com.shengyu.module.system.dal.dataobject.permission.RoleDO;
import com.shengyu.module.system.service.auth.AdminAuthService;
import com.shengyu.module.system.service.permission.MenuService;
import com.shengyu.module.system.service.permission.PermissionService;
import com.shengyu.module.system.service.permission.RoleService;
import com.shengyu.module.system.service.user.AdminUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.annotation.security.PermitAll;
import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Set;

import static cn.hutool.core.collection.CollUtil.isEmpty;
import static com.shengyu.framework.common.enums.logger.LoginLogTypeEnum.LOGOUT_SELF;
import static com.shengyu.framework.common.pojo.CommonResult.success;
import static com.shengyu.framework.common.util.collection.CollectionUtils.convertSet;
import static com.shengyu.framework.security.core.util.SecurityFrameworkUtils.getLoginUserId;

/**
 * 移动端 - 认证 Controller
 * 
 * 与 Web 端的区别：
 * 1. 登录接口支持设备信息（deviceType、deviceId、clientVersion）
 * 2. 支持多端登录策略（同设备类型互踢，不同设备类型共存）
 * 3. 路由前缀为 /app-api/system/auth（由 WebProperties 自动路由）
 * 
 * 注意：
 * - 本 Controller 放在 controller.app.auth 包下，会自动路由到 /app-api/**
 * - Service 层复用 Web 端的 AdminAuthService，业务逻辑一致
 * - 设备信息会在 Service 层处理，用于多端登录管理
 *
 * @author 圣钰科技
 */
@Tag(name = "移动端 - 认证")
@RestController
@RequestMapping("/system/auth")
@Validated
@Slf4j
public class AppAuthController {

    @Resource
    private AdminAuthService adminAuthService;
    @Resource
    private AdminUserService adminUserService;
    @Resource
    private RoleService roleService;
    @Resource
    private PermissionService permissionService;
    @Resource
    private SecurityProperties securityProperties;
    @Resource
    private MenuService menuService;

    @PostMapping("/login")
    @PermitAll
    @Operation(summary = "使用账号密码登录（移动端）")
    @OperateLog(enable = false) // 避免 Post 请求被记录操作日志
    public CommonResult<AuthLoginRespVO> login(@RequestBody @Valid AppAuthLoginReqVO reqVO) {
        log.info("[移动端登录] 用户: {}, 设备类型: {}, 设备ID: {}", 
                reqVO.getUsername(), reqVO.getDeviceType(), reqVO.getDeviceId());
        
        // 转换为 Web 端的 VO（Service 层复用）
        // 注意：设备信息会在后续的 WebSocket 认证时使用
        return success(adminAuthService.login(AuthConvert.INSTANCE.convert(reqVO)));
    }

    @PostMapping("/logout")
    @PermitAll
    @Operation(summary = "登出系统（移动端）")
    @OperateLog(enable = false) // 避免 Post 请求被记录操作日志
    public CommonResult<Boolean> logout(HttpServletRequest request) {
        String token = SecurityFrameworkUtils.obtainAuthorization(request,
                securityProperties.getTokenHeader(), securityProperties.getTokenParameter());
        if (StrUtil.isNotBlank(token)) {
            adminAuthService.logout(token, LOGOUT_SELF.getType());
        }
        return success(true);
    }

    @PostMapping("/refresh-token")
    @PermitAll
    @Operation(summary = "刷新令牌（移动端）")
    @Parameter(name = "refreshToken", description = "刷新令牌", required = true)
    @OperateLog(enable = false) // 避免 Post 请求被记录操作日志
    public CommonResult<AuthLoginRespVO> refreshToken(@RequestParam("refreshToken") String refreshToken) {
        return success(adminAuthService.refreshToken(refreshToken));
    }

    @GetMapping("/get-permission-info")
    @Operation(summary = "获取登录用户的权限信息（移动端）")
    public CommonResult<AuthPermissionInfoRespVO> getPermissionInfo() {
        // 1.1 获得用户信息
        UserRespVO user = adminUserService.getUser(getLoginUserId());
        if (user == null) {
            return null;
        }
        
        List<RoleDO> roles = Collections.emptyList();
        Set<Long> menuIds;
        
        // 1.2 判断是否为租户管理员
        if (adminUserService.hasTenantAdmin(user.getId())) {
            menuIds = permissionService.getRoleMenuListByTenantPackageAndPlugMenu();
        } else {
            // 1.3 获得角色列表
            Set<Long> roleIds = permissionService.getUserRoleIdListByUserId(getLoginUserId());
            if (isEmpty(roleIds)) {
                return success(AuthConvert.INSTANCE.convert(user, Collections.emptyList(), Collections.emptyList()));
            }
            roles = roleService.getRoleList(roleIds);
            // 移除禁用的角色
            roles.removeIf(role -> !CommonStatusEnum.ENABLE.getStatus().equals(role.getStatus()));
            // 1.4 获得菜单列表
            menuIds = permissionService.getRoleMenuListByRoleId(convertSet(roles, RoleDO::getId));
        }
        
        // 1.5 查询菜单列表
        TenantMenuListReqDTO reqDTO = new TenantMenuListReqDTO();
        reqDTO.setStatus(CommonStatusEnum.ENABLE.getStatus());
        reqDTO.setIds(new ArrayList<>(menuIds));
        List<TenantMenuRespDTO> menuList = menuService.getMenuListSimpleByTenant(reqDTO);
        
        // 2. 拼接结果返回
        return success(AuthConvert.INSTANCE.convert(user, roles, menuList));
    }

    // ========== 短信登录相关 ==========

    @PostMapping("/sms-login")
    @PermitAll
    @Operation(summary = "使用短信验证码登录（移动端）")
    @OperateLog(enable = false) // 避免 Post 请求被记录操作日志
    public CommonResult<AuthLoginRespVO> smsLogin(@RequestBody @Valid AppAuthSmsLoginReqVO reqVO) {
        log.info("[移动端短信登录] 手机号: {}, 设备类型: {}, 设备ID: {}", 
                reqVO.getMobile(), reqVO.getDeviceType(), reqVO.getDeviceId());
        
        // 转换为 Web 端的 VO（Service 层复用）
        return success(adminAuthService.smsLogin(AuthConvert.INSTANCE.convert(reqVO)));
    }

    @PostMapping("/send-sms-code")
    @PermitAll
    @Operation(summary = "发送手机验证码（移动端）")
    @OperateLog(enable = false) // 避免 Post 请求被记录操作日志
    public CommonResult<Boolean> sendLoginSmsCode(@RequestBody @Valid AppAuthSmsSendReqVO reqVO) {
        // 转换为 Web 端的 VO（Service 层复用）
        adminAuthService.sendSmsCode(AuthConvert.INSTANCE.convert(reqVO));
        return success(true);
    }

}
