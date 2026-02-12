package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.im.ImGroupDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * IM 群组 Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface ImGroupMapper extends BaseMapperX<ImGroupDO> {

    /**
     * 根据群主ID查询群组列表
     *
     * @param ownerId 群主ID
     * @return 群组列表
     */
    default List<ImGroupDO> selectListByOwnerId(Long ownerId) {
        return selectList(ImGroupDO::getOwnerId, ownerId);
    }

    /**
     * 根据群组状态查询群组列表
     *
     * @param status 群组状态
     * @return 群组列表
     */
    default List<ImGroupDO> selectListByStatus(Integer status) {
        return selectList(ImGroupDO::getStatus, status);
    }

    /**
     * 根据群名模糊查询
     *
     * @param name 群名
     * @return 群组列表
     */
    default List<ImGroupDO> selectListByNameLike(String name) {
        return selectList(new LambdaQueryWrapperX<ImGroupDO>()
                .likeIfPresent(ImGroupDO::getName, name));
    }

}
