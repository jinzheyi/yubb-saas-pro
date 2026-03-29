package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.im.ImUserStickerDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface ImUserStickerMapper extends BaseMapperX<ImUserStickerDO> {

    default ImUserStickerDO selectByUserIdAndMd5(Long userId, String md5) {
        return selectOne(new LambdaQueryWrapperX<ImUserStickerDO>()
                .eq(ImUserStickerDO::getUserId, userId)
                .eq(ImUserStickerDO::getMd5, md5)
                .eq(ImUserStickerDO::getStatus, 1)
                .orderByDesc(ImUserStickerDO::getId)
                .last("LIMIT 1"));
    }

    default ImUserStickerDO selectUndeletedByUserIdAndMd5(Long userId, String md5) {
        return selectOne(new LambdaQueryWrapperX<ImUserStickerDO>()
                .eq(ImUserStickerDO::getUserId, userId)
                .eq(ImUserStickerDO::getMd5, md5)
                .orderByDesc(ImUserStickerDO::getId)
                .last("LIMIT 1"));
    }

    default List<ImUserStickerDO> selectActiveByUserId(Long userId) {
        return selectList(new LambdaQueryWrapperX<ImUserStickerDO>()
                .eq(ImUserStickerDO::getUserId, userId)
                .eq(ImUserStickerDO::getStatus, 1)
                .orderByAsc(ImUserStickerDO::getSortNo)
                .orderByDesc(ImUserStickerDO::getUpdateTime)
                .orderByDesc(ImUserStickerDO::getId));
    }

    default ImUserStickerDO selectActiveByIdAndUserId(Long id, Long userId) {
        return selectOne(new LambdaQueryWrapperX<ImUserStickerDO>()
                .eq(ImUserStickerDO::getId, id)
                .eq(ImUserStickerDO::getUserId, userId)
                .eq(ImUserStickerDO::getStatus, 1));
    }
}
