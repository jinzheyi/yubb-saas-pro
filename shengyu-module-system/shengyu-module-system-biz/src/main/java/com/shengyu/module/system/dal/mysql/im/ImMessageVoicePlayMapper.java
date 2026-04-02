package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.im.ImMessageVoicePlayDO;
import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.time.LocalDateTime;
import java.util.List;

@Mapper
public interface ImMessageVoicePlayMapper extends BaseMapperX<ImMessageVoicePlayDO> {

    @Insert("INSERT IGNORE INTO im_message_voice_play(tenant_id, chat_id, message_id, user_id, played_time, creator, create_time, updater, update_time, deleted) " +
            "VALUES(#{tenantId}, #{chatId}, #{messageId}, #{userId}, NOW(), '', NOW(), '', NOW(), 0)")
    int insertIgnore(@Param("tenantId") Long tenantId,
                     @Param("chatId") Long chatId,
                     @Param("messageId") Long messageId,
                     @Param("userId") Long userId);

    @Select({"<script>",
            "SELECT message_id FROM im_message_voice_play",
            "WHERE tenant_id = #{tenantId} AND user_id = #{userId} AND deleted = 0",
            "<if test='chatId != null'> AND chat_id = #{chatId} </if>",
            "AND message_id IN",
            "<foreach collection='messageIds' item='id' open='(' separator=',' close=')'>",
            "#{id}",
            "</foreach>",
            "</script>"})
    List<Long> selectPlayedMessageIds(@Param("tenantId") Long tenantId,
                                      @Param("userId") Long userId,
                                      @Param("chatId") Long chatId,
                                      @Param("messageIds") List<Long> messageIds);

    @Delete("DELETE FROM im_message_voice_play " +
            "WHERE deleted = 0 AND played_time < #{expireBefore} " +
            "ORDER BY played_time ASC " +
            "LIMIT #{limit}")
    int deleteExpiredByPlayedTime(@Param("expireBefore") LocalDateTime expireBefore,
                                  @Param("limit") int limit);

}
