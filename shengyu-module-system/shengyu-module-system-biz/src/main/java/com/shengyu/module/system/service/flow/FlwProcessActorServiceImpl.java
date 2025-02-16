package com.shengyu.module.system.service.flow;

import com.aizuda.boot.modules.flw.entity.FlwProcessActor;
import com.aizuda.boot.modules.flw.mapper.FlwProcessActorMapper;
import com.aizuda.boot.modules.flw.service.IFlwProcessActorService;
import com.aizuda.service.service.BaseServiceImpl;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 流程定义参与者 服务实现类
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Service
public class FlwProcessActorServiceImpl extends BaseServiceImpl<FlwProcessActorMapper, FlwProcessActor> implements IFlwProcessActorService {

    @Override
    public boolean saveProcessActors(Long processId, List<FlwProcessActor> flwProcessActors) {
        // 先删除流程定义ID历史数据
        this.removeByProcessId(processId);
        // 保存流程定义参与者列表
        return super.saveBatch(flwProcessActors);
    }

    @Override
    public void removeByProcessId(Long processId) {
        super.remove(this.getWrappers(processId));
    }

    private LambdaQueryWrapper<FlwProcessActor> getWrappers(Long processId) {
        return Wrappers.<FlwProcessActor>lambdaQuery().eq(FlwProcessActor::getProcessId, processId);
    }

    @Override
    public List<FlwProcessActor> getByProcessId(Long processId) {
        return super.list(this.getWrappers(processId));
    }
}
