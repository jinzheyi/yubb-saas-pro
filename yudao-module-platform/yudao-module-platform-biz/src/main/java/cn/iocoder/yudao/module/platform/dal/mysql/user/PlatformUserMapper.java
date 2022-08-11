package cn.iocoder.yudao.module.platform.dal.mysql.user;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.platform.controller.center.user.vo.user.UserExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.user.vo.user.UserPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.user.PlatformUserDO;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.apache.ibatis.annotations.Mapper;

import java.util.Collection;
import java.util.List;

@Mapper
public interface PlatformUserMapper extends BaseMapperX<PlatformUserDO> {

    default PlatformUserDO selectByUsername(String username) {
        return selectOne(new LambdaQueryWrapper<PlatformUserDO>().eq(PlatformUserDO::getUsername, username));
    }

    default PlatformUserDO selectByEmail(String email) {
        return selectOne(new LambdaQueryWrapper<PlatformUserDO>().eq(PlatformUserDO::getEmail, email));
    }

    default PlatformUserDO selectByMobile(String mobile) {
        return selectOne(new LambdaQueryWrapper<PlatformUserDO>().eq(PlatformUserDO::getMobile, mobile));
    }

    default PageResult<PlatformUserDO> selectPage(UserPageReqVO reqVO, Collection<Long> deptIds) {
        return selectPage(reqVO, new LambdaQueryWrapperX<PlatformUserDO>()
                .likeIfPresent(PlatformUserDO::getUsername, reqVO.getUsername())
                .likeIfPresent(PlatformUserDO::getMobile, reqVO.getMobile())
                .eqIfPresent(PlatformUserDO::getStatus, reqVO.getStatus())
                .betweenIfPresent(PlatformUserDO::getCreateTime, reqVO.getCreateTime())
                .inIfPresent(PlatformUserDO::getDeptId, deptIds)
                .orderByDesc(PlatformUserDO::getId));
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

    default List<PlatformUserDO> selectListByUsername(String username) {
        return selectList(new LambdaQueryWrapperX<PlatformUserDO>().like(PlatformUserDO::getUsername, username));
    }

    default List<PlatformUserDO> selectListByStatus(Integer status) {
        return selectList(PlatformUserDO::getStatus, status);
    }

    default List<PlatformUserDO> selectListByDeptIds(Collection<Long> deptIds) {
        return selectList(PlatformUserDO::getDeptId, deptIds);
    }

}
