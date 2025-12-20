package com.shengyu.module.system.controller.admin.im.vo.moment;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;

/**
 * 发布朋友圈请求VO
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Data
@Schema(description = "发布朋友圈请求VO")
public class ImMomentCreateReqVO {

    @Schema(description = "内容", example = "这是一条朋友圈")
    private String content;

    @Schema(description = "图片", example = "image1.jpg,image2.jpg")
    private String image;

    @Schema(description = "视频", example = "video.mp4")
    private String video;

    @Schema(description = "朋友圈类型", required = true, example = "content")
    @NotBlank(message = "朋友圈类型不能为空")
    @Pattern(regexp = "^(content|image|video)$", message = "朋友圈类型只能是 content, image, video 中的一种")
    private String type;

    @Schema(description = "位置", example = "北京市朝阳区")
    private String location;

    @Schema(description = "提醒谁看", example = "1,2,3")
    private String remind;

    @Schema(description = "谁可以看", example = "all", defaultValue = "all")
    @Pattern(regexp = "^(all|only:[0-9,]+|except:[0-9,]+|none)$", message = "谁可以看的格式不正确")
    private String see = "all";
}