package com.shengyu.module.system.dal.mysql.flow;

import com.aizuda.boot.modules.flw.entity.FlwFormCategory;
import com.aizuda.service.mapper.CrudMapper;

import java.util.List;

/**
 * <p>
 * 流程表单分类 Mapper 接口
 * </p>
 *
 * @author hubin
 * @since 2024-05-19
 */
public interface FlwFormCategoryMapper extends CrudMapper<FlwFormCategory> {

    List<Long> selectIdsRecursive(Long id);
}
