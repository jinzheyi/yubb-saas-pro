package cn.iocoder.yudao.module.system.service.plug;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.PLUG_TENANT_APP_DISABLE;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.PLUG_TENANT_APP_ENABLE;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.PLUG_TENANT_APP_NOT_AUTHORIZE;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.PLUG_TENANT_APP_SN_NOT_EXISTS;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.PLUG_TENANT_NOT_EXISTS;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.ArrayUtil;
import cn.iocoder.yudao.framework.common.enums.CommonConstants;
import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.framework.tenant.core.aop.TenantIgnore;
import cn.iocoder.yudao.module.platform.api.plug.PlugAppApi;
import cn.iocoder.yudao.module.platform.api.plug.dto.PlugAppRespDTO;
import cn.iocoder.yudao.module.platform.api.plug.dto.PlugAppSimpleRespDTO;
import cn.iocoder.yudao.module.system.api.plug.dto.tenant.PlugAppEnableReqDTO;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.tenant.PlugTenantPageReqVO;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.tenant.PlugTenantRespVO;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.tenant.PlugTenantUpdateReqVO;
import cn.iocoder.yudao.module.system.controller.admin.user.vo.user.UserRespVO;
import cn.iocoder.yudao.module.system.dal.dataobject.plug.PlugTenantDO;
import cn.iocoder.yudao.module.system.dal.dataobject.user.AdminUserDO;
import cn.iocoder.yudao.module.system.dal.mysql.plug.PlugTenantMapper;
import cn.iocoder.yudao.module.system.service.user.AdminUserService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;
import javax.annotation.Resource;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

/**
 * 租户应用 Service 实现类
 *
 * @author zhusy
 */
@Service
@Validated
public class PlugTenantServiceImpl extends ServiceImpl<PlugTenantMapper, PlugTenantDO> implements
    PlugTenantService {

    @Resource
    private PlugTenantMapper plugTenantMapper;

    @Resource
    private AdminUserService adminUserService;

    @Resource
    private PlugAppApi plugAppApi;

    @Override
    public void updateTenant(PlugTenantUpdateReqVO updateReqVO) {
        // 校验存在
        validateTenantExists(updateReqVO.getId());
        // 更新
        PlugTenantDO updateObj = BeanUtils.toBean(updateReqVO, PlugTenantDO.class);
        plugTenantMapper.updateById(updateObj);
    }

    @Override
    @TenantIgnore
    public boolean enableTenantApp(PlugAppEnableReqDTO reqDTO) {
        List<PlugTenantDO> plugTenantDoS = plugTenantMapper.selectList(PlugTenantDO::getPlugAppId,
            reqDTO.getPlugAppId());
        plugTenantDoS.forEach(plug -> {
            plug.setEnable(reqDTO.getEnable());
        });
        return super.updateBatchById(plugTenantDoS);
    }

    private void validateTenantExists(Long id) {
        if (plugTenantMapper.selectById(id) == null) {
            throw exception(PLUG_TENANT_NOT_EXISTS);
        }
    }

    @Override
    public PlugTenantRespVO getTenant(Long id) {
        PlugTenantDO plugTenantDO = Optional.ofNullable(plugTenantMapper.selectById(id))
            .orElseThrow(() -> exception(PLUG_TENANT_NOT_EXISTS));
        PlugTenantRespVO tenantRespVO = BeanUtils.toBean(plugTenantDO, PlugTenantRespVO.class);
        PlugAppRespDTO appRespDTO = plugAppApi.getPlugApp(plugTenantDO.getPlugAppId());
        tenantRespVO.setAppSn(appRespDTO.getAppSn())
            .setMainPic(appRespDTO.getMainPic())
            .setName(appRespDTO.getName())
            .setOutline(appRespDTO.getOutline())
            .setDescription(appRespDTO.getDescription());
        return tenantRespVO;
    }

    @Override
    public PlugTenantDO getPlugTenant(Long plugAppId) {
        return plugTenantMapper.selectOne(PlugTenantDO::getPlugAppId, plugAppId);
    }

    @Override
    public PageResult<PlugTenantRespVO> getTenantPage(PlugTenantPageReqVO pageReqVO) {
        PageResult<PlugTenantDO> plugTenantDoPageResult = plugTenantMapper.selectPage(pageReqVO);
        PageResult<PlugTenantRespVO> plugTenantRespVoPageResult = BeanUtils.toBean(plugTenantDoPageResult, PlugTenantRespVO.class);
        List<PlugTenantRespVO> pageResultList = plugTenantRespVoPageResult.getList();
        if (!pageResultList.isEmpty()) {
            List<PlugAppSimpleRespDTO> plugAppList = plugAppApi.getPlugAppList(
                pageResultList.stream().map(PlugTenantRespVO::getPlugAppId)
                    .collect(Collectors.toList()), null);
            pageResultList.forEach(pt -> {
                plugAppList.stream()
                    .filter(p -> p.getId().equals(pt.getPlugAppId())).findFirst()
                    .ifPresent(plugAppSimpleRespDTO -> pt.setAppSn(plugAppSimpleRespDTO.getAppSn())
                        .setMainPic(plugAppSimpleRespDTO.getMainPic())
                        .setName(plugAppSimpleRespDTO.getName())
                        .setOutline(plugAppSimpleRespDTO.getOutline()));
            });
        }
        return plugTenantRespVoPageResult;
    }

    @Override
    public boolean hasAllPlugApp(Long userId, String... plugAppSn) {
        // 如果为空，说明已经有插件权限
        if (ArrayUtil.isEmpty(plugAppSn)) {
            return true;
        }
        //根据租户用户编号查询所属用户信息，会一并查询出对应SaaS体系用户信息
        UserRespVO user = adminUserService.getUser(userId);
        if (Objects.isNull(user)) {
            return false;
        }
        //查询租户包含的插件
        List<PlugTenantDO> plugTenantDoS = plugTenantMapper.selectList(PlugTenantDO::getTenantId,
            user.getTenantId());
        //当前访问用户所属租户没有购买任何插件
        if (CollUtil.isEmpty(plugTenantDoS)) {
            throw exception(PLUG_TENANT_APP_SN_NOT_EXISTS);
        }
        List<String> plugAppSns = Arrays.stream(plugAppSn).collect(Collectors.toList());
        List<PlugAppSimpleRespDTO> appSimpleRespDtoS = plugAppApi.getPlugAppList(null, plugAppSns);
        //插件应用id
        List<Long> plugAppId = appSimpleRespDtoS.stream().map(PlugAppSimpleRespDTO::getId)
            .collect(Collectors.toList());
        //租户含有的插件必须全部满足所需插件
        boolean app = new HashSet<>(plugTenantDoS.stream().map(PlugTenantDO::getPlugAppId)
            .collect(Collectors.toList())).containsAll(plugAppId);
        if (!app) {
            //根据应用编码获取需要哪些插件授权的提示
            List<String> appMsg = plugAppSns.stream()
                .map(CommonConstants.PlugAppSnEnum::getValueByCode).collect(Collectors.toList());
            throw exception(PLUG_TENANT_APP_NOT_AUTHORIZE, StringUtils.join(appMsg, ","));
        }
        //上面已经判断了租户包含了插件，剩下是判断是否上架并启用
        appSimpleRespDtoS.forEach(appDTO -> {
            PlugTenantDO plugTenantDO = plugTenantDoS.stream()
                .filter(plugTenan -> plugTenan.getPlugAppId().equals(appDTO.getId())).findFirst()
                .orElse(null);
            if (Objects.nonNull(plugTenantDO)) {
                if (!CommonStatusEnum.ENABLE.getStatus().equals(plugTenantDO.getStatus())) {
                    throw exception(PLUG_TENANT_APP_DISABLE,
                        CommonConstants.PlugAppSnEnum.getValueByCode(appDTO.getAppSn()));
                }
                if (!CommonStatusEnum.ENABLE.getStatus().equals(plugTenantDO.getEnable())) {
                    throw exception(PLUG_TENANT_APP_ENABLE,
                        CommonConstants.PlugAppSnEnum.getValueByCode(appDTO.getAppSn()));
                }
            }
        });
        return true;
    }

}
