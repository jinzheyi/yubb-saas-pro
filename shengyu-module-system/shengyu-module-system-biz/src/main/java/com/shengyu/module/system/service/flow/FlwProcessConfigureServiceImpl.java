package com.shengyu.module.system.service.flow;

import com.shengyu.module.system.dal.dataobject.flow.FlwProcessConfigure;
import com.shengyu.module.system.controller.admin.flow.dto.FlwCategorySortDTO;
import com.shengyu.module.system.controller.admin.flow.dto.FlwProcessDTO;
import com.shengyu.module.system.dal.mysql.flow.FlwProcessConfigureMapper;
import com.shengyu.module.system.service.flow.IFlwProcessConfigureService;
import com.aizuda.service.service.BaseServiceImpl;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import org.apache.commons.collections.CollectionUtils;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Objects;

/**
 * 流程定义配置 服务实现类
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Service
public class FlwProcessConfigureServiceImpl extends BaseServiceImpl<FlwProcessConfigureMapper, FlwProcessConfigure> implements IFlwProcessConfigureService {

    @Override
    public boolean saveByDto(Long processId, FlwProcessDTO dto) {
        // 保存最新配置
        FlwProcessConfigure fpc = new FlwProcessConfigure();
        fpc.setProcessId(processId);
        fpc.setCategoryId(dto.getCategoryId());
        fpc.setProcessSetting(dto.getProcessSetting());
        if (Objects.equals(dto.getProcessType(), "business")) {
            fpc.setProcessForm(dto.getBusinessForm());
        } else {
            fpc.setProcessForm(dto.getProcessForm());
        }
        return super.save(fpc);
    }

    @Override
    public boolean removeByProcessId(Long processId) {
        return super.remove(this.getWrappers(processId));
    }

    private LambdaQueryWrapper<FlwProcessConfigure> getWrappers(Long processId) {
        return Wrappers.<FlwProcessConfigure>lambdaQuery().eq(FlwProcessConfigure::getProcessId, processId);
    }

    @Override
    public FlwProcessConfigure getByProcessId(Long processId) {
        return super.getOne(this.getWrappers(processId));
    }

    @Override
    public boolean existByCategoryIds(List<Long> categoryIdList) {
        return super.count(Wrappers.<FlwProcessConfigure>lambdaQuery()
                .in(FlwProcessConfigure::getCategoryId, categoryIdList)) > 0;
    }

    @Override
    public void updateRelation(List<FlwCategorySortDTO> dtoList) {
        dtoList.forEach(t -> {
            if (CollectionUtils.isNotEmpty(t.getProcessIds())) {
                lambdaUpdate().set(FlwProcessConfigure::getCategoryId, t.getCategoryId())
                        .in(FlwProcessConfigure::getProcessId, t.getProcessIds()).update();
            }
        });
    }
}
