package com.shengyu.module.system.service.im.impl;

import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.framework.common.exception.ServiceException;
import com.shengyu.framework.common.util.json.JsonUtils;
import com.shengyu.framework.netty.service.NettyService;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.im.vo.moment.*;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.dal.dataobject.im.*;
import com.shengyu.module.system.dal.mysql.im.*;
import com.shengyu.module.system.dal.redis.im.ImMessageRedisDAO;
import com.shengyu.module.system.service.im.ImMomentService;
import com.shengyu.module.system.service.user.AdminUserService;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 朋友圈服务实现类
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Service
public class ImMomentServiceImpl implements ImMomentService {

    @Resource
    private ImMomentMapper imMomentMapper;

    @Resource
    private ImMomentCommentMapper imMomentCommentMapper;

    @Resource
    private ImMomentLikeMapper imMomentLikeMapper;

    @Resource
    private ImMomentTimelineMapper imMomentTimelineMapper;

    @Resource
    private ImFriendMapper imFriendMapper;

    @Resource
    private AdminUserService adminUserService;

    @Resource
    private NettyService nettyService;

    @Resource
    private ImMessageRedisDAO imMessageRedisDAO;

    /**
     * 获取当前登录用户ID
     */
    private Long getCurrentUserId() {
        return SecurityFrameworkUtils.getLoginUserId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ImMomentDO createMoment(ImMomentCreateReqVO reqVO) {
        Long currentUserId = getCurrentUserId();

        // 验证请求参数，确保对应类型的内容不为空
        if ("content".equals(reqVO.getType()) && StrUtil.isBlank(reqVO.getContent())) {
            throw new ServiceException("内容不能为空");
        } else if ("image".equals(reqVO.getType()) && StrUtil.isBlank(reqVO.getImage())) {
            throw new ServiceException("图片不能为空");
        } else if ("video".equals(reqVO.getType()) && StrUtil.isBlank(reqVO.getVideo())) {
            throw new ServiceException("视频不能为空");
        }

        // 创建朋友圈
        ImMomentDO moment = new ImMomentDO();
        BeanUtils.copyProperties(reqVO, moment);
        moment.setUserId(currentUserId);
        imMomentMapper.insert(moment);

        // 推送到好友的时间轴
        toTimeline(moment);

        return moment;
    }

    /**
     * 推送到好友的时间轴
     */
    @Transactional(rollbackFor = Exception.class)
    private void toTimeline(ImMomentDO moment) {
        Long currentUserId = getCurrentUserId();

        // 获取当前用户所有好友
        List<ImFriendDO> friends = imFriendMapper.selectList(
                new LambdaQueryWrapper<ImFriendDO>()
                        .eq(ImFriendDO::getUserId, currentUserId)
                        .eq(ImFriendDO::getIsblack, 0)
        );

        // 解析谁可以看的规则
        String see = moment.getSee();
        String[] sees = see.split(":");
        String seeType = sees[0];
        final List<Long> onlyList;
        final List<Long> exceptList;

        if (("only".equals(seeType) || "except".equals(seeType)) && sees.length > 1) {
            List<Long> idList = Arrays.stream(sees[1].split(","))
                    .map(Long::parseLong)
                    .collect(Collectors.toList());
            if ("only".equals(seeType)) {
                onlyList = idList;
                exceptList = Collections.emptyList();
            } else {
                onlyList = Collections.emptyList();
                exceptList = idList;
            }
        } else {
            onlyList = Collections.emptyList();
            exceptList = Collections.emptyList();
        }

        // 过滤可以看这条朋友圈的好友
        List<ImFriendDO> visibleFriends = friends.stream().filter(friend -> {
            if ("all".equals(seeType)) {
                return true;
            } else if ("only".equals(seeType)) {
                return onlyList.contains(friend.getFriendId());
            } else if ("except".equals(seeType)) {
                return !exceptList.contains(friend.getFriendId());
            } else {
                // "none" 仅自己可见
                return false;
            }
        }).collect(Collectors.toList());

        // 构建时间轴数据
        List<ImMomentTimelineDO> timelineList = new ArrayList<>();

        // 添加好友的时间轴记录
        for (ImFriendDO friend : visibleFriends) {
            ImMomentTimelineDO timeline = new ImMomentTimelineDO();
            timeline.setUserId(friend.getFriendId());
            timeline.setMomentId(moment.getId());
            timeline.setOwn(0);
            timelineList.add(timeline);
        }

        // 添加自己的时间轴记录
        ImMomentTimelineDO ownTimeline = new ImMomentTimelineDO();
        ownTimeline.setUserId(currentUserId);
        ownTimeline.setMomentId(moment.getId());
        ownTimeline.setOwn(1);
        timelineList.add(ownTimeline);

        // 批量插入时间轴记录
        if (!timelineList.isEmpty()) {
            imMomentTimelineMapper.insertBatch(timelineList);
        }

        // 发送通知给好友
        sendMomentNotification(timelineList, currentUserId, "new");

        // 提醒指定用户
        if (StrUtil.isNotBlank(moment.getRemind())) {
            List<Long> remindUserIds = Arrays.stream(moment.getRemind().split(","))
                    .map(Long::parseLong)
                    .collect(Collectors.toList());
            sendMomentNotificationToRemindUsers(remindUserIds, currentUserId, "remind");
        }
    }

    /**
     * 发送朋友圈通知
     */
    private void sendMomentNotification(List<ImMomentTimelineDO> timelineList, Long fromUserId, String type) {
        UserRespVO fromUser = adminUserService.getUser(fromUserId);
        if (fromUser == null) {
            return;
        }

        Map<String, Object> notification = new HashMap<>();
        notification.put("avatar", fromUser.getAvatar());
        notification.put("user_id", fromUserId);
        notification.put("type", type);

        for (ImMomentTimelineDO timeline : timelineList) {
            sendNotification(timeline.getUserId(), notification, "moment");
        }
    }

    /**
     * 发送通知给提醒的用户
     */
    private void sendMomentNotificationToRemindUsers(List<Long> remindUserIds, Long fromUserId, String type) {
        UserRespVO fromUser = adminUserService.getUser(fromUserId);
        if (fromUser == null) {
            return;
        }

        Map<String, Object> notification = new HashMap<>();
        notification.put("avatar", fromUser.getAvatar());
        notification.put("user_id", fromUserId);
        notification.put("type", type);

        for (Long userId : remindUserIds) {
            sendNotification(userId, notification, "moment");
        }
    }

    /**
     * 发送通知
     */
    private void sendNotification(Long userId, Map<String, Object> notification, String msgType) {
        String userIdStr = userId.toString();
        boolean isOnline = nettyService.isUserOnline(userIdStr);

        if (isOnline) {
            // 用户在线，直接发送消息
            nettyService.sendToUser(userIdStr, notification);
        } else {
            // 用户离线，存储到离线消息列表
            imMessageRedisDAO.addOfflineMessage(userId, notification);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean likeMoment(ImMomentLikeReqVO reqVO) {
        Long currentUserId = getCurrentUserId();
        Long momentId = reqVO.getId();

        // 验证朋友圈是否存在且当前用户可以查看
        ImMomentTimelineDO timeline = imMomentTimelineMapper.selectOne(
                new LambdaQueryWrapper<ImMomentTimelineDO>()
                        .eq(ImMomentTimelineDO::getUserId, currentUserId)
                        .eq(ImMomentTimelineDO::getMomentId, momentId)
        );

        if (timeline == null) {
            throw new ServiceException("朋友圈消息不存在");
        }

        // 检查是否已经点赞
        ImMomentLikeDO existingLike = imMomentLikeMapper.selectOne(
                new LambdaQueryWrapper<ImMomentLikeDO>()
                        .eq(ImMomentLikeDO::getUserId, currentUserId)
                        .eq(ImMomentLikeDO::getMomentId, momentId)
        );

        // 获取朋友圈信息
        ImMomentDO moment = imMomentMapper.selectById(momentId);
        if (moment == null) {
            throw new ServiceException("朋友圈消息不存在");
        }

        // 构建通知消息
        Map<String, Object> notification = new HashMap<>();
        UserRespVO currentUser = adminUserService.getUser(currentUserId);
        if (currentUser != null) {
            notification.put("avatar", currentUser.getAvatar());
            notification.put("user_id", currentUserId);
            notification.put("type", "like");
        }

        boolean result;
        if (existingLike != null) {
            // 取消点赞
            imMomentLikeMapper.deleteById(existingLike.getId());
            result = false;
        } else {
            // 添加点赞
            ImMomentLikeDO like = new ImMomentLikeDO();
            like.setUserId(currentUserId);
            like.setMomentId(momentId);
            imMomentLikeMapper.insert(like);
            result = true;
        }

        // 通知作者
        if (!moment.getUserId().equals(currentUserId)) {
            sendNotification(moment.getUserId(), notification, "moment");
        }

        // 通知其他点赞用户
        List<ImMomentLikeDO> likes = imMomentLikeMapper.selectList(
                new LambdaQueryWrapper<ImMomentLikeDO>()
                        .eq(ImMomentLikeDO::getMomentId, momentId)
        );
        for (ImMomentLikeDO like : likes) {
            if (!like.getUserId().equals(currentUserId)) {
                sendNotification(like.getUserId(), notification, "moment");
            }
        }

        return result;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ImMomentCommentDO createComment(ImMomentCommentReqVO reqVO) {
        Long currentUserId = getCurrentUserId();
        Long momentId = reqVO.getId();

        // 验证朋友圈是否存在且当前用户可以查看
        ImMomentTimelineDO timeline = imMomentTimelineMapper.selectOne(
                new LambdaQueryWrapper<ImMomentTimelineDO>()
                        .eq(ImMomentTimelineDO::getUserId, currentUserId)
                        .eq(ImMomentTimelineDO::getMomentId, momentId)
        );

        if (timeline == null) {
            throw new ServiceException("朋友圈消息不存在");
        }

        // 获取朋友圈信息
        ImMomentDO moment = imMomentMapper.selectById(momentId);
        if (moment == null) {
            throw new ServiceException("朋友圈消息不存在");
        }

        // 创建评论
        ImMomentCommentDO comment = new ImMomentCommentDO();
        comment.setUserId(currentUserId);
        comment.setMomentId(momentId);
        comment.setContent(reqVO.getContent());
        comment.setReplyId(reqVO.getReply_id());
        imMomentCommentMapper.insert(comment);

        // 构建通知消息
        Map<String, Object> notification = new HashMap<>();
        UserRespVO currentUser = adminUserService.getUser(currentUserId);
        if (currentUser != null) {
            notification.put("avatar", currentUser.getAvatar());
            notification.put("user_id", currentUserId);
            notification.put("type", "comment");
        }

        // 通知作者
        if (!moment.getUserId().equals(currentUserId)) {
            sendNotification(moment.getUserId(), notification, "moment");
        }

        // 通知点赞用户
        List<ImMomentLikeDO> likes = imMomentLikeMapper.selectList(
                new LambdaQueryWrapper<ImMomentLikeDO>()
                        .eq(ImMomentLikeDO::getMomentId, momentId)
        );
        for (ImMomentLikeDO like : likes) {
            if (!like.getUserId().equals(currentUserId)) {
                sendNotification(like.getUserId(), notification, "moment");
            }
        }

        // 通知被回复人
        if (reqVO.getReply_id() > 0) {
            sendNotification(reqVO.getReply_id(), notification, "moment");
        }

        return comment;
    }

    @Override
    public List<ImMomentTimelineRespVO> getTimeline(ImMomentTimelineReqVO reqVO) {
        Long currentUserId = getCurrentUserId();
        int page = reqVO.getPage() > 0 ? reqVO.getPage() : 1;
        int limit = reqVO.getLimit() > 0 ? reqVO.getLimit() : 10;
        int offset = (page - 1) * limit;

        // 获取当前用户的朋友圈时间线
        List<ImMomentTimelineDO> timelineList = imMomentTimelineMapper.selectList(
                new LambdaQueryWrapper<ImMomentTimelineDO>()
                        .eq(ImMomentTimelineDO::getUserId, currentUserId)
                        .orderByDesc(ImMomentTimelineDO::getId)
                        .last("LIMIT " + offset + ", " + limit)
        );

        // 获取双向好友列表
        List<ImFriendDO> friends = imFriendMapper.selectList(
                new LambdaQueryWrapper<ImFriendDO>()
                        .eq(ImFriendDO::getUserId, currentUserId)
                        .eq(ImFriendDO::getLookhim, 1)
        );

        List<ImFriendDO> bfriends = imFriendMapper.selectList(
                new LambdaQueryWrapper<ImFriendDO>()
                        .eq(ImFriendDO::getFriendId, currentUserId)
                        .eq(ImFriendDO::getLookme, 1)
        );

        Set<Long> friendIds = friends.stream()
                .map(ImFriendDO::getFriendId)
                .collect(Collectors.toSet());

        Set<Long> bfriendIds = bfriends.stream()
                .map(ImFriendDO::getUserId)
                .collect(Collectors.toSet());

        // 交集：互相可见的好友
        friendIds.retainAll(bfriendIds);

        // 添加自己到可见列表
        friendIds.add(currentUserId);

        // 构建响应数据
        List<ImMomentTimelineRespVO> result = new ArrayList<>();
        for (ImMomentTimelineDO timeline : timelineList) {
            ImMomentDO moment = imMomentMapper.selectById(timeline.getMomentId());
            if (moment == null) {
                continue;
            }

            // 检查是否可见
            if (!friendIds.contains(moment.getUserId())) {
                continue;
            }

            ImMomentTimelineRespVO respVO = buildMomentRespVO(moment, timeline.getOwn(), friendIds);
            result.add(respVO);
        }

        return result;
    }

    @Override
    public List<ImMomentListRespVO> getMomentList(ImMomentListReqVO reqVO) {
        Long currentUserId = getCurrentUserId();
        Long userId = reqVO.getUserId();
        int page = reqVO.getPage() > 0 ? reqVO.getPage() : 1;
        int limit = reqVO.getLimit() > 0 ? reqVO.getLimit() : 10;
        int offset = (page - 1) * limit;

        Set<Long> lookIds = new HashSet<>();

        if (userId == null || userId.equals(currentUserId)) {
            // 本人
            userId = currentUserId;
        } else {
            // 验证权限，检查是否是好友且互相可见
            ImFriendDO friend = imFriendMapper.selectOne(
                    new LambdaQueryWrapper<ImFriendDO>()
                            .eq(ImFriendDO::getUserId, currentUserId)
                            .eq(ImFriendDO::getFriendId, userId)
                            .eq(ImFriendDO::getLookhim, 1)
            );

            ImFriendDO bfriend = imFriendMapper.selectOne(
                    new LambdaQueryWrapper<ImFriendDO>()
                            .eq(ImFriendDO::getFriendId, currentUserId)
                            .eq(ImFriendDO::getUserId, userId)
                            .eq(ImFriendDO::getLookme, 1)
            );

            // 不是好友或不可见
            if (friend == null || bfriend == null) {
                return new ArrayList<>();
            }

            // 获取共同好友列表，用于过滤评论和点赞
            List<ImFriendDO> friends = imFriendMapper.selectList(
                    new LambdaQueryWrapper<ImFriendDO>()
                            .eq(ImFriendDO::getUserId, currentUserId)
                            .eq(ImFriendDO::getIsblack, 0)
            );

            lookIds = friends.stream()
                    .map(ImFriendDO::getFriendId)
                    .collect(Collectors.toSet());
        }

        // 获取用户的朋友圈
        List<ImMomentDO> momentList = imMomentMapper.selectList(
                new LambdaQueryWrapper<ImMomentDO>()
                        .eq(ImMomentDO::getUserId, userId)
                        .orderByDesc(ImMomentDO::getId)
                        .last("LIMIT " + offset + ", " + limit)
        );

        // 构建响应数据
        List<ImMomentListRespVO> result = new ArrayList<>();
        for (ImMomentDO moment : momentList) {
            ImMomentListRespVO respVO = buildMomentListRespVO(moment, userId.equals(currentUserId) ? 1 : 0, lookIds);
            result.add(respVO);
        }

        return result;
    }

    /**
     * 构建朋友圈响应VO
     */
    private ImMomentTimelineRespVO buildMomentRespVO(ImMomentDO moment, Integer own, Set<Long> friendIds) {
        ImMomentTimelineRespVO respVO = new ImMomentTimelineRespVO();

        // 获取用户信息
        UserRespVO user = adminUserService.getUser(moment.getUserId());
        if (user != null) {
            respVO.setUserId(user.getId());
            respVO.setUserName(StrUtil.isNotBlank(user.getNickname()) ? user.getNickname() : user.getUsername());
            respVO.setAvatar(user.getAvatar());
        }

        respVO.setMomentId(moment.getId());
        respVO.setContent(moment.getContent());
        respVO.setLocation(moment.getLocation());
        respVO.setOwn(own);
        respVO.setCreatedAt(moment.getCreateTime().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli());

        // 处理图片列表
        if (StrUtil.isNotBlank(moment.getImage())) {
            List<String> images = Arrays.asList(moment.getImage().split(","));
            respVO.setImage(images);
        } else {
            respVO.setImage(Collections.emptyList());
        }

        // 处理视频
        if (StrUtil.isNotBlank(moment.getVideo())) {
            ImMomentTimelineRespVO.VideoInfo videoInfo = new ImMomentTimelineRespVO.VideoInfo();
            videoInfo.setUrl(moment.getVideo());
            respVO.setVideo(videoInfo);
        }

        // 处理评论
        List<ImMomentCommentDO> comments = imMomentCommentMapper.selectList(
                new LambdaQueryWrapper<ImMomentCommentDO>()
                        .eq(ImMomentCommentDO::getMomentId, moment.getId())
        );

        List<ImMomentCommentRespVO> commentRespVOs = new ArrayList<>();
        for (ImMomentCommentDO comment : comments) {
            UserRespVO commentUser = adminUserService.getUser(comment.getUserId());
            if (commentUser == null || !friendIds.contains(commentUser.getId())) {
                continue;
            }

            ImMomentCommentRespVO commentRespVO = new ImMomentCommentRespVO();
            commentRespVO.setContent(comment.getContent());

            // 评论用户
            ImMomentCommentRespVO.CommentUser userVO = new ImMomentCommentRespVO.CommentUser();
            userVO.setId(commentUser.getId());
            userVO.setName(StrUtil.isNotBlank(commentUser.getNickname()) ? commentUser.getNickname() : commentUser.getUsername());
            commentRespVO.setUser(userVO);

            // 回复用户
            if (comment.getReplyId() > 0) {
                UserRespVO replyUser = adminUserService.getUser(comment.getReplyId());
                if (replyUser != null) {
                    ImMomentCommentRespVO.CommentUser replyVO = new ImMomentCommentRespVO.CommentUser();
                    replyVO.setId(replyUser.getId());
                    replyVO.setName(StrUtil.isNotBlank(replyUser.getNickname()) ? replyUser.getNickname() : replyUser.getUsername());
                    commentRespVO.setReply(replyVO);
                }
            }

            commentRespVOs.add(commentRespVO);
        }
        respVO.setComments(commentRespVOs);

        // 处理点赞
        List<ImMomentLikeDO> likes = imMomentLikeMapper.selectList(
                new LambdaQueryWrapper<ImMomentLikeDO>()
                        .eq(ImMomentLikeDO::getMomentId, moment.getId())
        );

        List<ImMomentLikeRespVO> likeRespVOs = new ArrayList<>();
        for (ImMomentLikeDO like : likes) {
            UserRespVO likeUser = adminUserService.getUser(like.getUserId());
            if (likeUser == null || !friendIds.contains(likeUser.getId())) {
                continue;
            }

            ImMomentLikeRespVO likeRespVO = new ImMomentLikeRespVO();
            likeRespVO.setId(likeUser.getId());
            likeRespVO.setName(StrUtil.isNotBlank(likeUser.getNickname()) ? likeUser.getNickname() : likeUser.getUsername());
            likeRespVOs.add(likeRespVO);
        }
        respVO.setLikes(likeRespVOs);

        return respVO;
    }

    /**
     * 构建用户朋友圈列表响应VO
     */
    private ImMomentListRespVO buildMomentListRespVO(ImMomentDO moment, Integer own, Set<Long> lookIds) {
        ImMomentListRespVO respVO = new ImMomentListRespVO();

        // 获取用户信息
        UserRespVO user = adminUserService.getUser(moment.getUserId());
        if (user != null) {
            respVO.setUserId(user.getId());
            respVO.setUserName(StrUtil.isNotBlank(user.getNickname()) ? user.getNickname() : user.getUsername());
            respVO.setAvatar(user.getAvatar());
        }

        respVO.setMomentId(moment.getId());
        respVO.setContent(moment.getContent());
        respVO.setLocation(moment.getLocation());
        respVO.setOwn(own);
        respVO.setCreatedAt(moment.getCreateTime().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli());

        // 处理图片列表
        if (StrUtil.isNotBlank(moment.getImage())) {
            List<String> images = Arrays.asList(moment.getImage().split(","));
            respVO.setImage(images);
        } else {
            respVO.setImage(Collections.emptyList());
        }

        // 处理视频
        if (StrUtil.isNotBlank(moment.getVideo())) {
            ImMomentListRespVO.VideoInfo videoInfo = new ImMomentListRespVO.VideoInfo();
            videoInfo.setUrl(moment.getVideo());
            respVO.setVideo(videoInfo);
        }

        // 处理评论
        List<ImMomentCommentDO> comments = imMomentCommentMapper.selectList(
                new LambdaQueryWrapper<ImMomentCommentDO>()
                        .eq(ImMomentCommentDO::getMomentId, moment.getId())
        );

        List<ImMomentCommentRespVO> commentRespVOs = new ArrayList<>();
        for (ImMomentCommentDO comment : comments) {
            UserRespVO commentUser = adminUserService.getUser(comment.getUserId());
            if (commentUser == null) {
                continue;
            }

            // 检查是否可以查看该评论
            if (!lookIds.isEmpty() && !lookIds.contains(commentUser.getId())) {
                continue;
            }

            ImMomentCommentRespVO commentRespVO = new ImMomentCommentRespVO();
            commentRespVO.setContent(comment.getContent());

            // 评论用户
            ImMomentCommentRespVO.CommentUser userVO = new ImMomentCommentRespVO.CommentUser();
            userVO.setId(commentUser.getId());
            userVO.setName(StrUtil.isNotBlank(commentUser.getNickname()) ? commentUser.getNickname() : commentUser.getUsername());
            commentRespVO.setUser(userVO);

            // 回复用户
            if (comment.getReplyId() > 0) {
                UserRespVO replyUser = adminUserService.getUser(comment.getReplyId());
                if (replyUser != null) {
                    ImMomentCommentRespVO.CommentUser replyVO = new ImMomentCommentRespVO.CommentUser();
                    replyVO.setId(replyUser.getId());
                    replyVO.setName(StrUtil.isNotBlank(replyUser.getNickname()) ? replyUser.getNickname() : replyUser.getUsername());
                    commentRespVO.setReply(replyVO);
                }
            }

            commentRespVOs.add(commentRespVO);
        }
        respVO.setComments(commentRespVOs);

        // 处理点赞
        List<ImMomentLikeDO> likes = imMomentLikeMapper.selectList(
                new LambdaQueryWrapper<ImMomentLikeDO>()
                        .eq(ImMomentLikeDO::getMomentId, moment.getId())
        );

        List<ImMomentLikeRespVO> likeRespVOs = new ArrayList<>();
        for (ImMomentLikeDO like : likes) {
            UserRespVO likeUser = adminUserService.getUser(like.getUserId());
            if (likeUser == null) {
                continue;
            }

            // 检查是否可以查看该点赞
            if (!lookIds.isEmpty() && !lookIds.contains(likeUser.getId())) {
                continue;
            }

            ImMomentLikeRespVO likeRespVO = new ImMomentLikeRespVO();
            likeRespVO.setId(likeUser.getId());
            likeRespVO.setName(StrUtil.isNotBlank(likeUser.getNickname()) ? likeUser.getNickname() : likeUser.getUsername());
            likeRespVOs.add(likeRespVO);
        }
        respVO.setLikes(likeRespVOs);

        return respVO;
    }
}