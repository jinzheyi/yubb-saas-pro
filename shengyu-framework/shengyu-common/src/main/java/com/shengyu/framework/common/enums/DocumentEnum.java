package com.shengyu.framework.common.enums;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 文档地址
 *
 * @author 圣钰科技
 */
@Getter
@AllArgsConstructor
public enum DocumentEnum {

    REDIS_INSTALL("https://gitee.com/jinzheyi/yubb-saas-pro", "圣钰 SaaS 下载地址"),
    TENANT("http://www.shengyukj.top", "圣钰 SaaS 多租户官网");

    private final String url;
    private final String memo;

}
