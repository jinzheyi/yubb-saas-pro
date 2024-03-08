package cn.iocoder.yudao.module.system.dal.mysql.plug;

import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.tenant.PlugTenantPageReqVO;
import cn.iocoder.yudao.module.system.dal.dataobject.plug.PlugTenantDO;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import java.util.List;
import java.util.stream.Collectors;
import org.apache.ibatis.annotations.Mapper;

/**
 * 租户应用 Mapper
 *
 * @author zhusy
 */
@Mapper
public interface PlugTenantMapper extends BaseMapperX<PlugTenantDO> {

    default PageResult<PlugTenantDO> selectPage(PlugTenantPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlugTenantDO>()
                .eqIfPresent(PlugTenantDO::getStatus, reqVO.getStatus())
                .eqIfPresent(PlugTenantDO::getEnable, reqVO.getEnable())
                .betweenIfPresent(PlugTenantDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(PlugTenantDO::getId));
    }

    /**
     * 查询当前租户自己已上架且平台正常启用的拥有的插件
     * @return 当前租户自己已上架且平台正常启用的拥有的插件
     */
    default List<PlugTenantDO> selectListStatusAndEnable() {
        return selectList(new LambdaQueryWrapper<PlugTenantDO>()
            .eq(PlugTenantDO::getStatus, CommonStatusEnum.ENABLE.getStatus())
            .eq(PlugTenantDO::getEnable, CommonStatusEnum.ENABLE.getStatus()));
    }

    /**
     * 查询当前租户自己拥有的插件
     * @return 当前租户自己拥有的插件
     */
    default List<PlugTenantDO> selectListAll() {
        return selectList();
    }

}
