package cn.iocoder.yudao.module.platform.convert.user;

import cn.iocoder.yudao.module.platform.api.user.dto.AdminUserRespDTO;
import cn.iocoder.yudao.module.platform.controller.center.user.vo.profile.UserProfileRespVO;
import cn.iocoder.yudao.module.platform.controller.center.user.vo.profile.UserProfileUpdatePasswordReqVO;
import cn.iocoder.yudao.module.platform.controller.center.user.vo.profile.UserProfileUpdateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.user.vo.user.*;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.DeptDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PostDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.permission.RoleDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.social.SocialUserDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.user.AdminUserDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

@Mapper
public interface UserConvert {

    UserConvert INSTANCE = Mappers.getMapper(UserConvert.class);

    UserPageItemRespVO convert(AdminUserDO bean);

    UserPageItemRespVO.Dept convert(DeptDO bean);

    AdminUserDO convert(UserCreateReqVO bean);

    AdminUserDO convert(UserUpdateReqVO bean);

    UserExcelVO convert02(AdminUserDO bean);

    AdminUserDO convert(UserImportExcelVO bean);

    UserProfileRespVO convert03(AdminUserDO bean);

    List<UserProfileRespVO.Role> convertList(List<RoleDO> list);

    UserProfileRespVO.Dept convert02(DeptDO bean);

    AdminUserDO convert(UserProfileUpdateReqVO bean);

    AdminUserDO convert(UserProfileUpdatePasswordReqVO bean);

    List<UserProfileRespVO.Post> convertList02(List<PostDO> list);

    List<UserProfileRespVO.SocialUser> convertList03(List<SocialUserDO> list);

    List<UserSimpleRespVO> convertList04(List<AdminUserDO> list);

    AdminUserRespDTO convert4(AdminUserDO bean);

    List<AdminUserRespDTO> convertList4(List<AdminUserDO> users);

}
