package com.shengyu.module.im.dal.mapper;

import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.im.dal.dataobject.ImGroupDO;
import org.apache.ibatis.annotations.Mapper;

/**
 * IM群组Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface ImGroupMapper extends BaseMapperX<ImGroupDO> {

    /**
     * 增加群组成员数量
     *
     * @param groupId 群组ID
     * @param count   增加数量
     * @return 更新条数
     */
    default int increaseMemberCount(Long groupId, Integer count) {
        // 使用MyBatis-Plus的UpdateWrapper来实现动态SQL更新
        LambdaUpdateWrapper<ImGroupDO> updateWrapper = new LambdaUpdateWrapper<>();
        updateWrapper.eq(ImGroupDO::getId, groupId)
                .set(ImGroupDO::getMemberCount, count);
        return update(null, updateWrapper);
    }

    /**
     * 减少群组成员数量
     *
     * @param groupId 群组ID
     * @param count   减少数量
     * @return 更新条数
     */
    default int decreaseMemberCount(Long groupId, Integer count) {
        // 使用MyBatis-Plus的UpdateWrapper来实现动态SQL更新
        LambdaUpdateWrapper<ImGroupDO> updateWrapper = new LambdaUpdateWrapper<>();
        updateWrapper.eq(ImGroupDO::getId, groupId)
                .set(ImGroupDO::getMemberCount, count)
                .ge(ImGroupDO::getMemberCount, count); // 确保成员数量不小于要减少的数量
        return update(null, updateWrapper);
    }
}
