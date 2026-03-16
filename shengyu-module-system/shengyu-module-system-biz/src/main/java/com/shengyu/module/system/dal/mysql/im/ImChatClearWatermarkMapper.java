package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.im.ImChatClearWatermarkDO;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface ImChatClearWatermarkMapper extends BaseMapperX<ImChatClearWatermarkDO> {

    @Select("SELECT clear_sequence FROM im_chat_clear_watermark WHERE tenant_id = #{tenantId} AND user_id = #{userId} AND chat_id = #{chatId} AND deleted = 0")
    Long selectClearSequence(@Param("tenantId") Long tenantId, @Param("userId") Long userId, @Param("chatId") Long chatId);

    @Insert("INSERT INTO im_chat_clear_watermark(tenant_id, chat_id, user_id, clear_sequence, cleared_at, creator, create_time, updater, update_time, deleted) " +
            "VALUES(#{tenantId}, #{chatId}, #{userId}, #{clearSequence}, NOW(), '', NOW(), '', NOW(), 0) " +
            "ON DUPLICATE KEY UPDATE clear_sequence = GREATEST(IFNULL(clear_sequence,0), VALUES(clear_sequence)), cleared_at = NOW(), deleted = 0")
    int upsertMax(@Param("tenantId") Long tenantId,
                 @Param("chatId") Long chatId,
                 @Param("userId") Long userId,
                 @Param("clearSequence") Long clearSequence);

}
