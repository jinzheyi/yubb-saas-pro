package com.shengyu.module.system.service.flow;

import com.shengyu.module.system.dal.dataobject.flow.FlwFormTemplate;
import com.shengyu.module.system.framework.engine.core.IBaseService;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;

import java.util.List;

/**
 * 流程表单模板 服务类
 *
 * @author hubin
 * @since 2024-05-19
 */
public interface IFlwFormTemplateService extends IBaseService<FlwFormTemplate> {

    Page<FlwFormTemplate> page(Page<FlwFormTemplate> page, FlwFormTemplate flwFormTemplate);

    Page<FlwFormTemplate> pageSimple(Page<FlwFormTemplate> page, FlwFormTemplate flwFormTemplate);

    boolean existByFormCategoryIds(List<Long> formCategoryIds);

    /**
     * 删除非绑定表单模板
     */
    boolean removeNotBindByIds(List<Long> ids);

    /**
     * 根据流程表单配置查询
     *
     * @param configureProcessForm 流程表单配置
     */
    FlwFormTemplate getByConfigure(String configureProcessForm);

    /**
     * 修改流程表单状态
     */
    boolean updateStatusById(Long id, Integer status);
}
