package com.shengyu.module.system.controller.app.captcha;

import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.util.servlet.ServletUtils;
import com.shengyu.framework.operatelog.core.annotations.OperateLog;
import com.shengyu.framework.tenant.core.aop.TenantIgnore;
import com.xingyuv.captcha.model.common.ResponseModel;
import com.xingyuv.captcha.model.vo.CaptchaVO;
import com.xingyuv.captcha.service.CaptchaService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import javax.annotation.security.PermitAll;
import javax.servlet.http.HttpServletRequest;

/**
 * 移动端 - 验证码 Controller
 * 
 * 说明：
 * 1. 与 Web 端的验证码接口功能完全一致
 * 2. 路由前缀为 /app-api/system/captcha（由 WebProperties 自动路由）
 * 3. Service 层复用 Web 端的 CaptchaService
 * 
 * 注意：
 * - 本 Controller 放在 controller.app.captcha 包下，会自动路由到 /app-api/**
 * - 验证码服务使用第三方库 AJ-Captcha，支持滑动验证、点选验证等多种类型
 *
 * @author 圣钰科技
 */
@Tag(name = "移动端 - 验证码")
@RestController
@RequestMapping("/system/captcha")
@Slf4j
public class AppCaptchaController {

    @Resource
    private CaptchaService captchaService;

    @PostMapping({"/get"})
    @Operation(summary = "获得验证码（移动端）")
    @PermitAll
    @TenantIgnore
    @OperateLog(enable = false) // 避免 Post 请求被记录操作日志
    public ResponseModel get(@RequestBody CaptchaVO data, HttpServletRequest request) {
        assert request.getRemoteHost() != null;
        data.setBrowserInfo(getRemoteId(request));
        
        log.debug("[移动端验证码] 获取验证码, captchaType: {}", data.getCaptchaType());
        
        return captchaService.get(data);
    }

    @PostMapping("/check")
    @Operation(summary = "校验验证码（移动端）")
    @PermitAll
    @TenantIgnore
    @OperateLog(enable = false) // 避免 Post 请求被记录操作日志
    public ResponseModel check(@RequestBody CaptchaVO data, HttpServletRequest request) {
        data.setBrowserInfo(getRemoteId(request));
        
        log.debug("[移动端验证码] 校验验证码, captchaType: {}", data.getCaptchaType());
        
        return captchaService.check(data);
    }

    /**
     * 获取远程标识
     * 用于验证码的唯一性校验
     */
    public static String getRemoteId(HttpServletRequest request) {
        String ip = ServletUtils.getClientIP(request);
        String ua = request.getHeader("user-agent");
        if (StrUtil.isNotBlank(ip)) {
            return ip + ua;
        }
        return request.getRemoteAddr() + ua;
    }

}
