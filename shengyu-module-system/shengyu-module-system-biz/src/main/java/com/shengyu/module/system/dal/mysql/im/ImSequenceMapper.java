package com.shengyu.module.system.dal.mysql.im;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.im.ImSequenceDO;
import org.apache.ibatis.annotations.Mapper;

/**
 * IM 序列号 Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface ImSequenceMapper extends BaseMapperX<ImSequenceDO> {

    /**
     * 根据序列号类型查询
     *
     * @param sequenceType 序列号类型
     * @return 序列号DO
     */
    default ImSequenceDO selectBySequenceType(Integer sequenceType) {
        return selectOne(ImSequenceDO::getSequenceType, sequenceType);
    }

}
