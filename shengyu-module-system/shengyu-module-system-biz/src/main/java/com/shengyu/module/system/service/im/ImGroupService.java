package com.shengyu.module.system.service.im;

import com.shengyu.module.system.controller.admin.im.vo.group.*;
import com.shengyu.module.system.dal.dataobject.im.ImGroupDO;

import java.util.List;

/**
 * 群聊服务接口
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
public interface ImGroupService {

    /**
     * 获取群聊列表
     *
     * @param page 页码
     * @param limit 每页数量
     * @return 群聊列表
     */
    List<ImGroupInfoRespVO> getGroupList(int page, int limit);

    /**
     * 创建群聊
     *
     * @param reqVO 群聊创建请求
     * @return 群聊信息
     */
    ImGroupDO createGroup(ImGroupCreateReqVO reqVO);

    /**
     * 获取群聊信息
     *
     * @param id 群聊ID
     * @return 群聊信息
     */
    ImGroupInfoRespVO getGroupInfo(Long id);

    /**
     * 修改群名称
     *
     * @param reqVO 群聊重命名请求
     * @return 是否成功
     */
    boolean renameGroup(ImGroupRenameReqVO reqVO);

    /**
     * 更新群公告
     *
     * @param reqVO 群公告更新请求
     * @return 是否成功
     */
    boolean updateGroupRemark(ImGroupRemarkReqVO reqVO);

    /**
     * 更新群昵称
     *
     * @param reqVO 群昵称更新请求
     * @return 是否成功
     */
    boolean updateGroupNickname(ImGroupNicknameReqVO reqVO);

    /**
     * 退出群聊
     *
     * @param reqVO 群聊退出请求
     * @return 是否成功
     */
    boolean quitGroup(ImGroupQuitReqVO reqVO);

    /**
     * 踢出群成员
     *
     * @param reqVO 群聊踢人请求
     * @return 是否成功
     */
    boolean kickoffGroupMember(ImGroupKickoffReqVO reqVO);

    /**
     * 邀请加入群聊
     *
     * @param reqVO 群聊邀请请求
     * @return 是否成功
     */
    boolean inviteToGroup(ImGroupInviteReqVO reqVO);

    /**
     * 加入群聊
     *
     * @param reqVO 群聊加入请求
     * @return 是否成功
     */
    boolean joinGroup(ImGroupJoinReqVO reqVO);

    /**
     * 检查群聊关系
     *
     * @param id 群聊ID
     * @return 群聊关系
     */
    GroupRelationRespVO checkGroupRelation(Long id);
    
    /**
     * 生成群二维码
     *
     * @param id 群聊ID
     * @return 二维码图片字节数组
     */
    byte[] generateGroupQrcode(Long id);
}
