package cn.iocoder.yudao.module.platform.api.user;

import cn.iocoder.yudao.module.platform.api.user.dto.AdminUserRespDTO;
import cn.iocoder.yudao.module.platform.convert.user.UserConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.user.PlatformUserDO;
import cn.iocoder.yudao.module.platform.service.user.PlatformUserService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.Collection;
import java.util.List;
import java.util.Set;

/**
 * Admin 用户 API 实现类
 *
 * @author 芋道源码
 */
@Service
public class PlatformUserApiImpl implements AdminUserApi {

    @Resource
    private PlatformUserService userService;

    @Override
    public AdminUserRespDTO getUser(Long id) {
        PlatformUserDO user = userService.getUser(id);
        return UserConvert.INSTANCE.convert4(user);
    }

    @Override
    public List<AdminUserRespDTO> getUsers(Collection<Long> ids) {
        List<PlatformUserDO> users = userService.getUsers(ids);
        return UserConvert.INSTANCE.convertList4(users);
    }

    @Override
    public List<AdminUserRespDTO> getUsersByDeptIds(Collection<Long> deptIds) {
        List<PlatformUserDO> users = userService.getUsersByDeptIds(deptIds);
        return UserConvert.INSTANCE.convertList4(users);
    }

    @Override
    public List<AdminUserRespDTO> getUsersByPostIds(Collection<Long> postIds) {
        List<PlatformUserDO> users = userService.getUsersByPostIds(postIds);
        return UserConvert.INSTANCE.convertList4(users);
    }

    @Override
    public void validUsers(Set<Long> ids) {
        userService.validUsers(ids);
    }

}
