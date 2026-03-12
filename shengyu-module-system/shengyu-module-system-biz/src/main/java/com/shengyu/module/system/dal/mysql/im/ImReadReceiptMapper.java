package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.module.system.controller.app.im.vo.readreceipt.AppImReadReceiptDetailRespVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface ImReadReceiptMapper {

    @Select("SELECT COUNT(1) FROM im_group_member gm " +
            "LEFT JOIN im_conversation_user_state s " +
            "  ON s.tenant_id = gm.tenant_id AND s.user_id = gm.user_id AND s.chat_id = #{chatId} " +
            "  AND s.deleted = 0 AND s.deleted_by_user = 0 " +
            "WHERE gm.tenant_id = #{tenantId} AND gm.group_id = #{groupId} AND gm.deleted = 0 " +
            "  AND IFNULL(s.last_read_sequence, 0) >= #{sequence}")
    Long countReadMembers(@Param("tenantId") Long tenantId,
                         @Param("groupId") Long groupId,
                         @Param("chatId") Long chatId,
                         @Param("sequence") Long sequence);

    @Select("SELECT COUNT(1) FROM im_group_member gm " +
            "LEFT JOIN im_conversation_user_state s " +
            "  ON s.tenant_id = gm.tenant_id AND s.user_id = gm.user_id AND s.chat_id = #{chatId} " +
            "  AND s.deleted = 0 AND s.deleted_by_user = 0 " +
            "WHERE gm.tenant_id = #{tenantId} AND gm.group_id = #{groupId} AND gm.deleted = 0 " +
            "  AND IFNULL(s.last_read_sequence, 0) < #{sequence}")
    Long countUnreadMembers(@Param("tenantId") Long tenantId,
                           @Param("groupId") Long groupId,
                           @Param("chatId") Long chatId,
                           @Param("sequence") Long sequence);

    @Select("<script>" +
            "SELECT gm.user_id AS userId, u.nickname AS userNickname, u.avatar AS userAvatar, s.last_read_time AS readTime " +
            "FROM im_group_member gm " +
            "LEFT JOIN im_conversation_user_state s " +
            "  ON s.tenant_id = gm.tenant_id AND s.user_id = gm.user_id AND s.chat_id = #{chatId} " +
            "  AND s.deleted = 0 AND s.deleted_by_user = 0 " +
            "LEFT JOIN system_users u ON u.id = gm.user_id AND u.deleted = 0 AND u.tenant_id = gm.tenant_id " +
            "WHERE gm.tenant_id = #{tenantId} AND gm.group_id = #{groupId} AND gm.deleted = 0 " +
            "<choose>" +
            "  <when test='status == \"read\"'> AND IFNULL(s.last_read_sequence, 0) &gt;= #{sequence} </when>" +
            "  <otherwise> AND IFNULL(s.last_read_sequence, 0) &lt; #{sequence} </otherwise>" +
            "</choose>" +
            "<choose>" +
            "  <when test='status == \"read\"'> ORDER BY s.last_read_time DESC </when>" +
            "  <otherwise> ORDER BY gm.join_time DESC </otherwise>" +
            "</choose>" +
            "LIMIT #{limit} OFFSET #{offset}" +
            "</script>")
    List<AppImReadReceiptDetailRespVO> selectDetailPage(@Param("tenantId") Long tenantId,
                                                       @Param("groupId") Long groupId,
                                                       @Param("chatId") Long chatId,
                                                       @Param("sequence") Long sequence,
                                                       @Param("status") String status,
                                                       @Param("offset") Integer offset,
                                                       @Param("limit") Integer limit);

}
