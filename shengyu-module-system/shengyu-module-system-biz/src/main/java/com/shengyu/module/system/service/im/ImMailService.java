package com.shengyu.module.system.service.im;

import com.shengyu.module.system.controller.admin.im.vo.mail.ImMailListRespVO;
import com.shengyu.module.system.controller.admin.im.vo.mail.ImMailUserDetailRespVO;

/**
 * 用户通讯录 Service 接口
 *
 * @author zhusy
 * @since 2022/11/23
 */
public interface ImMailService {

    /**
     * 获取用户通讯录列表
     *
     * @return 用户通讯录列表
     */
    ImMailListRespVO list();

    /**
     * 获取用户资料详情
     *
     * @param userId 目标用户ID
     * @return 用户资料详情
     */
    ImMailUserDetailRespVO getUserDetail(Long userId);
    
    /**
     * 更新好友黑名单状态
     *
     * @param userId 目标用户ID
     * @param isBlack 是否移入黑名单（0：移除，1：移入）
     */
    void updateBlackStatus(Long userId, Integer isBlack);
    
    /**
     * 设置/取消星标好友
     *
     * @param userId 目标用户ID
     * @param star 是否设置为星标好友（0：取消，1：设置）
     */
    void updateStarStatus(Long userId, Integer star);
    
    /**
     * 设置朋友圈权限
     *
     * @param userId 目标用户ID
     * @param lookme 是否允许对方查看我的朋友圈（0：不允许，1：允许）
     * @param lookhim 是否允许查看对方的朋友圈（0：不允许，1：允许）
     */
    void setMomentAuth(Long userId, Integer lookme, Integer lookhim);
    
    /**
     * 设置备注和标签
     *
     * @param userId 目标用户ID
     * @param nickname 昵称备注
     * @param tags 标签列表，用逗号分隔
     */
    void setRemarkTag(Long userId, String nickname, String tags);
    
    /**
     * 删除好友
     *
     * @param friendId 好友ID
     */
    void deleteFriend(Long friendId);

}
