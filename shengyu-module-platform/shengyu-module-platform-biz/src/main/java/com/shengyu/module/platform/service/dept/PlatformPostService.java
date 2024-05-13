package com.shengyu.module.platform.service.dept;

import com.shengyu.framework.common.enums.CommonStatusEnum;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.platform.controller.platform.dept.vo.post.PostCreateReqVO;
import com.shengyu.module.platform.controller.platform.dept.vo.post.PostExportReqVO;
import com.shengyu.module.platform.controller.platform.dept.vo.post.PostPageReqVO;
import com.shengyu.module.platform.controller.platform.dept.vo.post.PostUpdateReqVO;
import com.shengyu.module.platform.dal.dataobject.dept.PlatformPostDO;
import org.springframework.lang.Nullable;

import java.util.Collection;
import java.util.List;

import static com.shengyu.framework.common.util.collection.SetUtils.asSet;

/**
 * 岗位 Service 接口
 *
 * @author 圣钰科技
 */
public interface PlatformPostService {

    /**
     * 创建岗位
     *
     * @param reqVO 岗位信息
     * @return 岗位编号
     */
    Long createPost(PostCreateReqVO reqVO);

    /**
     * 更新岗位
     *
     * @param reqVO 岗位信息
     */
    void updatePost(PostUpdateReqVO reqVO);

    /**
     * 删除岗位信息
     *
     * @param id 岗位编号
     */
    void deletePost(Long id);

    /**
     * 获得岗位列表
     *
     * @param ids 岗位编号数组。如果为空，不进行筛选
     * @return 部门列表
     */
    default List<PlatformPostDO> getPostList(@Nullable Collection<Long> ids) {
        return getPostList(ids, asSet(CommonStatusEnum.ENABLE.getStatus(), CommonStatusEnum.DISABLE.getStatus()));
    }

    /**
     * 获得符合条件的岗位列表
     *
     * @param ids 岗位编号数组。如果为空，不进行筛选
     * @param statuses 状态数组。如果为空，不进行筛选
     * @return 部门列表
     */
    List<PlatformPostDO> getPostList(@Nullable Collection<Long> ids, @Nullable Collection<Integer> statuses);

    /**
     * 获得岗位分页列表
     *
     * @param reqVO 分页条件
     * @return 部门分页列表
     */
    PageResult<PlatformPostDO> getPostPage(PostPageReqVO reqVO);

    /**
     * 获得岗位列表
     *
     * @param reqVO 查询条件
     * @return 部门列表
     */
    List<PlatformPostDO> getPostList(PostExportReqVO reqVO);

    /**
     * 获得岗位信息
     *
     * @param id 岗位编号
     * @return 岗位信息
     */
    PlatformPostDO getPost(Long id);

    /**
     * 校验岗位们是否有效。如下情况，视为无效：
     * 1. 岗位编号不存在
     * 2. 岗位被禁用
     *
     * @param ids 岗位编号数组
     */
    void validatePostList(Collection<Long> ids);

}
