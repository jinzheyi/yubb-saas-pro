package com.shengyu.module.system.service.im;

import com.shengyu.module.system.dal.dataobject.im.ImSequenceDO;
import com.shengyu.module.system.dal.mysql.im.ImSequenceMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.List;

/**
 * IM 序列号 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class ImSequenceServiceImpl implements ImSequenceService {

    private static final Integer MESSAGE_SEQUENCE_TYPE = 1;
    private static final Integer DEFAULT_STEP = 100;

    @Resource
    private ImSequenceMapper sequenceMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long generateMessageSequence() {
        // 获取或创建序列号记录
        ImSequenceDO sequence = sequenceMapper.selectBySequenceType(MESSAGE_SEQUENCE_TYPE);
        if (sequence == null) {
            // 首次创建
            sequence = new ImSequenceDO();
            sequence.setSequenceType(MESSAGE_SEQUENCE_TYPE);
            sequence.setCurrentValue(1L);
            sequence.setStep(DEFAULT_STEP);
            sequenceMapper.insert(sequence);
            return 1L;
        }

        // 更新序列号
        Long nextValue = sequence.getCurrentValue() + 1;
        sequence.setCurrentValue(nextValue);
        sequenceMapper.updateById(sequence);

        return nextValue;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public List<Long> generateMessageSequences(int count) {
        List<Long> sequences = new ArrayList<>(count);
        
        // 获取或创建序列号记录
        ImSequenceDO sequence = sequenceMapper.selectBySequenceType(MESSAGE_SEQUENCE_TYPE);
        if (sequence == null) {
            // 首次创建
            sequence = new ImSequenceDO();
            sequence.setSequenceType(MESSAGE_SEQUENCE_TYPE);
            sequence.setCurrentValue((long) count);
            sequence.setStep(DEFAULT_STEP);
            sequenceMapper.insert(sequence);
            
            for (long i = 1; i <= count; i++) {
                sequences.add(i);
            }
            return sequences;
        }

        // 批量生成序列号
        Long startValue = sequence.getCurrentValue() + 1;
        Long endValue = startValue + count - 1;
        
        for (long i = startValue; i <= endValue; i++) {
            sequences.add(i);
        }

        // 更新序列号
        sequence.setCurrentValue(endValue);
        sequenceMapper.updateById(sequence);

        return sequences;
    }

}
