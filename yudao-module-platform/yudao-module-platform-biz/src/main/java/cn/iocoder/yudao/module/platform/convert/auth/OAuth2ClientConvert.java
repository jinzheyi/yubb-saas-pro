package cn.iocoder.yudao.module.platform.convert.auth;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.client.OAuth2ClientCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.client.OAuth2ClientRespVO;
import cn.iocoder.yudao.module.platform.controller.center.oauth2.vo.client.OAuth2ClientUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.oauth2.PlatformOAuth2ClientDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

/**
 * OAuth2 客户端 Convert
 *
 * @author 芋道源码
 */
@Mapper
public interface OAuth2ClientConvert {

    OAuth2ClientConvert INSTANCE = Mappers.getMapper(OAuth2ClientConvert.class);

    PlatformOAuth2ClientDO convert(OAuth2ClientCreateReqVO bean);

    PlatformOAuth2ClientDO convert(OAuth2ClientUpdateReqVO bean);

    OAuth2ClientRespVO convert(PlatformOAuth2ClientDO bean);

    List<OAuth2ClientRespVO> convertList(List<PlatformOAuth2ClientDO> list);

    PageResult<OAuth2ClientRespVO> convertPage(PageResult<PlatformOAuth2ClientDO> page);

}
