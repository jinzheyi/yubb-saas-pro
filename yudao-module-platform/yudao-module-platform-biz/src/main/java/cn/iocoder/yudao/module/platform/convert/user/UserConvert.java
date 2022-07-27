package cn.iocoder.yudao.module.platform.convert.user;

import cn.iocoder.yudao.module.platform.api.user.dto.PlatformUserRespDTO;
import cn.iocoder.yudao.module.platform.controller.center.user.vo.profile.UserProfileRespVO;
import cn.iocoder.yudao.module.platform.controller.center.user.vo.profile.UserProfileUpdatePasswordReqVO;
import cn.iocoder.yudao.module.platform.controller.center.user.vo.profile.UserProfileUpdateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.user.vo.user.*;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformDeptDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformPostDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.permission.PlatformRoleDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.social.PlatformSocialUserDO;
import cn.iocoder.yudao.module.platform.dal.dataobject.user.PlatformUserDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;
import java.util.Map;

@Mapper
public interface UserConvert {

    UserConvert INSTANCE = Mappers.getMapper(UserConvert.class);

    UserPageItemRespVO convert(PlatformUserDO bean);

    UserPageItemRespVO.Dept convert(PlatformDeptDO bean);

    PlatformUserDO convert(UserCreateReqVO bean);

    PlatformUserDO convert(UserUpdateReqVO bean);

    UserExcelVO convert02(PlatformUserDO bean);

    PlatformUserDO convert(UserImportExcelVO bean);

    UserProfileRespVO convert03(PlatformUserDO bean);

    List<UserProfileRespVO.Role> convertList(List<PlatformRoleDO> list);

    UserProfileRespVO.Dept convert02(PlatformDeptDO bean);

    PlatformUserDO convert(UserProfileUpdateReqVO bean);

    PlatformUserDO convert(UserProfileUpdatePasswordReqVO bean);

    List<UserProfileRespVO.Post> convertList02(List<PlatformPostDO> list);

    //TODO 这里先标记一下平台是否需要社交账号
    List<UserProfileRespVO.SocialUser> convertList03(List<PlatformSocialUserDO> list);

    List<UserSimpleRespVO> convertList04(List<PlatformUserDO> list);

    PlatformUserRespDTO convert4(PlatformUserDO bean);

    List<PlatformUserRespDTO> convertList4(List<PlatformUserDO> users);

    Map<Long, PlatformUserRespDTO> convertMap4(Map<Long, PlatformUserDO> map);

}
