package cn.iocoder.yudao.module.platform.dal.mysql.social;

import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.dal.dataobject.social.PlatformSocialUserBindDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface PlatformSocialUserBindMapper extends BaseMapperX<PlatformSocialUserBindDO> {

    default void deleteByUserTypeAndUserIdAndSocialType(Integer userType, Long userId, Integer socialType) {
        delete(new LambdaQueryWrapperX<PlatformSocialUserBindDO>()
                .eq(PlatformSocialUserBindDO::getUserType, userType)
                .eq(PlatformSocialUserBindDO::getUserId, userId)
                .eq(PlatformSocialUserBindDO::getSocialType, socialType));
    }

    default void deleteByUserTypeAndSocialUserId(Integer userType, Long socialUserId) {
        delete(new LambdaQueryWrapperX<PlatformSocialUserBindDO>()
                .eq(PlatformSocialUserBindDO::getUserType, userType)
                .eq(PlatformSocialUserBindDO::getSocialUserId, socialUserId));
    }

    default PlatformSocialUserBindDO selectByUserTypeAndSocialUserId(Integer userType, Long socialUserId) {
        return selectOne(new LambdaQueryWrapperX<PlatformSocialUserBindDO>()
                .eq(PlatformSocialUserBindDO::getUserType, userType)
                .eq(PlatformSocialUserBindDO::getSocialUserId, socialUserId));
    }

    default List<PlatformSocialUserBindDO> selectListByUserIdAndUserType(Long userId, Integer userType) {
        return selectList(new LambdaQueryWrapperX<PlatformSocialUserBindDO>()
                .eq(PlatformSocialUserBindDO::getUserId, userId)
                .eq(PlatformSocialUserBindDO::getUserType, userType));
    }

}
