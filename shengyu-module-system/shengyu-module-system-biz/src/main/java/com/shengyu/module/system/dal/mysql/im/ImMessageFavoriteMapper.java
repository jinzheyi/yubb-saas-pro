package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.im.ImMessageFavoriteDO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

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

    @Select("<script>" +
            "SELECT * FROM im_message_favorite " +
            "WHERE tenant_id = #{tenantId} AND user_id = #{userId} AND deleted = 0 " +
            "<if test='tab != null and tab != \"\" and tab == \"normal\"'> " +
            "AND message_type NOT IN (2,4,5) " +
            "</if> " +
            "<if test='tab != null and tab != \"\" and tab == \"media\"'> " +
            "AND message_type IN (2,4) " +
            "</if> " +
            "<if test='tab != null and tab != \"\" and tab == \"file\"'> " +
            "AND message_type = 5 " +
            "</if> " +
            "<if test='keyword != null and keyword != \"\"'> " +
            "AND (message_preview LIKE CONCAT('%', #{keyword}, '%') " +
            "OR message_content LIKE CONCAT('%', #{keyword}, '%') " +
            "OR message_extra LIKE CONCAT('%', #{keyword}, '%')) " +
            "</if> " +
            "ORDER BY create_time DESC, id DESC " +
            "LIMIT #{limit} OFFSET #{offset}" +
            "</script>")
    List<ImMessageFavoriteDO> selectSearchPageByUserId(@Param("tenantId") Long tenantId,
                                                       @Param("userId") Long userId,
                                                       @Param("keyword") String keyword,
                                                       @Param("tab") String tab,
                                                       @Param("offset") Integer offset,
                                                       @Param("limit") Integer limit);

    @Select("<script>" +
            "SELECT message_type AS messageType, COUNT(1) AS cnt " +
            "FROM im_message_favorite " +
            "WHERE tenant_id = #{tenantId} AND user_id = #{userId} AND deleted = 0 " +
            "<if test='keyword != null and keyword != \"\"'> " +
            "AND (message_preview LIKE CONCAT('%', #{keyword}, '%') " +
            "OR message_content LIKE CONCAT('%', #{keyword}, '%') " +
            "OR message_extra LIKE CONCAT('%', #{keyword}, '%')) " +
            "</if> " +
            "GROUP BY message_type" +
            "</script>")
    List<Map<String, Object>> selectSearchTypeCountsByUser(@Param("tenantId") Long tenantId,
                                                           @Param("userId") Long userId,
                                                           @Param("keyword") String keyword);
}
