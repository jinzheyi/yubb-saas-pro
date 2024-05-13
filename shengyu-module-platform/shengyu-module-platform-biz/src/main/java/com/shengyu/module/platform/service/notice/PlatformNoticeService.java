package com.shengyu.module.platform.service.notice;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.platform.controller.platform.notice.vo.NoticeCreateReqVO;
import com.shengyu.module.platform.controller.platform.notice.vo.NoticePageReqVO;
import com.shengyu.module.platform.controller.platform.notice.vo.NoticeUpdateReqVO;
import com.shengyu.module.platform.dal.dataobject.notice.PlatformNoticeDO;

/**
 * 通知公告 Service 接口
 */
public interface PlatformNoticeService {

    /**
     * 创建岗位公告公告
     *
     * @param reqVO 岗位公告公告信息
     * @return 岗位公告公告编号
     */
    Long createNotice(NoticeCreateReqVO reqVO);

    /**
     * 更新岗位公告公告
     *
     * @param reqVO 岗位公告公告信息
     */
    void updateNotice(NoticeUpdateReqVO reqVO);

    /**
     * 删除岗位公告公告信息
     *
     * @param id 岗位公告公告编号
     */
    void deleteNotice(Long id);

    /**
     * 获得岗位公告公告分页列表
     *
     * @param reqVO 分页条件
     * @return 部门分页列表
     */
    PageResult<PlatformNoticeDO> getNoticePage(NoticePageReqVO reqVO);

    /**
     * 获得岗位公告公告信息
     *
     * @param id 岗位公告公告编号
     * @return 岗位公告公告信息
     */
    PlatformNoticeDO getNotice(Long id);

}
