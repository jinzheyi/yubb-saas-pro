package com.shengyu.module.platform.api.user;

import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.platform.api.user.dto.AdminUserRespDTO;
import com.shengyu.module.platform.dal.dataobject.user.PlatformUserDO;
import com.shengyu.module.platform.service.user.PlatformUserService;
import java.util.Collection;
import java.util.List;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;

/**
 * 平台 用户 API 实现类
 *
 * @author 圣钰科技
 */
@Service
public class PlatformUserApiImpl implements PlatformUserApi {

    @Resource
    private PlatformUserService platformUserService;

    @Override
    public AdminUserRespDTO getUser(Long id) {
        PlatformUserDO user = platformUserService.getUser(id);
        return BeanUtils.toBean(user, AdminUserRespDTO.class);
    }

    @Override
    public List<AdminUserRespDTO> getUserList(Collection<Long> ids) {
        List<PlatformUserDO> users = platformUserService.getUserList(ids);
        return BeanUtils.toBean(users, AdminUserRespDTO.class);
    }

    @Override
    public List<AdminUserRespDTO> getUserListByDeptIds(Collection<Long> deptIds) {
        List<PlatformUserDO> users = platformUserService.getUserListByDeptIds(deptIds);
        return BeanUtils.toBean(users, AdminUserRespDTO.class);
    }

    @Override
    public List<AdminUserRespDTO> getUsersByPostIds(Collection<Long> postIds) {
        List<PlatformUserDO> users = platformUserService.getUserListByPostIds(postIds);
        return BeanUtils.toBean(users, AdminUserRespDTO.class);
    }

    @Override
    public void validateUserList(Collection<Long> ids) {
        platformUserService.validateUserList(ids);
    }

}
