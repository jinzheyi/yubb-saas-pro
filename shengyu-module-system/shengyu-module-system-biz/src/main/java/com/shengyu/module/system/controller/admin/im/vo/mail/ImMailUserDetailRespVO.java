package com.shengyu.module.system.controller.admin.im.vo.mail;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

/**
 * @author zhusy
 * @since 2022/11/23
 */
@Schema(description = "用户资料详情 Response VO")
@Data
public class ImMailUserDetailRespVO {

    @Schema(description = "用户ID")
    private Long id;

    @Schema(description = "用户名")
    private String username;

    @Schema(description = "用户昵称")
    private String nickname;

    @Schema(description = "用户头像")
    private String avatar;

    @Schema(description = "性别")
    private Integer sex;

    @Schema(description = "个性签名")
    private String sign;

    @Schema(description = "地区")
    private String area;

    @Schema(description = "是否为好友")
    private Boolean friend;

    @Schema(description = "是否可以查看我的信息")
    private Integer lookme;

    @Schema(description = "是否可以查看他的信息")
    private Integer lookhim;

    @Schema(description = "是否星标好友")
    private Integer star;

    @Schema(description = "是否拉黑")
    private Integer isblack;

    @Schema(description = "好友标签列表")
    private List<String> tags;

    @Schema(description = "用户动态列表")
    private List<Moment> moments;

    // --- 内部类 ---

    @Data
    @Schema(description = "用户动态")
    public static class Moment {
        @Schema(description = "动态ID")
        private Long id;
        
        @Schema(description = "动态内容")
        private String content;
        
        @Schema(description = "创建时间")
        private String createTime;
        
        // 可根据实际需求添加更多动态字段
    }

}
