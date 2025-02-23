package com.shengyu.module.system.service.flow;

import com.aizuda.boot.modules.flw.entity.FlwProcessConfigure;
import com.aizuda.boot.modules.flw.entity.dto.FlwCategorySortDTO;
import com.aizuda.boot.modules.flw.entity.dto.FlwProcessDTO;
import com.aizuda.service.service.IBaseService;

import java.util.List;

/**
 * 流程定义配置 服务类
 *
 * @author 青苗
 * @since 2023-09-07
 */
public interface IFlwProcessConfigureService extends IBaseService<FlwProcessConfigure> {

    /**
     * 根据流程定义DTO对象保存配置
     *
     * @param processId 流程定义ID
     * @param dto       流程定义DTO
     */
    boolean saveByDto(Long processId, FlwProcessDTO dto);

    /**
     * 根据流程定义ID删除流程定义配置
     *
     * @param processId 流程定义ID
     */
    boolean removeByProcessId(Long processId);

    /**
     * 查询是否存在指定分类ID流程定义信息
     *
     * @param categoryIdList 流程分类ID列表
     */
    boolean existByCategoryIds(List<Long> categoryIdList);

    /**
     * 根据流程定义ID流程定义配置
     *
     * @param processId 流程定义ID
     */
    FlwProcessConfigure getByProcessId(Long processId);

    /**
     * 根据流程ID更新流程分类关联关系
     *
     * @param dtoList 流程分类排序DTO列表
     */
    void updateRelation(List<FlwCategorySortDTO> dtoList);
}
