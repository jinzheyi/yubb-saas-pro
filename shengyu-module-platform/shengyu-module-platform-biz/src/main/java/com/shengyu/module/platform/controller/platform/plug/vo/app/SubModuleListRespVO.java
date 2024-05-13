package com.shengyu.module.platform.controller.platform.plug.vo.app;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 获得插件代码子模块
 *
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2023/5/12 22:34
 */
@Schema(description = "管理后台 -获得插件代码子模块 Response VO")
@Data
public class SubModuleListRespVO {

    @Schema(description = "功能appSn")
    private String code;

    @Schema(description = "名称")
    private String name;

}
