package cn.iocoder.yudao.framework.security.core.service;

/**
 * Security 框架 Service 接口，定义权限相关的校验操作
 *
 * @author 圣钰科技
 */
public interface SecurityFrameworkService {

    /**
     * 判断是否有权限
     *
     * @param permission 权限
     * @return 是否
     */
    boolean hasPermission(String permission);

    /**
     * 判断是否有权限，任一一个即可
     *
     * @param permissions 权限
     * @return 是否
     */
    boolean hasAnyPermissions(String... permissions);

    /**
     * 判断是否有角色
     *
     * 注意，角色使用的是 SysRoleDO 的 code 标识
     *
     * @param role 角色
     * @return 是否
     */
    boolean hasRole(String role);

    /**
     * 判断是否有角色，任一一个即可
     *
     * @param roles 角色数组
     * @return 是否
     */
    boolean hasAnyRoles(String... roles);

    /**
     * 判断是否有授权
     *
     * @param scope 授权
     * @return 是否
     */
    boolean hasScope(String scope);

    /**
     * 判断是否有授权范围，任一一个即可
     *
     * @param scope 授权范围数组
     * @return 是否
     */
    boolean hasAnyScopes(String... scope);

    /**
     * 访问时判断是否购买了该插件，可以判断多个插件标识
     * @param plugAppSn 插件编码
     * @return true 通过 false 不通过
     */
    boolean hasAllPlugApp(String... plugAppSn);

}
