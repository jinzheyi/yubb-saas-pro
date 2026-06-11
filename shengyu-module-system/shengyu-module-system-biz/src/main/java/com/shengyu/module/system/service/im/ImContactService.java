package com.shengyu.module.system.service.im;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.system.controller.app.im.vo.contact.AppImContactListByDeptReqVO;
import com.shengyu.module.system.controller.app.im.vo.contact.AppImContactRespVO;
import com.shengyu.module.system.controller.app.im.vo.contact.AppImContactSettingUpdateReqVO;

import java.util.List;

/**
 * IM 联系人 Service 接口
 *
 * @author 圣钰科技
 */
public interface ImContactService {

    /**
     * 获取联系人列表
     * 
     * 说明: 企业内部IM,联系人直接来源于租户的用户表(system_users)
     *
     * @param userId 用户ID
     * @param limit 返回上限
     * @return 联系人列表
     */
    List<AppImContactRespVO> getContactList(Long userId, Integer limit);

    /**
     * 搜索联系人
     *
     * @param userId 用户ID
     * @param keyword 关键词(姓名/部门)
     * @return 联系人列表
     */
    List<AppImContactRespVO> searchContacts(Long userId, String keyword);

    /**
     * 分页搜索联系人
     *
     * @param userId 用户ID
     * @param keyword 关键词(姓名/部门)
     * @param pageNo 页码(从1开始)
     * @param pageSize 每页数量
     * @return 分页结果
     */
    PageResult<AppImContactRespVO> searchContactsPage(Long userId, String keyword, Integer pageNo, Integer pageSize);

    /**
     * 获取联系人详情
     *
     * @param userId 用户ID
     * @param contactId 联系人ID
     * @return 联系人详情
     */
    AppImContactRespVO getContact(Long userId, Long contactId);

    /**
     * 更新联系人设置
     *
     * @param userId 用户ID
     * @param updateReqVO 更新请求
     */
    void updateContactSetting(Long userId, AppImContactSettingUpdateReqVO updateReqVO);

    /**
     * 获取星标联系人列表
     *
     * @param userId 用户ID
     * @param limit 返回上限
     * @return 星标联系人列表
     */
    List<AppImContactRespVO> getStarContacts(Long userId, Integer limit);

    /**
     * 根据部门ID获取联系人列表
     *
     * @param userId 用户ID
     * @param deptId 部门ID
     * @return 联系人列表
     */
    List<AppImContactRespVO> getContactListByDept(Long userId, Long deptId);

    /**
     * 根据部门ID分页获取联系人列表
     */
    PageResult<AppImContactRespVO> getContactPageByDept(Long userId, AppImContactListByDeptReqVO reqVO);

}
