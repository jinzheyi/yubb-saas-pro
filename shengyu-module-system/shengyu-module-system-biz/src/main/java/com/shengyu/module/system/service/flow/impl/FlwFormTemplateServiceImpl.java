package com.shengyu.module.system.service.flow.impl;

import com.shengyu.module.system.dal.dataobject.flow.FlwFormTemplate;
import com.aizuda.boot.modules.flw.mapper.FlwFormTemplateMapper;
import com.aizuda.boot.modules.flw.service.IFlwFormTemplateService;
import com.aizuda.common.toolkit.JacksonUtils;
import com.aizuda.core.api.ApiAssert;
import com.aizuda.service.service.BaseServiceImpl;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * 流程表单模板 服务实现类
 *
 * @author hubin
 * @since 2024-05-19
 */
@Service
public class FlwFormTemplateServiceImpl extends BaseServiceImpl<FlwFormTemplateMapper, FlwFormTemplate> implements IFlwFormTemplateService {

    @Override
    public Page<FlwFormTemplate> page(Page<FlwFormTemplate> page, FlwFormTemplate flwFormTemplate) {
        LambdaQueryWrapper<FlwFormTemplate> lqw = Wrappers.lambdaQuery(flwFormTemplate);
        lqw.orderByDesc(FlwFormTemplate::getCreateTime);
        return super.page(page, lqw);
    }

    @Override
    public Page<FlwFormTemplate> pageSimple(Page<FlwFormTemplate> page, FlwFormTemplate flwFormTemplate) {
        if (null == flwFormTemplate) {
            flwFormTemplate = new FlwFormTemplate();
        }
        flwFormTemplate.setStatus(1);
        LambdaQueryWrapper<FlwFormTemplate> lqw = Wrappers.lambdaQuery(flwFormTemplate);
        lqw.select(FlwFormTemplate::getId, FlwFormTemplate::getName, FlwFormTemplate::getCode);
        lqw.orderByDesc(FlwFormTemplate::getCreateTime);
        return super.page(page, lqw);
    }

    @Override
    public boolean updateById(FlwFormTemplate flwFormTemplate) {
        ApiAssert.fail(null == flwFormTemplate.getId(), "主键不存在无法更新");
        return super.updateById(flwFormTemplate);
    }

    @Override
    public boolean removeNotBindByIds(List<Long> ids) {
        return super.remove(Wrappers.<FlwFormTemplate>lambdaQuery().in(FlwFormTemplate::getId, ids)
                .ne(FlwFormTemplate::getStatus, 3));
    }

    @Override
    public boolean existByFormCategoryIds(List<Long> formCategoryIds) {
        return lambdaQuery().in(FlwFormTemplate::getFormCategoryId, formCategoryIds).count() > 0;
    }

    @Override
    public FlwFormTemplate getByConfigure(String configureProcessForm) {
        Long id = null;
        if (null != configureProcessForm) {
            // 加载表单模板内容
            Map<String, Object> formMap = JacksonUtils.readMap(configureProcessForm);
            if (null != formMap) {
                String formId = (String) formMap.get("formId");
                if (null != formId) {
                    id = Long.valueOf(formId);
                }
            }
        }
        ApiAssert.fail(null == id, "业务表单配置内容有误");
        FlwFormTemplate flwFormTemplate = this.checkById(id);
        if (null != flwFormTemplate && !Objects.equals(3, flwFormTemplate.getStatus())) {
            // 加载设置为绑定状态，该状态不允许删除，只能修改编辑
            FlwFormTemplate temp = new FlwFormTemplate();
            temp.setStatus(3);
            temp.setId(flwFormTemplate.getId());
            super.updateById(temp);
        }
        return flwFormTemplate;
    }

    @Override
    public boolean updateStatusById(Long id, Integer status) {
        FlwFormTemplate flwFormTemplate = new FlwFormTemplate();
        flwFormTemplate.setId(id);
        flwFormTemplate.setStatus(Objects.equals(status, 1) ? 1 : 0);
        return super.updateById(flwFormTemplate);
    }
}
