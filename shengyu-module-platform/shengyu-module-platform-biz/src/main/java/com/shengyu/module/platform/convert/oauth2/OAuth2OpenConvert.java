package com.shengyu.module.platform.convert.oauth2;

import cn.hutool.core.date.LocalDateTimeUtil;
import com.shengyu.framework.common.core.KeyValue;
import com.shengyu.framework.common.enums.UserTypeEnum;
import com.shengyu.framework.common.util.collection.CollectionUtils;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.platform.controller.platform.oauth2.vo.open.OAuth2OpenAccessTokenRespVO;
import com.shengyu.module.platform.controller.platform.oauth2.vo.open.OAuth2OpenAuthorizeInfoRespVO;
import com.shengyu.module.platform.controller.platform.oauth2.vo.open.OAuth2OpenCheckTokenRespVO;
import com.shengyu.module.platform.dal.dataobject.oauth2.PlatformOAuth2AccessTokenDO;
import com.shengyu.module.platform.dal.dataobject.oauth2.PlatformOAuth2ApproveDO;
import com.shengyu.module.platform.dal.dataobject.oauth2.PlatformOAuth2ClientDO;
import com.shengyu.module.platform.util.oauth2.OAuth2Utils;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Mapper
public interface OAuth2OpenConvert {

    OAuth2OpenConvert INSTANCE = Mappers.getMapper(OAuth2OpenConvert.class);

    default OAuth2OpenAccessTokenRespVO convert(PlatformOAuth2AccessTokenDO bean) {
        OAuth2OpenAccessTokenRespVO respVO = BeanUtils.toBean(bean, OAuth2OpenAccessTokenRespVO.class);
        respVO.setTokenType(SecurityFrameworkUtils.AUTHORIZATION_BEARER.toLowerCase());
        respVO.setExpiresIn(OAuth2Utils.getExpiresIn(bean.getExpiresTime()));
        respVO.setScope(OAuth2Utils.buildScopeStr(bean.getScopes()));
        return respVO;
    }

    default OAuth2OpenCheckTokenRespVO convert2(PlatformOAuth2AccessTokenDO bean) {
        OAuth2OpenCheckTokenRespVO respVO = BeanUtils.toBean(bean, OAuth2OpenCheckTokenRespVO.class);
        respVO.setExp(LocalDateTimeUtil.toEpochMilli(bean.getExpiresTime()) / 1000L);
        respVO.setUserType(UserTypeEnum.PLATFORM.getValue());
        return respVO;
    }

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
