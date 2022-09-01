package cn.iocoder.yudao.module.infra.service.config;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.tenant.core.util.TenantUtils;
import cn.iocoder.yudao.module.infra.controller.center.config.vo.ConfigCreateReqVO;
import cn.iocoder.yudao.module.infra.controller.center.config.vo.ConfigExportReqVO;
import cn.iocoder.yudao.module.infra.controller.center.config.vo.ConfigPageReqVO;
import cn.iocoder.yudao.module.infra.controller.center.config.vo.ConfigUpdateReqVO;
import cn.iocoder.yudao.module.infra.convert.config.ConfigConvert;
import cn.iocoder.yudao.module.infra.dal.dataobject.config.ConfigDO;
import cn.iocoder.yudao.module.infra.dal.mysql.config.ConfigMapper;
import cn.iocoder.yudao.module.infra.enums.ErrorCodeConstants;
import cn.iocoder.yudao.module.infra.enums.config.ConfigTypeEnum;
import cn.iocoder.yudao.module.infra.mq.producer.config.ConfigProducer;
import cn.iocoder.yudao.module.platform.api.tenant.TenantApi;
import cn.iocoder.yudao.module.system.api.config.ConfigurationApi;
import com.google.common.annotations.VisibleForTesting;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;
import java.util.List;

/**
 * 参数配置 Service 实现类
 */
@Service
@Slf4j
@Validated
public class ConfigServiceImpl implements ConfigService {

    @Resource
    private ConfigMapper configMapper;

    @Resource
    private ConfigProducer configProducer;

    @Resource
    private TenantApi tenantApi;

    @Resource
    private ConfigurationApi configurationApi;

    /**
     * 初始化租户端同步平台端的配置。这里的配置一般是跟代码修改紧密相关的，
     * 平台修改了配置理论上代码也应该会做调整，这种配置不应该来让租户来进行维护，但是考虑到租户配置的个性化，租户可以进行值得修改，比如主题颜色配置
     * 由平台默认的蓝色改为绿色，或者自定义是否开启验证码等。
     * 添加跟删除的操作交给平台同步给租户，租户只能修改键的值，租户端key不能改，只改值
     */
    @Override
    public void initTenantConfig() {
        // 获取所有配置列表
        List<ConfigDO> configList = configMapper.selectAllList();
        if (CollUtil.isEmpty(configList)) {
            return;
        }
        List<Long> idList = tenantApi.getTenantIds();
        if (idList.isEmpty()) {
            return;
        }
        idList.forEach(tenantId -> {
            this.createOrDel(tenantId, configList);
        });
    }

    private void createOrDel(Long tenantId, List<ConfigDO> configList) {
        TenantUtils.execute(tenantId, () -> {
            configurationApi.createOrDel(ConfigConvert.INSTANCE.convertListDTO(configList));
        });
    }

    @Override
    public Long createConfig(ConfigCreateReqVO reqVO) {
        // 校验正确性
        checkCreateOrUpdate(null, reqVO.getKey());
        // 插入参数配置
        ConfigDO config = ConfigConvert.INSTANCE.convert(reqVO);
        config.setType(ConfigTypeEnum.CUSTOM.getType());
        configMapper.insert(config);
        // 发送刷新消息
        configProducer.sendConfigRefreshMessage();
        return config.getId();
    }

    @Override
    public void updateConfig(ConfigUpdateReqVO reqVO) {
        // 校验正确性
        checkCreateOrUpdate(reqVO.getId(), null); // 不允许更新 key
        // 更新参数配置
        ConfigDO updateObj = ConfigConvert.INSTANCE.convert(reqVO);
        configMapper.updateById(updateObj);
        // 发送刷新消息
        configProducer.sendConfigRefreshMessage();
    }

    @Override
    public void deleteConfig(Long id) {
        // 校验配置存在
        ConfigDO config = checkConfigExists(id);
        // 内置配置，不允许删除
        if (ConfigTypeEnum.SYSTEM.getType().equals(config.getType())) {
            throw ServiceExceptionUtil.exception(ErrorCodeConstants.CONFIG_CAN_NOT_DELETE_SYSTEM_TYPE);
        }
        // 删除
        configMapper.deleteById(id);
        // 发送刷新消息
        configProducer.sendConfigRefreshMessage();
    }

    @Override
    public ConfigDO getConfig(Long id) {
        return configMapper.selectById(id);
    }

    @Override
    public ConfigDO getConfigByKey(String key) {
        return configMapper.selectByKey(key);
    }

    @Override
    public PageResult<ConfigDO> getConfigPage(ConfigPageReqVO reqVO) {
        return configMapper.selectPage(reqVO);
    }

    @Override
    public List<ConfigDO> getConfigList(ConfigExportReqVO reqVO) {
        return configMapper.selectList(reqVO);
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
    public ConfigDO checkConfigExists(Long id) {
        if (id == null) {
            return null;
        }
        ConfigDO config = configMapper.selectById(id);
        if (config == null) {
            throw ServiceExceptionUtil.exception(ErrorCodeConstants.CONFIG_NOT_EXISTS);
        }
        return config;
    }

    @VisibleForTesting
    public void checkConfigKeyUnique(Long id, String key) {
        ConfigDO config = configMapper.selectByKey(key);
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
