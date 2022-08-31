package cn.iocoder.yudao.module.system.dal.mysql.config;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.system.controller.admin.config.vo.ConfigPageReqVO;
import cn.iocoder.yudao.module.system.dal.dataobject.config.ConfigurationDO;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface ConfigurationMapper extends BaseMapperX<ConfigurationDO> {

    default ConfigurationDO selectByKey(String key) {
        return selectOne(ConfigurationDO::getConfigKey, key);
    }

    default PageResult<ConfigurationDO> selectPage(ConfigPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<ConfigurationDO>()
                .likeIfPresent(ConfigurationDO::getName, reqVO.getName())
                .likeIfPresent(ConfigurationDO::getConfigKey, reqVO.getKey())
                .eqIfPresent(ConfigurationDO::getType, reqVO.getType())
                .betweenIfPresent(ConfigurationDO::getCreateTime, reqVO.getCreateTime()));
    }

}
