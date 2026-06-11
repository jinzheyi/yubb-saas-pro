package com.shengyu.module.system.controller.app.im.vo.favorite;

import com.shengyu.framework.common.pojo.PageParam;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Schema(description = "移动端 - IM 收藏消息分页 Request VO")
@Data
@EqualsAndHashCode(callSuper = true)
public class AppImFavoritePageReqVO extends PageParam {

    @Schema(description = "类型筛选：default(全部)/normal(文字)/media(图片视频)/file(文件)", example = "default")
    private String tab;
}
