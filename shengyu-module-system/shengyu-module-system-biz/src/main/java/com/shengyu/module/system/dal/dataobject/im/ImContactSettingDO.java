package com.shengyu.module.system.dal.dataobject.im;

import com.baomidou.mybatisplus.annotation.KeySequence;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.framework.tenant.core.db.TenantBaseDO;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

/**
 * IM 联系人设置 DO
 * 
 * 对应表: im_contact_setting
 * 功能: 存储用户对联系人的个性化设置(备注名、星标、免打扰)
 * 说明: 企业内部IM,联系人直接来源于租户的用户表(system_users),本表仅存储个性化设置
 *
 * @author 圣钰科技
 */
@TableName(value = "im_contact_setting", autoResultMap = true)
@KeySequence("im_contact_setting_seq")
@Data
@EqualsAndHashCode(callSuper = true)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImContactSettingDO extends TenantBaseDO {

    /**
     * 主键ID
     */
    @TableId
    private Long id;

    /**
     * 用户ID
     */
    private Long userId;

    /**
     * 联系人ID(对应 system_users.id)
     */
    private Long contactId;

    /**
     * 备注名
     */
    private String nickname;

    /**
     * 是否星标联系人
     */
    private Boolean star;

    /**
     * 是否免打扰
     */
    private Boolean noDisturb;

}
