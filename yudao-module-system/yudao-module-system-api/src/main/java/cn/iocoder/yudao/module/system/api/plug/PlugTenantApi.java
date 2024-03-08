package cn.iocoder.yudao.module.system.api.plug;

import cn.iocoder.yudao.module.system.api.plug.dto.tenant.PlugAppEnableReqDTO;

import javax.validation.Valid;

/**
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2023/4/15 15:28
 */
public interface PlugTenantApi {

    /**
     * 访问时判断是否购买了该插件，可以判断多个插件标识
     *
     * @param userId 当前访问用户id
     * @param plugAppSn 一个活多个插件应用编码
     * @return true 通过 false 不通过
     */
    boolean hasAllPlugApp(Long userId, String... plugAppSn);

    /**
     * 禁用所有租户的对应插件应用
     * @param reqDTO 入参
     * @return 结果
     */
    boolean enableTenantApp(@Valid PlugAppEnableReqDTO reqDTO);

}
