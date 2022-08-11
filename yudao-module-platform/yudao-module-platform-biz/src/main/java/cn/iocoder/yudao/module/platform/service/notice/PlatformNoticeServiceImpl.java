package cn.iocoder.yudao.module.platform.service.notice;

import cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.controller.center.notice.vo.NoticeCreateReqVO;
import cn.iocoder.yudao.module.platform.controller.center.notice.vo.NoticePageReqVO;
import cn.iocoder.yudao.module.platform.controller.center.notice.vo.NoticeUpdateReqVO;
import cn.iocoder.yudao.module.platform.convert.notice.NoticeConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.notice.PlatformNoticeDO;
import cn.iocoder.yudao.module.platform.dal.mysql.notice.PlatformNoticeMapper;
import com.google.common.annotations.VisibleForTesting;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.NOTICE_NOT_FOUND;

/**
 * 通知公告 Service 实现类
 *
 * @author 芋道源码
 */
@Service
public class PlatformNoticeServiceImpl implements PlatformNoticeService {

    @Resource
    private PlatformNoticeMapper platformNoticeMapper;

    @Override
    public Long createNotice(NoticeCreateReqVO reqVO) {
        PlatformNoticeDO notice = NoticeConvert.INSTANCE.convert(reqVO);
        platformNoticeMapper.insert(notice);
        return notice.getId();
    }

    @Override
    public void updateNotice(NoticeUpdateReqVO reqVO) {
        // 校验是否存在
        this.checkNoticeExists(reqVO.getId());
        // 更新通知公告
        PlatformNoticeDO updateObj = NoticeConvert.INSTANCE.convert(reqVO);
        platformNoticeMapper.updateById(updateObj);
    }

    @Override
    public void deleteNotice(Long id) {
        // 校验是否存在
        this.checkNoticeExists(id);
        // 删除通知公告
        platformNoticeMapper.deleteById(id);
    }

    @Override
    public PageResult<PlatformNoticeDO> pageNotices(NoticePageReqVO reqVO) {
        return platformNoticeMapper.selectPage(reqVO);
    }

    @Override
    public PlatformNoticeDO getNotice(Long id) {
        return platformNoticeMapper.selectById(id);
    }

    @VisibleForTesting
    public void checkNoticeExists(Long id) {
        if (id == null) {
            return;
        }
        PlatformNoticeDO notice = platformNoticeMapper.selectById(id);
        if (notice == null) {
            throw ServiceExceptionUtil.exception(NOTICE_NOT_FOUND);
        }
    }

}
