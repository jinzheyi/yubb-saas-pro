package com.shengyu.module.platform.service.apprelease;

import cn.hutool.core.util.StrUtil;
import com.google.common.annotations.VisibleForTesting;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.platform.controller.app.apprelease.vo.AppReleaseCheckReqVO;
import com.shengyu.module.platform.controller.app.apprelease.vo.AppReleaseCheckRespVO;
import com.shengyu.module.platform.controller.platform.apprelease.vo.PlatformAppReleaseBaseVO;
import com.shengyu.module.platform.controller.platform.apprelease.vo.PlatformAppReleaseCreateReqVO;
import com.shengyu.module.platform.controller.platform.apprelease.vo.PlatformAppReleasePageReqVO;
import com.shengyu.module.platform.controller.platform.apprelease.vo.PlatformAppReleaseUpdateReqVO;
import com.shengyu.module.platform.dal.dataobject.apprelease.PlatformAppReleaseDO;
import com.shengyu.module.platform.dal.mysql.apprelease.PlatformAppReleaseMapper;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.APP_RELEASE_NOT_EXISTS;
import static com.shengyu.module.system.enums.ErrorCodeConstants.APP_RELEASE_PACKAGE_URL_REQUIRED;
import static com.shengyu.module.system.enums.ErrorCodeConstants.APP_RELEASE_PUBLISHED_CAN_NOT_DELETE;
import static com.shengyu.module.system.enums.ErrorCodeConstants.APP_RELEASE_VERSION_DUPLICATE;

@Service
@Validated
public class PlatformAppReleaseServiceImpl implements PlatformAppReleaseService {

    private static final String DEFAULT_CHANNEL = "prod";
    private static final String STATUS_DRAFT = "DRAFT";
    private static final String STATUS_PUBLISHED = "PUBLISHED";
    private static final String STATUS_PAUSED = "PAUSED";
    private static final String UPDATE_TYPE_NONE = "NONE";
    private static final String UPDATE_TYPE_FULL = "FULL";

    @Resource
    private PlatformAppReleaseMapper appReleaseMapper;

    @Override
    public Long createAppRelease(PlatformAppReleaseCreateReqVO reqVO) {
        normalize(reqVO);
        validatePackageUrl(reqVO.getUpdateType(), reqVO.getPackageUrl());
        validateVersionDuplicate(null, reqVO.getAppKey(), reqVO.getPlatform(), reqVO.getChannel(), reqVO.getVersionCode());
        PlatformAppReleaseDO release = BeanUtils.toBean(reqVO, PlatformAppReleaseDO.class);
        release.setStatus(STATUS_DRAFT);
        appReleaseMapper.insert(release);
        return release.getId();
    }

    @Override
    public void updateAppRelease(PlatformAppReleaseUpdateReqVO reqVO) {
        normalize(reqVO);
        validateAppReleaseExists(reqVO.getId());
        validatePackageUrl(reqVO.getUpdateType(), reqVO.getPackageUrl());
        validateVersionDuplicate(reqVO.getId(), reqVO.getAppKey(), reqVO.getPlatform(), reqVO.getChannel(), reqVO.getVersionCode());
        PlatformAppReleaseDO updateObj = BeanUtils.toBean(reqVO, PlatformAppReleaseDO.class);
        appReleaseMapper.updateById(updateObj);
    }

    @Override
    public void deleteAppRelease(Long id) {
        PlatformAppReleaseDO release = validateAppReleaseExists(id);
        if (STATUS_PUBLISHED.equals(release.getStatus())) {
            throw exception(APP_RELEASE_PUBLISHED_CAN_NOT_DELETE);
        }
        appReleaseMapper.deleteById(id);
    }

    @Override
    public void publishAppRelease(Long id) {
        PlatformAppReleaseDO release = validateAppReleaseExists(id);
        validatePackageUrl(release.getUpdateType(), release.getPackageUrl());
        PlatformAppReleaseDO updateObj = new PlatformAppReleaseDO();
        updateObj.setId(id);
        updateObj.setStatus(STATUS_PUBLISHED);
        appReleaseMapper.updateById(updateObj);
    }

    @Override
    public void pauseAppRelease(Long id) {
        validateAppReleaseExists(id);
        PlatformAppReleaseDO updateObj = new PlatformAppReleaseDO();
        updateObj.setId(id);
        updateObj.setStatus(STATUS_PAUSED);
        appReleaseMapper.updateById(updateObj);
    }

    @Override
    public PlatformAppReleaseDO getAppRelease(Long id) {
        return appReleaseMapper.selectById(id);
    }

    @Override
    public PageResult<PlatformAppReleaseDO> getAppReleasePage(PlatformAppReleasePageReqVO reqVO) {
        return appReleaseMapper.selectPage(reqVO);
    }

    @Override
    public AppReleaseCheckRespVO checkAppRelease(AppReleaseCheckReqVO reqVO) {
        String channel = StrUtil.blankToDefault(reqVO.getChannel(), DEFAULT_CHANNEL);
        PlatformAppReleaseDO latest = appReleaseMapper.selectLatestPublished(
                normalizeLower(reqVO.getAppKey()), normalizeLower(reqVO.getPlatform()), normalizeLower(channel));
        if (latest == null || reqVO.getVersionCode() >= latest.getVersionCode()) {
            return noUpdate();
        }
        AppReleaseCheckRespVO respVO = BeanUtils.toBean(latest, AppReleaseCheckRespVO.class);
        respVO.setHasUpdate(true);
        respVO.setForceUpdate(Boolean.TRUE.equals(latest.getForceUpdate())
                || reqVO.getVersionCode() < latest.getMinSupportedVersionCode());
        respVO.setPromptStrategy(respVO.getForceUpdate() ? "FORCE" : "NORMAL");
        return respVO;
    }

    @VisibleForTesting
    public PlatformAppReleaseDO validateAppReleaseExists(Long id) {
        PlatformAppReleaseDO release = appReleaseMapper.selectById(id);
        if (release == null) {
            throw exception(APP_RELEASE_NOT_EXISTS);
        }
        return release;
    }

    private void validateVersionDuplicate(Long id, String appKey, String platform, String channel, Integer versionCode) {
        PlatformAppReleaseDO release = appReleaseMapper.selectByVersion(appKey, platform, channel, versionCode);
        if (release != null && !release.getId().equals(id)) {
            throw exception(APP_RELEASE_VERSION_DUPLICATE);
        }
    }

    private void validatePackageUrl(String updateType, String packageUrl) {
        if (UPDATE_TYPE_FULL.equals(updateType) && StrUtil.isBlank(packageUrl)) {
            throw exception(APP_RELEASE_PACKAGE_URL_REQUIRED);
        }
    }

    private AppReleaseCheckRespVO noUpdate() {
        AppReleaseCheckRespVO respVO = new AppReleaseCheckRespVO();
        respVO.setHasUpdate(false);
        respVO.setUpdateType(UPDATE_TYPE_NONE);
        respVO.setForceUpdate(false);
        respVO.setPromptStrategy("NONE");
        return respVO;
    }

    private void normalize(PlatformAppReleaseBaseVO reqVO) {
        reqVO.setAppKey(normalizeLower(reqVO.getAppKey()));
        reqVO.setPlatform(normalizeLower(reqVO.getPlatform()));
        reqVO.setChannel(normalizeLower(StrUtil.blankToDefault(reqVO.getChannel(), DEFAULT_CHANNEL)));
        reqVO.setUpdateType(StrUtil.blankToDefault(reqVO.getUpdateType(), UPDATE_TYPE_FULL).toUpperCase());
    }

    private String normalizeLower(String value) {
        return StrUtil.blankToDefault(value, "").trim().toLowerCase();
    }

}
