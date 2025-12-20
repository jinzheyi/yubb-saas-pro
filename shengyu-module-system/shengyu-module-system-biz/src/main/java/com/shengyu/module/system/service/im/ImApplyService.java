package com.shengyu.module.system.service.im;

import com.shengyu.module.system.controller.admin.im.vo.apply.ImApplyAddReqVO;
import com.shengyu.module.system.controller.admin.im.vo.apply.ImApplyHandleReqVO;
import com.shengyu.module.system.controller.admin.im.vo.apply.ImApplyListRespVO;
import com.shengyu.module.system.dal.dataobject.im.ImApplyDO;

import java.util.List;

/**
 * 好友申请服务接口
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
public interface ImApplyService {

    /**
     * 申请添加好友
     *
     * @param reqVO 好友申请请求
     * @return 好友申请信息
     */
    ImApplyDO addFriend(ImApplyAddReqVO reqVO);

    /**
     * 获取好友申请列表
     *
     * @param page 页码
     * @param limit 每页数量
     * @return 好友申请列表
     */
    List<ImApplyListRespVO> getApplyList(int page, int limit);

    /**
     * 处理好友申请
     *
     * @param id 申请ID
     * @param reqVO 处理请求
     * @return 处理结果
     */
    boolean handleApply(Long id, ImApplyHandleReqVO reqVO);
}
