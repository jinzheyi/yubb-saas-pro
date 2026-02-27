package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.im.ImNotificationDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * IM 通知 Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface ImNotificationMapper extends BaseMapperX<ImNotificationDO> {

    /**
     * 根据用户ID查询通知列表(按创建时间倒序)
     *
     * @param userId 用户ID
     * @return 通知列表
     */
    default List<ImNotificationDO> selectListByUserId(Long userId) {
        return selectList(new LambdaQueryWrapperX<ImNotificationDO>()
                .eq(ImNotificationDO::getUserId, userId)
                .orderByDesc(ImNotificationDO::getCreateTime));
    }

    /**
     * 根据用户ID和已读状态查询通知列表
     *
     * @param userId 用户ID
     * @param isRead 是否已读
     * @return 通知列表
     */
    default List<ImNotificationDO> selectListByUserIdAndReadStatus(Long userId, Boolean isRead) {
        return selectList(new LambdaQueryWrapperX<ImNotificationDO>()
                .eq(ImNotificationDO::getUserId, userId)
                .eq(ImNotificationDO::getIsRead, isRead)
                .orderByDesc(ImNotificationDO::getCreateTime));
    }

    /**
     * 根据用户ID和通知类型查询通知列表
     *
     * @param userId 用户ID
     * @param notifyType 通知类型
     * @return 通知列表
     */
    default List<ImNotificationDO> selectListByUserIdAndType(Long userId, Integer notifyType) {
        return selectList(new LambdaQueryWrapperX<ImNotificationDO>()
                .eq(ImNotificationDO::getUserId, userId)
                .eq(ImNotificationDO::getNotifyType, notifyType)
                .orderByDesc(ImNotificationDO::getCreateTime));
    }

}
