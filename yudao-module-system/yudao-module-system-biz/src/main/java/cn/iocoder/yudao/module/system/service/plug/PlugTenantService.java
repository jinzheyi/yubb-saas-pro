package cn.iocoder.yudao.module.system.service.plug;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.system.api.plug.dto.tenant.PlugAppEnableReqDTO;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.tenant.PlugTenantPageReqVO;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.tenant.PlugTenantRespVO;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.tenant.PlugTenantUpdateReqVO;
import cn.iocoder.yudao.module.system.dal.dataobject.plug.PlugTenantDO;
import com.baomidou.mybatisplus.extension.service.IService;

import javax.validation.Valid;

/**
 * 租户应用 Service 接口
 *
 * @author zhusy
 */
public interface PlugTenantService extends IService<PlugTenantDO> {

    /**
     * 更新租户应用
     *
     * @param updateReqVO 更新信息
     */
    void updateTenant(@Valid PlugTenantUpdateReqVO updateReqVO);

    /**
     * 运营端禁用所有租户的对应插件应用
     * @param reqDTO 入参
     * @return 结果
     */
    boolean enableTenantApp(@Valid PlugAppEnableReqDTO reqDTO);

    /**
     * 获得租户应用
     *
     * @param id 编号
     * @return 租户应用
     */
    PlugTenantRespVO getTenant(Long id);

    /**
     * 获得租户应用
     *
     * @param plugAppId 插件应用id
     * @return 租户应用
     */
    PlugTenantDO getPlugTenant(Long plugAppId);

    /**
     * 获得租户应用分页
     *
     * @param pageReqVO 分页查询
     * @return 租户应用分页
     */
    PageResult<PlugTenantRespVO> getTenantPage(PlugTenantPageReqVO pageReqVO);

    /**
     * 访问时判断是否购买了该插件，可以判断多个插件标识
     *
     * @param userId 当前访问用户id
     * @param plugAppSn 一个或多个插件应用编码
     * @return true 通过 false 不通过
     */
    boolean hasAllPlugApp(Long userId, String... plugAppSn);

}
