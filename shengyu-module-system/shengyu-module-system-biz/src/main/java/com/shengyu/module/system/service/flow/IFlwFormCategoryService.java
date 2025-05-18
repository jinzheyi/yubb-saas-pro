package com.shengyu.module.system.service.flow;

import com.aizuda.boot.modules.flw.entity.FlwFormCategory;
import com.aizuda.boot.modules.flw.entity.vo.FlwFormCategoryVO;
import com.aizuda.service.service.IBaseService;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;

import java.util.List;

/**
 * 流程表单分类 服务类
 *
 * @author hubin
 * @since 2024-05-19
 */
public interface IFlwFormCategoryService extends IBaseService<FlwFormCategory> {

    Page<FlwFormCategory> page(Page<FlwFormCategory> page, FlwFormCategory flwFormCategory);

    List<FlwFormCategoryVO> listTree(FlwFormCategory flwFormCategory);

    List<FlwFormCategory> listAll();

    boolean removeByIds(List<Long> ids);
}
