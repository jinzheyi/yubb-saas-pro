package com.shengyu.module.platform.api.plug;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.platform.api.plug.dto.PlugAppPageReqDTO;
import com.shengyu.module.platform.api.plug.dto.PlugAppRespDTO;
import com.shengyu.module.platform.api.plug.dto.PlugAppSimpleRespDTO;

import java.util.List;

/**
 * @Description 插件api接口
 * @Author zhusy
 * @Date 2023/4/13 10:56
 * @Version 1.0
 **/
public interface PlugAppApi {

    /**
     * 通过插件 ID 查询插件app
     *
     * @param id 插件ID
     * @return 插件对象信息
     */
    PlugAppRespDTO getPlugApp(Long id);

    /**
     * 根据插件应用id集合或应用编码查询插件列表，两个参数不能全为空
     * @param ids 应用ids
     * @param appSns 应用编码
     * @return 插件列表
     */
    List<PlugAppSimpleRespDTO> getPlugAppList(List<Long> ids, List<String> appSns);

    /**
     * 查询插件分页列表
     * @param reqDTO 入参
     * @return 插件列表
     */
    PageResult<PlugAppSimpleRespDTO> getPlugAppPage(PlugAppPageReqDTO reqDTO);

}
