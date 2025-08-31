package com.shengyu.framework.flowlong.engine.dao.impl;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.shengyu.framework.flowlong.engine.dao.FlwProcessConfigureDao;
import com.shengyu.framework.flowlong.engine.entity.FlwProcessConfigure;
import com.shengyu.framework.flowlong.engine.mapper.FlwProcessConfigureMapper;

/**
 * <p>
 * 流程定义配置接口实现
 * </p>
 *
 * @author 朱述勇
 * @since 2023-09-07
 */
public class FlwProcessConfigureDaoImpl implements FlwProcessConfigureDao {

  private FlwProcessConfigureMapper processConfigureMapper;

  public FlwProcessConfigureDaoImpl(FlwProcessConfigureMapper processConfigureMapper) {
    this.processConfigureMapper = processConfigureMapper;
  }

  @Override
  public FlwProcessConfigure selectByProcessId(Long processId) {
    return processConfigureMapper.selectOne(Wrappers.<FlwProcessConfigure>lambdaQuery()
      .eq(FlwProcessConfigure::getProcessId, processId), false);
  }

}
