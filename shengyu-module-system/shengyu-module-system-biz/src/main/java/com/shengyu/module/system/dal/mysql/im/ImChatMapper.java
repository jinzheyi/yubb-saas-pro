package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.im.ImChatDO;
import com.baomidou.dynamic.datasource.annotation.DS;
import com.shengyu.framework.datasource.core.enums.DataSourceEnum;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
@DS(DataSourceEnum.MASTER)
public interface ImChatMapper extends BaseMapperX<ImChatDO> {

    default ImChatDO selectSingleChat(Long user1, Long user2, Integer chatType) {
        return selectOne(new LambdaQueryWrapperX<ImChatDO>()
                .eq(ImChatDO::getChatType, chatType)
                .eq(ImChatDO::getSingleUser1, user1)
                .eq(ImChatDO::getSingleUser2, user2)
                .eq(ImChatDO::getDeleted, false));
    }

    default ImChatDO selectGroupChat(Long groupId, Integer chatType) {
        return selectOne(new LambdaQueryWrapperX<ImChatDO>()
                .eq(ImChatDO::getChatType, chatType)
                .eq(ImChatDO::getGroupId, groupId)
                .eq(ImChatDO::getDeleted, false));
    }

    @Insert("INSERT INTO im_chat (id, chat_type, group_id, status, tenant_id, deleted, last_sequence) " +
            "VALUES (#{chatId}, #{chatType}, #{groupId}, #{status}, #{tenantId}, 0, 0) " +
            "ON DUPLICATE KEY UPDATE id = id")
    int insertGroupChatIfAbsent(@Param("tenantId") Long tenantId,
                                @Param("chatId") Long chatId,
                                @Param("chatType") Integer chatType,
                                @Param("groupId") Long groupId,
                                @Param("status") Integer status);

    @Insert("INSERT INTO im_chat (id, chat_type, single_user1, single_user2, status, tenant_id, deleted, last_sequence) " +
            "VALUES (#{chatId}, #{chatType}, #{user1}, #{user2}, #{status}, #{tenantId}, 0, 0) " +
            "ON DUPLICATE KEY UPDATE id = id")
    int insertSingleChatIfAbsent(@Param("tenantId") Long tenantId,
                                 @Param("chatId") Long chatId,
                                 @Param("chatType") Integer chatType,
                                 @Param("user1") Long user1,
                                 @Param("user2") Long user2,
                                 @Param("status") Integer status);

    @Update("UPDATE im_chat SET last_sequence = LAST_INSERT_ID(last_sequence + 1) WHERE id = #{chatId}")
    int bumpLastSequence(@Param("chatId") Long chatId);

    @Select("SELECT LAST_INSERT_ID()")
    Long selectLastInsertId();

    @Select("SELECT DISTINCT CASE " +
            "WHEN single_user1 = #{userId} THEN single_user2 " +
            "WHEN single_user2 = #{userId} THEN single_user1 " +
            "END AS peerUserId " +
            "FROM im_chat " +
            "WHERE deleted = 0 AND chat_type = ${@com.shengyu.module.system.enums.im.ImConversationTypeEnum@SINGLE.getType()} AND (single_user1 = #{userId} OR single_user2 = #{userId})")
    List<Long> selectSingleChatPeerUserIds(@Param("userId") Long userId);

    default Long nextSequence(Long chatId) {
        bumpLastSequence(chatId);
        return selectLastInsertId();
    }
}
