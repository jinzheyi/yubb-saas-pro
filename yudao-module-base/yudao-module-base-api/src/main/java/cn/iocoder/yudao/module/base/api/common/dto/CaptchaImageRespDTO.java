package cn.iocoder.yudao.module.base.api.common.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 验证码图片 Response DTO
 *
 * @author 朱述勇
 * @since 2022/7/6 23:04
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CaptchaImageRespDTO {

    /**
     * 是否开启，如果为 false，则关闭验证码功能
     */
    private Boolean enable;

    /**
     * enable = true 时，非空！通过该 uuid 作为该验证码的标识
     */
    private String uuid;

    /**
     *  图片，enable = true 时，非空！验证码的图片内容，使用 Base64 编码
     */
    private String img;

}
