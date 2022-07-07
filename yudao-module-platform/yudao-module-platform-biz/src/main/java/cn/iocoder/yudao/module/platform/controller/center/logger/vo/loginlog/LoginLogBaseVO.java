package cn.iocoder.yudao.module.platform.controller.center.logger.vo.loginlog;

import cn.iocoder.yudao.module.platform.enums.logger.PlatformLoginLogTypeEnum;
import cn.iocoder.yudao.module.platform.enums.logger.PlatformLoginResultEnum;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

/**
 * 登录日志 Base VO，提供给添加、修改、详细的子 VO 使用
 * 如果子 VO 存在差异的字段，请不要添加到这里，影响 Swagger 文档生成
 *
 * @author 朱述勇
 * @since 2022/7/7 3:24 PM
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 */
@Data
public class LoginLogBaseVO {

    /**
     * 日志类型 {@link PlatformLoginLogTypeEnum}
     */
    @ApiModelProperty(value = "日志类型", required = true, example = "1", notes = "参见 PlatformLoginLogTypeEnum 枚举类")
    @NotNull(message = "日志类型不能为空")
    private Integer logType;

    @ApiModelProperty(value = "链路追踪编号", required = true, example = "89aca178-a370-411c-ae02-3f0d672be4ab")
    @NotEmpty(message = "链路追踪编号不能为空")
    private String traceId;

    @ApiModelProperty(value = "用户账号", required = true, example = "圣钰SaaS")
    @NotBlank(message = "用户账号不能为空")
    @Size(max = 30, message = "用户账号长度不能超过30个字符")
    private String username;

    /**
     * 登录结果 {@link PlatformLoginResultEnum}
     */
    @ApiModelProperty(value = "登录结果", required = true, example = "1", notes = "参见 PlatformLoginResultEnum 枚举类")
    @NotNull(message = "登录结果不能为空")
    private Integer result;

    @ApiModelProperty(value = "用户 IP", required = true, example = "127.0.0.1")
    @NotEmpty(message = "用户 IP 不能为空")
    private String userIp;

    @ApiModelProperty(value = "浏览器 UserAgent", required = true, example = "Mozilla/5.0")
    @NotEmpty(message = "浏览器 UserAgent 不能为空")
    private String userAgent;

}
