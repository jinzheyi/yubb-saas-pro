package com.shengyu.module.system.service.im;

/**
 * IM 序列号 Service 接口
 *
 * @author 圣钰科技
 */
public interface ImSequenceService {

    /**
     * 生成消息序列号
     *
     * @return 序列号
     */
    Long generateMessageSequence();

    /**
     * 批量生成消息序列号
     *
     * @param count 数量
     * @return 序列号列表
     */
    java.util.List<Long> generateMessageSequences(int count);

}
