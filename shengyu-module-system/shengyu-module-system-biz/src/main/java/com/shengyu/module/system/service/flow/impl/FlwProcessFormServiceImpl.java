package com.shengyu.module.system.service.flow.impl;

import com.shengyu.framework.mybatis.core.service.BaseServiceImpl;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessForm;
import com.shengyu.module.system.dal.mysql.flow.FlwProcessFormMapper;
import com.shengyu.module.system.service.flow.IFlwProcessFormService;
import org.springframework.stereotype.Service;

/**
 * 流程定义表单 服务实现类
 *
 * @author hubin
 * @since 2024-02-29
 */
@Service
public class FlwProcessFormServiceImpl extends BaseServiceImpl<FlwProcessFormMapper, FlwProcessForm> implements IFlwProcessFormService {

    @Override
    public boolean saveForm(Long instanceId, String content) {
        FlwProcessForm fpf = this.getByInstanceId(instanceId);
        if (null == fpf) {
            // 保存表单内容
            fpf = new FlwProcessForm();
            fpf.setInstanceId(instanceId);
            fpf.setContent(content);
            return super.save(fpf);
        }

        // 更新表单内容
        fpf.setContent(content);
        return super.updateById(fpf);
    }

    @Override
    public FlwProcessForm getByInstanceId(Long instanceId) {
        return lambdaQuery().eq(FlwProcessForm::getInstanceId, instanceId).one();
    }
}
