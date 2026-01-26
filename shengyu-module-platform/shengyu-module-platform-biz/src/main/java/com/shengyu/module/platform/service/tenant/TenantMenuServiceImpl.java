package com.shengyu.module.platform.service.tenant;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.framework.common.util.collection.CollectionUtils.convertList;
import static com.shengyu.module.system.enums.ErrorCodeConstants.*;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.enums.CommonConstants;
import com.shengyu.framework.common.enums.permission.MenuIdEnum;
import com.shengyu.framework.common.enums.permission.MenuTypeEnum;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.platform.controller.platform.tenant.vo.menu.TenantMenuCreateReqVO;
import com.shengyu.module.platform.controller.platform.tenant.vo.menu.TenantMenuListReqVO;
import com.shengyu.module.platform.controller.platform.tenant.vo.menu.TenantMenuUpdateReqVO;
import com.shengyu.module.platform.dal.dataobject.plug.PlugAppDO;
import com.shengyu.module.platform.dal.dataobject.tenant.TenantMenuDO;
import com.shengyu.module.platform.dal.mysql.tenant.TenantMenuMapper;
import com.shengyu.module.platform.dal.redis.RedisKeyConstants;
import com.shengyu.module.platform.service.plug.PlugAppService;
import com.shengyu.module.system.api.permission.PermissionApi;
import com.google.common.annotations.VisibleForTesting;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import javax.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 租户菜单 Service 实现
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class TenantMenuServiceImpl implements TenantMenuService {

    @Resource
    private TenantMenuMapper tenantMenuMapper;

    @Resource
    private PermissionApi permissionApi;

    @Resource
    private PlugAppService plugAppService;

    @Override
    @CacheEvict(value = RedisKeyConstants.TENANT_PERMISSION_MENU_ID_LIST, key = "#reqVO.permission",
        condition = "#reqVO.permission != null")
    public Long createMenu(TenantMenuCreateReqVO reqVO) {
        // 校验父菜单存在
        validateParentMenu(reqVO.getParentId(), null);
        // 校验菜单（自己）
        validateMenu(reqVO.getParentId(), reqVO.getName(), null);
        // 校验组件名是否重复
        validateMenuComponentName(reqVO.getComponentName(), null);
        //校验插件菜单
        validatePlugMenu(reqVO.getDimension(), reqVO.getPlugAppSn());

        // 插入数据库
        TenantMenuDO menu = BeanUtils.toBean(reqVO, TenantMenuDO.class);
        initMenuProperty(menu);
        tenantMenuMapper.insert(menu);
        // 返回
        return menu.getId();
    }

    @Override
    @CacheEvict(value = RedisKeyConstants.TENANT_PERMISSION_MENU_ID_LIST,
        allEntries = true) // allEntries 清空所有缓存，因为 permission 如果变更，涉及到新老两个 permission。直接清理，简单有效
    public void updateMenu(TenantMenuUpdateReqVO reqVO) {
        // 校验更新的菜单是否存在
        if (tenantMenuMapper.selectById(reqVO.getId()) == null) {
            throw exception(MENU_NOT_EXISTS);
        }
        // 校验父菜单存在
        validateParentMenu(reqVO.getParentId(), reqVO.getId());
        // 校验菜单（自己）
        validateMenu(reqVO.getParentId(), reqVO.getName(), reqVO.getId());
        // 校验组件名是否重复
        validateMenuComponentName(reqVO.getComponentName(), reqVO.getId());
        //校验插件菜单
        validatePlugMenu(reqVO.getDimension(), reqVO.getPlugAppSn());

        // 更新到数据库
        TenantMenuDO updateObject = BeanUtils.toBean(reqVO, TenantMenuDO.class);
        initMenuProperty(updateObject);
        tenantMenuMapper.updateById(updateObject);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @CacheEvict(value = RedisKeyConstants.TENANT_PERMISSION_MENU_ID_LIST,
        allEntries = true) // allEntries 清空所有缓存，因为此时不知道 id 对应的 permission 是多少。直接清理，简单有效
    public void deleteMenu(Long menuId) {
        // 校验是否还有子菜单
        if (tenantMenuMapper.selectCountByParentId(menuId) > 0) {
            throw exception(MENU_EXISTS_CHILDREN);
        }
        // 校验删除的菜单是否存在
        if (tenantMenuMapper.selectById(menuId) == null) {
            throw exception(MENU_NOT_EXISTS);
        }
        //校验该菜单是否有租户在使用
        this.validateTenantRoleMenu(menuId);
        // 标记删除
        tenantMenuMapper.deleteById(menuId);
        // 删除授予给角色的权限
        permissionApi.processMenuDeleted(menuId);
    }

    @Override
    public List<TenantMenuDO> getMenuList(TenantMenuListReqVO reqVO) {
        if (CollUtil.isNotEmpty(reqVO.getPlugIds())) {
            reqVO.setPlugAppSns(plugAppService.getPlugAppList(reqVO.getPlugIds(), null).stream().map(PlugAppDO::getAppSn).collect(
                Collectors.toList()));
        }
        return tenantMenuMapper.selectList(reqVO);
    }

    @Override
    @Cacheable(value = RedisKeyConstants.TENANT_PERMISSION_MENU_ID_LIST, key = "#permission")
    public List<Long> getMenuIdListByPermissionFromCache(String permission) {
        List<TenantMenuDO> menus = tenantMenuMapper.selectListByPermission(permission);
        return convertList(menus, TenantMenuDO::getId);
    }

    @Override
    public TenantMenuDO getMenu(Long id) {
        return tenantMenuMapper.selectById(id);
    }

    /**
     * 校验父菜单是否合法
     * <p>
     * 1. 不能设置自己为父菜单 2. 父菜单不存在 3. 父菜单必须是 {@link MenuTypeEnum#MENU} 菜单类型
     *
     * @param parentId 父菜单编号
     * @param childId  当前菜单编号
     */
    @VisibleForTesting
    void validateParentMenu(Long parentId, Long childId) {
        if (parentId == null || MenuIdEnum.ROOT.getId().equals(parentId)) {
            return;
        }
        // 不能设置自己为父菜单
        if (parentId.equals(childId)) {
            throw exception(MENU_PARENT_ERROR);
        }
        TenantMenuDO menu = tenantMenuMapper.selectById(parentId);
        // 父菜单不存在
        if (menu == null) {
            throw exception(MENU_PARENT_NOT_EXISTS);
        }
        // 父菜单必须是目录或者菜单类型
        if (!MenuTypeEnum.DIR.getType().equals(menu.getType())
            && !MenuTypeEnum.MENU.getType().equals(menu.getType())) {
            throw exception(MENU_PARENT_NOT_DIR_OR_MENU);
        }
    }

    /**
     * 校验菜单是否合法
     * <p>
     * 1. 校验相同父菜单编号下，是否存在相同的菜单名
     *
     * @param name     菜单名字
     * @param parentId 父菜单编号
     * @param id       菜单编号
     */
    @VisibleForTesting
    void validateMenu(Long parentId, String name, Long id) {
        TenantMenuDO menu = tenantMenuMapper.selectByParentIdAndName(parentId, name);
        if (menu == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同 id 的菜单
        if (id == null) {
            throw exception(MENU_NAME_DUPLICATE);
        }
        if (!menu.getId().equals(id)) {
            throw exception(MENU_NAME_DUPLICATE);
        }
    }

    /**
     * 校验菜单组件名是否合法
     *
     * @param componentName 组件名
     * @param id            菜单编号
     */
    @VisibleForTesting
    void validateMenuComponentName(String componentName, Long id) {
        if (StrUtil.isBlank(componentName)) {
            return;
        }
        TenantMenuDO menu = tenantMenuMapper.selectByComponentName(componentName);
        if (menu == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同 id 的菜单
        if (id == null) {
            throw exception(MENU_COMPONENT_NAME_DUPLICATE);
        }
        if (!menu.getId().equals(id)) {
            throw exception(MENU_COMPONENT_NAME_DUPLICATE);
        }
    }

    /**
     * 校验插件菜单
     *
     * @param dimension 菜单维度
     * @param plugAppSn 应用插件条码
     */
    @VisibleForTesting
    void validatePlugMenu(Integer dimension, String plugAppSn) {
        if (CommonConstants.MenuDimensionEnum.MENU.getCode().equals(dimension)) {
            return;
        }
        if (CommonConstants.MenuDimensionEnum.PLUG.getCode().equals(dimension)) {
            if (StrUtil.isBlank(plugAppSn)) {
                throw exception(PLUG_APP_MENU);
            }
            Optional.ofNullable(plugAppService.getPlugAppBySn(plugAppSn))
                .orElseThrow(() -> exception(PLUG_APP_NOT_EXISTS));
        }
    }

    /**
     * 初始化菜单的通用属性。
     * <p>
     * 例如说，只有目录或者菜单类型的菜单，才设置 icon
     *
     * @param menu 菜单
     */
    private void initMenuProperty(TenantMenuDO menu) {
        // 菜单为按钮类型时，无需 component、icon、path 属性，进行置空
        if (MenuTypeEnum.BUTTON.getType().equals(menu.getType())) {
            menu.setComponent("");
            menu.setComponentName("");
            menu.setIcon("");
            menu.setPath("");
        }
    }

    /**
     * 校验该菜单是否有租户角色在使用
     *
     * @param menuId 菜单id
     */
    private void validateTenantRoleMenu(Long menuId) {
        if (permissionApi.hasAnyRoleMenu(menuId)) {
            throw exception(TENANT_MENU_USED);
        }
    }

}
