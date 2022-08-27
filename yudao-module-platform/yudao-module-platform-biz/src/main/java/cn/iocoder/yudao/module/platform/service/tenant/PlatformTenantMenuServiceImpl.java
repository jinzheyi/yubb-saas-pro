package cn.iocoder.yudao.module.platform.service.tenant;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil;
import cn.iocoder.yudao.framework.common.util.collection.CollectionUtils;
import cn.iocoder.yudao.framework.tenant.core.aop.TenantIgnore;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.menu.TenantMenuCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.menu.TenantMenuListReqVO;
import cn.iocoder.yudao.module.platform.controller.center.tenant.vo.menu.TenantMenuUpdateReqVO;
import cn.iocoder.yudao.module.platform.convert.tenant.TenantMenuConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.tenant.TenantMenuDO;
import cn.iocoder.yudao.module.platform.dal.mysql.tenant.PlatformTenantMenuMapper;
import cn.iocoder.yudao.framework.common.enums.permission.MenuIdEnum;
import cn.iocoder.yudao.framework.common.enums.permission.MenuTypeEnum;
import cn.iocoder.yudao.module.platform.mq.producer.tenant.PlatformTenantMenuProducer;
import cn.iocoder.yudao.module.system.api.permission.PermissionApi;
import com.google.common.annotations.VisibleForTesting;
import com.google.common.collect.ImmutableMap;
import com.google.common.collect.ImmutableMultimap;
import com.google.common.collect.Multimap;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Lazy;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import javax.annotation.PostConstruct;
import javax.annotation.Resource;
import java.util.*;
import java.util.stream.Collectors;

import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.*;

/**
 * 菜单 Service 实现
 *
 * @author 芋道源码
 */
@Service
@Slf4j
public class PlatformTenantMenuServiceImpl implements PlatformTenantMenuService {

    /**
     * 定时执行 {@link #schedulePeriodicRefresh()} 的周期
     * 因为已经通过 Redis Pub/Sub 机制，所以频率不需要高
     */
    private static final long SCHEDULER_PERIOD = 5 * 60 * 1000L;

    /**
     * 菜单缓存
     * key：菜单编号
     *
     * 这里声明 volatile 修饰的原因是，每次刷新时，直接修改指向
     */
    private volatile Map<Long, TenantMenuDO> menuCache;
    /**
     * 权限与菜单缓存
     * key：权限 {@link TenantMenuDO#getPermission()}
     * value：MenuDO 数组，因为一个权限可能对应多个 MenuDO 对象
     *
     * 这里声明 volatile 修饰的原因是，每次刷新时，直接修改指向
     */
    private volatile Multimap<String, TenantMenuDO> permissionMenuCache;
    /**
     * 缓存菜单的最大更新时间，用于后续的增量轮询，判断是否有更新
     */
    private volatile Date maxUpdateTime;

    @Resource
    private PlatformTenantMenuMapper platformTenantMenuMapper;

    @Resource
    private PermissionApi permissionApi;

    @Resource
    @Lazy // 延迟，避免循环依赖报错
    private PlatformTenantService platformTenantService;

    @Resource
    private PlatformTenantMenuProducer platformTenantMenuProducer;

    /**
     * 初始化 {@link #menuCache} 和 {@link #permissionMenuCache} 缓存
     */
    @Override
    @PostConstruct
    public synchronized void initLocalCache() {
        // 获取菜单列表，如果有更新
        List<TenantMenuDO> menuList = this.loadMenuIfUpdate(maxUpdateTime);
        if (CollUtil.isEmpty(menuList)) {
            return;
        }

        // 构建缓存
        ImmutableMap.Builder<Long, TenantMenuDO> menuCacheBuilder = ImmutableMap.builder();
        ImmutableMultimap.Builder<String, TenantMenuDO> permMenuCacheBuilder = ImmutableMultimap.builder();
        menuList.forEach(menuDO -> {
            menuCacheBuilder.put(menuDO.getId(), menuDO);
            if (StrUtil.isNotEmpty(menuDO.getPermission())) { // 会存在 permission 为 null 的情况，导致 put 报 NPE 异常
                permMenuCacheBuilder.put(menuDO.getPermission(), menuDO);
            }
        });
        menuCache = menuCacheBuilder.build();
        permissionMenuCache = permMenuCacheBuilder.build();
        maxUpdateTime = CollectionUtils.getMaxValue(menuList, TenantMenuDO::getUpdateTime);
        log.info("[initLocalCache][缓存菜单，数量为:{}]", menuList.size());
    }

    /**
     * fixedDelay控制方法执行的间隔时间(毫秒)，是以上一次方法执行完开始算起，如上一次方法执行阻塞住了，那么直到上一次执行完，
     * 并间隔给定的时间后，执行下一次。上个过程结束后，等待300ms，执行下个过程
     *
     * initialDelay 如： @Scheduled(initialDelay = 10000,fixedRate = 15000,
     * 这个定时器就是在上一个的基础上加了一个initialDelay = 10000 意思就是在容器启动后,延迟10秒后再执行一次定时器,以后每15秒再执行一次该定时器。
     */
    @Scheduled(fixedDelay = SCHEDULER_PERIOD, initialDelay = SCHEDULER_PERIOD)
    public void schedulePeriodicRefresh() {
        initLocalCache();
    }

    /**
     * 如果菜单发生变化，从数据库中获取最新的全量菜单。
     * 如果未发生变化，则返回空
     *
     * @param maxUpdateTime 当前菜单的最大更新时间
     * @return 菜单列表
     */
    private List<TenantMenuDO> loadMenuIfUpdate(Date maxUpdateTime) {
        // 第一步，判断是否要更新。
        if (maxUpdateTime == null) { // 如果更新时间为空，说明 DB 一定有新数据
            log.info("[loadMenuIfUpdate][首次加载全量菜单]");
        } else { // 判断数据库中是否有更新的菜单
            if (platformTenantMenuMapper.selectCountByUpdateTimeGt(maxUpdateTime) == 0) {
                return null;
            }
            log.info("[loadMenuIfUpdate][增量加载全量菜单]");
        }
        // 第二步，如果有更新，则从数据库加载所有菜单
        return platformTenantMenuMapper.selectList();
    }

    @Override
    public Long createMenu(TenantMenuCreateReqVO reqVO) {
        // 校验父菜单存在
        checkParentResource(reqVO.getParentId(), null);
        // 校验菜单（自己）
        checkResource(reqVO.getParentId(), reqVO.getName(), null);
        // 插入数据库
        TenantMenuDO menu = TenantMenuConvert.INSTANCE.convert(reqVO);
        initMenuProperty(menu);
        platformTenantMenuMapper.insert(menu);
        // 发送刷新消息
        platformTenantMenuProducer.sendMenuRefreshMessage();
        // 返回
        return menu.getId();
    }

    @Override
    public void updateMenu(TenantMenuUpdateReqVO reqVO) {
        // 校验更新的菜单是否存在
        if (platformTenantMenuMapper.selectById(reqVO.getId()) == null) {
            throw ServiceExceptionUtil.exception(MENU_NOT_EXISTS);
        }
        // 校验父菜单存在
        checkParentResource(reqVO.getParentId(), reqVO.getId());
        // 校验菜单（自己）
        checkResource(reqVO.getParentId(), reqVO.getName(), reqVO.getId());
        // 更新到数据库
        TenantMenuDO updateObject = TenantMenuConvert.INSTANCE.convert(reqVO);
        initMenuProperty(updateObject);
        platformTenantMenuMapper.updateById(updateObject);
        // 发送刷新消息
        platformTenantMenuProducer.sendMenuRefreshMessage();
    }

    /**
     * 删除菜单
     *
     * @param menuId 菜单编号
     */
    @Transactional(rollbackFor = Exception.class)
    @Override
    @TenantIgnore
    public void deleteMenu(Long menuId) {
        // 校验是否还有子菜单
        if (platformTenantMenuMapper.selectCountByParentId(menuId) > 0) {
            throw ServiceExceptionUtil.exception(MENU_EXISTS_CHILDREN);
        }
        // 校验删除的菜单是否存在
        if (platformTenantMenuMapper.selectById(menuId) == null) {
            throw ServiceExceptionUtil.exception(MENU_NOT_EXISTS);
        }
        //校验该菜单是否有租户在使用
        this.validateRoleMenu(menuId);
        // 标记删除
        platformTenantMenuMapper.deleteById(menuId);
        // 删除授予给角色的权限
        permissionApi.processMenuDeleted(menuId);
        // 发送刷新消息. 注意，需要事务提交后，在进行发送刷新消息。不然 db 还未提交，结果缓存先刷新了
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {

            @Override
            public void afterCommit() {
                platformTenantMenuProducer.sendMenuRefreshMessage();
            }

        });
    }

    @Override
    public List<TenantMenuDO> getMenus() {
        return platformTenantMenuMapper.selectList();
    }

    @Override
    public List<TenantMenuDO> getMenus(TenantMenuListReqVO reqVO) {
        return platformTenantMenuMapper.selectList(reqVO);
    }

    @Override
    public List<TenantMenuDO> getMenuListFromCache(Collection<Integer> menuTypes, Collection<Integer> menusStatuses) {
        // 任一一个参数为空，则返回空
        if (CollectionUtils.isAnyEmpty(menuTypes, menusStatuses)) {
            return Collections.emptyList();
        }
        // 创建新数组，避免缓存被修改
        return menuCache.values().stream().filter(menu -> menuTypes.contains(menu.getType())
                && menusStatuses.contains(menu.getStatus()))
                .collect(Collectors.toList());
    }

    @Override
    public List<TenantMenuDO> getMenuListFromCache(Collection<Long> menuIds, Collection<Integer> menuTypes,
                                             Collection<Integer> menusStatuses) {
        // 任一一个参数为空，则返回空
        if (CollectionUtils.isAnyEmpty(menuIds, menuTypes, menusStatuses)) {
            return Collections.emptyList();
        }
        return menuCache.values().stream().filter(menu -> menuIds.contains(menu.getId())
                && menuTypes.contains(menu.getType())
                && menusStatuses.contains(menu.getStatus()))
                .collect(Collectors.toList());
    }

    @Override
    public List<TenantMenuDO> getMenuListByPermissionFromCache(String permission) {
        return new ArrayList<>(permissionMenuCache.get(permission));
    }

    @Override
    public TenantMenuDO getMenu(Long id) {
        return platformTenantMenuMapper.selectById(id);
    }

    /**
     * 校验父菜单是否合法
     *
     * 1. 不能设置自己为父菜单
     * 2. 父菜单不存在
     * 3. 父菜单必须是 {@link MenuTypeEnum#MENU} 菜单类型
     *
     * @param parentId 父菜单编号
     * @param childId 当前菜单编号
     */
    @VisibleForTesting
    public void checkParentResource(Long parentId, Long childId) {
        if (parentId == null || MenuIdEnum.ROOT.getId().equals(parentId)) {
            return;
        }
        // 不能设置自己为父菜单
        if (parentId.equals(childId)) {
            throw ServiceExceptionUtil.exception(MENU_PARENT_ERROR);
        }
        TenantMenuDO menu = platformTenantMenuMapper.selectById(parentId);
        // 父菜单不存在
        if (menu == null) {
            throw ServiceExceptionUtil.exception(MENU_PARENT_NOT_EXISTS);
        }
        // 父菜单必须是目录或者菜单类型
        if (!MenuTypeEnum.DIR.getType().equals(menu.getType())
            && !MenuTypeEnum.MENU.getType().equals(menu.getType())) {
            throw ServiceExceptionUtil.exception(MENU_PARENT_NOT_DIR_OR_MENU);
        }
    }

    /**
     * 校验菜单是否合法
     *
     * 1. 校验相同父菜单编号下，是否存在相同的菜单名
     *
     * @param name 菜单名字
     * @param parentId 父菜单编号
     * @param id 菜单编号
     */
    @VisibleForTesting
    public void checkResource(Long parentId, String name, Long id) {
        TenantMenuDO menu = platformTenantMenuMapper.selectByParentIdAndName(parentId, name);
        if (menu == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同 id 的菜单
        if (id == null) {
            throw ServiceExceptionUtil.exception(MENU_NAME_DUPLICATE);
        }
        if (!menu.getId().equals(id)) {
            throw ServiceExceptionUtil.exception(MENU_NAME_DUPLICATE);
        }
    }

    /**
     * 初始化菜单的通用属性。
     *
     * 例如说，只有目录或者菜单类型的菜单，才设置 icon
     *
     * @param menu 菜单
     */
    private void initMenuProperty(TenantMenuDO menu) {
        // 菜单为按钮类型时，无需 component、icon、path 属性，进行置空
        if (MenuTypeEnum.BUTTON.getType().equals(menu.getType())) {
            menu.setComponent("");
            menu.setIcon("");
            menu.setPath("");
        }
    }

    /**
     * 校验该菜单是否有租户角色在使用
     * @param menuId
     */
    private void validateRoleMenu(Long menuId) {
        if (permissionApi.hasAnyRoleMenu(menuId)) {
            throw ServiceExceptionUtil.exception(TENANT_MENU_USED);
        }
    }

}
