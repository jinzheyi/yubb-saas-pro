package com.shengyu.module.system.convert.user;

import cn.hutool.core.collection.CollUtil;
import com.shengyu.framework.common.util.collection.CollectionUtils;
import com.shengyu.framework.common.util.collection.MapUtils;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.platform.api.social.dto.SocialUserRespDTO;
import com.shengyu.module.system.controller.admin.dept.vo.dept.DeptSimpleRespVO;
import com.shengyu.module.system.controller.admin.dept.vo.dept.UserDeptRespVO;
import com.shengyu.module.system.controller.admin.dept.vo.post.PostSimpleRespVO;
import com.shengyu.module.system.controller.admin.permission.vo.role.RoleSimpleRespVO;
import com.shengyu.module.system.controller.admin.user.vo.profile.UserProfileRespVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserSimpleRespVO;
import com.shengyu.module.system.dal.dataobject.dept.DeptDO;
import com.shengyu.module.system.dal.dataobject.dept.PostDO;
import com.shengyu.module.system.dal.dataobject.permission.RoleDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Mapper
public interface UserConvert {

    UserConvert INSTANCE = Mappers.getMapper(UserConvert.class);

    default List<UserRespVO> convertList(List<UserRespVO> list, Map<Long, List<UserDeptRespVO>> userDeptList) {
        return CollectionUtils.convertList(list, user -> convert(user, userDeptList.get(user.getId())));
    }

    default UserRespVO convert(UserRespVO user, List<UserDeptRespVO> userDeptList) {
        UserRespVO userVO = BeanUtils.toBean(user, UserRespVO.class);
        if (CollUtil.isNotEmpty(userDeptList)) {
            userVO.setDeptName(userDeptList.stream().map(UserDeptRespVO::getDeptName).collect(Collectors.joining(", ")));
        }
        return userVO;
    }

    default List<UserSimpleRespVO> convertSimpleList(List<AdminUserDO> list, Map<Long, List<UserDeptRespVO>> userDeptList) {
        return CollectionUtils.convertList(list, user -> {
            UserSimpleRespVO userVO = BeanUtils.toBean(user, UserSimpleRespVO.class);
            MapUtils.findAndThen(userDeptList, user.getId(), deptList -> userVO.setDeptName(deptList.stream()
                    .map(UserDeptRespVO::getDeptName).collect(Collectors.joining(", "))));
            return userVO;
        });
    }

    default UserProfileRespVO convert(UserRespVO user, List<RoleDO> userRoles,
        DeptDO dept, List<PostDO> posts, List<SocialUserRespDTO> socialUsers) {
        UserProfileRespVO userVO = BeanUtils.toBean(user, UserProfileRespVO.class);
        userVO.setRoles(BeanUtils.toBean(userRoles, RoleSimpleRespVO.class));
        userVO.setDept(BeanUtils.toBean(dept, DeptSimpleRespVO.class));
        userVO.setPosts(BeanUtils.toBean(posts, PostSimpleRespVO.class));
        userVO.setSocialUsers(BeanUtils.toBean(socialUsers, UserProfileRespVO.SocialUser.class));
        return userVO;
    }

}
