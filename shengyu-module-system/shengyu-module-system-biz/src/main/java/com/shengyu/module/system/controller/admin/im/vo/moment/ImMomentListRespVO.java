package com.shengyu.module.system.controller.admin.im.vo.moment;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

/**
 * 用户朋友圈列表响应VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "用户朋友圈列表响应VO")
public class ImMomentListRespVO {

    @Schema(description = "用户id", example = "1")
    private Long userId;

    @Schema(description = "用户名称", example = "张三")
    private String userName;

    @Schema(description = "用户头像", example = "avatar.jpg")
    private String avatar;

    @Schema(description = "朋友圈id", example = "1")
    private Long momentId;

    @Schema(description = "朋友圈内容", example = "这是一条朋友圈")
    private String content;

    @Schema(description = "图片列表", example = "[\"image1.jpg\",\"image2.jpg\"]")
    private List<String> image;

    @Schema(description = "视频", example = "{\"url\":\"video.mp4\"}")
    private VideoInfo video;

    @Schema(description = "位置", example = "北京市朝阳区")
    private String location;

    @Schema(description = "是否是自己的朋友圈", example = "1")
    private Integer own;

    @Schema(description = "创建时间", example = "1734691200000")
    private Long createdAt;

    @Schema(description = "评论列表")
    private List<ImMomentCommentRespVO> comments;

    @Schema(description = "点赞列表")
    private List<ImMomentLikeRespVO> likes;

    /**
     * 视频信息VO
     */
    @Data
    public static class VideoInfo {
        @Schema(description = "视频URL", example = "video.mp4")
        private String url;
    }
}