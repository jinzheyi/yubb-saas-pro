package com.shengyu.module.system.service.im;

import com.shengyu.module.system.controller.app.im.vo.message.AppImLocationSearchReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImLocationSearchRespVO;

public interface ImLocationService {

    AppImLocationSearchRespVO searchLocation(Long userId, AppImLocationSearchReqVO reqVO);

}
