package cn.iocoder.yudao.module.platform.service.oauth2;

import cn.hutool.core.util.IdUtil;
import cn.iocoder.yudao.framework.common.util.date.DateUtils;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2CodeDO;
import cn.iocoder.yudao.module.platform.dal.mysql.oauth2.PlatformOAuth2CodeMapper;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.util.List;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.*;

/**
 * OAuth2.0 授权码 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Validated
public class PlatformOAuth2CodeServiceImpl implements PlatformOAuth2CodeService {

    /**
     * 授权码的过期时间，默认 5 分钟
     */
    private static final Integer TIMEOUT = 5 * 60;

    @Resource
    private PlatformOAuth2CodeMapper oauth2CodeMapperPlatform;

    @Override
    public PlatformOAuth2CodeDO createAuthorizationCode(Long userId, Integer userType, String clientId,
                                                        List<String> scopes, String redirectUri, String state) {
        PlatformOAuth2CodeDO codeDO = new PlatformOAuth2CodeDO().setCode(generateCode())
                .setUserId(userId).setUserType(userType)
                .setClientId(clientId).setScopes(scopes)
                .setExpiresTime(LocalDateTime.now().plusSeconds(TIMEOUT))
                .setRedirectUri(redirectUri).setState(state);
        oauth2CodeMapperPlatform.insert(codeDO);
        return codeDO;
    }

    @Override
    public PlatformOAuth2CodeDO consumeAuthorizationCode(String code) {
        PlatformOAuth2CodeDO codeDO = oauth2CodeMapperPlatform.selectByCode(code);
        if (codeDO == null) {
            throw exception(OAUTH2_CODE_NOT_EXISTS);
        }
        if (DateUtils.isExpired(codeDO.getExpiresTime())) {
            throw exception(OAUTH2_CODE_EXPIRE);
        }
        oauth2CodeMapperPlatform.deleteById(codeDO.getId());
        return codeDO;
    }

    private static String generateCode() {
        return IdUtil.fastSimpleUUID();
    }

}
