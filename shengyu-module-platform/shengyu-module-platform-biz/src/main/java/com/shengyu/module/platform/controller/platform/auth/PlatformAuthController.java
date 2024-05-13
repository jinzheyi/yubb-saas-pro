package com.shengyu.module.platform.controller.platform.auth;

import static com.shengyu.framework.common.pojo.CommonResult.success;
import static com.shengyu.framework.common.util.collection.CollectionUtils.convertSet;
import static com.shengyu.framework.security.core.util.SecurityFrameworkUtils.getLoginUserId;
import static com.shengyu.framework.security.core.util.SecurityFrameworkUtils.getPlatformLoginUserId;
import static com.shengyu.framework.security.core.util.SecurityFrameworkUtils.obtainAuthorization;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.enums.logger.LoginLogTypeEnum;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.operatelog.core.annotations.OperateLog;
import com.shengyu.framework.security.config.SecurityProperties;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.platform.controller.platform.auth.vo.AuthLoginReqVO;
import com.shengyu.module.platform.controller.platform.auth.vo.AuthLoginRespVO;
import com.shengyu.module.platform.controller.platform.auth.vo.AuthPermissionInfoRespVO;
import com.shengyu.module.platform.controller.platform.auth.vo.AuthSmsLoginReqVO;
import com.shengyu.module.platform.controller.platform.auth.vo.AuthSmsSendReqVO;
import com.shengyu.module.platform.convert.auth.AuthConvert;
import com.shengyu.module.platform.dal.dataobject.permission.MenuDO;
import com.shengyu.module.platform.dal.dataobject.permission.PlatformRoleDO;
import com.shengyu.module.platform.dal.dataobject.user.PlatformUserDO;
import com.shengyu.module.platform.service.auth.PlatformAuthService;
import com.shengyu.module.platform.service.permission.PlatformMenuService;
import com.shengyu.module.platform.service.permission.PlatformPermissionService;
import com.shengyu.module.platform.service.permission.PlatformRoleService;
import com.shengyu.module.platform.service.user.PlatformUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import javax.annotation.Resource;
import javax.annotation.security.PermitAll;
import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "管理后台 - 认证")
@RestController
@RequestMapping("/system/auth")
@Validated
@Slf4j
public class PlatformAuthController {

    @Resource
    private PlatformAuthService authService;
    @Resource
    private PlatformUserService platformUserService;
    @Resource
    private PlatformRoleService platformRoleService;
    @Resource
    private PlatformMenuService platformMenuService;
    @Resource
    private PlatformPermissionService platformPermissionService;
    @Resource
    private SecurityProperties securityProperties;

    @PostMapping("/login")
    @PermitAll
    @Operation(summary = "使用账号密码登录")
    @OperateLog(enable = false) // 避免 Post 请求被记录操作日志
    public CommonResult<AuthLoginRespVO> login(@RequestBody @Valid AuthLoginReqVO reqVO) {
        return success(authService.login(reqVO));
    }

    @PostMapping("/logout")
    @PermitAll
    @Operation(summary = "登出系统")
    @OperateLog(enable = false) // 避免 Post 请求被记录操作日志
    public CommonResult<Boolean> logout(HttpServletRequest request) {
        String token = SecurityFrameworkUtils.obtainAuthorization(request,
            securityProperties.getTokenHeader(), securityProperties.getTokenParameter());
        if (StrUtil.isNotBlank(token)) {
            authService.logout(token, LoginLogTypeEnum.LOGOUT_SELF.getType());
        }
        return success(true);
    }

    @PostMapping("/refresh-token")
    @PermitAll
    @Operation(summary = "刷新令牌")
    @Parameter(name = "refreshToken", description = "刷新令牌", required = true)
    @OperateLog(enable = false) // 避免 Post 请求被记录操作日志
    public CommonResult<AuthLoginRespVO> refreshToken(@RequestParam("refreshToken") String refreshToken) {
        return success(authService.refreshToken(refreshToken));
    }

    @GetMapping("/get-permission-info")
    @Operation(summary = "获取登录用户的权限信息")
    public CommonResult<AuthPermissionInfoRespVO> getPermissionInfo() {
        // 获得用户信息
        PlatformUserDO user = platformUserService.getUser(getPlatformLoginUserId());
        if (user == null) {
            return null;
        }
        // 1.2 获得角色列表
        Set<Long> roleIds = platformPermissionService.getUserRoleIdListByUserId(getPlatformLoginUserId());
        if (CollUtil.isEmpty(roleIds)) {
            return success(AuthConvert.INSTANCE.convert(user, Collections.emptyList(), Collections.emptyList()));
        }
        List<PlatformRoleDO> roles = platformRoleService.getRoleList(roleIds);
        // 移除禁用的角色
        roles.removeIf(role -> !CommonStatusEnum.ENABLE.getStatus().equals(role.getStatus()));

        // 1.3 获得菜单列表
        Set<Long> menuIds = platformPermissionService.getRoleMenuListByRoleId(convertSet(roles, PlatformRoleDO::getId));
        List<MenuDO> menuList = platformMenuService.getMenuList(menuIds);
        // 移除禁用的菜单
        menuList.removeIf(menu -> !CommonStatusEnum.ENABLE.getStatus().equals(menu.getStatus()));

        // 2. 拼接结果返回
        return success(AuthConvert.INSTANCE.convert(user, roles, menuList));
    }

    // ========== 短信登录相关 ==========

    @PostMapping("/sms-login")
    @PermitAll
    @Operation(summary = "使用短信验证码登录")
    @OperateLog(enable = false) // 避免 Post 请求被记录操作日志
    public CommonResult<AuthLoginRespVO> smsLogin(@RequestBody @Valid AuthSmsLoginReqVO reqVO) {
        return success(authService.smsLogin(reqVO));
    }

    @PostMapping("/send-sms-code")
    @PermitAll
    @Operation(summary = "发送手机验证码")
    @OperateLog(enable = false) // 避免 Post 请求被记录操作日志
    public CommonResult<Boolean> sendLoginSmsCode(@RequestBody @Valid AuthSmsSendReqVO reqVO) {
        authService.sendSmsCode(reqVO);
        return success(true);
    }

}
