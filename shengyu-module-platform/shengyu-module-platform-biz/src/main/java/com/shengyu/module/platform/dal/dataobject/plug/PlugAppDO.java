package com.shengyu.module.platform.dal.dataobject.plug;

import com.shengyu.framework.common.enums.CommonConstants;
import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.mybatis.core.dataobject.BaseDO;
import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 插件应用 DO
 *
 * @author zhusy
 */
@TableName("platform_plug_app")
@KeySequence("platform_plug_app_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
public class PlugAppDO extends BaseDO {

    /**
     * id
     */
    @TableId
    private Long id;
    /**
     * 应用名称
     */
    private String name;
    /**
     * 概要描述
     */
    private String outline;
    /**
     * 条码
     */
    private String appSn;
    /**
     * 描述
     */
    private String description;
    /**
     * 状态（0上架 1下架）,影响的是租户不能下单购买
     *
     * 枚举 {@link CommonStatusEnum}
     */
    private Integer status;
    /**
     * 状态（0启用 1停用）平台端操作，停用后租户不能使用该插件
     *
     * 枚举 {@link CommonStatusEnum}
     */
    private Integer enable;
    /**
     * 应用主图地址
     */
    private String mainPic;

}
