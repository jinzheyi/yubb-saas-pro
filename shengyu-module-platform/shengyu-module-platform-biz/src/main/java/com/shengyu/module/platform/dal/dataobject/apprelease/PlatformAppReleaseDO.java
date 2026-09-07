package com.shengyu.module.platform.dal.dataobject.apprelease;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.mybatis.core.dataobject.BaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 平台应用版本发布记录
 *
 * @author 圣钰科技
 */
@TableName("platform_app_release")
@KeySequence("platform_app_release_seq")
@Data
@EqualsAndHashCode(callSuper = true)
public class PlatformAppReleaseDO extends BaseDO {

    private Long id;

    private String appKey;

    private String platform;

    private String channel;

    private String versionName;

    private Integer versionCode;

    private Integer minSupportedVersionCode;

    private String updateType;

    private Boolean forceUpdate;

    private String title;

    private String changelog;

    private String packageUrl;

    private Long packageSize;

    private String sha256;

    private String status;

    private String remark;

    private String patchProvider;

    private String patchReleaseId;

    private Integer patchNo;

}
