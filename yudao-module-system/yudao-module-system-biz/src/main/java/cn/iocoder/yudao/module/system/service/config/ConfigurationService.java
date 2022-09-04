package cn.iocoder.yudao.module.system.service.config;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.system.controller.admin.config.vo.ConfigCreateOrDelReqVO;
import cn.iocoder.yudao.module.system.controller.admin.config.vo.ConfigPageReqVO;
import cn.iocoder.yudao.module.system.controller.admin.config.vo.ConfigUpdateReqVO;
import cn.iocoder.yudao.module.system.dal.dataobject.config.ConfigurationDO;
import com.baomidou.mybatisplus.extension.service.IService;

import javax.validation.Valid;
import java.util.List;

/**
 * 参数配置 Service 接口
 *
 * @author 芋道源码
 */
public interface ConfigurationService extends IService<ConfigurationDO> {

    /**
     * 创建参数配置
     *
     * @param reqVOList 创建信息
     * @return 配置编号
     */
    void createOrDel(@Valid List<ConfigCreateOrDelReqVO> reqVOList);

    /**
     * 更新参数配置
     *
     * @param reqVO 更新信息
     */
    void updateConfig(@Valid ConfigUpdateReqVO reqVO);

    /**
     * 获得参数配置
     *
     * @param id 配置编号
     * @return 参数配置
     */
    ConfigurationDO getConfig(Long id);

    /**
     * 根据参数键，获得参数配置
     *
     * @param key 配置键
     * @return 参数配置
     */
    ConfigurationDO getConfigByKey(String key);

    /**
     * 获得参数配置分页列表
     *
     * @param reqVO 分页条件
     * @return 分页列表
     */
    PageResult<ConfigurationDO> getConfigPage(@Valid ConfigPageReqVO reqVO);

    /**
     * 根据参数键，获得参数配置
     *
     * @param key 配置键
     * @return 参数配置
     */
    ConfigurationDO getTenantConfigByKey(String key);

}
