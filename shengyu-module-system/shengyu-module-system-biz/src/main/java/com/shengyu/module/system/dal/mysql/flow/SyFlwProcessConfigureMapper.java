package com.shengyu.module.system.dal.mysql.flow;

import com.shengyu.framework.flowlong.engine.mapper.FlwProcessConfigureMapper;
import org.apache.ibatis.annotations.Mapper;
import org.springframework.context.annotation.Primary;

/**
 * <p>
 * 流程定义配置 Mapper 接口
 * </p>
 *
 * @author 朱述勇
 * @since 2023-09-07
 */
@Primary
@Mapper
public interface SyFlwProcessConfigureMapper extends FlwProcessConfigureMapper {

}
