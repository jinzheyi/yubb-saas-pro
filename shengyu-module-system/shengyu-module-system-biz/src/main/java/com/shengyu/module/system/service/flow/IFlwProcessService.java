package com.shengyu.module.system.service.flow;

import com.shengyu.framework.flowlong.engine.core.FlowCreator;
import com.shengyu.framework.flowlong.engine.entity.FlwProcess;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.shengyu.framework.mybatis.core.service.IBaseService;
import com.shengyu.module.system.controller.admin.flow.dto.DestroyInstanceDTO;
import com.shengyu.module.system.controller.admin.flow.dto.FlwCategorySortDTO;
import com.shengyu.module.system.controller.admin.flow.dto.FlwProcessDTO;
import com.shengyu.module.system.controller.admin.flow.dto.FlwProcessHistoryDTO;
import com.shengyu.module.system.controller.admin.flow.dto.FlwProcessInstanceDTO;
import com.shengyu.module.system.controller.admin.flow.dto.ProcessStartDTO;
import com.shengyu.module.system.controller.admin.flow.vo.FlwInstanceVO;
import com.shengyu.module.system.controller.admin.flow.vo.FlwProcessCategoryVO;

import java.util.List;
import java.util.Map;

/**
 * 流程分类 服务类
 *
 * @author 青苗
 * @since 2023-09-07
 */
public interface IFlwProcessService extends IBaseService<FlwProcess> {

    /**
     * 流程定义历史分页列表
     */
    Page<FlwProcess> pageHistory(Page<FlwProcess> page, FlwProcessHistoryDTO dto);

    /**
     * 流程实例分页列表
     */
    Page<FlwInstanceVO> pageInstance(Page<FlwInstanceVO> page, FlwProcessInstanceDTO dto);

    /**
     * 流程定义分类查询所有流程定义列表
     *
     * @param keyword 搜索关键词
     */
    List<FlwProcessCategoryVO> listCategoryAll(String keyword);

    /**
     * 获取发起分类流程定义列表
     *
     * @param keyword 搜索关键词
     */
    List<FlwProcessCategoryVO> listLaunch(String keyword);

    /**
     * 查询满足条件前10条子流程列表
     *
     * @param keyword 搜索关键词
     */
    List<FlwProcess> listChildTop10(String keyword);

    /**
     * 发起流程
     *
     * @param dto         流程发起 DTO
     * @param flowCreator 流程创建者
     * @return 流程实例ID
     */
    Long launchProcess(ProcessStartDTO dto, FlowCreator flowCreator);

    /**
     * 根据实例ID获取流程变量
     *
     * @param instanceId 流程实例ID
     * @return 流程变量 MAP
     */
    Map<String, Object> getVariableByInstanceId(Long instanceId);

    /**
     * 根据实例ID删除暂存待审流程
     *
     * @param instanceId 流程实例ID
     * @return true 成功 false 失败
     */
    boolean removeProcessByInstanceId(Long instanceId);

    /**
     * 根据流程实例ID唤醒撤销拒审终止流程实例
     *
     * @param instanceId 流程实例ID
     * @return true 成功 false 失败
     */
    boolean resumeProcessByInstanceId(Long instanceId);

    /**
     * 作废流程实例
     */
    boolean destroyProcessByInstanceId(DestroyInstanceDTO dto);

    /**
     * 根据 id 获取模型
     *
     * @param id 流程定义ID
     */
    String getNodeModelById(Long id);

    /**
     * 根据 id 查询流程定义相关信息
     *
     * @param id 流程定义ID
     */
    FlwProcessDTO getDtoById(Long id);

    /**
     * 根据 key 查询流程定义相关信息
     *
     * @param key 流程定义KEY
     */
    FlwProcessDTO getDtoByKey(String key);

    /**
     * 创建添加流程定义配置
     *
     * @param dto 流程定义配置 DTO
     * @return 流程定义ID
     */
    Long saveDto(FlwProcessDTO dto);

    /**
     * 根据ID删除流程定义相关信息
     *
     * @param id 流程定义ID
     */
    boolean removeProcessInfo(Long id);

    /**
     * 根据ID更新流程定义排序
     *
     * @param dtoList 流程分类排序DTO列表
     */
    boolean sort(List<FlwCategorySortDTO> dtoList);

    /**
     * 根据ID更新流程定义流程状态
     *
     * @param id    流程定义ID
     * @param state 流程状态 0，不可用 1，可用
     */
    boolean updateSateById(Long id, Integer state);

    /**
     * 根据ID克隆流程定义信息
     *
     * @param id 流程定义ID
     */
    boolean cloneById(Long id);

    /**
     * 根据指定ID签出历史流程
     * <p>
     * 当前版本和历史版本交换
     * </p>
     *
     * @param id 流程定义ID
     */
    boolean checkoutById(Long id);
}
