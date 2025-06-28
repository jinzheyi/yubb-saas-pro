package com.shengyu.module.system.service.flow.impl;

import com.shengyu.framework.common.exception.util.ServiceExceptionUtil;
import com.shengyu.framework.mybatis.core.service.BaseServiceImpl;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessCategory;
import com.shengyu.module.system.dal.mysql.flow.FlwProcessCategoryMapper;
import com.shengyu.module.system.enums.ErrorCodeConstants;
import com.shengyu.module.system.service.flow.IFlwProcessCategoryService;
import com.shengyu.module.system.service.flow.IFlwProcessConfigureService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;

/**
 * 流程分类 服务实现类
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Service
public class FlwProcessCategoryServiceImpl extends BaseServiceImpl<FlwProcessCategoryMapper, FlwProcessCategory> implements IFlwProcessCategoryService {
    @Resource
    private IFlwProcessConfigureService flwProcessConfigureService;

    @Override
    public List<FlwProcessCategory> listAll() {
        return lambdaQuery().orderByDesc(FlwProcessCategory::getSort).list();
    }

    @Override
    public boolean save(FlwProcessCategory flwProcessCategory) {
        ServiceExceptionUtil.fail(super.lambdaQuery().eq(FlwProcessCategory::getName,
                flwProcessCategory.getName()).count() > 0, ErrorCodeConstants.FLOW_1_002_029_049);
        if (null == flwProcessCategory.getSort()) {
            // 设置默认排序
            flwProcessCategory.setSort(0);
        }
        return super.save(flwProcessCategory);
    }

    @Override
    public boolean updateById(FlwProcessCategory flwProcessCategory) {
        ServiceExceptionUtil.fail(null == flwProcessCategory.getId(), ErrorCodeConstants.FLOW_1_002_029_050);
        return super.updateById(flwProcessCategory);
    }

    @Override
    public boolean removeCategoryByIds(List<Long> ids) {
        ServiceExceptionUtil.fail(flwProcessConfigureService.existByCategoryIds(ids), ErrorCodeConstants.FLOW_1_002_029_051);
        return super.removeByIds(ids);
    }

    @Override
    public boolean sort(List<FlwProcessCategory> processCategorieList) {
        return super.updateBatchById(processCategorieList.stream().map(t -> {
            FlwProcessCategory fpc = new FlwProcessCategory();
            fpc.setId(t.getId());
            fpc.setSort(t.getSort());
            return fpc;
        }).toList());
    }
}
