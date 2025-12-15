package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.common.enums.im.ImReportStatusEnum;
import com.shengyu.framework.common.enums.im.ImReportedTypeEnum;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 朋友圈举报 DO
 *
 * @author 朱述勇
 * @since 2025/12/14 19:13
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 */
@TableName("im_report")
@Data
@EqualsAndHashCode(callSuper = true)
public class ImReportDO extends TenantBaseDO {

    /**
     * 主键
     */
    @TableId
    private Long id;
    /**
     * 用户id
     */
    private Long userId;
    /**
     * 朋友圈id
     */
    private Long momentId;
    /**
     * 被举报用户id
     */
    private Long reportedId;
    /**
     * 举报类型
     * {@link ImReportedTypeEnum}
     */
    private Integer reportedType;
    /**
     * 举报内容
     */
    private String content;
    /**
     * 举报分类
     */
    private String category;
    /**
     * 举报状态
     * {@link ImReportStatusEnum}
     */
    private String status;

}
