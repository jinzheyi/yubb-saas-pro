package com.shengyu.module.system.api.user;

import static com.shengyu.framework.common.util.collection.CollectionUtils.convertSet;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.ObjUtil;
import com.shengyu.framework.common.enums.permission.RoleCodeEnum;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.system.api.user.dto.AdminUserCreateReqDTO;
import com.shengyu.module.system.api.user.dto.AdminUserRespDTO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserSaveReqVO;
import com.shengyu.module.system.dal.dataobject.dept.DeptDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.service.dept.DeptService;
import com.shengyu.module.system.service.user.AdminUserService;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;

/**
 * Admin 用户 API 实现类
 *
 * @author 圣钰科技
 */
@Service
public class AdminUserApiImpl implements AdminUserApi {

    @Resource
    private AdminUserService adminUserService;

    @Resource
    private DeptService deptService;

    @Override
    public AdminUserRespDTO getUser(Long id) {
        UserRespVO user = adminUserService.getUser(id);
        return BeanUtils.toBean(user, AdminUserRespDTO.class);
    }

    @Override
    public List<AdminUserRespDTO> getUserListBySubordinate(Long userId) {
        // 1.1 获取用户负责的部门
        UserRespVO user = adminUserService.getUser(userId);
        if (user == null) {
            return Collections.emptyList();
        }
        ArrayList<Long> deptIds = new ArrayList<>();
        DeptDO dept = deptService.getDept(user.getDeptId());
        if (dept == null) {
            return Collections.emptyList();
        }
        // 校验为负责人
        if (ObjUtil.notEqual(dept.getLeaderUserId(), userId)) {
            return Collections.emptyList();
        }
        deptIds.add(dept.getId());
        // 1.2 获取所有子部门
        List<DeptDO> childDeptList = deptService.getChildDeptList(dept.getId());
        if (CollUtil.isNotEmpty(childDeptList)) {
            deptIds.addAll(convertSet(childDeptList, DeptDO::getId));
        }

        // 2. 获取部门对应的用户信息
        List<AdminUserDO> users = adminUserService.getUserListByDeptIds(deptIds);
        users.removeIf(item -> ObjUtil.equal(item.getId(), userId)); // 排除自己
        return BeanUtils.toBean(users, AdminUserRespDTO.class);
    }

    @Override
    public List<AdminUserRespDTO> getUserList(Collection<Long> ids) {
        List<AdminUserDO> users = adminUserService.getUserList(ids);
        return BeanUtils.toBean(users, AdminUserRespDTO.class);
    }

    @Override
    public List<AdminUserRespDTO> getUserListByDeptIds(Collection<Long> deptIds) {
        List<AdminUserDO> users = adminUserService.getUserListByDeptIds(deptIds);
        return BeanUtils.toBean(users, AdminUserRespDTO.class);
    }

    @Override
    public List<AdminUserRespDTO> getUserListByPostIds(Collection<Long> postIds) {
        List<AdminUserDO> users = adminUserService.getUserListByPostIds(postIds);
        return BeanUtils.toBean(users, AdminUserRespDTO.class);
    }

    @Override
    public void validateUserList(Collection<Long> ids) {
        adminUserService.validateUserList(ids);
    }

    @Override
    public Long createUser(AdminUserCreateReqDTO reqDTO, String businessName) {
        if (RoleCodeEnum.TENANT_ADMIN.getCode().equals(businessName)) {
            return adminUserService.createTenantUser(BeanUtils.toBean(reqDTO, UserSaveReqVO.class), reqDTO);
        }
        return adminUserService.createUser(BeanUtils.toBean(reqDTO, UserSaveReqVO.class));
    }

}
