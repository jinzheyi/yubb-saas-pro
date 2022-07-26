package cn.iocoder.yudao.module.platform.api.oauth2.dto;

import lombok.Data;

import java.io.Serializable;
import java.util.List;

/**
 * OAuth2.0 访问令牌的校验 Response DTO
 *
 * @author 芋道源码
 */
@Data
public class PlatformOAuth2AccessTokenCheckRespDTO implements Serializable {

    /**
     * 用户编号
     */
    private Long userId;
    /**
     * 用户类型
     */
    private Integer userType;
    /**
     * 授权范围的数组
     */
    private List<String> scopes;

}
