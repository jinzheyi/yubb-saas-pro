package cn.iocoder.yudao.module.platform.dal.mysql.sensitiveword;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.center.sensitiveword.vo.SensitiveWordExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.sensitiveword.vo.SensitiveWordPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.sensitiveword.PlatformSensitiveWordDO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.Date;
import java.util.List;

/**
 * 敏感词 Mapper
 *
 * @author 永不言败
 */
@Mapper
public interface PlatformSensitiveWordMapper extends BaseMapperX<PlatformSensitiveWordDO> {

    default PageResult<PlatformSensitiveWordDO> selectPage(SensitiveWordPageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlatformSensitiveWordDO>()
                .likeIfPresent(PlatformSensitiveWordDO::getName, reqVO.getName())
                .likeIfPresent(PlatformSensitiveWordDO::getTags, reqVO.getTag())
                .eqIfPresent(PlatformSensitiveWordDO::getStatus, reqVO.getStatus())
                .betweenIfPresent(PlatformSensitiveWordDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(PlatformSensitiveWordDO::getId));
    }

    default List<PlatformSensitiveWordDO> selectList(SensitiveWordExportReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<PlatformSensitiveWordDO>()
                .likeIfPresent(PlatformSensitiveWordDO::getName, reqVO.getName())
                .likeIfPresent(PlatformSensitiveWordDO::getTags, reqVO.getTag())
                .eqIfPresent(PlatformSensitiveWordDO::getStatus, reqVO.getStatus())
                .betweenIfPresent(PlatformSensitiveWordDO::getCreateTime, reqVO.getCreateTime())
                .orderByDesc(PlatformSensitiveWordDO::getId));
    }

    default PlatformSensitiveWordDO selectByName(String name) {
        return selectOne(PlatformSensitiveWordDO::getName, name);
    }

    @Select("SELECT COUNT(*) FROM platform_sensitive_word WHERE update_time > #{maxUpdateTime}")
    Long selectCountByUpdateTimeGt(Date maxUpdateTime);

}
