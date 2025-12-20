package com.shengyu.module.system.service.im;

import com.shengyu.module.system.controller.admin.im.vo.moment.*;
import com.shengyu.module.system.dal.dataobject.im.ImMomentCommentDO;
import com.shengyu.module.system.dal.dataobject.im.ImMomentDO;

import java.util.List;

/**
 * 朋友圈服务接口
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
public interface ImMomentService {

    /**
     * 发布朋友圈
     *
     * @param reqVO 朋友圈发布请求
     * @return 朋友圈信息
     */
    ImMomentDO createMoment(ImMomentCreateReqVO reqVO);

    /**
     * 朋友圈点赞
     *
     * @param reqVO 点赞请求
     * @return 点赞结果
     */
    boolean likeMoment(ImMomentLikeReqVO reqVO);

    /**
     * 朋友圈评论
     *
     * @param reqVO 评论请求
     * @return 评论结果
     */
    ImMomentCommentDO createComment(ImMomentCommentReqVO reqVO);

    /**
     * 获取朋友圈时间线
     *
     * @param reqVO 时间线请求
     * @return 朋友圈列表
     */
    List<ImMomentTimelineRespVO> getTimeline(ImMomentTimelineReqVO reqVO);

    /**
     * 获取某个用户的朋友圈列表
     *
     * @param reqVO 用户朋友圈请求
     * @return 朋友圈列表
     */
    List<ImMomentListRespVO> getMomentList(ImMomentListReqVO reqVO);
}