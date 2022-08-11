package cn.iocoder.yudao.module.platform.dal.mysql.social;

import cn.iocoder.yudao.module.platform.dal.dataobject.social.PlatformSocialUserDO;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface PlatformSocialUserMapper extends BaseMapperX<PlatformSocialUserDO> {

    default PlatformSocialUserDO selectByTypeAndCodeAnState(Integer type, String code, String state) {
        return selectOne(new LambdaQueryWrapper<PlatformSocialUserDO>()
                .eq(PlatformSocialUserDO::getType, type)
                .eq(PlatformSocialUserDO::getCode, code)
                .eq(PlatformSocialUserDO::getState, state));
    }

    default PlatformSocialUserDO selectByTypeAndOpenid(Integer type, String openid) {
        return selectOne(new LambdaQueryWrapper<PlatformSocialUserDO>()
                .eq(PlatformSocialUserDO::getType, type)
                .eq(PlatformSocialUserDO::getOpenid, openid));
    }

}
