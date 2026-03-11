package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.im.ImUserCursorDO;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

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
}
