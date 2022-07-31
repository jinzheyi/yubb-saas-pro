package cn.iocoder.yudao.module.platform.dal.mapper.sms;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.template.SmsTemplateExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.sms.vo.template.SmsTemplatePageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.sms.PlatformSmsTemplateDO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.Date;
import java.util.List;

@Mapper
public interface PlatformSmsTemplateMapper extends BaseMapperX<PlatformSmsTemplateDO> {

    @Select("SELECT COUNT(*) FROM platform_sms_template WHERE update_time > #{maxUpdateTime}")
    Long selectCountByUpdateTimeGt(Date maxUpdateTime);

    default PlatformSmsTemplateDO selectByCode(String code) {
        return selectOne(PlatformSmsTemplateDO::getCode, code);
    }

    default PageResult<PlatformSmsTemplateDO> selectPage(SmsTemplatePageReqVO reqVO) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlatformSmsTemplateDO>()
                .eqIfPresent(PlatformSmsTemplateDO::getType, reqVO.getType())
                .eqIfPresent(PlatformSmsTemplateDO::getStatus, reqVO.getStatus())
                .likeIfPresent(PlatformSmsTemplateDO::getCode, reqVO.getCode())
                .likeIfPresent(PlatformSmsTemplateDO::getContent, reqVO.getContent())
                .likeIfPresent(PlatformSmsTemplateDO::getApiTemplateId, reqVO.getApiTemplateId())
                .eqIfPresent(PlatformSmsTemplateDO::getChannelId, reqVO.getChannelId())
                .betweenIfPresent(PlatformSmsTemplateDO::getCreateTime, reqVO.getBeginCreateTime(), reqVO.getEndCreateTime())
                .orderByDesc(PlatformSmsTemplateDO::getId));
    }

    default List<PlatformSmsTemplateDO> selectList(SmsTemplateExportReqVO reqVO) {
        return selectList(new LambdaQueryWrapperX<PlatformSmsTemplateDO>()
                .eqIfPresent(PlatformSmsTemplateDO::getType, reqVO.getType())
                .eqIfPresent(PlatformSmsTemplateDO::getStatus, reqVO.getStatus())
                .likeIfPresent(PlatformSmsTemplateDO::getCode, reqVO.getCode())
                .likeIfPresent(PlatformSmsTemplateDO::getContent, reqVO.getContent())
                .likeIfPresent(PlatformSmsTemplateDO::getApiTemplateId, reqVO.getApiTemplateId())
                .eqIfPresent(PlatformSmsTemplateDO::getChannelId, reqVO.getChannelId())
                .betweenIfPresent(PlatformSmsTemplateDO::getCreateTime, reqVO.getBeginCreateTime(), reqVO.getEndCreateTime())
                .orderByDesc(PlatformSmsTemplateDO::getId));
    }

    default Long selectCountByChannelId(Long channelId) {
        return selectCount(PlatformSmsTemplateDO::getChannelId, channelId);
    }

}
