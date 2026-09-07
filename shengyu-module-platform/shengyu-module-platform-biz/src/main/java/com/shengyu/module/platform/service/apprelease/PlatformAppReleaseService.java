package com.shengyu.module.platform.service.apprelease;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.platform.controller.app.apprelease.vo.AppReleaseCheckReqVO;
import com.shengyu.module.platform.controller.app.apprelease.vo.AppReleaseCheckRespVO;
import com.shengyu.module.platform.controller.platform.apprelease.vo.PlatformAppReleaseCreateReqVO;
import com.shengyu.module.platform.controller.platform.apprelease.vo.PlatformAppReleasePageReqVO;
import com.shengyu.module.platform.controller.platform.apprelease.vo.PlatformAppReleaseUpdateReqVO;
import com.shengyu.module.platform.dal.dataobject.apprelease.PlatformAppReleaseDO;

public interface PlatformAppReleaseService {

    Long createAppRelease(PlatformAppReleaseCreateReqVO reqVO);

    void updateAppRelease(PlatformAppReleaseUpdateReqVO reqVO);

    void deleteAppRelease(Long id);

    void publishAppRelease(Long id);

    void pauseAppRelease(Long id);

    PlatformAppReleaseDO getAppRelease(Long id);

    PageResult<PlatformAppReleaseDO> getAppReleasePage(PlatformAppReleasePageReqVO reqVO);

    AppReleaseCheckRespVO checkAppRelease(AppReleaseCheckReqVO reqVO);

}
