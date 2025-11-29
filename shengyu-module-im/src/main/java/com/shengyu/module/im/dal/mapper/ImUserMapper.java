package com.shengyu.module.im.dal.mapper;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.im.dal.dataobject.ImUserDO;
import org.apache.ibatis.annotations.Mapper;

/**
 * IM用户Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface ImUserMapper extends BaseMapperX<ImUserDO> {

    /**
     * 根据系统用户ID获取IM用户信息
     *
     * @param userId 系统用户ID
     * @return IM用户信息
     */
    default ImUserDO getByUserId(Long userId) {
        return selectOne(new LambdaQueryWrapperX<ImUserDO>()
                .eq(ImUserDO::getUserId, userId));
    }

    /**
     * 更新用户在线状态
     *
     * @param userId       系统用户ID
     * @param onlineStatus 在线状态
     * @return 更新条数
     */
    default int updateOnlineStatus(Long userId, Integer onlineStatus) {
        // 使用MyBatis-Plus的UpdateWrapper来实现动态SQL更新
        com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper<ImUserDO> updateWrapper = new com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper<>();
        updateWrapper.eq(ImUserDO::getUserId, userId)
                .set(ImUserDO::getOnlineStatus, onlineStatus);
        return update(null, updateWrapper);
    }
}
