package com.shengyu.module.member.convert.auth;

import com.shengyu.framework.common.enums.sms.SmsSceneEnum;
import com.shengyu.module.member.controller.app.auth.vo.*;
import com.shengyu.module.member.controller.app.auth.vo.*;
import com.shengyu.module.member.controller.app.social.vo.AppSocialUserUnbindReqVO;
import com.shengyu.module.member.controller.app.user.vo.AppMemberUserResetPasswordReqVO;
import com.shengyu.module.system.api.oauth2.dto.OAuth2AccessTokenRespDTO;
import com.shengyu.module.platform.api.sms.dto.code.SmsCodeSendReqDTO;
import com.shengyu.module.platform.api.sms.dto.code.SmsCodeUseReqDTO;
import com.shengyu.module.platform.api.sms.dto.code.SmsCodeValidateReqDTO;
import com.shengyu.module.platform.api.social.dto.SocialUserBindReqDTO;
import com.shengyu.module.platform.api.social.dto.SocialUserUnbindReqDTO;
import com.shengyu.module.platform.api.social.dto.SocialWxJsapiSignatureRespDTO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

@Mapper
public interface AuthConvert {

    AuthConvert INSTANCE = Mappers.getMapper(AuthConvert.class);

    SocialUserBindReqDTO convert(Long userId, Integer userType, AppAuthSocialLoginReqVO reqVO);
    SocialUserUnbindReqDTO convert(Long userId, Integer userType, AppSocialUserUnbindReqVO reqVO);

    SmsCodeSendReqDTO convert(AppAuthSmsSendReqVO reqVO);
    SmsCodeUseReqDTO convert(AppMemberUserResetPasswordReqVO reqVO, SmsSceneEnum scene, String usedIp);
    SmsCodeUseReqDTO convert(AppAuthSmsLoginReqVO reqVO, Integer scene, String usedIp);

    AppAuthLoginRespVO convert(OAuth2AccessTokenRespDTO bean, String openid);

    SmsCodeValidateReqDTO convert(AppAuthSmsValidateReqVO bean);

    SocialWxJsapiSignatureRespDTO convert(SocialWxJsapiSignatureRespDTO bean);

}
