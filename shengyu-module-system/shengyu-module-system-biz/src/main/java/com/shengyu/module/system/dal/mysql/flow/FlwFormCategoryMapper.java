package com.shengyu.module.system.dal.mysql.flow;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.flow.FlwFormCategory;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * <p>
 * 流程表单分类 Mapper 接口
 * </p>
 *
 * @author hubin
 * @since 2024-05-19
 */
@Mapper
public interface FlwFormCategoryMapper extends BaseMapperX<FlwFormCategory> {

    List<Long> selectIdsRecursive(Long id);
}
