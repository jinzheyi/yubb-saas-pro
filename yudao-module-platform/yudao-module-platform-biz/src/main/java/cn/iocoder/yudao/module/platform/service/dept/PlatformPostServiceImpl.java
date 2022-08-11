package cn.iocoder.yudao.module.platform.service.dept;

import cn.hutool.core.collection.CollUtil;
import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.post.PostCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.post.PostExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.post.PostPageReqVO;
import cn.iocoder.yudao.module.platform.controller.center.dept.vo.post.PostUpdateReqVO;
import cn.iocoder.yudao.module.platform.convert.dept.PostConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformPostDO;
import cn.iocoder.yudao.module.platform.dal.mysql.dept.PlatformPostMapper;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.framework.common.util.collection.CollectionUtils.convertMap;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.*;

/**
 * 岗位 Service 实现类
 *
 * @author 芋道源码
 */
@Service
@Validated
public class PlatformPostServiceImpl implements PlatformPostService {

    @Resource
    private PlatformPostMapper platformPostMapper;

    @Override
    public Long createPost(PostCreateReqVO reqVO) {
        // 校验正确性
        this.checkCreateOrUpdate(null, reqVO.getName(), reqVO.getCode());
        // 插入岗位
        PlatformPostDO post = PostConvert.INSTANCE.convert(reqVO);
        platformPostMapper.insert(post);
        return post.getId();
    }

    @Override
    public void updatePost(PostUpdateReqVO reqVO) {
        // 校验正确性
        this.checkCreateOrUpdate(reqVO.getId(), reqVO.getName(), reqVO.getCode());
        // 更新岗位
        PlatformPostDO updateObj = PostConvert.INSTANCE.convert(reqVO);
        platformPostMapper.updateById(updateObj);
    }

    @Override
    public void deletePost(Long id) {
        // 校验是否存在
        this.checkPostExists(id);
        // 删除部门
        platformPostMapper.deleteById(id);
    }

    @Override
    public List<PlatformPostDO> getPosts(Collection<Long> ids, Collection<Integer> statuses) {
        return platformPostMapper.selectList(ids, statuses);
    }

    @Override
    public PageResult<PlatformPostDO> getPostPage(PostPageReqVO reqVO) {
        return platformPostMapper.selectPage(reqVO);
    }

    @Override
    public List<PlatformPostDO> getPosts(PostExportReqVO reqVO) {
        return platformPostMapper.selectList(reqVO);
    }

    @Override
    public PlatformPostDO getPost(Long id) {
        return platformPostMapper.selectById(id);
    }

    private void checkCreateOrUpdate(Long id, String name, String code) {
        // 校验自己存在
        checkPostExists(id);
        // 校验岗位名的唯一性
        checkPostNameUnique(id, name);
        // 校验岗位编码的唯一性
        checkPostCodeUnique(id, code);
    }

    private void checkPostNameUnique(Long id, String name) {
        PlatformPostDO post = platformPostMapper.selectByName(name);
        if (post == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同 id 的岗位
        if (id == null) {
            throw ServiceExceptionUtil.exception(POST_NAME_DUPLICATE);
        }
        if (!post.getId().equals(id)) {
            throw ServiceExceptionUtil.exception(POST_NAME_DUPLICATE);
        }
    }

    private void checkPostCodeUnique(Long id, String code) {
        PlatformPostDO post = platformPostMapper.selectByCode(code);
        if (post == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同 id 的岗位
        if (id == null) {
            throw ServiceExceptionUtil.exception(POST_CODE_DUPLICATE);
        }
        if (!post.getId().equals(id)) {
            throw ServiceExceptionUtil.exception(POST_CODE_DUPLICATE);
        }
    }

    private void checkPostExists(Long id) {
        if (id == null) {
            return;
        }
        PlatformPostDO post = platformPostMapper.selectById(id);
        if (post == null) {
            throw ServiceExceptionUtil.exception(POST_NOT_FOUND);
        }
    }

    @Override
    public void validPosts(Collection<Long> ids) {
        if (CollUtil.isEmpty(ids)) {
            return;
        }
        // 获得岗位信息
        List<PlatformPostDO> posts = platformPostMapper.selectBatchIds(ids);
        Map<Long, PlatformPostDO> postMap = convertMap(posts, PlatformPostDO::getId);
        // 校验
        ids.forEach(id -> {
            PlatformPostDO post = postMap.get(id);
            if (post == null) {
                throw exception(POST_NOT_FOUND);
            }
            if (!CommonStatusEnum.ENABLE.getStatus().equals(post.getStatus())) {
                throw exception(POST_NOT_ENABLE, post.getName());
            }
        });
    }
}
