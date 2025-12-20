package com.shengyu.module.system.service.im.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.framework.common.exception.ServiceException;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.admin.im.vo.fava.*;
import com.shengyu.module.system.dal.dataobject.im.ImFavaDO;
import com.shengyu.module.system.dal.mysql.im.ImFavaMapper;
import com.shengyu.module.system.service.im.ImFavaService;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;

/**
 * 收藏服务实现
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Service
public class ImFavaServiceImpl implements ImFavaService {

    @Resource
    private ImFavaMapper imFavaMapper;

    /**
     * 获取当前登录用户ID
     */
    private Long getCurrentUserId() {
        return SecurityFrameworkUtils.getLoginUserId();
    }

    @Override
    public ImFavaDO createFava(ImFavaCreateReqVO reqVO) {
        Long currentUserId = getCurrentUserId();

        // 创建收藏
        ImFavaDO fava = new ImFavaDO();
        BeanUtils.copyProperties(reqVO, fava);
        fava.setUserId(currentUserId);
        imFavaMapper.insert(fava);

        return fava;
    }

    @Override
    public List<ImFavaDO> getFavaList(int page, int limit) {
        Long currentUserId = getCurrentUserId();
        int offset = (page - 1) * limit;

        // 查询收藏列表
        return imFavaMapper.selectList(
                new LambdaQueryWrapper<ImFavaDO>()
                        .eq(ImFavaDO::getUserId, currentUserId)
                        .orderByDesc(ImFavaDO::getId)
                        .last("LIMIT " + offset + ", " + limit)
        );
    }

    @Override
    public boolean deleteFava(ImFavaDeleteReqVO reqVO) {
        Long currentUserId = getCurrentUserId();

        // 删除收藏，确保只能删除自己的收藏
        int result = imFavaMapper.delete(
                new LambdaQueryWrapper<ImFavaDO>()
                        .eq(ImFavaDO::getId, reqVO.getId())
                        .eq(ImFavaDO::getUserId, currentUserId)
        );

        return result > 0;
    }
}