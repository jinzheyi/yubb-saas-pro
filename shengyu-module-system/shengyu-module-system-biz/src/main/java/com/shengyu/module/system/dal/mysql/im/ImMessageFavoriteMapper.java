package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.im.ImMessageFavoriteDO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface ImMessageFavoriteMapper extends BaseMapperX<ImMessageFavoriteDO> {

    default ImMessageFavoriteDO selectByIdAndUserId(Long tenantId, Long userId, Long favoriteId) {
        return selectOne(new LambdaQueryWrapperX<ImMessageFavoriteDO>()
                .eq(ImMessageFavoriteDO::getTenantId, tenantId)
                .eq(ImMessageFavoriteDO::getUserId, userId)
                .eq(ImMessageFavoriteDO::getId, favoriteId)
                .last("LIMIT 1"));
    }

    @Select("SELECT COUNT(1) FROM im_message_favorite WHERE tenant_id = #{tenantId} AND user_id = #{userId} AND deleted = 0")
    Long countByUserId(@Param("tenantId") Long tenantId, @Param("userId") Long userId);

    @Select("<script>" +
            "SELECT * FROM im_message_favorite " +
            "WHERE tenant_id = #{tenantId} AND user_id = #{userId} AND deleted = 0 " +
            "ORDER BY create_time DESC, id DESC " +
            "LIMIT #{limit} OFFSET #{offset}" +
            "</script>")
    List<ImMessageFavoriteDO> selectPageByUserId(@Param("tenantId") Long tenantId,
                                                 @Param("userId") Long userId,
                                                 @Param("offset") Integer offset,
                                                 @Param("limit") Integer limit);
}
