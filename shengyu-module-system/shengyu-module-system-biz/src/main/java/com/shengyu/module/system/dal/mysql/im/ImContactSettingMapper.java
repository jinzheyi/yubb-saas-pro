package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.im.ImContactSettingDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * IM 联系人设置 Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface ImContactSettingMapper extends BaseMapperX<ImContactSettingDO> {

    /**
     * 根据用户ID查询联系人设置列表
     *
     * @param userId 用户ID
     * @return 联系人设置列表
     */
    default List<ImContactSettingDO> selectListByUserId(Long userId) {
        return selectList(ImContactSettingDO::getUserId, userId);
    }

    /**
     * 根据用户ID和联系人ID查询设置
     *
     * @param userId 用户ID
     * @param contactId 联系人ID
     * @return 联系人设置
     */
    default ImContactSettingDO selectByUserIdAndContactId(Long userId, Long contactId) {
        return selectOne(new LambdaQueryWrapperX<ImContactSettingDO>()
                .eq(ImContactSettingDO::getUserId, userId)
                .eq(ImContactSettingDO::getContactId, contactId));
    }

    /**
     * 根据用户ID查询星标联系人列表
     *
     * @param userId 用户ID
     * @return 星标联系人设置列表
     */
    default List<ImContactSettingDO> selectListByUserIdAndStar(Long userId) {
        return selectList(new LambdaQueryWrapperX<ImContactSettingDO>()
                .eq(ImContactSettingDO::getUserId, userId)
                .eq(ImContactSettingDO::getStar, true));
    }

}
