package com.shengyu.module.system.service.im;

import com.shengyu.module.system.controller.admin.im.vo.fava.*;
import com.shengyu.module.system.dal.dataobject.im.ImFavaDO;

import java.util.List;

/**
 * 收藏服务接口
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
public interface ImFavaService {

    /**
     * 创建收藏
     *
     * @param reqVO 收藏创建请求
     * @return 收藏信息
     */
    ImFavaDO createFava(ImFavaCreateReqVO reqVO);

    /**
     * 获取收藏列表
     *
     * @param page 页码
     * @param limit 每页数量
     * @return 收藏列表
     */
    List<ImFavaDO> getFavaList(int page, int limit);

    /**
     * 删除收藏
     *
     * @param reqVO 收藏删除请求
     * @return 是否成功
     */
    boolean deleteFava(ImFavaDeleteReqVO reqVO);
}