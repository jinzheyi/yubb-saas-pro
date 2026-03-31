package com.shengyu.module.platform.dal.mysql.user;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.platform.controller.platform.user.vo.user.UserExportReqVO;
import com.shengyu.module.platform.controller.platform.user.vo.user.UserPageReqVO;
import com.shengyu.module.platform.dal.dataobject.user.PlatformUserDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collection;
import java.util.List;

@Mapper
public interface PlatformUserMapper extends BaseMapperX<PlatformUserDO> {

    default PlatformUserDO selectByUsername(String username) {
        return selectOne(PlatformUserDO::getUsername, username);
    }

    default PlatformUserDO selectByEmail(String email) {
        return selectOne(PlatformUserDO::getEmail, email);
    }

    default PlatformUserDO selectByMobile(String mobile) {
        return selectOne(PlatformUserDO::getMobile, mobile);
    }

    default PageResult<PlatformUserDO> selectPage(UserPageReqVO reqVO, Collection<Long> deptIds) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlatformUserDO>()
                .likeIfPresent(PlatformUserDO::getUsername, reqVO.getUsername())
                .likeIfPresent(PlatformUserDO::getMobile, reqVO.getMobile())
                .eqIfPresent(PlatformUserDO::getStatus, reqVO.getStatus())
                .betweenIfPresent(PlatformUserDO::getCreateTime, reqVO.getCreateTime())
                .inIfPresent(PlatformUserDO::getDeptId, deptIds)
                .orderByDesc(PlatformUserDO::getCreateTime));
    }

    default List<PlatformUserDO> selectList(UserExportReqVO reqVO, Collection<Long> deptIds) {
        return selectList(new LambdaQueryWrapperX<PlatformUserDO>()
                .likeIfPresent(PlatformUserDO::getUsername, reqVO.getUsername())
                .likeIfPresent(PlatformUserDO::getMobile, reqVO.getMobile())
                .eqIfPresent(PlatformUserDO::getStatus, reqVO.getStatus())
                .betweenIfPresent(PlatformUserDO::getCreateTime, reqVO.getCreateTime())
                .inIfPresent(PlatformUserDO::getDeptId, deptIds));
    }

    default List<PlatformUserDO> selectListByNickname(String nickname) {
        return selectList(new LambdaQueryWrapperX<PlatformUserDO>().like(PlatformUserDO::getNickname, nickname));
    }

    default List<PlatformUserDO> selectListByStatus(Integer status) {
        return selectList(PlatformUserDO::getStatus, status);
    }

    default List<PlatformUserDO> selectListByDeptIds(Collection<Long> deptIds) {
        return selectList(PlatformUserDO::getDeptId, deptIds);
    }

}
