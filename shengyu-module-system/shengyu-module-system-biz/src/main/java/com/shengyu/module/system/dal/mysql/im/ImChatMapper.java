package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.dal.dataobject.im.ImChatDO;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface ImChatMapper extends BaseMapperX<ImChatDO> {

    default ImChatDO selectSingleChat(Long user1, Long user2, Integer chatType) {
        return selectOne(new LambdaQueryWrapperX<ImChatDO>()
                .eq(ImChatDO::getChatType, chatType)
                .eq(ImChatDO::getSingleUser1, user1)
                .eq(ImChatDO::getSingleUser2, user2));
    }

    default ImChatDO selectGroupChat(Long groupId, Integer chatType) {
        return selectOne(new LambdaQueryWrapperX<ImChatDO>()
                .eq(ImChatDO::getChatType, chatType)
                .eq(ImChatDO::getGroupId, groupId));
    }

}
