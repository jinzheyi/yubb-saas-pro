package cn.iocoder.yudao.module.platform.service.plug;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.platform.plug.vo.app.*;
import cn.iocoder.yudao.module.platform.dal.dataobject.plug.PlugAppDO;

import javax.validation.Valid;
import java.util.Collection;
import java.util.List;

/**
 * 插件应用 Service 接口
 *
 * @author zhusy
 */
public interface PlugAppService {

    /**
     * 创建插件应用
     *
     * @param createReqVO 创建信息
     * @return 编号
     */
    Long createPlugApp(@Valid PlugAppCreateReqVO createReqVO);

    /**
     * 更新插件应用
     *
     * @param updateReqVO 更新信息
     */
    void updatePlugApp(@Valid PlugAppUpdateReqVO updateReqVO);

    /**
     * 上下架插件应用，影响的是租户不能下单购买
     *
     * @param updateReqVO 更新信息
     */
    void updateStatusPlugApp(@Valid PlugAppUpdateStatusReqVO updateReqVO);

    /**
     * 停用启用插件应用，停用后租户不能使用该插件
     *
     * @param updateReqVO 更新信息
     */
    void updateEnablePlugApp(@Valid PlugAppUpdateEnableReqVO updateReqVO);

    /**
     * 获得插件应用
     *
     * @param id 编号
     * @return 插件应用
     */
    PlugAppDO getPlugApp(Long id);

    /**
     * 根据应用条码获得插件应用
     * @param appSn 条码
     * @return 插件应用
     */
    PlugAppDO getPlugAppBySn(String appSn);

    /**
     * 获得插件应用列表
     *
     * @return 插件应用列表
     */
    List<PlugAppDO> getPlugAppList();

    /**
     * 获得插件应用分页
     *
     * @param pageReqVO 分页查询
     * @return 插件应用分页
     */
    PageResult<PlugAppDO> getPlugAppPage(PlugAppPageReqVO pageReqVO);

    /**
     * 获得插件应用列表, 用于 Excel 导出
     *
     * @param exportReqVO 查询条件
     * @return 插件应用列表
     */
    List<PlugAppDO> getPlugAppList(PlugAppExportReqVO exportReqVO);

    /**
     * 根据插件应用id集合或应用编码查询插件列表，两个参数不能全为空
     * @param ids 应用ids
     * @param appSns 应用编码
     * @return 插件列表
     */
    List<PlugAppDO> getPlugAppList(List<Long> ids, List<String> appSns);

}
