package com.shengyu.module.system.dal.mysql.user;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.collection.ArrayUtils;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.framework.mybatis.core.query.LambdaQueryWrapperX;
import com.shengyu.module.system.controller.admin.user.vo.user.UserPageReqVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.dataobject.user.SaasUserDO;
import com.github.yulichang.wrapper.MPJLambdaWrapper;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Objects;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface AdminUserMapper extends BaseMapperX<AdminUserDO> {

    /**
     * 理论上SaaSUserId对应user表的多条记录，但这里会拼接上租户id，所以只会查询出一条记录
     * @param saasUserId SaaS用户表id
     * @return 结果
     */
    default AdminUserDO selectBySaasUserId(Long saasUserId) {
        return selectOne(AdminUserDO::getSaasUserId, saasUserId);
    }

    default AdminUserDO selectByTenantIdAndSaasUserId(Long tenantId, Long saasUserId) {
        return selectOne(new LambdaQueryWrapperX<AdminUserDO>()
                .eq(AdminUserDO::getTenantId, tenantId)
                .eq(AdminUserDO::getSaasUserId, saasUserId));
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

    default PageResult<UserRespVO> selectJoinPage(UserPageReqVO reqVO, Collection<Long> userIds) {
        LocalDateTime startTime = ArrayUtils.get(reqVO.getCreateTime(), 0);
        LocalDateTime endTime = ArrayUtils.get(reqVO.getCreateTime(), 1);
        MPJLambdaWrapper<AdminUserDO> wrapper = new MPJLambdaWrapper<AdminUserDO>()
          .selectAll(AdminUserDO.class)
          .select(SaasUserDO::getUsername, SaasUserDO::getMobile, SaasUserDO::getSex)
          .selectAs(SaasUserDO::getUsername, UserRespVO::getEmail)
          .leftJoin(SaasUserDO.class, SaasUserDO::getId, AdminUserDO::getSaasUserId);
        if (StrUtil.isNotBlank(reqVO.getUsername())) {
            wrapper.and(wrapper1 -> wrapper1.like(SaasUserDO::getUsername, reqVO.getUsername())
                    .or().like(AdminUserDO::getNickname, reqVO.getUsername()));
        }
        wrapper.like(StrUtil.isNotBlank(reqVO.getMobile()), SaasUserDO::getMobile, reqVO.getMobile())
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
        if (userIds != null && !userIds.isEmpty()) {
            wrapper.in(AdminUserDO::getId, userIds);
        }
        wrapper.orderByDesc(AdminUserDO::getCreateTime);
        return selectJoinPage(reqVO, UserRespVO.class, wrapper);
    }

    default List<AdminUserDO> selectListByNickname(String nickname) {
        return selectList(new LambdaQueryWrapperX<AdminUserDO>().like(AdminUserDO::getNickname, nickname));
    }

    default List<AdminUserDO> selectListByNicknameLikeLimit(String nickname, Integer limit) {
        int finalLimit = limit != null && limit > 0 ? Math.min(limit, 200) : 50;
        return selectList(new LambdaQueryWrapperX<AdminUserDO>()
                .likeIfPresent(AdminUserDO::getNickname, nickname)
                .last("LIMIT " + finalLimit));
    }

    default Long countByNicknameLike(String nickname, Long excludeUserId) {
        return selectCount(new LambdaQueryWrapperX<AdminUserDO>()
                .likeIfPresent(AdminUserDO::getNickname, nickname)
                .ne(excludeUserId != null, AdminUserDO::getId, excludeUserId));
    }

    default List<AdminUserDO> selectListByNicknameLikePage(String nickname, Long excludeUserId, Long offset, Integer limit) {
        long safeOffset = offset != null && offset > 0 ? offset : 0L;
        int finalLimit = limit != null && limit > 0 ? Math.min(limit, 200) : 20;
        return selectList(new LambdaQueryWrapperX<AdminUserDO>()
                .likeIfPresent(AdminUserDO::getNickname, nickname)
                .ne(excludeUserId != null, AdminUserDO::getId, excludeUserId)
                .last("LIMIT " + safeOffset + "," + finalLimit));
    }

    default List<AdminUserDO> selectListByStatus(Integer status) {
        return selectList(AdminUserDO::getStatus, status);
    }

    default List<AdminUserDO> selectListByDeptIds(Collection<Long> deptIds) {
        return selectList(AdminUserDO::getDeptId, deptIds);
    }

}
