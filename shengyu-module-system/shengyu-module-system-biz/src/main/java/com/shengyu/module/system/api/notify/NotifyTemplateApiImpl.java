package com.shengyu.module.system.api.notify;

import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.system.api.notify.dto.NotifyTemplateSaveReqDTO;
import com.shengyu.module.system.controller.admin.notify.vo.template.NotifyTemplateSaveReqVO;
import com.shengyu.module.system.service.notify.NotifyTemplateService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import javax.validation.Valid;

/**
 * 站内信模版 API 接口
 *
 * @author zhusy
 */
@Service
public class NotifyTemplateApiImpl implements NotifyTemplateApi{

    @Resource
    private NotifyTemplateService notifyTemplateService;

    @Override
    public Long createNotifyTemplate(@Valid NotifyTemplateSaveReqDTO createReqDTO) {
        return notifyTemplateService.createNotifyTemplate(BeanUtils.toBean(createReqDTO, NotifyTemplateSaveReqVO.class));
    }

}
