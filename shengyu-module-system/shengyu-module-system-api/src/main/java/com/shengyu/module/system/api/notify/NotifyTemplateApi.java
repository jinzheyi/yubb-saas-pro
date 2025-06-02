package com.shengyu.module.system.api.notify;

import com.shengyu.module.system.api.notify.dto.NotifyTemplateSaveReqDTO;

import javax.validation.Valid;

/**
 * 站内信模版 API 接口
 *
 * @author zhusy
 */
public interface NotifyTemplateApi {

    /**
     * 创建站内信模版
     *
     * @param createReqDTO 创建信息
     * @return 编号
     */
    Long createNotifyTemplate(@Valid NotifyTemplateSaveReqDTO createReqDTO);

}
