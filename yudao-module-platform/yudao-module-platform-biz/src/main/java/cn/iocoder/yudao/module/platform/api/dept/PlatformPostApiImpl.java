package cn.iocoder.yudao.module.platform.api.dept;

import cn.iocoder.yudao.module.platform.service.dept.PlatformPostService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.Collection;

/**
 * 岗位 API 实现类
 *
 * @author 芋道源码
 */
@Service
public class PlatformPostApiImpl implements PostApi {

    @Resource
    private PlatformPostService platformPostService;

    @Override
    public void validPosts(Collection<Long> ids) {
        platformPostService.validPosts(ids);
    }
}
