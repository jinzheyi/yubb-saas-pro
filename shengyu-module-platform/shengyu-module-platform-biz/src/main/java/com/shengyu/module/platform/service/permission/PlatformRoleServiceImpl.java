package com.shengyu.module.platform.service.permission;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.framework.common.util.collection.CollectionUtils.convertList;
import static com.shengyu.framework.common.util.collection.CollectionUtils.convertMap;
import static com.shengyu.module.system.enums.ErrorCodeConstants.ROLE_CAN_NOT_UPDATE_SYSTEM_TYPE_ROLE;
import static com.shengyu.module.system.enums.ErrorCodeConstants.ROLE_CODE_DUPLICATE;
import static com.shengyu.module.system.enums.ErrorCodeConstants.ROLE_IS_DISABLE;
import static com.shengyu.module.system.enums.ErrorCodeConstants.ROLE_NAME_DUPLICATE;
import static com.shengyu.module.system.enums.ErrorCodeConstants.ROLE_NOT_EXISTS;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.collection.CollectionUtil;
import cn.hutool.core.util.ObjectUtil;
import cn.hutool.extra.spring.SpringUtil;
import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.enums.permission.DataScopeEnum;
import com.shengyu.framework.common.enums.permission.RoleTypeEnum;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.platform.controller.platform.permission.vo.role.RoleCreateReqVO;
import com.shengyu.module.platform.controller.platform.permission.vo.role.RoleExportReqVO;
import com.shengyu.module.platform.controller.platform.permission.vo.role.RolePageReqVO;
import com.shengyu.module.platform.controller.platform.permission.vo.role.RoleUpdateReqVO;
import com.shengyu.module.platform.dal.dataobject.permission.PlatformRoleDO;
import com.shengyu.module.platform.dal.mysql.permission.PlatformRoleMapper;
import com.shengyu.module.platform.dal.redis.RedisKeyConstants;
import com.google.common.annotations.VisibleForTesting;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;
import javax.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

/**
 * 角色 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class PlatformRoleServiceImpl implements PlatformRoleService {

    @Resource
    private PlatformPermissionService platformPermissionService;

    @Resource
    private PlatformRoleMapper platformRoleMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createRole(RoleCreateReqVO reqVO, Integer type) {
        // 校验角色
        validateRoleDuplicate(reqVO.getName(), reqVO.getCode(), null);
        // 插入到数据库
        PlatformRoleDO role = BeanUtils.toBean(reqVO, PlatformRoleDO.class);
        role.setType(ObjectUtil.defaultIfNull(type, RoleTypeEnum.CUSTOM.getType()));
        role.setStatus(CommonStatusEnum.ENABLE.getStatus());
        role.setDataScope(DataScopeEnum.ALL.getScope()); // 默认可查看所有数据。原因是，可能一些项目不需要项目权限
        platformRoleMapper.insert(role);
        // 返回
        return role.getId();
    }

    @Override
    @CacheEvict(value = RedisKeyConstants.ROLE, key = "#reqVO.id")
    public void updateRole(RoleUpdateReqVO reqVO) {
        // 校验是否可以更新
        validateRoleForUpdate(reqVO.getId());
        // 校验角色的唯一字段是否重复
        validateRoleDuplicate(reqVO.getName(), reqVO.getCode(), reqVO.getId());

        // 更新到数据库
        PlatformRoleDO updateObj = BeanUtils.toBean(reqVO, PlatformRoleDO.class);
        platformRoleMapper.updateById(updateObj);
    }

    @Override
    @CacheEvict(value = RedisKeyConstants.ROLE, key = "#id")
    public void updateRoleStatus(Long id, Integer status) {
        // 校验是否可以更新
        validateRoleForUpdate(id);

        // 更新状态
        PlatformRoleDO updateObj = new PlatformRoleDO().setId(id).setStatus(status);
        platformRoleMapper.updateById(updateObj);
    }

    @Override
    @CacheEvict(value = RedisKeyConstants.ROLE, key = "#id")
    public void updateRoleDataScope(Long id, Integer dataScope, Set<Long> dataScopeDeptIds) {
        // 校验是否可以更新
        validateRoleForUpdate(id);

        // 更新数据范围
        PlatformRoleDO updateObject = new PlatformRoleDO();
        updateObject.setId(id);
        updateObject.setDataScope(dataScope);
        updateObject.setDataScopeDeptIds(dataScopeDeptIds);
        platformRoleMapper.updateById(updateObject);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @CacheEvict(value = RedisKeyConstants.ROLE, key = "#id")
    public void deleteRole(Long id) {
        // 校验是否可以更新
        validateRoleForUpdate(id);
        // 标记删除
        platformRoleMapper.deleteById(id);
        // 删除相关数据
        platformPermissionService.processRoleDeleted(id);
    }

    /**
     * 校验角色的唯一字段是否重复
     * 1. 是否存在相同名字的角色
     * 2. 是否存在相同编码的角色
     *
     * @param name 角色名字
     * @param code 角色额编码
     * @param id 角色编号
     */
    @VisibleForTesting
    void validateRoleDuplicate(String name, String code, Long id) {
        // 1. 该 name 名字被其它角色所使用
        PlatformRoleDO role = platformRoleMapper.selectByName(name);
        if (role != null && !role.getId().equals(id)) {
            throw exception(ROLE_NAME_DUPLICATE, name);
        }
        // 2. 是否存在相同编码的角色
        if (!StringUtils.hasText(code)) {
            return;
        }
        // 该 code 编码被其它角色所使用
        role = platformRoleMapper.selectByCode(code);
        if (role != null && !role.getId().equals(id)) {
            throw exception(ROLE_CODE_DUPLICATE, code);
        }
    }

    /**
     * 校验角色是否可以被更新
     *
     * @param id 角色编号
     */
    @VisibleForTesting
    void validateRoleForUpdate(Long id) {
        PlatformRoleDO roleDO = platformRoleMapper.selectById(id);
        if (roleDO == null) {
            throw exception(ROLE_NOT_EXISTS);
        }
        // 内置角色，不允许删除
        if (RoleTypeEnum.SYSTEM.getType().equals(roleDO.getType())) {
            throw exception(ROLE_CAN_NOT_UPDATE_SYSTEM_TYPE_ROLE);
        }
    }

    @Override
    public PlatformRoleDO getRole(Long id) {
        return platformRoleMapper.selectById(id);
    }

    @Override
    @Cacheable(value = RedisKeyConstants.ROLE, key = "#id",
        unless = "#result == null")
    public PlatformRoleDO getRoleFromCache(Long id) {
        return platformRoleMapper.selectById(id);
    }


    @Override
    public List<PlatformRoleDO> getRoleListByStatus(Collection<Integer> statuses) {
        return platformRoleMapper.selectListByStatus(statuses);
    }

    @Override
    public List<PlatformRoleDO> getRoleList() {
        return platformRoleMapper.selectList();
    }

    @Override
    public List<PlatformRoleDO> getRoleList(Collection<Long> ids) {
        if (CollectionUtil.isEmpty(ids)) {
            return Collections.emptyList();
        }
        return platformRoleMapper.selectBatchIds(ids);
    }

    @Override
    public List<PlatformRoleDO> getRoleListFromCache(Collection<Long> ids) {
        if (CollectionUtil.isEmpty(ids)) {
            return Collections.emptyList();
        }
        // 这里采用 for 循环从缓存中获取，主要考虑 Spring CacheManager 无法批量操作的问题
        PlatformRoleServiceImpl self = getSelf();
        return convertList(ids, self::getRoleFromCache);
    }

    @Override
    public PageResult<PlatformRoleDO> getRolePage(RolePageReqVO reqVO) {
        return platformRoleMapper.selectPage(reqVO);
    }

    @Override
    public List<PlatformRoleDO> getRoleList(RoleExportReqVO reqVO) {
        return platformRoleMapper.selectList(reqVO);
    }

    @Override
    public void validateRoleList(Collection<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return;
        }
        // 获得角色信息
        List<PlatformRoleDO> roles = platformRoleMapper.selectBatchIds(ids);
        Map<Long, PlatformRoleDO> roleMap = convertMap(roles, PlatformRoleDO::getId);
        // 校验
        ids.forEach(id -> {
            PlatformRoleDO role = roleMap.get(id);
            if (role == null) {
                throw exception(ROLE_NOT_EXISTS);
            }
            if (!CommonStatusEnum.ENABLE.getStatus().equals(role.getStatus())) {
                throw exception(ROLE_IS_DISABLE, role.getName());
            }
        });
    }

    /**
     * 获得自身的代理对象，解决 AOP 生效问题
     *
     * @return 自己
     */
    private PlatformRoleServiceImpl getSelf() {
        return SpringUtil.getBean(getClass());
    }
}
