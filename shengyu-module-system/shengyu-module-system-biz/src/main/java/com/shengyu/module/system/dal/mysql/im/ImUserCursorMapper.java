package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.im.ImUserCursorDO;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.util.List;

@Mapper
public interface ImUserCursorMapper extends BaseMapperX<ImUserCursorDO> {

    @Insert("INSERT IGNORE INTO im_user_cursor(tenant_id, user_id, next_cursor_version, deleted) VALUES(#{tenantId}, #{userId}, 0, 0)")
    int insertIgnore(@Param("tenantId") Long tenantId, @Param("userId") Long userId);

    @Select("SELECT id, tenant_id, user_id, next_cursor_version FROM im_user_cursor " +
            "WHERE tenant_id = #{tenantId} AND user_id = #{userId} AND deleted = 0 FOR UPDATE")
    ImUserCursorDO selectForUpdate(@Param("tenantId") Long tenantId, @Param("userId") Long userId);

    @Update("UPDATE im_user_cursor SET next_cursor_version = #{nextCursorVersion} " +
            "WHERE tenant_id = #{tenantId} AND user_id = #{userId} AND deleted = 0")
    int updateNext(@Param("tenantId") Long tenantId,
                   @Param("userId") Long userId,
                   @Param("nextCursorVersion") Long nextCursorVersion);

    @Insert({"<script>",
            "INSERT IGNORE INTO im_user_cursor(tenant_id, user_id, next_cursor_version, deleted) VALUES ",
            "<foreach collection='userIds' item='uid' separator=','>",
            "(#{tenantId}, #{uid}, 0, 0)",
            "</foreach>",
            "</script>"})
    int insertIgnoreBatch(@Param("tenantId") Long tenantId, @Param("userIds") List<Long> userIds);

    @Update({"<script>",
            "UPDATE im_user_cursor ",
            "SET next_cursor_version = next_cursor_version + 1 ",
            "WHERE tenant_id = #{tenantId} AND deleted = 0 ",
            "AND user_id IN ",
            "<foreach collection='userIds' item='uid' open='(' separator=',' close=')'>",
            "#{uid}",
            "</foreach>",
            "</script>"})
    int incrementNextBatch(@Param("tenantId") Long tenantId, @Param("userIds") List<Long> userIds);

    @Select({"<script>",
            "SELECT id, tenant_id, user_id, next_cursor_version FROM im_user_cursor ",
            "WHERE tenant_id = #{tenantId} AND deleted = 0 ",
            "AND user_id IN ",
            "<foreach collection='userIds' item='uid' open='(' separator=',' close=')'>",
            "#{uid}",
            "</foreach>",
            "</script>"})
    List<ImUserCursorDO> selectListByUserIds(@Param("tenantId") Long tenantId, @Param("userIds") List<Long> userIds);
}
