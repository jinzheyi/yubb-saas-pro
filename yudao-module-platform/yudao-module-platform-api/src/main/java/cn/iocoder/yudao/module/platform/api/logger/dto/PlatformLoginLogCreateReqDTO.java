package cn.iocoder.yudao.module.platform.api.logger.dto;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

/**
 * 创建登录日志 Request DTO
 * @author 朱述勇
 * @since 2022/7/7 4:24 PM
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 */
@Data
public class PlatformLoginLogCreateReqDTO {

    /**
     * 日志类型
     */
    @NotNull(message = "日志类型不能为空")
    private Integer logType;
    /**
     * 链路追踪编号
     */
    private String traceId;

    /**
     * 用户编号
     */
    private Long userId;
    /**
     * 用户类型
     */
    @NotNull(message = "用户类型不能为空")
    private Integer userType;
    /**
     * 用户账号
     */
    @NotBlank(message = "用户账号不能为空")
    @Size(max = 30, message = "用户账号长度不能超过30个字符")
    private String username;

    /**
     * 登录结果
     */
    @NotNull(message = "登录结果不能为空")
    private Integer result;

    /**
     * 用户 IP
     */
    @NotEmpty(message = "用户 IP 不能为空")
    private String userIp;
    /**
     * 浏览器 UserAgent
     *
     * 允许空，原因：Job 过期登出时，是无法传递 UserAgent 的
     */
    private String userAgent;

}
