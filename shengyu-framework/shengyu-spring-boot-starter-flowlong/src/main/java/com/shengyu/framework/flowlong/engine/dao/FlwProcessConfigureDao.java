package com.shengyu.framework.flowlong.engine.dao;

import com.jxscxkj.cxkjflow.common.bpm.engine.entity.FlwProcessConfigure;

/**
 * <p>
 * 流程定义配置接口
 * </p>
 *
 * @author 朱述勇
 * @since 2023-09-07
 */
public interface FlwProcessConfigureDao {

  FlwProcessConfigure selectByProcessId(Long processId);

}
