package com.shengyu.module.system.service.im;

import com.shengyu.module.system.controller.admin.im.vo.mail.ImMailListRespVO;

/**
 * 用户通讯录 Service 接口
 *
 * @author zhusy
 * @since 2022/11/23
 */
public interface ImMailService {

    /**
     * 获取用户通讯录列表
     *
     * @return 用户通讯录列表
     */
    ImMailListRespVO list();

}
