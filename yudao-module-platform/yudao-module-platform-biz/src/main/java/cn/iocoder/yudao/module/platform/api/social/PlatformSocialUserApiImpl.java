package cn.iocoder.yudao.module.platform.api.social;

import cn.iocoder.yudao.module.platform.api.social.dto.SocialUserBindReqDTO;
import cn.iocoder.yudao.module.platform.api.social.dto.SocialUserUnbindReqDTO;
import cn.iocoder.yudao.module.platform.service.social.PlatformSocialUserService;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;

/**
 * 社交用户的 API 实现类
 *
 * @author 芋道源码
 */
@Service
@Validated
public class PlatformSocialUserApiImpl implements SocialUserApi {

    @Resource
    private PlatformSocialUserService platformSocialUserService;

    @Override
    public String getAuthorizeUrl(Integer type, String redirectUri) {
        return platformSocialUserService.getAuthorizeUrl(type, redirectUri);
    }

    @Override
    public void bindSocialUser(SocialUserBindReqDTO reqDTO) {
        platformSocialUserService.bindSocialUser(reqDTO);
    }

    @Override
    public void unbindSocialUser(SocialUserUnbindReqDTO reqDTO) {
        platformSocialUserService.unbindSocialUser(reqDTO.getUserId(), reqDTO.getUserType(),
                reqDTO.getType(), reqDTO.getUnionId());
    }

    @Override
    public Long getBindUserId(Integer userType, Integer type, String code, String state) {
       return platformSocialUserService.getBindUserId(userType, type, code, state);
    }

}
