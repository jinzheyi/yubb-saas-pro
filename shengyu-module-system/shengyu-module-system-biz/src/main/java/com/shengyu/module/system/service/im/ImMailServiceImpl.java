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
        Long currentUserId = SecurityFrameworkUtils.getLoginUserId();
        
        // 查询当前用户的好友列表
        List<ImFriendDO> friends = imFriendMapper.selectList(
            new LambdaQueryWrapper<ImFriendDO>()
                .eq(ImFriendDO::getUserId, currentUserId)
        );
        
        // 构建好友ID列表
        List<Long> friendIds = friends.stream()
            .map(ImFriendDO::getFriendId)
            .collect(Collectors.toList());
        
        // 查询好友对应的AdminUserDO信息
        Map<Long, AdminUserDO> adminUserMap = new HashMap<>();
        List<AdminUserDO> adminUsers = new ArrayList<>();
        if (!friendIds.isEmpty()) {
            adminUsers = adminUserMapper.selectList(
                new LambdaQueryWrapper<AdminUserDO>()
                    .in(AdminUserDO::getId, friendIds)
            );
            for (AdminUserDO user : adminUsers) {
                adminUserMap.put(user.getId(), user);
            }
        }
        
        // 查询对应的SaasUserDO信息
        List<Long> saasUserIds = adminUsers.stream()
            .map(AdminUserDO::getSaasUserId)
            .collect(Collectors.toList());
        Map<Long, SaasUserDO> saasUserMap = new HashMap<>();
        if (!saasUserIds.isEmpty()) {
            List<SaasUserDO> saasUsers = adminUserMapper.selectJoinList(SaasUserDO.class, 
                new MPJLambdaWrapper<AdminUserDO>()
                    .selectAs(SaasUserDO::getId, SaasUserDO::getId)
                    .selectAs(SaasUserDO::getUsername, SaasUserDO::getUsername)
                    .leftJoin(SaasUserDO.class, SaasUserDO::getId, AdminUserDO::getSaasUserId)
                    .in(AdminUserDO::getSaasUserId, saasUserIds)
            );
            for (SaasUserDO user : saasUsers) {
                saasUserMap.put(user.getId(), user);
            }
        }
        
        // 处理好友数据
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
            
            // 确定显示名称：优先使用好友备注，然后是用户昵称
            String name = friend.getNickname();
            if (StrUtil.isBlank(name)) {
                name = StrUtil.isNotBlank(adminUser.getNickname()) ? adminUser.getNickname() : saasUser.getUsername();
            }
            ImMailListRespVO.User userVO = new ImMailListRespVO.User();
            userVO.setId(friend.getId());
            userVO.setUserId(adminUser.getId());
            userVO.setName(name);
            userVO.setUsername(saasUser.getUsername());
            userVO.setAvatar(adminUser.getAvatar());
            
            userList.add(userVO);
        }
        
        // 按名称排序
        userList.sort(Comparator.comparing(ImMailListRespVO.User::getName));
        
        // 构建返回结果
        ImMailListRespVO respVO = new ImMailListRespVO();
        respVO.setCount(userList.size());
        respVO.setTotal(userList.size());
        
        // 分组并生成索引
        Map<String, List<ImMailListRespVO.User>> groupMap = new HashMap<>();
        for (ImMailListRespVO.User user : userList) {
            String firstChar = StrUtils.getRemarkPinYinLetter(user.getName());
            if (StrUtil.isBlank(firstChar)) {
                firstChar = "#";
            }
            groupMap.computeIfAbsent(firstChar, k -> new ArrayList<>()).add(user);
        }
        
        // 生成索引列表
        List<String> indexList = new ArrayList<>(groupMap.keySet());
        Collections.sort(indexList);
        respVO.setIndexList(indexList);
        
        // 构建行数据
        ImMailListRespVO.Rows rows = new ImMailListRespVO.Rows();
        List<ImMailListRespVO.NewList> newList = new ArrayList<>();
        
        for (String key : indexList) {
            ImMailListRespVO.NewList newListItem = new ImMailListRespVO.NewList();
            newListItem.setTitle(key);
            newListItem.setList(groupMap.get(key));
            newList.add(newListItem);
        }
        
        rows.setNewList(newList);
        respVO.setRows(rows);
        
        return respVO;
    }

}
