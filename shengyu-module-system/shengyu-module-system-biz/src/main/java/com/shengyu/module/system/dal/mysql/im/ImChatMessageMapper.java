package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.im.ImChatMessageDO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Update;

import java.util.List;

@Mapper
public interface ImChatMessageMapper extends BaseMapperX<ImChatMessageDO> {

    default PageResult<ImChatMessageDO> selectPageByChatId(Long chatId, com.shengyu.framework.common.pojo.PageParam pageParam) {
        return selectPage(pageParam, new LambdaQueryWrapperX<ImChatMessageDO>()
                .eq(ImChatMessageDO::getChatId, chatId)
                .orderByDesc(ImChatMessageDO::getId));
    }

    @Update({"<script>",
            "UPDATE im_chat_message",
            "SET status = #{status}",
            "WHERE id IN",
            "<foreach collection='ids' item='id' open='(' separator=',' close=')'>",
            "#{id}",
            "</foreach>",
            "</script>"})
    int updateStatusByIds(@Param("ids") List<Long> ids, @Param("status") Integer status);

    default List<ImChatMessageDO> selectListByChatIdAndSequenceGt(Long chatId, Long lastSequence, Integer limit) {
        return selectList(new LambdaQueryWrapperX<ImChatMessageDO>()
                .eq(ImChatMessageDO::getChatId, chatId)
                .gt(ImChatMessageDO::getSequence, lastSequence)
                .orderByAsc(ImChatMessageDO::getSequence)
                .last("LIMIT " + limit));
    }

}
