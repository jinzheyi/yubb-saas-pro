package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 朋友圈评论 DO
 *
 * @author 朱述勇
 * @since 2022/12/5 22:18
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 */
@TableName("im_moment_comment")
@KeySequence("im_moment_comment_seq") // 用于 Oracle、PostgreSQL、Kingbase、DB2、H2 数据库的主键自增。如果是 MySQL 等数据库，可不写。
@Data
@EqualsAndHashCode(callSuper = true)
public class ImMomentCommentDO extends TenantBaseDO {

    /**
     * 主键
     */
    @TableId
    private Long id;
    /**
     * 评论用户id
     */
    private Long userId;
    /**
     * 朋友圈消息id
     */
    private Long momentId;
    /**
     * 评论内容
     */
    private String content;
    /**
     * 回复用户id
     */
    private Long replyId;

}
