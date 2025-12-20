package com.shengyu.module.system.service.im;

import com.shengyu.module.system.controller.admin.im.vo.tag.ImTagListRespVO;
import com.shengyu.module.system.controller.admin.im.vo.tag.ImTagUserListRespVO;
import com.shengyu.module.system.dal.dataobject.im.ImTagDO;

import java.util.List;

/**
 * 标签服务接口
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
public interface ImTagService {

    /**
     * 获取标签列表
     *
     * @return 标签列表
     */
    List<ImTagListRespVO> getTagList();

    /**
     * 获取标签用户列表
     *
     * @param tagId 标签ID
     * @return 标签用户列表
     */
    List<ImTagUserListRespVO> getTagUserList(Long tagId);
}