package com.shengyu.module.system.service.flow.impl;

import com.shengyu.module.system.dal.dataobject.flow.FlwProcessCategory;
import com.aizuda.boot.modules.flw.mapper.FlwProcessCategoryMapper;
import com.aizuda.boot.modules.flw.service.IFlwProcessCategoryService;
import com.aizuda.boot.modules.flw.service.IFlwProcessConfigureService;
import com.aizuda.core.api.ApiAssert;
import com.aizuda.service.service.BaseServiceImpl;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 流程分类 服务实现类
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Service
@AllArgsConstructor
public class FlwProcessCategoryServiceImpl extends BaseServiceImpl<FlwProcessCategoryMapper, FlwProcessCategory> implements IFlwProcessCategoryService {
    private IFlwProcessConfigureService flwProcessConfigureService;

    @Override
    public List<FlwProcessCategory> listAll() {
        return lambdaQuery().orderByDesc(FlwProcessCategory::getSort).list();
    }

    @Override
    public boolean save(FlwProcessCategory flwProcessCategory) {
        ApiAssert.fail(super.lambdaQuery().eq(FlwProcessCategory::getName,
                flwProcessCategory.getName()).count() > 0, "分类名称已存在，请更换其它名称");
        if (null == flwProcessCategory.getSort()) {
            // 设置默认排序
            flwProcessCategory.setSort(0);
        }
        return super.save(flwProcessCategory);
    }

    @Override
    public boolean updateById(FlwProcessCategory flwProcessCategory) {
        ApiAssert.fail(null == flwProcessCategory.getId(), "主键不存在无法更新");
        return super.updateById(flwProcessCategory);
    }

    @Override
    public boolean removeCategoryByIds(List<Long> ids) {
        ApiAssert.fail(flwProcessConfigureService.existByCategoryIds(ids), "存在流程定义关联不允许删除");
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
