package com.shengyu.module.system.service.plug;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.system.controller.admin.plug.vo.app.PlugAppBuyReqVO;
import com.shengyu.module.system.controller.admin.plug.vo.app.PlugAppPageReqVO;
import com.shengyu.module.system.controller.admin.plug.vo.app.PlugAppRespVO;
import com.shengyu.module.system.controller.admin.plug.vo.app.PlugAppSimpleRespVO;

import javax.validation.Valid;

/**
 * @Description 插件市场服务接口
 * @Author zhusy
 * @Date 2023/4/13 15:26
 * @Version 1.0
 **/
public interface PlugAppApiService {

    /**
     * 通过插件 ID 查询插件app
     *
     * @param id 插件ID
     * @return 插件对象信息
     */
    PlugAppRespVO getPlugApp(Long id);

    /**
     * 查询插件分页列表
     * @param reqVO 入参
     */
    PageResult<PlugAppSimpleRespVO> getPlugAppList(PlugAppPageReqVO reqVO);

    /**
     * 下单购买插件
     * @param reqVO 入参信息
     * @return 订单id
     */
    Long buyPlugApp(@Valid PlugAppBuyReqVO reqVO);

}
