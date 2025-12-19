package com.shengyu.module.system.service.im;

import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.github.yulichang.wrapper.MPJLambdaWrapper;
import com.shengyu.framework.common.util.string.StrUtils;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.im.vo.mail.ImMailListRespVO;
import com.shengyu.module.system.controller.admin.im.vo.mail.ImMailUserDetailRespVO;
import com.shengyu.module.system.dal.dataobject.im.ImFriendDO;
import com.shengyu.module.system.dal.dataobject.im.ImFriendTagDO;
import com.shengyu.module.system.dal.dataobject.im.ImMomentDO;
import com.shengyu.module.system.dal.dataobject.im.ImTagDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.dataobject.user.SaasUserDO;
import com.shengyu.module.system.dal.mysql.im.ImFriendMapper;
import com.shengyu.module.system.dal.mysql.im.ImFriendTagMapper;
import com.shengyu.module.system.dal.mysql.im.ImMomentMapper;
import com.shengyu.module.system.dal.mysql.im.ImTagMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;
import org.springframework.transaction.annotation.Transactional;

/**
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2022/11/19 15:01
 */
@Service
public class ImMailServiceImpl implements ImMailService {

    @Autowired
    private ImFriendMapper imFriendMapper;

    @Autowired
    private ImFriendTagMapper imFriendTagMapper;

    @Autowired
    private ImMomentMapper imMomentMapper;

    @Autowired
    private ImTagMapper imTagMapper;

    @Autowired
    private AdminUserMapper adminUserMapper;

    @Override
    public ImMailListRespVO list() {
        // 获取当前登录用户ID
        Long currentUserId = getCurrentUserId();

        // 查询好友列表
        List<ImFriendDO> friends = getFriendsByUserId(currentUserId);

        // 构建好友ID列表
        List<Long> friendIds = extractFriendIds(friends);

        // 查询用户关联信息
        Map<Long, AdminUserDO> adminUserMap = getAdminUserMap(friendIds);
        Map<Long, SaasUserDO> saasUserMap = getSaasUserMap(adminUserMap.values());

        // 处理并转换好友数据
        List<ImMailListRespVO.User> userList = buildUserList(friends, adminUserMap, saasUserMap);

        // 按名称排序
        sortUserListByName(userList);

        // 构建并返回结果
        return buildResponseVO(userList);
    }

    @Override
    public ImMailUserDetailRespVO getUserDetail(Long userId) {
        // 获取当前登录用户ID
        Long currentUserId = getCurrentUserId();

        // 查询目标用户信息
        AdminUserDO adminUser = adminUserMapper.selectById(userId);
        if (adminUser == null) {
            throw new RuntimeException("用户不存在");
        }

        // 查询Saas用户信息
        SaasUserDO saasUser = getSaasUserByAdminUser(adminUser);
        if (saasUser == null) {
            throw new RuntimeException("用户不存在");
        }

        // 查询用户最新动态
        List<ImMomentDO> moments = getLatestMoments(userId);

        // 构建基础用户信息
        ImMailUserDetailRespVO respVO = buildBaseUserDetail(adminUser, saasUser, moments);

        // 查询好友关系
        ImFriendDO friend = getFriendRelation(currentUserId, userId);
        if (friend != null) {
            // 如果是好友，查询标签信息
            List<ImTagDO> tags = getFriendTags(friend.getId());
            // 更新好友相关信息
            updateFriendInfo(respVO, friend, tags);
        }

        return respVO;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateBlackStatus(Long userId, Integer isBlack) {
        // 获取当前登录用户ID
        Long currentUserId = getCurrentUserId();

        // 查询好友关系
        ImFriendDO friend = getFriendRelation(currentUserId, userId);
        if (friend == null) {
            throw new RuntimeException("该记录不存在");
        }

        // 更新黑名单状态
        friend.setIsblack(isBlack);
        imFriendMapper.updateById(friend);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateStarStatus(Long userId, Integer star) {
        // 获取当前登录用户ID
        Long currentUserId = getCurrentUserId();

        // 查询好友关系（排除黑名单用户）
        ImFriendDO friend = getFriendRelationByNotBlack(currentUserId, userId);
        if (friend == null) {
            throw new RuntimeException("该记录不存在");
        }

        // 更新星标状态
        friend.setStar(star);
        imFriendMapper.updateById(friend);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void setMomentAuth(Long userId, Integer lookme, Integer lookhim) {
        // 获取当前登录用户ID
        Long currentUserId = getCurrentUserId();

        // 查询好友关系（排除黑名单用户）
        ImFriendDO friend = getFriendRelationByNotBlack(currentUserId, userId);
        if (friend == null) {
            throw new RuntimeException("该记录不存在");
        }

        // 更新朋友圈权限
        friend.setLookme(lookme);
        friend.setLookhim(lookhim);
        imFriendMapper.updateById(friend);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void setRemarkTag(Long userId, String nickname, String tags) {
        // 获取当前登录用户ID
        Long currentUserId = getCurrentUserId();

        // 查询好友关系（排除黑名单用户）
        ImFriendDO friend = getFriendRelationByNotBlack(currentUserId, userId);
        if (friend == null) {
            throw new RuntimeException("该记录不存在");
        }

        // 更新昵称备注
        if (nickname != null) {
            friend.setNickname(nickname);
            imFriendMapper.updateById(friend);
        }

        // 处理标签逻辑
        handleFriendTags(currentUserId, friend.getId(), tags);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteFriend(Long friendId) {
        // 获取当前登录用户ID
        Long currentUserId = getCurrentUserId();

        // 删除当前用户对该好友的好友关系
        imFriendMapper.delete(
            new LambdaQueryWrapper<ImFriendDO>()
                .eq(ImFriendDO::getUserId, currentUserId)
                .eq(ImFriendDO::getFriendId, friendId)
        );

        // 删除该好友对当前用户的好友关系（双向删除）
        imFriendMapper.delete(
            new LambdaQueryWrapper<ImFriendDO>()
                .eq(ImFriendDO::getUserId, friendId)
                .eq(ImFriendDO::getFriendId, currentUserId)
        );

        // 删除关联的申请记录（假设存在申请表）
        // 这里可以根据实际的表结构和Mapper进行补充
    }

    /**
     * 处理好友标签
     */
    private void handleFriendTags(Long currentUserId, Long friendId, String tags) {
        // 将标签字符串拆分为列表
        List<String> tagList = Arrays.asList(tags.split(","));

        // 查询当前用户已有的所有标签
        List<ImTagDO> existingTags = imTagMapper.selectList(
            new LambdaQueryWrapper<ImTagDO>()
                .eq(ImTagDO::getUserId, currentUserId)
        );

        // 构建现有标签名称到ID的映射
        Map<String, Long> existingTagMap = existingTags.stream()
            .collect(Collectors.toMap(ImTagDO::getName, ImTagDO::getId));

        // 找出需要添加的新标签
        List<String> newTagNames = tagList.stream()
            .filter(tagName -> !existingTagMap.containsKey(tagName))
            .collect(Collectors.toList());

        // 添加新标签
        if (!newTagNames.isEmpty()) {
            List<ImTagDO> newTags = newTagNames.stream()
                .map(tagName -> {
                    ImTagDO tag = new ImTagDO();
                    tag.setUserId(currentUserId);
                    tag.setName(tagName);
                    return tag;
                })
                .collect(Collectors.toList());

            // 批量插入新标签
            imTagMapper.insertBatch(newTags);

            // 更新现有标签映射，包括新添加的标签
            newTags.forEach(tag -> existingTagMap.put(tag.getName(), tag.getId()));
        }

        // 获取所有标签的ID
        List<Long> targetTagIds = tagList.stream()
            .map(existingTagMap::get)
            .filter(Objects::nonNull)
            .collect(Collectors.toList());

        // 查询当前好友已有的标签关联
        List<ImFriendTagDO> existingFriendTags = imFriendTagMapper.selectList(
            new LambdaQueryWrapper<ImFriendTagDO>()
                .eq(ImFriendTagDO::getFriendId, friendId)
        );

        // 构建现有标签关联的标签ID集合
        Set<Long> existingFriendTagIds = existingFriendTags.stream()
            .map(ImFriendTagDO::getTagId)
            .collect(Collectors.toSet());

        // 找出需要添加的标签关联
        List<Long> tagsToAdd = targetTagIds.stream()
            .filter(tagId -> !existingFriendTagIds.contains(tagId))
            .collect(Collectors.toList());

        // 找出需要删除的标签关联
        List<Long> tagsToRemove = existingFriendTags.stream()
            .filter(friendTag -> !targetTagIds.contains(friendTag.getTagId()))
            .map(ImFriendTagDO::getId)
            .collect(Collectors.toList());

        // 添加新的标签关联
        if (!tagsToAdd.isEmpty()) {
            List<ImFriendTagDO> newFriendTags = tagsToAdd.stream()
                .map(tagId -> {
                    ImFriendTagDO friendTag = new ImFriendTagDO();
                    friendTag.setFriendId(friendId);
                    friendTag.setTagId(tagId);
                    return friendTag;
                })
                .collect(Collectors.toList());

            imFriendTagMapper.insertBatch(newFriendTags);
        }

        // 删除不需要的标签关联
        if (!tagsToRemove.isEmpty()) {
            imFriendTagMapper.deleteByIds(tagsToRemove);
        }
    }

    /**
     * 获取当前登录用户ID
     */
    private Long getCurrentUserId() {
        return SecurityFrameworkUtils.getLoginUserId();
    }

    /**
     * 根据用户ID查询好友列表
     */
    private List<ImFriendDO> getFriendsByUserId(Long userId) {
        return imFriendMapper.selectList(
            new LambdaQueryWrapper<ImFriendDO>()
                .eq(ImFriendDO::getUserId, userId)
        );
    }

    /**
     * 提取好友ID列表
     */
    private List<Long> extractFriendIds(List<ImFriendDO> friends) {
        return friends.stream()
            .map(ImFriendDO::getFriendId)
            .collect(Collectors.toList());
    }

    /**
     * 查询并构建AdminUserDO映射
     */
    private Map<Long, AdminUserDO> getAdminUserMap(List<Long> friendIds) {
        if (friendIds.isEmpty()) {
            return Collections.emptyMap();
        }

        List<AdminUserDO> adminUsers = adminUserMapper.selectList(
            new LambdaQueryWrapper<AdminUserDO>()
                .in(AdminUserDO::getId, friendIds)
        );

        return adminUsers.stream()
            .collect(Collectors.toMap(AdminUserDO::getId, user -> user));
    }

    /**
     * 查询并构建SaasUserDO映射
     */
    private Map<Long, SaasUserDO> getSaasUserMap(Collection<AdminUserDO> adminUsers) {
        List<Long> saasUserIds = adminUsers.stream()
            .map(AdminUserDO::getSaasUserId)
            .collect(Collectors.toList());

        if (saasUserIds.isEmpty()) {
            return Collections.emptyMap();
        }

        List<SaasUserDO> saasUsers = adminUserMapper.selectJoinList(SaasUserDO.class,
            new MPJLambdaWrapper<AdminUserDO>()
                .selectAs(SaasUserDO::getId, SaasUserDO::getId)
                .selectAs(SaasUserDO::getUsername, SaasUserDO::getUsername)
                .leftJoin(SaasUserDO.class, SaasUserDO::getId, AdminUserDO::getSaasUserId)
                .in(AdminUserDO::getSaasUserId, saasUserIds)
        );

        return saasUsers.stream()
            .collect(Collectors.toMap(SaasUserDO::getId, user -> user));
    }

    /**
     * 根据AdminUser查询SaasUser
     */
    private SaasUserDO getSaasUserByAdminUser(AdminUserDO adminUser) {
        List<SaasUserDO> saasUsers = adminUserMapper.selectJoinList(SaasUserDO.class,
            new MPJLambdaWrapper<AdminUserDO>()
                .selectAs(SaasUserDO::getId, SaasUserDO::getId)
                .selectAs(SaasUserDO::getUsername, SaasUserDO::getUsername)
                .selectAs(SaasUserDO::getSex, SaasUserDO::getSex)
                .leftJoin(SaasUserDO.class, SaasUserDO::getId, AdminUserDO::getSaasUserId)
                .eq(AdminUserDO::getSaasUserId, adminUser.getSaasUserId())
        );

        return saasUsers.isEmpty() ? null : saasUsers.get(0);
    }

    /**
     * 获取用户最新动态
     */
    private List<ImMomentDO> getLatestMoments(Long userId) {
        return imMomentMapper.selectList(
            new LambdaQueryWrapper<ImMomentDO>()
                .eq(ImMomentDO::getUserId, userId)
                .orderByDesc(ImMomentDO::getId)
                .last("LIMIT 1")
        );
    }

    /**
     * 构建基础用户信息
     */
    private ImMailUserDetailRespVO buildBaseUserDetail(AdminUserDO adminUser, SaasUserDO saasUser, List<ImMomentDO> moments) {
        ImMailUserDetailRespVO respVO = new ImMailUserDetailRespVO();
        respVO.setId(adminUser.getId());
        respVO.setUsername(saasUser.getUsername());
        respVO.setNickname(StrUtil.isNotBlank(adminUser.getNickname()) ? adminUser.getNickname() : saasUser.getUsername());
        respVO.setAvatar(adminUser.getAvatar());
        respVO.setSex(saasUser.getSex());
        respVO.setFriend(false);

        // 转换动态数据
        List<ImMailUserDetailRespVO.Moment> momentVOs = moments.stream()
            .map(moment -> {
                ImMailUserDetailRespVO.Moment momentVO = new ImMailUserDetailRespVO.Moment();
                momentVO.setId(moment.getId());
                momentVO.setContent(moment.getContent());
                momentVO.setCreateTime(moment.getCreateTime().toString());
                return momentVO;
            })
            .collect(Collectors.toList());
        respVO.setMoments(momentVOs);

        return respVO;
    }

    /**
     * 查询好友关系
     */
    private ImFriendDO getFriendRelation(Long currentUserId, Long targetUserId) {
        return imFriendMapper.selectOne(
            new LambdaQueryWrapper<ImFriendDO>()
                .eq(ImFriendDO::getUserId, currentUserId)
                .eq(ImFriendDO::getFriendId, targetUserId)
        );
    }

    /**
     * 查询非黑名单的好友关系
     */
    private ImFriendDO getFriendRelationByNotBlack(Long currentUserId, Long targetUserId) {
        return imFriendMapper.selectOne(
            new LambdaQueryWrapper<ImFriendDO>()
                .eq(ImFriendDO::getUserId, currentUserId)
                .eq(ImFriendDO::getFriendId, targetUserId)
                .eq(ImFriendDO::getIsblack, 0)
        );
    }

    /**
     * 获取好友标签
     */
    private List<ImTagDO> getFriendTags(Long friendId) {
        // 通过好友ID查询所有关联的标签ID
        List<ImFriendTagDO> friendTags = imFriendTagMapper.selectList(
            new LambdaQueryWrapper<ImFriendTagDO>()
                .eq(ImFriendTagDO::getFriendId, friendId)
        );

        if (friendTags.isEmpty()) {
            return Collections.emptyList();
        }

        // 提取标签ID列表
        List<Long> tagIds = friendTags.stream()
            .map(ImFriendTagDO::getTagId)
            .collect(Collectors.toList());

        // 查询标签详细信息
        return imTagMapper.selectList(
            new LambdaQueryWrapper<ImTagDO>()
                .in(ImTagDO::getId, tagIds)
        );
    }

    /**
     * 更新好友相关信息
     */
    private void updateFriendInfo(ImMailUserDetailRespVO respVO, ImFriendDO friend, List<ImTagDO> tags) {
        respVO.setFriend(true);

        // 如果有好友备注名，使用备注名
        if (StrUtil.isNotBlank(friend.getNickname())) {
            respVO.setNickname(friend.getNickname());
        }

        respVO.setLookme(friend.getLookme());
        respVO.setLookhim(friend.getLookhim());
        respVO.setStar(friend.getStar());
        respVO.setIsblack(friend.getIsblack());

        // 转换标签名称列表
        List<String> tagNames = tags.stream()
            .map(ImTagDO::getName)
            .collect(Collectors.toList());
        respVO.setTags(tagNames);
    }

    /**
     * 构建用户列表
     */
    private List<ImMailListRespVO.User> buildUserList(List<ImFriendDO> friends,
                                                     Map<Long, AdminUserDO> adminUserMap,
                                                     Map<Long, SaasUserDO> saasUserMap) {
        List<ImMailListRespVO.User> userList = new ArrayList<>();

        for (ImFriendDO friend : friends) {
            AdminUserDO adminUser = adminUserMap.get(friend.getFriendId());
            if (adminUser == null) {
                continue;
            }

            SaasUserDO saasUser = saasUserMap.get(adminUser.getSaasUserId());
            if (saasUser == null) {
                continue;
            }

            ImMailListRespVO.User userVO = buildUserVO(friend, adminUser, saasUser);
            userList.add(userVO);
        }

        return userList;
    }

    /**
     * 构建用户VO
     */
    private ImMailListRespVO.User buildUserVO(ImFriendDO friend, AdminUserDO adminUser, SaasUserDO saasUser) {
        ImMailListRespVO.User userVO = new ImMailListRespVO.User();
        userVO.setId(friend.getId());
        userVO.setUserId(adminUser.getId());
        userVO.setName(determineDisplayName(friend, adminUser, saasUser));
        userVO.setUsername(saasUser.getUsername());
        userVO.setAvatar(adminUser.getAvatar());
        return userVO;
    }

    /**
     * 确定显示名称
     */
    private String determineDisplayName(ImFriendDO friend, AdminUserDO adminUser, SaasUserDO saasUser) {
        String name = friend.getNickname();
        if (StrUtil.isBlank(name)) {
            name = StrUtil.isNotBlank(adminUser.getNickname()) ? adminUser.getNickname() : saasUser.getUsername();
        }
        return name;
    }

    /**
     * 按名称排序用户列表
     */
    private void sortUserListByName(List<ImMailListRespVO.User> userList) {
        userList.sort(Comparator.comparing(ImMailListRespVO.User::getName));
    }

    /**
     * 构建返回结果
     */
    private ImMailListRespVO buildResponseVO(List<ImMailListRespVO.User> userList) {
        ImMailListRespVO respVO = new ImMailListRespVO();
        respVO.setCount(userList.size());
        respVO.setTotal(userList.size());

        // 分组并生成索引
        Map<String, List<ImMailListRespVO.User>> groupMap = groupUsersByFirstLetter(userList);

        // 生成索引列表
        List<String> indexList = generateIndexList(groupMap);
        respVO.setIndexList(indexList);

        // 构建行数据
        respVO.setRows(buildRows(groupMap, indexList));

        return respVO;
    }

    /**
     * 按首字母分组用户列表
     */
    private Map<String, List<ImMailListRespVO.User>> groupUsersByFirstLetter(List<ImMailListRespVO.User> userList) {
        Map<String, List<ImMailListRespVO.User>> groupMap = new HashMap<>();

        for (ImMailListRespVO.User user : userList) {
            String firstChar = StrUtils.getRemarkPinYinLetter(user.getName());
            if (StrUtil.isBlank(firstChar)) {
                firstChar = "#";
            }
            groupMap.computeIfAbsent(firstChar, k -> new ArrayList<>()).add(user);
        }

        return groupMap;
    }

    /**
     * 生成索引列表
     */
    private List<String> generateIndexList(Map<String, List<ImMailListRespVO.User>> groupMap) {
        List<String> indexList = new ArrayList<>(groupMap.keySet());
        Collections.sort(indexList);
        return indexList;
    }

    /**
     * 构建行数据
     */
    private ImMailListRespVO.Rows buildRows(Map<String, List<ImMailListRespVO.User>> groupMap, List<String> indexList) {
        ImMailListRespVO.Rows rows = new ImMailListRespVO.Rows();
        List<ImMailListRespVO.NewList> newList = new ArrayList<>();

        for (String key : indexList) {
            ImMailListRespVO.NewList newListItem = new ImMailListRespVO.NewList();
            newListItem.setTitle(key);
            newListItem.setList(groupMap.get(key));
            newList.add(newListItem);
        }

        rows.setNewList(newList);
        return rows;
    }

}
