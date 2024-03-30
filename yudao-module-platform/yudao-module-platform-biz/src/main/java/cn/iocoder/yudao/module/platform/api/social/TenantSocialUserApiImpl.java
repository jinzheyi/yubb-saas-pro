package cn.iocoder.yudao.module.platform.api.social;

import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.module.platform.api.social.dto.SocialUserBindReqDTO;
import cn.iocoder.yudao.module.platform.api.social.dto.SocialUserRespDTO;
import cn.iocoder.yudao.module.platform.api.social.dto.SocialUserUnbindReqDTO;
import cn.iocoder.yudao.module.platform.service.social.SocialUserService;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;

/**
 * 社交用户的 API 实现类
 *
 * @author 圣钰科技
 */
@Service
@Validated
public class TenantSocialUserApiImpl implements TenantSocialUserApi {

    @Resource
    private SocialUserService socialUserService;

    @Override
    public String bindSocialUser(SocialUserBindReqDTO reqDTO) {
        return socialUserService.bindSocialUser(reqDTO);
    }

    @Override
    public void unbindSocialUser(SocialUserUnbindReqDTO reqDTO) {
        socialUserService.unbindSocialUser(reqDTO.getUserId(), reqDTO.getUserType(),
                reqDTO.getSocialType(), reqDTO.getOpenid());
    }

    @Override
    public SocialUserRespDTO getSocialUserByUserId(Integer userType, Long userId, Integer socialType) {
        return socialUserService.getSocialUserByUserId(userType, userId, socialType);
    }

    @Override
    public SocialUserRespDTO getSocialUserByCode(Integer userType, Integer socialType, String code, String state) {
       return socialUserService.getSocialUserByCode(userType, socialType, code, state);
    }

    @Override
    public List<SocialUserRespDTO> getSocialUserList(Long userId, Integer userType) {
        return BeanUtils.toBean(socialUserService.getSocialUserList(userId, userType), SocialUserRespDTO.class);
    }

}
