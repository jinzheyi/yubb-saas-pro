package cn.iocoder.yudao.module.system.service.config;

import cn.hutool.core.util.StrUtil;
import cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.tenant.core.context.TenantContextHolder;
import cn.iocoder.yudao.module.infra.enums.ErrorCodeConstants;
import cn.iocoder.yudao.module.system.controller.admin.config.vo.ConfigCreateOrDelReqVO;
import cn.iocoder.yudao.module.system.controller.admin.config.vo.ConfigPageReqVO;
import cn.iocoder.yudao.module.system.controller.admin.config.vo.ConfigUpdateReqVO;
import cn.iocoder.yudao.module.system.convert.config.ConfigurationConvert;
import cn.iocoder.yudao.module.system.dal.dataobject.config.ConfigurationDO;
import cn.iocoder.yudao.module.system.dal.mysql.config.ConfigurationMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.google.common.annotations.VisibleForTesting;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.List;

/**
 * 参数配置 Service 实现类
 */
@Service
@Slf4j
@Validated
public class ConfigurationServiceImpl extends ServiceImpl<ConfigurationMapper, ConfigurationDO> implements ConfigurationService {

    @Resource
    private ConfigurationMapper configurationMapper;

//    @Resource
//    private ConfigProducer configProducer;

    @Override
    public void createOrDel(List<ConfigCreateOrDelReqVO> reqVOList) {
        List<ConfigurationDO> createList = new ArrayList<>();
        List<Long> delIdsList = new ArrayList<>();
        reqVOList.forEach(reqVO -> {
            // 校验正确性
            if (checkCreate(reqVO.getConfigKey()) && !reqVO.getDeleted()) {
                createList.add(ConfigurationConvert.INSTANCE.convert(reqVO));
            };
            if (reqVO.getDeleted()) {
                delIdsList.add(reqVO.getConfigId());
            }
        });
        try {
            log.info("TenantContextHolder.getTenantId()====" + TenantContextHolder.getTenantId());
            this.saveBatch(createList);
            this.removeBatchByIds(delIdsList);
        } catch (Exception e) {
            log.error("租户同步平台配置发生异常:{}", e);
        }
        // 发送刷新消息
//        configProducer.sendConfigRefreshMessage();
    }

    @Override
    public void updateConfig(ConfigUpdateReqVO reqVO) {
        // 校验正确性
        checkCreateOrUpdate(reqVO.getId(), null); // 不允许更新 key
        // 更新参数配置
        ConfigurationDO updateObj = ConfigurationConvert.INSTANCE.convert(reqVO);
        configurationMapper.updateById(updateObj);
        // 发送刷新消息
//        configProducer.sendConfigRefreshMessage();
    }

    @Override
    public ConfigurationDO getConfig(Long id) {
        return configurationMapper.selectById(id);
    }

    @Override
    public ConfigurationDO getConfigByKey(String key) {
        return configurationMapper.selectByKey(key);
    }

    @Override
    public PageResult<ConfigurationDO> getConfigPage(ConfigPageReqVO reqVO) {
        return configurationMapper.selectPage(reqVO);
    }

    private boolean checkCreate(String key) {
        // 校验参数配置 key 的唯一性
        if (StrUtil.isNotEmpty(key)) {
            ConfigurationDO config = configurationMapper.selectByKey(key);
            if (config == null) {
                return true;
            }
        }
        return false;
    }

    private void checkCreateOrUpdate(Long id, String key) {
        // 校验自己存在
        checkConfigExists(id);
        // 校验参数配置 key 的唯一性
        if (StrUtil.isNotEmpty(key)) {
            checkConfigKeyUnique(id, key);
        }
    }

    @VisibleForTesting
    public ConfigurationDO checkConfigExists(Long id) {
        if (id == null) {
            return null;
        }
        ConfigurationDO config = configurationMapper.selectById(id);
        if (config == null) {
            throw ServiceExceptionUtil.exception(ErrorCodeConstants.CONFIG_NOT_EXISTS);
        }
        return config;
    }

    @VisibleForTesting
    public void checkConfigKeyUnique(Long id, String key) {
        ConfigurationDO config = configurationMapper.selectByKey(key);
        if (config == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同 id 的参数配置
        if (id == null) {
            throw ServiceExceptionUtil.exception(ErrorCodeConstants.CONFIG_KEY_DUPLICATE);
        }
        if (!config.getId().equals(id)) {
            throw ServiceExceptionUtil.exception(ErrorCodeConstants.CONFIG_KEY_DUPLICATE);
        }
    }

}
