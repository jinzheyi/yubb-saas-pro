package cn.iocoder.yudao.module.platform.service.dept;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.framework.common.util.collection.CollectionUtils.convertMap;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.POST_CODE_DUPLICATE;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.POST_NAME_DUPLICATE;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.POST_NOT_ENABLE;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.POST_NOT_FOUND;

import cn.hutool.core.collection.CollUtil;
import cn.iocoder.yudao.framework.common.enums.CommonStatusEnum;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.module.platform.controller.platform.dept.vo.post.PostCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.dept.vo.post.PostExportReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.dept.vo.post.PostPageReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.dept.vo.post.PostUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.dept.PlatformPostDO;
import cn.iocoder.yudao.module.platform.dal.mysql.dept.PlatformPostMapper;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

/**
 * 岗位 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Validated
public class PlatformPostServiceImpl implements PlatformPostService {

    @Resource
    private PlatformPostMapper platformPostMapper;

    @Override
    public Long createPost(PostCreateReqVO reqVO) {
        // 校验正确性
        validatePostForCreateOrUpdate(null, reqVO.getName(), reqVO.getCode());

        // 插入岗位
        PlatformPostDO post = BeanUtils.toBean(reqVO, PlatformPostDO.class);
        platformPostMapper.insert(post);
        return post.getId();
    }

    @Override
    public void updatePost(PostUpdateReqVO reqVO) {
        // 校验正确性
        validatePostForCreateOrUpdate(reqVO.getId(), reqVO.getName(), reqVO.getCode());

        // 更新岗位
        PlatformPostDO updateObj = BeanUtils.toBean(reqVO, PlatformPostDO.class);
        platformPostMapper.updateById(updateObj);
    }

    @Override
    public void deletePost(Long id) {
        // 校验是否存在
        validatePostExists(id);
        // 删除部门
        platformPostMapper.deleteById(id);
    }

    private void validatePostForCreateOrUpdate(Long id, String name, String code) {
        // 校验自己存在
        validatePostExists(id);
        // 校验岗位名的唯一性
        validatePostNameUnique(id, name);
        // 校验岗位编码的唯一性
        validatePostCodeUnique(id, code);
    }

    private void validatePostNameUnique(Long id, String name) {
        PlatformPostDO post = platformPostMapper.selectByName(name);
        if (post == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同 id 的岗位
        if (id == null) {
            throw exception(POST_NAME_DUPLICATE);
        }
        if (!post.getId().equals(id)) {
            throw exception(POST_NAME_DUPLICATE);
        }
    }

    private void validatePostCodeUnique(Long id, String code) {
        PlatformPostDO post = platformPostMapper.selectByCode(code);
        if (post == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同 id 的岗位
        if (id == null) {
            throw exception(POST_CODE_DUPLICATE);
        }
        if (!post.getId().equals(id)) {
            throw exception(POST_CODE_DUPLICATE);
        }
    }

    private void validatePostExists(Long id) {
        if (id == null) {
            return;
        }
        if (platformPostMapper.selectById(id) == null) {
            throw exception(POST_NOT_FOUND);
        }
    }

    @Override
    public List<PlatformPostDO> getPostList(Collection<Long> ids, Collection<Integer> statuses) {
        return platformPostMapper.selectList(ids, statuses);
    }

    @Override
    public PageResult<PlatformPostDO> getPostPage(PostPageReqVO reqVO) {
        return platformPostMapper.selectPage(reqVO);
    }

    @Override
    public List<PlatformPostDO> getPostList(PostExportReqVO reqVO) {
        return platformPostMapper.selectList(reqVO);
    }

    @Override
    public PlatformPostDO getPost(Long id) {
        return platformPostMapper.selectById(id);
    }

    @Override
    public void validatePostList(Collection<Long> ids) {
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
