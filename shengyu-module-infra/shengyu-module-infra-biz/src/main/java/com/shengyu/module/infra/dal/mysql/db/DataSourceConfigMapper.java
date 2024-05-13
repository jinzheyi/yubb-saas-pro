package com.shengyu.module.infra.dal.mysql.db;

import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.infra.dal.dataobject.db.DataSourceConfigDO;
import org.apache.ibatis.annotations.Mapper;

/**
 * 数据源配置 Mapper
 *
 * @author 圣钰科技
 */
@Mapper
public interface DataSourceConfigMapper extends BaseMapperX<DataSourceConfigDO> {
}
