package com.shengyu.module.system.service.flow;

import com.shengyu.module.system.dal.dataobject.flow.FlwProcessCategory;
import com.shengyu.module.system.framework.engine.core.IBaseService;

import java.util.List;

/**
 * 流程分类 服务类
 *
 * @author 青苗
 * @since 2023-09-07
 */
public interface FlwProcessCategoryService extends IBaseService<FlwProcessCategory> {

    List<FlwProcessCategory> listAll();

    boolean removeCategoryByIds(List<Long> ids);

    boolean sort(List<FlwProcessCategory> processCategorieList);

}
