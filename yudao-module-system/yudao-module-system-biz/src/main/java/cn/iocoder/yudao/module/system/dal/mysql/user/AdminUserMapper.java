package cn.iocoder.yudao.module.system.dal.mysql.user;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.collection.ArrayUtils;
import cn.iocoder.yudao.framework.mybatis.core.mapper.BaseMapperX;
import cn.iocoder.yudao.framework.mybatis.core.query.LambdaQueryWrapperX;
import cn.iocoder.yudao.module.system.controller.admin.user.vo.user.UserPageReqVO;
import cn.iocoder.yudao.module.system.controller.admin.user.vo.user.UserRespVO;
import cn.iocoder.yudao.module.system.dal.dataobject.user.AdminUserDO;
import cn.iocoder.yudao.module.system.dal.dataobject.user.SaasUserDO;
import com.github.yulichang.wrapper.MPJLambdaWrapper;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Objects;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface AdminUserMapper extends BaseMapperX<AdminUserDO> {

    default AdminUserDO selectBySaasUserId(Long saasUserId) {
        return selectOne(AdminUserDO::getSaasUserId, saasUserId);
    }

    default AdminUserDO selectByOpenAccount(String openAccount) {
        return selectOne(AdminUserDO::getOpenAccount, openAccount);
    }

//    default PageResult<AdminUserDO> selectPage(UserPageReqVO reqVO, Collection<Long> deptIds) {
//        return selectPage(reqVO, new LambdaQueryWrapperX<AdminUserDO>()
//                .likeIfPresent(AdminUserDO::getUsername, reqVO.getUsername())
//                .likeIfPresent(AdminUserDO::getMobile, reqVO.getMobile())
//                .eqIfPresent(AdminUserDO::getStatus, reqVO.getStatus())
//                .betweenIfPresent(AdminUserDO::getCreateTime, reqVO.getCreateTime())
//                .inIfPresent(AdminUserDO::getDeptId, deptIds)
//                .orderByDesc(AdminUserDO::getId));
//    }

    default UserRespVO selectJoinOne(Long userId) {
        return selectJoinOne(UserRespVO.class, new MPJLambdaWrapper<AdminUserDO>()
          .selectAll(AdminUserDO.class)
          .select(SaasUserDO::getUsername, SaasUserDO::getMobile, SaasUserDO::getSex)
          .selectAs(SaasUserDO::getUsername, UserRespVO::getEmail)
          .leftJoin(SaasUserDO.class, SaasUserDO::getId, AdminUserDO::getSaasUserId)
          .eq(AdminUserDO::getId, userId));
    }

    default PageResult<UserRespVO> selectJoinPage(UserPageReqVO reqVO, Collection<Long> deptIds) {
        LocalDateTime startTime = ArrayUtils.get(reqVO.getCreateTime(), 0);
        LocalDateTime endTime = ArrayUtils.get(reqVO.getCreateTime(), 1);
        MPJLambdaWrapper<AdminUserDO> wrapper = new MPJLambdaWrapper<AdminUserDO>()
          .selectAll(AdminUserDO.class)
          .select(SaasUserDO::getUsername, SaasUserDO::getMobile, SaasUserDO::getSex)
          .selectAs(SaasUserDO::getUsername, UserRespVO::getEmail)
          .leftJoin(SaasUserDO.class, SaasUserDO::getId, AdminUserDO::getSaasUserId)
          .like(StrUtil.isNotBlank(reqVO.getUsername()), SaasUserDO::getUsername, reqVO.getUsername())
          .like(StrUtil.isNotBlank(reqVO.getMobile()), SaasUserDO::getMobile, reqVO.getMobile())
          .eq(Objects.nonNull(reqVO.getStatus()), AdminUserDO::getStatus, reqVO.getStatus());
        if (startTime != null && endTime != null) {
            wrapper.between(AdminUserDO::getCreateTime, startTime, endTime);
        }
        if (startTime != null) {
            wrapper.ge(AdminUserDO::getCreateTime, startTime);
        }
        if (endTime != null) {
            wrapper.le(AdminUserDO::getCreateTime, endTime);
        }
        wrapper.in(CollUtil.isNotEmpty(deptIds), AdminUserDO::getDeptId, deptIds)
          .orderByDesc(AdminUserDO::getId);
        return selectJoinPage(reqVO, UserRespVO.class, wrapper);
    }

    default List<AdminUserDO> selectListByNickname(String nickname) {
        return selectList(new LambdaQueryWrapperX<AdminUserDO>().like(AdminUserDO::getNickname, nickname));
    }

    default List<AdminUserDO> selectListByStatus(Integer status) {
        return selectList(AdminUserDO::getStatus, status);
    }

    default List<AdminUserDO> selectListByDeptIds(Collection<Long> deptIds) {
        return selectList(AdminUserDO::getDeptId, deptIds);
    }

}
