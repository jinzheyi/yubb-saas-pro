package com.shengyu.module.im.service.impl;

import com.shengyu.module.im.dal.dataobject.ImUserDO;
import com.shengyu.module.im.dal.mapper.ImUserMapper;
import com.shengyu.module.im.service.ImUserService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

/**
 * IM用户服务实现类
 *
 * @author 圣钰科技
 */
@Slf4j
@Service
@Validated
public class ImUserServiceImpl implements ImUserService {

    @Autowired
    private ImUserMapper imUserMapper;

    @Override
    public ImUserDO getImUserByUserId(Long userId) {
        return imUserMapper.getByUserId(userId);
    }

    @Override
    public Long createOrUpdateImUser(Long userId, String nickname, String avatar) {
        // 检查用户是否已存在
        ImUserDO imUserDO = imUserMapper.getByUserId(userId);
        
        if (imUserDO != null) {
            // 更新用户信息
            imUserDO.setNickname(nickname);
            imUserDO.setAvatar(avatar);
            imUserMapper.updateById(imUserDO);
            return imUserDO.getId();
        } else {
            // 创建新用户
            ImUserDO newUserDO = new ImUserDO();
            newUserDO.setUserId(userId);
            newUserDO.setNickname(nickname);
            newUserDO.setAvatar(avatar);
            newUserDO.setStatus(0); // 0表示正常
            newUserDO.setOnlineStatus(0); // 0表示离线
            imUserMapper.insert(newUserDO);
            return newUserDO.getId();
        }
    }

    @Override
    public boolean updateOnlineStatus(Long userId, Integer onlineStatus) {
        int result = imUserMapper.updateOnlineStatus(userId, onlineStatus);
        return result > 0;
    }

    @Override
    public Integer getOnlineStatus(Long userId) {
        ImUserDO imUserDO = imUserMapper.getByUserId(userId);
        if (imUserDO != null) {
            return imUserDO.getOnlineStatus();
        }
        return 0; // 默认离线
    }

    @Override
    public boolean disableUser(Long userId) {
        ImUserDO imUserDO = imUserMapper.getByUserId(userId);
        if (imUserDO != null) {
            imUserDO.setStatus(1); // 1表示禁用
            int result = imUserMapper.updateById(imUserDO);
            return result > 0;
        }
        return false;
    }

    @Override
    public boolean enableUser(Long userId) {
        ImUserDO imUserDO = imUserMapper.getByUserId(userId);
        if (imUserDO != null) {
            imUserDO.setStatus(0); // 0表示正常
            int result = imUserMapper.updateById(imUserDO);
            return result > 0;
        }
        return false;
    }
}
