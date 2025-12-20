package com.shengyu.module.system.controller.admin.im.vo.moment;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 朋友圈评论响应VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "朋友圈评论响应VO")
public class ImMomentCommentRespVO {

    @Schema(description = "评论内容", example = "这条朋友圈很有意思")
    private String content;

    @Schema(description = "评论用户")
    private CommentUser user;

    @Schema(description = "回复用户")
    private CommentUser reply;

    /**
     * 评论用户VO
     */
    @Data
    public static class CommentUser {
        @Schema(description = "用户id", example = "1")
        private Long id;

        @Schema(description = "用户名称", example = "张三")
        private String name;
    }
}