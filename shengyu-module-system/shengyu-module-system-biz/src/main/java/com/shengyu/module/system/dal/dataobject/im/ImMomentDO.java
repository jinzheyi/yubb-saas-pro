package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.common.enums.im.ImMomentSeeEnum;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 朋友圈消息 DO
 *
 * @author 朱述勇
 * @since 2022/12/3 21:40
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 */
@TableName("im_moment")
@KeySequence("im_moment_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
public class ImMomentDO extends TenantBaseDO {

    /**
     * 主键
     */
    @TableId
    private Long id;
    /**
     * 朋友圈内容
     */
    private String content;
    /**
     * 朋友圈图片
     */
    private String image;
    /**
     * 朋友圈视频
     */
    private String video;
    /**
     * 位置
     */
    private String location;
    /**
     * 提醒谁看
     */
    private String remind;
    /**
     * 谁可以看 all公开 none私密
     * {@link ImMomentSeeEnum}
     */
    private String see;
    /**
     * 用户id
     */
    private Long userId;

}
