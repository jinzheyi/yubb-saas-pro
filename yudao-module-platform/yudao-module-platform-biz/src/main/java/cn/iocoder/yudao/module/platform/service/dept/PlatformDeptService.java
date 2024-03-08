package cn.iocoder.yudao.module.platform.service.dept;

import cn.hutool.core.collection.CollUtil;
import cn.iocoder.yudao.framework.common.util.collection.CollectionUtils;
import cn.iocoder.yudao.module.platform.controller.platform.dept.vo.dept.DeptCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.dept.vo.dept.DeptListReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.dept.vo.dept.DeptUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformDeptDO;

import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 部门 Service 接口
 *
 * @author 圣钰科技
 */
public interface PlatformDeptService {

    /**
     * 创建部门
     *
     * @param reqVO 部门信息
     * @return 部门编号
     */
    Long createDept(DeptCreateReqVO reqVO);

    /**
     * 更新部门
     *
     * @param reqVO 部门信息
     */
    void updateDept(DeptUpdateReqVO reqVO);

    /**
     * 删除部门
     *
     * @param id 部门编号
     */
    void deleteDept(Long id);

    /**
     * 获得部门信息
     *
     * @param id 部门编号
     * @return 部门信息
     */
    PlatformDeptDO getDept(Long id);

    /**
     * 获得部门信息数组
     *
     * @param ids 部门编号数组
     * @return 部门信息数组
     */
    List<PlatformDeptDO> getDeptList(Collection<Long> ids);

    /**
     * 筛选部门列表
     *
     * @param reqVO 筛选条件请求 VO
     * @return 部门列表
     */
    List<PlatformDeptDO> getDeptList(DeptListReqVO reqVO);

    /**
     * 获得指定编号的部门 Map
     *
     * @param ids 部门编号数组
     * @return 部门 Map
     */
    default Map<Long, PlatformDeptDO> getDeptMap(Collection<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return Collections.emptyMap();
        }
        List<PlatformDeptDO> list = getDeptList(ids);
        return CollectionUtils.convertMap(list, PlatformDeptDO::getId);
    }

    /**
     * 获得指定部门的所有子部门
     *
     * @param id 部门编号
     * @return 子部门列表
     */
    List<PlatformDeptDO> getChildDeptList(Long id);

    /**
     * 获得所有子部门，从缓存中
     *
     * @param id 父部门编号
     * @return 子部门列表
     */
    Set<Long> getChildDeptIdListFromCache(Long id);

    /**
     * 校验部门们是否有效。如下情况，视为无效：
     * 1. 部门编号不存在
     * 2. 部门被禁用
     *
     * @param ids 角色编号数组
     */
    void validateDeptList(Collection<Long> ids);

}
