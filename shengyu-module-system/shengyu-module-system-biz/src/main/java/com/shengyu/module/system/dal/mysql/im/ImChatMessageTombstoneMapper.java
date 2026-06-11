package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.im.ImChatMessageTombstoneDO;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Set;

@Mapper
public interface ImChatMessageTombstoneMapper extends BaseMapperX<ImChatMessageTombstoneDO> {

    @Insert("INSERT IGNORE INTO im_chat_message_tombstone(tenant_id, chat_id, user_id, message_id, deleted_at, creator, create_time, updater, update_time, deleted) " +
            "VALUES(#{tenantId}, #{chatId}, #{userId}, #{messageId}, NOW(), '', NOW(), '', NOW(), 0)")
    int insertIgnore(@Param("tenantId") Long tenantId,
                     @Param("chatId") Long chatId,
                     @Param("userId") Long userId,
                     @Param("messageId") Long messageId);

    @Select({"<script>",
            "SELECT message_id FROM im_chat_message_tombstone",
            "WHERE tenant_id = #{tenantId} AND user_id = #{userId} AND chat_id = #{chatId} AND deleted = 0",
            "AND message_id IN",
            "<foreach collection='messageIds' item='id' open='(' separator=',' close=')'>",
            "#{id}",
            "</foreach>",
            "</script>"})
    List<Long> selectDeletedMessageIds(@Param("tenantId") Long tenantId,
                                      @Param("userId") Long userId,
                                      @Param("chatId") Long chatId,
                                      @Param("messageIds") List<Long> messageIds);

    /**
     * 检查消息是否已被用户删除（对我删除）
     */
    @Select("SELECT COUNT(*) > 0 FROM im_chat_message_tombstone " +
            "WHERE tenant_id = #{tenantId} AND user_id = #{userId} AND message_id = #{messageId} AND deleted = 0")
    boolean existsByUserIdAndMessageId(@Param("tenantId") Long tenantId,
                                       @Param("userId") Long userId,
                                       @Param("messageId") Long messageId);

    /**
     * 检查消息是否已被用户删除（对我删除）- 自动获取租户ID
     */
    default boolean existsByUserIdAndMessageId(Long userId, Long messageId) {
        Long tenantId = com.shengyu.framework.tenant.core.context.TenantContextHolder.getTenantId();
        return existsByUserIdAndMessageId(tenantId != null ? tenantId : 0L, userId, messageId);
    }

    /**
     * 批量查询用户在某会话中已删除的消息ID（用于搜索时过滤墓碑消息）
     */
    @Select("SELECT message_id FROM im_chat_message_tombstone " +
            "WHERE tenant_id = #{tenantId} AND user_id = #{userId} AND chat_id = #{chatId} AND deleted = 0")
    Set<Long> selectMessageIdsByUserAndChat(@Param("tenantId") Long tenantId,
                                            @Param("userId") Long userId,
                                            @Param("chatId") Long chatId);

}
