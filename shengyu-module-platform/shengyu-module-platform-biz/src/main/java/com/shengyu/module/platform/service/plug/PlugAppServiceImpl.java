package com.shengyu.module.platform.service.plug;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.PLUG_APP_NOT_EXISTS;
import static com.shengyu.module.system.enums.ErrorCodeConstants.PLUG_APP_SN_EXISTS;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.platform.controller.platform.plug.vo.app.PlugAppCreateReqVO;
import com.shengyu.module.platform.controller.platform.plug.vo.app.PlugAppExportReqVO;
import com.shengyu.module.platform.controller.platform.plug.vo.app.PlugAppPageReqVO;
import com.shengyu.module.platform.controller.platform.plug.vo.app.PlugAppUpdateEnableReqVO;
import com.shengyu.module.platform.controller.platform.plug.vo.app.PlugAppUpdateReqVO;
import com.shengyu.module.platform.controller.platform.plug.vo.app.PlugAppUpdateStatusReqVO;
import com.shengyu.module.platform.dal.dataobject.plug.PlugAppDO;
import com.shengyu.module.platform.dal.mysql.plug.PlugAppMapper;
import com.shengyu.module.system.api.plug.PlugTenantApi;
import com.shengyu.module.system.api.plug.dto.tenant.PlugAppEnableReqDTO;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import javax.annotation.Resource;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

/**
 * 插件应用 Service 实现类
 *
 * @author zhusy
 */
@Service
@Validated
public class PlugAppServiceImpl implements PlugAppService {

    @Resource
    private PlugAppMapper plugAppMapper;

    @Resource
    @Lazy
    private PlugTenantApi plugTenantApi;

    @Override
    public Long createPlugApp(PlugAppCreateReqVO createReqVO) {
        validatePlugAppExists(null, createReqVO.getAppSn());
        // 插入
        PlugAppDO plugApp = BeanUtils.toBean(createReqVO, PlugAppDO.class);
        plugAppMapper.insert(plugApp);
        // 返回
        return plugApp.getId();
    }

    @Override
    public void updatePlugApp(PlugAppUpdateReqVO updateReqVO) {
        // 校验存在
        validatePlugAppExists(updateReqVO.getId(), null);
        // 更新
        PlugAppDO updateObj = BeanUtils.toBean(updateReqVO, PlugAppDO.class);
        plugAppMapper.updateById(updateObj);
    }

    @Override
    public void updateStatusPlugApp(PlugAppUpdateStatusReqVO updateReqVO) {
        // 校验存在
        validatePlugAppExists(updateReqVO.getId(), null);
        // 更新
        PlugAppDO updateObj = new PlugAppDO();
        updateObj.setId(updateReqVO.getId());
        updateObj.setStatus(updateReqVO.getStatus());
        plugAppMapper.updateById(updateObj);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateEnablePlugApp(PlugAppUpdateEnableReqVO updateReqVO) {
        // 校验存在
        validatePlugAppExists(updateReqVO.getId(), null);
        // 更新
        PlugAppDO updateObj = new PlugAppDO();
        updateObj.setId(updateReqVO.getId());
        updateObj.setEnable(updateReqVO.getEnable());
        plugAppMapper.updateById(updateObj);
        //更新所有拥有该插件的租户
        PlugAppEnableReqDTO reqDTO = new PlugAppEnableReqDTO();
        reqDTO.setPlugAppId(updateReqVO.getId());
        reqDTO.setEnable(updateReqVO.getEnable());
        plugTenantApi.enableTenantApp(reqDTO);
    }

    private void validatePlugAppExists(Long id, String appSn) {
        if (Objects.nonNull(id) && plugAppMapper.selectById(id) == null) {
            throw exception(PLUG_APP_NOT_EXISTS);
        }
        if (StrUtil.isNotBlank(appSn) && Objects.nonNull(plugAppMapper.selectOne(PlugAppDO::getAppSn, appSn))) {
            throw exception(PLUG_APP_SN_EXISTS);
        }
    }

    @Override
    public PlugAppDO getPlugApp(Long id) {
        return plugAppMapper.selectById(id);
    }

    @Override
    public PlugAppDO getPlugAppBySn(String appSn) {
        return plugAppMapper.selectOne(PlugAppDO::getAppSn, appSn);
    }

    @Override
    public List<PlugAppDO> getPlugAppList() {
        return plugAppMapper.selectList();
    }

    @Override
    public PageResult<PlugAppDO> getPlugAppPage(PlugAppPageReqVO pageReqVO) {
        return plugAppMapper.selectPage(pageReqVO);
    }

    @Override
    public List<PlugAppDO> getPlugAppList(PlugAppExportReqVO exportReqVO) {
        return plugAppMapper.selectList(exportReqVO);
    }

    @Override
    public List<PlugAppDO> getPlugAppList(List<Long> ids, List<String> appSns) {
        if (CollUtil.isEmpty(ids) && CollUtil.isEmpty(appSns)) {
            return new ArrayList<>();
        }
        return plugAppMapper.selectList(new LambdaQueryWrapperX<PlugAppDO>()
                .inIfPresent(PlugAppDO::getId, ids).inIfPresent(PlugAppDO::getAppSn, appSns));
    }

}
