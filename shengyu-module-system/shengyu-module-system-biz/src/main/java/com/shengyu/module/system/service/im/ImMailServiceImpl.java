package com.shengyu.module.system.service.im;

import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.github.yulichang.wrapper.MPJLambdaWrapper;
import com.shengyu.framework.common.util.string.StrUtils;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.im.vo.mail.ImMailListRespVO;
import com.shengyu.module.system.dal.dataobject.im.ImFriendDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.dataobject.user.SaasUserDO;
import com.shengyu.module.system.dal.mysql.im.ImFriendMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

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
