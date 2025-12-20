package com.shengyu.module.system.service.im.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.framework.common.exception.ServiceException;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.im.vo.tag.ImTagListRespVO;
import com.shengyu.module.system.controller.admin.im.vo.tag.ImTagUserListRespVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.dal.dataobject.im.ImFriendDO;
import com.shengyu.module.system.dal.dataobject.im.ImFriendTagDO;
import com.shengyu.module.system.dal.dataobject.im.ImTagDO;
import com.shengyu.module.system.dal.mysql.im.ImFriendMapper;
import com.shengyu.module.system.dal.mysql.im.ImFriendTagMapper;
import com.shengyu.module.system.dal.mysql.im.ImTagMapper;
import com.shengyu.module.system.service.im.ImTagService;
import com.shengyu.module.system.service.user.AdminUserService;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 标签服务实现类
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Service
public class ImTagServiceImpl implements ImTagService {

    @Resource
    private ImTagMapper imTagMapper;

    @Resource
    private ImFriendTagMapper imFriendTagMapper;

    @Resource
    private ImFriendMapper imFriendMapper;

    @Resource
    private AdminUserService adminUserService;

    @Override
    public List<ImTagListRespVO> getTagList() {
        Long currentUserId = SecurityFrameworkUtils.getLoginUserId();

        // 查询当前用户的所有标签
        List<ImTagDO> tagList = imTagMapper.selectList(
                new LambdaQueryWrapper<ImTagDO>()
                        .eq(ImTagDO::getUserId, currentUserId)
        );

        // 转换为响应VO
        List<ImTagListRespVO> result = new ArrayList<>();
        for (ImTagDO tag : tagList) {
            ImTagListRespVO respVO = new ImTagListRespVO();
            respVO.setId(tag.getId());
            respVO.setName(tag.getName());
            result.add(respVO);
        }

        return result;
    }

    @Override
    public List<ImTagUserListRespVO> getTagUserList(Long tagId) {
        Long currentUserId = SecurityFrameworkUtils.getLoginUserId();

        // 验证标签是否存在且属于当前用户
        ImTagDO tag = imTagMapper.selectOne(
                new LambdaQueryWrapper<ImTagDO>()
                        .eq(ImTagDO::getId, tagId)
                        .eq(ImTagDO::getUserId, currentUserId)
        );

        if (tag == null) {
            throw new ServiceException("标签不存在");
        }

        // 查询该标签下的所有好友ID
        List<ImFriendTagDO> friendTagList = imFriendTagMapper.selectList(
                new LambdaQueryWrapper<ImFriendTagDO>()
                        .eq(ImFriendTagDO::getTagId, tagId)
        );

        if (friendTagList.isEmpty()) {
            return new ArrayList<>();
        }

        // 提取好友ID列表
        List<Long> friendIds = friendTagList.stream()
                .map(ImFriendTagDO::getFriendId)
                .collect(Collectors.toList());

        // 查询好友信息
        List<ImFriendDO> friendList = imFriendMapper.selectList(
                new LambdaQueryWrapper<ImFriendDO>()
                        .eq(ImFriendDO::getUserId, currentUserId)
                        .in(ImFriendDO::getFriendId, friendIds)
                        .eq(ImFriendDO::getIsblack, 0)
        );

        // 转换为响应VO
        List<ImTagUserListRespVO> result = new ArrayList<>();
        for (ImFriendDO friend : friendList) {
            UserRespVO user = adminUserService.getUser(friend.getFriendId());
            if (user != null) {
                ImTagUserListRespVO respVO = new ImTagUserListRespVO();
                respVO.setId(user.getId());
                respVO.setNickname(friend.getNickname());
                respVO.setUser(user);
                result.add(respVO);
            }
        }

        return result;
    }
}