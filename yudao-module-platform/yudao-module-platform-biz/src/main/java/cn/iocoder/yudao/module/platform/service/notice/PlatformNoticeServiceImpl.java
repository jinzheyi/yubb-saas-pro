package cn.iocoder.yudao.module.platform.service.notice;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.NOTICE_NOT_FOUND;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.module.platform.controller.platform.notice.vo.NoticeCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.notice.vo.NoticePageReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.notice.vo.NoticeUpdateReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.notice.PlatformNoticeDO;
import cn.iocoder.yudao.module.platform.dal.mysql.notice.PlatformNoticeMapper;
import com.google.common.annotations.VisibleForTesting;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;

/**
 * 通知公告 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
public class PlatformNoticeServiceImpl implements PlatformNoticeService {

    @Resource
    private PlatformNoticeMapper platformNoticeMapper;

    @Override
    public Long createNotice(NoticeCreateReqVO reqVO) {
        PlatformNoticeDO notice = BeanUtils.toBean(reqVO, PlatformNoticeDO.class);
        platformNoticeMapper.insert(notice);
        return notice.getId();
    }

    @Override
    public void updateNotice(NoticeUpdateReqVO reqVO) {
        // 校验是否存在
        validateNoticeExists(reqVO.getId());
        // 更新通知公告
        PlatformNoticeDO updateObj = BeanUtils.toBean(reqVO, PlatformNoticeDO.class);
        platformNoticeMapper.updateById(updateObj);
    }

    @Override
    public void deleteNotice(Long id) {
        // 校验是否存在
        validateNoticeExists(id);
        // 删除通知公告
        platformNoticeMapper.deleteById(id);
    }

    @Override
    public PageResult<PlatformNoticeDO> getNoticePage(NoticePageReqVO reqVO) {
        return platformNoticeMapper.selectPage(reqVO);
    }

    @Override
    public PlatformNoticeDO getNotice(Long id) {
        return platformNoticeMapper.selectById(id);
    }

    @VisibleForTesting
    public void validateNoticeExists(Long id) {
        if (id == null) {
            return;
        }
        PlatformNoticeDO notice = platformNoticeMapper.selectById(id);
        if (notice == null) {
            throw exception(NOTICE_NOT_FOUND);
        }
    }

}
