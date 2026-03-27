package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.im.ImUserStickerRecentDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface ImUserStickerRecentMapper extends BaseMapperX<ImUserStickerRecentDO> {

    default ImUserStickerRecentDO selectByUserIdAndStickerId(Long userId, Long stickerId) {
        return selectOne(new LambdaQueryWrapperX<ImUserStickerRecentDO>()
                .eq(ImUserStickerRecentDO::getUserId, userId)
                .eq(ImUserStickerRecentDO::getStickerId, stickerId)
                .orderByDesc(ImUserStickerRecentDO::getId)
                .last("LIMIT 1"));
    }

    default List<ImUserStickerRecentDO> selectRecentByUserId(Long userId, Integer limit) {
        return selectList(new LambdaQueryWrapperX<ImUserStickerRecentDO>()
                .eq(ImUserStickerRecentDO::getUserId, userId)
                .orderByDesc(ImUserStickerRecentDO::getLastUsedAt)
                .orderByDesc(ImUserStickerRecentDO::getUpdateTime)
                .last("LIMIT " + limit));
    }
}
