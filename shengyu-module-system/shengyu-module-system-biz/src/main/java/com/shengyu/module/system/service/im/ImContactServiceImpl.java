package com.shengyu.module.system.service.im;

import cn.hutool.core.util.StrUtil;
import cn.hutool.extra.pinyin.PinyinUtil;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.system.controller.app.im.vo.contact.AppImContactListByDeptReqVO;
import com.shengyu.module.system.controller.app.im.vo.contact.AppImContactRespVO;
import com.shengyu.module.system.controller.app.im.vo.contact.AppImContactSettingUpdateReqVO;
import com.shengyu.module.system.dal.dataobject.dept.DeptDO;
import com.shengyu.module.system.dal.dataobject.dept.PostDO;
import com.shengyu.module.system.dal.dataobject.dept.UserPostDO;
import com.shengyu.module.system.dal.dataobject.im.ImContactSettingDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.dataobject.dept.UserDeptDO;

import java.util.ArrayList;
import java.util.Collections;
import com.shengyu.module.system.dal.mysql.dept.DeptMapper;
import com.shengyu.module.system.dal.mysql.dept.PostMapper;
import com.shengyu.module.system.dal.mysql.dept.UserDeptMapper;
import com.shengyu.module.system.dal.mysql.dept.UserPostMapper;
import com.shengyu.module.system.dal.mysql.im.ImContactSettingMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.*;

/**
 * IM 联系人 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class ImContactServiceImpl implements ImContactService {

    @Resource
    private AdminUserMapper userMapper;

    @Resource
    private DeptMapper deptMapper;

    @Resource
    private ImContactSettingMapper contactSettingMapper;
    
    @Resource
    private UserPostMapper userPostMapper;
    
    @Resource
    private PostMapper postMapper;

    @Resource
    private UserDeptMapper userDeptMapper;

    @Override
    public List<AppImContactRespVO> getContactList(Long userId) {
        // 查询同租户下的所有用户(企业内部IM,联系人直接来源于system_users)
        List<AdminUserDO> users = userMapper.selectList();

        // 查询当前用户的联系人设置
        List<ImContactSettingDO> settings = contactSettingMapper.selectListByUserId(userId);
        Map<Long, ImContactSettingDO> settingMap = settings.stream()
                .collect(Collectors.toMap(ImContactSettingDO::getContactId, s -> s));

        // 转换为VO并填充设置信息
        return users.stream()
                .filter(user -> !user.getId().equals(userId)) // 排除自己
                .map(user -> {
                    AppImContactRespVO respVO = buildContactRespVO(user);
                    
                    // 填充个性化设置
                    ImContactSettingDO setting = settingMap.get(user.getId());
                    if (setting != null) {
                        respVO.setStar(setting.getStar());
                        respVO.setNoDisturb(setting.getNoDisturb());
                    } else {
                        respVO.setStar(false);
                        respVO.setNoDisturb(false);
                    }
                    
                    return respVO;
                })
                .collect(Collectors.toList());
    }

    @Override
    public PageResult<AppImContactRespVO> getContactPageByDept(Long userId, AppImContactListByDeptReqVO reqVO) {
        Long deptId = reqVO.getDeptId();
        // 1. 查询部门及其子部门（包含自身）
        DeptDO dept = deptMapper.selectById(deptId);
        if (dept == null) {
            throw exception(DEPT_NOT_FOUND);
        }
        List<Long> deptIds = new ArrayList<>();
        deptIds.add(deptId);
        List<Long> queue = new ArrayList<>();
        queue.add(deptId);
        for (int i = 0; i < queue.size(); i++) {
            Long current = queue.get(i);
            List<DeptDO> children = deptMapper.selectListByParentId(Collections.singleton(current));
            if (children == null || children.isEmpty()) {
                continue;
            }
            for (DeptDO child : children) {
                if (child == null || child.getId() == null) {
                    continue;
                }
                Long childId = child.getId();
                if (deptIds.contains(childId)) {
                    continue;
                }
                deptIds.add(childId);
                queue.add(childId);
            }
        }

        // 2. 查询部门下用户ID
        List<UserDeptDO> userDeptList = userDeptMapper.selectListByDeptIds(deptIds);
        if (userDeptList == null || userDeptList.isEmpty()) {
            return PageResult.empty();
        }
        List<Long> contactIds = userDeptList.stream()
                .map(UserDeptDO::getUserId)
                .filter(id -> id != null && !id.equals(userId))
                .distinct()
                .collect(Collectors.toList());
        if (contactIds.isEmpty()) {
            return PageResult.empty();
        }

        // 3. 查询用户信息
        List<AdminUserDO> users = userMapper.selectBatchIds(contactIds);
        if (users == null || users.isEmpty()) {
            return PageResult.empty();
        }

        String keyword = reqVO.getKeyword();
        List<AdminUserDO> filtered = users.stream()
                .filter(u -> u != null && u.getId() != null)
                .filter(u -> {
                    if (StrUtil.isBlank(keyword)) {
                        return true;
                    }
                    String nick = u.getNickname() != null ? u.getNickname() : "";
                    return StrUtil.contains(nick, keyword);
                })
                .collect(Collectors.toList());

        long total = filtered.size();
        if (total <= 0) {
            return PageResult.empty();
        }

        int pageNo = reqVO.getPageNo() != null ? reqVO.getPageNo() : 1;
        int pageSize = reqVO.getPageSize() != null ? reqVO.getPageSize() : 10;
        if (pageNo < 1) {
            pageNo = 1;
        }
        if (pageSize < 1) {
            pageSize = 10;
        }
        int fromIndex = (pageNo - 1) * pageSize;
        if (fromIndex >= filtered.size()) {
            return new PageResult<>(Collections.emptyList(), total);
        }
        int toIndex = Math.min(fromIndex + pageSize, filtered.size());
        List<AdminUserDO> pageUsers = filtered.subList(fromIndex, toIndex);

        // 4. 查询当前用户的联系人设置
        List<ImContactSettingDO> settings = contactSettingMapper.selectListByUserId(userId);
        Map<Long, ImContactSettingDO> settingMap = settings.stream()
                .collect(Collectors.toMap(ImContactSettingDO::getContactId, s -> s, (a, b) -> a));

        // 5. 转换为VO
        List<AppImContactRespVO> voList = pageUsers.stream()
                .map(u -> {
                    AppImContactRespVO respVO = buildContactRespVO(u);
                    ImContactSettingDO setting = settingMap.get(u.getId());
                    if (setting != null) {
                        respVO.setStar(setting.getStar());
                        respVO.setNoDisturb(setting.getNoDisturb());
                    } else {
                        respVO.setStar(false);
                        respVO.setNoDisturb(false);
                    }
                    return respVO;
                })
                .collect(Collectors.toList());

        return new PageResult<>(voList, total);
    }

    @Override
    public List<AppImContactRespVO> getContactListByDept(Long userId, Long deptId) {
        // 1. 查询部门及其子部门（包含自身）
        DeptDO dept = deptMapper.selectById(deptId);
        if (dept == null) {
            throw exception(DEPT_NOT_FOUND);
        }
        List<Long> deptIds = new ArrayList<>();
        deptIds.add(deptId);
        // BFS 获取所有子部门（避免仅查一层导致漏人）
        List<Long> queue = new ArrayList<>();
        queue.add(deptId);
        for (int i = 0; i < queue.size(); i++) {
            Long current = queue.get(i);
            List<DeptDO> children = deptMapper.selectListByParentId(Collections.singleton(current));
            if (children == null || children.isEmpty()) {
                continue;
            }
            for (DeptDO child : children) {
                if (child == null || child.getId() == null) {
                    continue;
                }
                Long childId = child.getId();
                if (deptIds.contains(childId)) {
                    continue;
                }
                deptIds.add(childId);
                queue.add(childId);
            }
        }

        // 2. 查询这些部门下的用户ID
        List<UserDeptDO> userDeptList = userDeptMapper.selectListByDeptIds(deptIds);
        if (userDeptList == null || userDeptList.isEmpty()) {
            return new ArrayList<>();
        }
        List<Long> contactIds = userDeptList.stream().map(UserDeptDO::getUserId).distinct().collect(Collectors.toList());
        // 排除自己
        contactIds = contactIds.stream().filter(id -> id != null && !id.equals(userId)).collect(Collectors.toList());
        if (contactIds.isEmpty()) {
            return new ArrayList<>();
        }

        // 3. 查询联系人用户信息
        List<AdminUserDO> users = userMapper.selectBatchIds(contactIds);

        // 4. 查询当前用户的联系人设置
        List<ImContactSettingDO> settings = contactSettingMapper.selectListByUserId(userId);
        Map<Long, ImContactSettingDO> settingMap = settings.stream()
                .collect(Collectors.toMap(ImContactSettingDO::getContactId, s -> s, (a, b) -> a));

        // 5. 转换为VO并填充设置信息
        return users.stream()
                .filter(u -> u != null && u.getId() != null && !u.getId().equals(userId))
                .map(u -> {
                    AppImContactRespVO respVO = buildContactRespVO(u);
                    ImContactSettingDO setting = settingMap.get(u.getId());
                    if (setting != null) {
                        respVO.setStar(setting.getStar());
                        respVO.setNoDisturb(setting.getNoDisturb());
                    } else {
                        respVO.setStar(false);
                        respVO.setNoDisturb(false);
                    }
                    return respVO;
                })
                .collect(Collectors.toList());
    }

    @Override
    public List<AppImContactRespVO> searchContacts(Long userId, String keyword) {
        // 查询同租户下的所有用户
        List<AdminUserDO> users = userMapper.selectList();

        // 查询当前用户的联系人设置
        List<ImContactSettingDO> settings = contactSettingMapper.selectListByUserId(userId);
        Map<Long, ImContactSettingDO> settingMap = settings.stream()
                .collect(Collectors.toMap(ImContactSettingDO::getContactId, s -> s));

        // 过滤并转换
        return users.stream()
                .filter(user -> !user.getId().equals(userId)) // 排除自己
                .filter(user -> StrUtil.contains(user.getNickname(), keyword)) // 按姓名搜索
                .map(user -> {
                    AppImContactRespVO respVO = buildContactRespVO(user);
                    
                    // 填充个性化设置
                    ImContactSettingDO setting = settingMap.get(user.getId());
                    if (setting != null) {
                        respVO.setStar(setting.getStar());
                        respVO.setNoDisturb(setting.getNoDisturb());
                    } else {
                        respVO.setStar(false);
                        respVO.setNoDisturb(false);
                    }
                    
                    return respVO;
                })
                .collect(Collectors.toList());
    }

    @Override
    public AppImContactRespVO getContact(Long userId, Long contactId) {
        // 查询联系人用户信息
        AdminUserDO user = userMapper.selectById(contactId);
        if (user == null) {
            throw exception(CONTACT_NOT_EXISTS);
        }

        AppImContactRespVO respVO = buildContactRespVO(user);

        // 查询个性化设置
        ImContactSettingDO setting = contactSettingMapper.selectByUserIdAndContactId(userId, contactId);
        if (setting != null) {
            respVO.setStar(setting.getStar());
            respVO.setNoDisturb(setting.getNoDisturb());
        } else {
            respVO.setStar(false);
            respVO.setNoDisturb(false);
        }

        return respVO;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateContactSetting(Long userId, AppImContactSettingUpdateReqVO updateReqVO) {
        // 验证联系人是否存在
        AdminUserDO contact = userMapper.selectById(updateReqVO.getContactId());
        if (contact == null) {
            throw exception(CONTACT_NOT_EXISTS);
        }

        // 查询或创建设置记录
        ImContactSettingDO setting = contactSettingMapper.selectByUserIdAndContactId(
                userId, updateReqVO.getContactId());
        
        if (setting == null) {
            // 创建新设置
            setting = new ImContactSettingDO();
            setting.setUserId(userId);
            setting.setContactId(updateReqVO.getContactId());
            setting.setRemarkName(updateReqVO.getNickname());
            setting.setStar(updateReqVO.getStar() != null ? updateReqVO.getStar() : false);
            setting.setNoDisturb(updateReqVO.getNoDisturb() != null ? updateReqVO.getNoDisturb() : false);
            contactSettingMapper.insert(setting);
        } else {
            // 更新设置
            if (updateReqVO.getNickname() != null) {
                setting.setRemarkName(updateReqVO.getNickname());
            }
            if (updateReqVO.getStar() != null) {
                setting.setStar(updateReqVO.getStar());
            }
            if (updateReqVO.getNoDisturb() != null) {
                setting.setNoDisturb(updateReqVO.getNoDisturb());
            }
            contactSettingMapper.updateById(setting);
        }
    }

    @Override
    public List<AppImContactRespVO> getStarContacts(Long userId) {
        // 查询星标联系人设置
        List<ImContactSettingDO> settings = contactSettingMapper.selectListByUserIdAndStar(userId);
        
        // 查询联系人信息
        List<Long> contactIds = settings.stream()
                .map(ImContactSettingDO::getContactId)
                .collect(Collectors.toList());
        
        if (contactIds.isEmpty()) {
            return new ArrayList<>();
        }

        List<AdminUserDO> users = userMapper.selectBatchIds(contactIds);
        Map<Long, ImContactSettingDO> settingMap = settings.stream()
                .collect(Collectors.toMap(ImContactSettingDO::getContactId, s -> s));

        return users.stream()
                .map(user -> {
                    AppImContactRespVO respVO = buildContactRespVO(user);
                    
                    // 填充个性化设置
                    ImContactSettingDO setting = settingMap.get(user.getId());
                    if (setting != null) {
                        respVO.setStar(setting.getStar());
                        respVO.setNoDisturb(setting.getNoDisturb());
                    }
                    
                    return respVO;
                })
                .collect(Collectors.toList());
    }

    /**
     * 构建联系人响应VO
     */
    private AppImContactRespVO buildContactRespVO(AdminUserDO user) {
        AppImContactRespVO respVO = new AppImContactRespVO();
        respVO.setId(user.getId());
        respVO.setNickname(user.getNickname());
        respVO.setAvatar(user.getAvatar());
        respVO.setDeptId(user.getDeptId());
        
        // 查询部门信息
        if (user.getDeptId() != null) {
            DeptDO dept = deptMapper.selectById(user.getDeptId());
            if (dept != null) {
                respVO.setDeptName(dept.getName());
            }
        }
        
        // 查询岗位信息（取第一个岗位）
        List<UserPostDO> userPosts = userPostMapper.selectListByUserId(user.getId());
        if (userPosts != null && !userPosts.isEmpty()) {
            Long postId = userPosts.get(0).getPostId();
            PostDO post = postMapper.selectById(postId);
            if (post != null) {
                respVO.setPostName(post.getName());
            }
        }
        
        // 获取拼音首字母
        if (StrUtil.isNotBlank(user.getNickname())) {
            String firstChar = PinyinUtil.getFirstLetter(user.getNickname(), "");
            respVO.setPinyin(firstChar.toUpperCase());
        }
        
        return respVO;
    }

}
