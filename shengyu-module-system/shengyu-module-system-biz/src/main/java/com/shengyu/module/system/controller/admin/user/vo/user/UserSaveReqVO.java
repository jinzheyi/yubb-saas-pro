package com.shengyu.module.system.controller.admin.user.vo.user;

import com.shengyu.framework.common.util.validation.ValidGroup;
import com.shengyu.framework.common.validation.Mobile;
import io.swagger.v3.oas.annotations.media.Schema;

import java.util.Collections;
import java.util.List;
import java.util.Set;
import javax.validation.constraints.Email;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;
import lombok.Data;

@Schema(description = "管理后台 - 用户创建/修改 Request VO")
@Data
public class UserSaveReqVO {

    @Schema(description = "邮箱账号,saas用户表的邮箱账号，用于通知SaaS用户邀请", example = "jin_zheyicn@qq.com")
    @Email(message = "邮箱账号格式不正确")
    @Size(max = 50, message = "邮箱账号长度不能超过 50 个字符")
    private String username;

    @Schema(description = "用户昵称", requiredMode = Schema.RequiredMode.REQUIRED, example = "圣钰")
    @Size(max = 30, message = "用户昵称长度不能超过30个字符")
    private String nickname;

    @Schema(description = "备注", example = "我是一个用户")
    private String remark;

    @Schema(description = "部门ID", example = "我是一个用户")
    private Set<Long> deptIdList = Collections.emptySet();

    @Schema(description = "岗位编号数组", example = "1")
    private Set<Long> postIds;

    @Schema(description = "手机号码", example = "15601691300")
    @Mobile(message = "手机号码格式不正确")
    private String mobile;

    @Schema(description = "用户头像", example = "https://www.iocoder.cn/xxx.png")
    private String avatar;

}
