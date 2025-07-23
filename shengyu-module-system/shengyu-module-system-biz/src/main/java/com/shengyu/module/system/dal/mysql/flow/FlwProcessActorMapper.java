package com.shengyu.module.system.dal.mysql.flow;

import cn.hutool.core.collection.CollUtil;
import com.github.yulichang.wrapper.MPJLambdaWrapper;
import com.shengyu.framework.flowlong.engine.entity.FlwProcess;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessActor;
import java.util.Collections;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;

/**
 * <p>
 * 流程定义参与者 Mapper 接口
 * </p>
 *
 * @author 青苗
 * @since 2023-09-07
 */
@Mapper
public interface FlwProcessActorMapper extends BaseMapperX<FlwProcessActor> {

  /**
   * 不存在角色权限的流程ID列表
   */
  default List<Long> selectNotExistProcessIds(List<Long> processIdList) {
    return selectJoinList(Long.class, new MPJLambdaWrapper<FlwProcessActor>()
      .distinct()
      .select(FlwProcessActor::getProcessId)
      .innerJoin(FlwProcess.class, FlwProcess::getId, FlwProcessActor::getProcessId, fp -> fp.eq(FlwProcess::getProcessState, 1))
      .notIn(CollUtil.isNotEmpty(processIdList), FlwProcessActor::getProcessId, processIdList)
    );
  }

  /**
   * 根据角色权限ID列表查询流程定义参与者列表
   */
  default List<FlwProcessActor> selectListByActorIdList(List<Long> actorIdList) {
    if (CollUtil.isEmpty(actorIdList)) {
      return Collections.emptyList();
    }
    return selectList(new MPJLambdaWrapper<FlwProcessActor>()
      .in(FlwProcessActor::getActorId, actorIdList)
    );
  }

}
