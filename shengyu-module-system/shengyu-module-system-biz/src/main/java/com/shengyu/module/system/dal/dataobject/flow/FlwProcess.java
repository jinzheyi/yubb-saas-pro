package com.shengyu.module.system.dal.dataobject.flow;

import com.baomidou.mybatisplus.annotation.TableName;
import com.shengyu.module.system.framework.engine.FlowConstants;
import com.shengyu.module.system.framework.engine.ProcessModelCache;
import com.shengyu.module.system.framework.engine.assist.Assert;
import com.shengyu.module.system.framework.engine.core.Execution;
import com.shengyu.module.system.framework.engine.core.FlowCreator;
import com.shengyu.module.system.framework.engine.core.FlowLongContext;
import com.shengyu.module.system.framework.engine.core.TenantFlowBaseDO;
import com.shengyu.module.system.framework.engine.core.enums.FlowState;
import com.shengyu.module.system.framework.engine.model.ModelHelper;
import com.shengyu.module.system.framework.engine.model.NodeModel;
import com.shengyu.module.system.framework.engine.model.ProcessModel;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.Optional;
import java.util.function.Function;

/**
 * 流程定义表
 *
 * @author hubin
 * @since 2024-02-29
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("flw_process")
public class FlwProcess extends TenantFlowBaseDO implements ProcessModelCache {

	/**
	 * 流程定义 key 唯一标识
	 */
	private String processKey;

	/**
	 * 流程定义名称
	 */
	private String processName;

	/**
	 * 流程图标地址
	 */
	private String processIcon;

	/**
	 * 流程定义类型
	 */
	private String processType;

	/**
	 * 流程定义版本
	 */
	private Integer processVersion;

	/**
	 * 实例地址
	 */
	private String instanceUrl;

	/**
	 * 备注说明
	 */
	private String remark;

	/**
	 * 使用范围 0，全员 1，指定人员（业务关联） 2，均不可提交
	 */
	private Integer useScope;

	/**
	 * 流程状态 0，不可用 1，可用 2，历史版本
	 */
	protected Integer processState;

	/**
	 * 流程模型定义JSON内容
	 */
	private String modelContent;

	/**
	 * 排序
	 */
	private Integer sort;

	public void setFlowState(FlowState flowState) {
		this.processState = flowState.getValue();
	}

	@Override
	public String modelCacheKey() {
		return FlowConstants.processCacheKey + this.id;
	}

	public static FlwProcess of(FlowCreator flowCreator, ProcessModel processModel, int processVersion, String jsonString) {
		FlwProcess process = new FlwProcess();
		process.setProcessVersion(processVersion);
		process.setFlowState(FlowState.active);
		process.setProcessKey(processModel.getKey());
		process.setProcessName(processModel.getName());
		process.setInstanceUrl(processModel.getInstanceUrl());
		process.setUseScope(0);
		process.setSort(0);
		process.setFlowCreator(flowCreator);
		process.setCreateTime(LocalDateTime.now());
		return process.formatModelContent(jsonString);
	}

	/**
	 * 执行开始模型
	 *
	 * @param flowLongContext 流程引擎上下文
	 * @param flowCreator     流程实例任务创建者
	 * @param function        流程执行对象处理函数
	 * @return 流程实例
	 */
	public Optional<FlwInstance> executeStartModel(FlowLongContext flowLongContext, FlowCreator flowCreator, Function<NodeModel, Execution> function) {
		FlwInstance flwInstance = null;
		if (null != this.modelContent) {
			NodeModel nodeModel = this.model().getNodeConfig();
			Assert.isNull(nodeModel, "流程定义[processName=" + this.processName + ", processVersion=" + this.processVersion + "]没有开始节点");
			Assert.isFalse(flowLongContext.getTaskActorProvider().isAllowed(nodeModel, flowCreator), "No permission to execute");
			Assert.isTrue(ModelHelper.checkDuplicateNodeKeys(nodeModel), "There are duplicate node keys present");
			// 回调执行创建实例
			Execution execution = function.apply(nodeModel);
			// 重新渲染逻辑节点
			nodeModel = execution.getProcessModel().getNodeConfig();
			// 创建首个审批任务
			flowLongContext.createTask(execution, nodeModel);
			// 当前执行实例
			flwInstance = execution.getFlwInstance();
		}
		return Optional.ofNullable(flwInstance);
	}

	/**
	 * 流程状态验证
	 *
	 * @return 流程定义实体
	 */
	public FlwProcess checkState() {
		if (Objects.equals(0, this.processState)) {
			Assert.illegal("指定的流程定义[id=" + this.id + ",processVersion=" + this.processVersion + "]为非活动状态");
		}
		return this;
	}

	/**
	 * 格式化 JSON 模型内容
	 *
	 * @param modelContent JSON 模型内容
	 * @return 流程定义实体
	 */
	public FlwProcess formatModelContent(String modelContent) {
		return setModelContent2Json(FlowLongContext.fromJson(modelContent, ProcessModel.class));
	}

	/**
	 * 设置 JSON 模型内容
	 *
	 * @param processModel 模型内容
	 * @return 流程定义实体
	 */
	public FlwProcess setModelContent2Json(ProcessModel processModel) {
		this.modelContent = FlowLongContext.toJson(processModel);
		return this;
	}

	/**
	 * 下一个流程版本
	 *
	 * @return 下一个流程版本
	 */
	public int nextProcessVersion() {
		return processVersion + 1;
	}

}
