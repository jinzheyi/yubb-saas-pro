package cn.iocoder.yudao.module.platform.convert.oauth2;

import cn.iocoder.yudao.framework.common.core.KeyValue;
import cn.iocoder.yudao.framework.common.enums.UserTypeEnum;
import cn.iocoder.yudao.framework.common.util.collection.CollectionUtils;
import cn.iocoder.yudao.framework.security.core.util.SecurityFrameworkUtils;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.open.OAuth2OpenAccessTokenRespVO;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.open.OAuth2OpenAuthorizeInfoRespVO;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.open.OAuth2OpenCheckTokenRespVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2AccessTokenDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2ApproveDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2ClientDO;
import cn.iocoder.yudao.module.platform.util.oauth2.OAuth2Utils;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Mapper
public interface OAuth2OpenConvert {

    OAuth2OpenConvert INSTANCE = Mappers.getMapper(OAuth2OpenConvert.class);

    default OAuth2OpenAccessTokenRespVO convert(PlatformOAuth2AccessTokenDO bean) {
        OAuth2OpenAccessTokenRespVO respVO = convert0(bean);
        respVO.setTokenType(SecurityFrameworkUtils.AUTHORIZATION_BEARER.toLowerCase());
        respVO.setExpiresIn(OAuth2Utils.getExpiresIn(bean.getExpiresTime()));
        respVO.setScope(OAuth2Utils.buildScopeStr(bean.getScopes()));
        return respVO;
    }
    OAuth2OpenAccessTokenRespVO convert0(PlatformOAuth2AccessTokenDO bean);

    default OAuth2OpenCheckTokenRespVO convert2(PlatformOAuth2AccessTokenDO bean) {
        OAuth2OpenCheckTokenRespVO respVO = convert3(bean);
        respVO.setExp(bean.getExpiresTime().getTime() / 1000L);
        respVO.setUserType(UserTypeEnum.CENTER.getValue());
        return respVO;
    }
    OAuth2OpenCheckTokenRespVO convert3(PlatformOAuth2AccessTokenDO bean);

    default OAuth2OpenAuthorizeInfoRespVO convert(PlatformOAuth2ClientDO client, List<PlatformOAuth2ApproveDO> approves) {
        // 构建 scopes
        List<KeyValue<String, Boolean>> scopes = new ArrayList<>(client.getScopes().size());
        Map<String, PlatformOAuth2ApproveDO> approveMap = CollectionUtils.convertMap(approves, PlatformOAuth2ApproveDO::getScope);
        client.getScopes().forEach(scope -> {
            PlatformOAuth2ApproveDO approve = approveMap.get(scope);
            scopes.add(new KeyValue<>(scope, approve != null ? approve.getApproved() : false));
        });
        // 拼接返回
        return new OAuth2OpenAuthorizeInfoRespVO(
                new OAuth2OpenAuthorizeInfoRespVO.Client(client.getName(), client.getLogo()), scopes);
    }

}
