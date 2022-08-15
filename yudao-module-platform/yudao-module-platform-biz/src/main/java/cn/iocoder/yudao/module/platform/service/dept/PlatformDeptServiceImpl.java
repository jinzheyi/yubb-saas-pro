package cn.iocoder.yudao.module.platform.service.dept;

import cn.hutool.core.collection.CollUtil;
import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil;
import cn.iocoder.yudao.framework.common.util.collection.CollectionUtils;
import cn.iocoder.yudao.framework.tenant.core.aop.TenantIgnore;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.dept.DeptCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.dept.DeptListReqVO;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.dept.DeptUpdateReqVO;
import cn.iocoder.yudao.module.platform.convert.dept.DeptConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformDeptDO;
import cn.iocoder.yudao.module.platform.dal.mysql.dept.PlatformDeptMapper;
import cn.iocoder.yudao.framework.common.enums.dept.DeptIdEnum;
import cn.iocoder.yudao.module.platform.mq.producer.dept.PlatformDeptProducer;
import com.google.common.collect.ImmutableMap;
import com.google.common.collect.ImmutableMultimap;
import com.google.common.collect.Multimap;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Lazy;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.PostConstruct;
import javax.annotation.Resource;
import java.util.*;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.*;

/**
 * 部门 Service 实现类
 *
 * @author 芋道源码
 */
@Service
@Validated
@Slf4j
public class PlatformDeptServiceImpl implements PlatformDeptService {

    /**
     * 定时执行 {@link #schedulePeriodicRefresh()} 的周期
     * 因为已经通过 Redis Pub/Sub 机制，所以频率不需要高
     */
    private static final long SCHEDULER_PERIOD = 5 * 60 * 1000L;

    /**
     * 部门缓存
     * key：部门编号 {@link PlatformDeptDO#getId()}
     *
     * 这里声明 volatile 修饰的原因是，每次刷新时，直接修改指向
     */
    @SuppressWarnings("FieldCanBeLocal")
    private volatile Map<Long, PlatformDeptDO> deptCache;
    /**
     * 父部门缓存
     * key：部门编号 {@link PlatformDeptDO#getParentId()}
     * value: 直接子部门列表
     *
     * 这里声明 volatile 修饰的原因是，每次刷新时，直接修改指向
     */
    private volatile Multimap<Long, PlatformDeptDO> parentDeptCache;
    /**
     * 缓存部门的最大更新时间，用于后续的增量轮询，判断是否有更新
     */
    private volatile Date maxUpdateTime;

    @Resource
    private PlatformDeptMapper platformDeptMapper;

    @Resource
    private PlatformDeptProducer platformDeptProducer;

    @Resource
    @Lazy // 注入自己，所以延迟加载
    private PlatformDeptService self;

    @Override
    @PostConstruct
    public synchronized void initLocalCache() {
        // 获取部门列表，如果有更新
        List<PlatformDeptDO> deptList = loadDeptIfUpdate(maxUpdateTime);
        if (CollUtil.isEmpty(deptList)) {
            return;
        }

        // 构建缓存
        ImmutableMap.Builder<Long, PlatformDeptDO> builder = ImmutableMap.builder();
        ImmutableMultimap.Builder<Long, PlatformDeptDO> parentBuilder = ImmutableMultimap.builder();
        deptList.forEach(sysRoleDO -> {
            builder.put(sysRoleDO.getId(), sysRoleDO);
            parentBuilder.put(sysRoleDO.getParentId(), sysRoleDO);
        });
        // 设置缓存
        deptCache = builder.build();
        parentDeptCache = parentBuilder.build();
        maxUpdateTime = CollectionUtils.getMaxValue(deptList, PlatformDeptDO::getUpdateTime);
        log.info("[initLocalCache][初始化 Dept 数量为 {}]", deptList.size());
    }

    @Scheduled(fixedDelay = SCHEDULER_PERIOD, initialDelay = SCHEDULER_PERIOD)
    public void schedulePeriodicRefresh() {
        self.initLocalCache();
    }

    /**
     * 如果部门发生变化，从数据库中获取最新的全量部门。
     * 如果未发生变化，则返回空
     *
     * @param maxUpdateTime 当前部门的最大更新时间
     * @return 部门列表
     */
    protected List<PlatformDeptDO> loadDeptIfUpdate(Date maxUpdateTime) {
        // 第一步，判断是否要更新。
        if (maxUpdateTime == null) { // 如果更新时间为空，说明 DB 一定有新数据
            log.info("[loadMenuIfUpdate][首次加载全量部门]");
        } else { // 判断数据库中是否有更新的部门
            if (platformDeptMapper.selectCountByUpdateTimeGt(maxUpdateTime) == 0) {
                return null;
            }
            log.info("[loadMenuIfUpdate][增量加载全量部门]");
        }
        // 第二步，如果有更新，则从数据库加载所有部门
        return platformDeptMapper.selectList();
    }

    @Override
    public Long createDept(DeptCreateReqVO reqVO) {
        // 校验正确性
        if (reqVO.getParentId() == null) {
            reqVO.setParentId(DeptIdEnum.ROOT.getId());
        }
        checkCreateOrUpdate(null, reqVO.getParentId(), reqVO.getName());
        // 插入部门
        PlatformDeptDO dept = DeptConvert.INSTANCE.convert(reqVO);
        platformDeptMapper.insert(dept);
        // 发送刷新消息
        platformDeptProducer.sendDeptRefreshMessage();
        return dept.getId();
    }

    @Override
    public void updateDept(DeptUpdateReqVO reqVO) {
        // 校验正确性
        if (reqVO.getParentId() == null) {
            reqVO.setParentId(DeptIdEnum.ROOT.getId());
        }
        checkCreateOrUpdate(reqVO.getId(), reqVO.getParentId(), reqVO.getName());
        // 更新部门
        PlatformDeptDO updateObj = DeptConvert.INSTANCE.convert(reqVO);
        platformDeptMapper.updateById(updateObj);
        // 发送刷新消息
        platformDeptProducer.sendDeptRefreshMessage();
    }

    @Override
    public void deleteDept(Long id) {
        // 校验是否存在
        checkDeptExists(id);
        // 校验是否有子部门
        if (platformDeptMapper.selectCountByParentId(id) > 0) {
            throw ServiceExceptionUtil.exception(DEPT_EXITS_CHILDREN);
        }
        // 删除部门
        platformDeptMapper.deleteById(id);
        // 发送刷新消息
        platformDeptProducer.sendDeptRefreshMessage();
    }

    @Override
    public List<PlatformDeptDO> getSimpleDepts(DeptListReqVO reqVO) {
        return platformDeptMapper.selectList(reqVO);
    }

    @Override
    public List<PlatformDeptDO> getDeptsByParentIdFromCache(Long parentId, boolean recursive) {
        if (parentId == null) {
            return Collections.emptyList();
        }
        List<PlatformDeptDO> result = new ArrayList<>(); // TODO 芋艿：待优化，新增缓存，避免每次遍历的计算
        // 递归，简单粗暴
        this.getDeptsByParentIdFromCache(result, parentId,
                recursive ? Integer.MAX_VALUE : 1, // 如果递归获取，则无限；否则，只递归 1 次
                parentDeptCache);
        return result;
    }

    /**
     * 递归获取所有的子部门，添加到 result 结果
     *
     * @param result 结果
     * @param parentId 父编号
     * @param recursiveCount 递归次数
     * @param parentDeptMap 父部门 Map，使用缓存，避免变化
     */
    private void getDeptsByParentIdFromCache(List<PlatformDeptDO> result, Long parentId, int recursiveCount,
                                             Multimap<Long, PlatformDeptDO> parentDeptMap) {
        // 递归次数为 0，结束！
        if (recursiveCount == 0) {
            return;
        }
        // 获得子部门
        Collection<PlatformDeptDO> depts = parentDeptMap.get(parentId);
        if (CollUtil.isEmpty(depts)) {
            return;
        }
        result.addAll(depts);
        // 继续递归
        depts.forEach(dept -> getDeptsByParentIdFromCache(result, dept.getId(),
                recursiveCount - 1, parentDeptMap));
    }

    private void checkCreateOrUpdate(Long id, Long parentId, String name) {
        // 校验自己存在
        checkDeptExists(id);
        // 校验父部门的有效性
        checkParentDeptEnable(id, parentId);
        // 校验部门名的唯一性
        checkDeptNameUnique(id, parentId, name);
    }

    private void checkParentDeptEnable(Long id, Long parentId) {
        if (parentId == null || DeptIdEnum.ROOT.getId().equals(parentId)) {
            return;
        }
        // 不能设置自己为父部门
        if (parentId.equals(id)) {
            throw ServiceExceptionUtil.exception(DEPT_PARENT_ERROR);
        }
        // 父岗位不存在
        PlatformDeptDO dept = platformDeptMapper.selectById(parentId);
        if (dept == null) {
            throw ServiceExceptionUtil.exception(DEPT_PARENT_NOT_EXITS);
        }
        // 父部门被禁用
        if (!CommonStatusEnum.ENABLE.getStatus().equals(dept.getStatus())) {
            throw ServiceExceptionUtil.exception(DEPT_NOT_ENABLE);
        }
        // 父部门不能是原来的子部门
        List<PlatformDeptDO> children = this.getDeptsByParentIdFromCache(id, true);
        if (children.stream().anyMatch(dept1 -> dept1.getId().equals(parentId))) {
            throw ServiceExceptionUtil.exception(DEPT_PARENT_IS_CHILD);
        }
    }

    private void checkDeptExists(Long id) {
        if (id == null) {
            return;
        }
        PlatformDeptDO dept = platformDeptMapper.selectById(id);
        if (dept == null) {
            throw ServiceExceptionUtil.exception(DEPT_NOT_FOUND);
        }
    }

    private void checkDeptNameUnique(Long id, Long parentId, String name) {
        PlatformDeptDO menu = platformDeptMapper.selectByParentIdAndName(parentId, name);
        if (menu == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同 id 的岗位
        if (id == null) {
            throw ServiceExceptionUtil.exception(DEPT_NAME_DUPLICATE);
        }
        if (!menu.getId().equals(id)) {
            throw ServiceExceptionUtil.exception(DEPT_NAME_DUPLICATE);
        }
    }

    @Override
    public List<PlatformDeptDO> getDepts(Collection<Long> ids) {
        return platformDeptMapper.selectBatchIds(ids);
    }

    @Override
    public PlatformDeptDO getDept(Long id) {
        return platformDeptMapper.selectById(id);
    }

    @Override
    public void validDepts(Collection<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return;
        }
        // 获得科室信息
        List<PlatformDeptDO> depts = platformDeptMapper.selectBatchIds(ids);
        Map<Long, PlatformDeptDO> deptMap = CollectionUtils.convertMap(depts, PlatformDeptDO::getId);
        // 校验
        ids.forEach(id -> {
            PlatformDeptDO dept = deptMap.get(id);
            if (dept == null) {
                throw exception(DEPT_NOT_FOUND);
            }
            if (!CommonStatusEnum.ENABLE.getStatus().equals(dept.getStatus())) {
                throw exception(DEPT_NOT_ENABLE, dept.getName());
            }
        });
    }

    @Override
    public List<PlatformDeptDO> getSimpleDepts(Collection<Long> ids) {
        return platformDeptMapper.selectBatchIds(ids);
    }

}
