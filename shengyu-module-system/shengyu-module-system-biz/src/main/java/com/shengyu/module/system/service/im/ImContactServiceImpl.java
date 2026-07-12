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
import com.shengyu.module.system.controller.admin.dept.vo.dept.UserDeptRespVO;

import java.util.Comparator;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;
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
    public List<AppImContactRespVO> getContactList(Long userId, Integer limit) {
        // 查询同租户下的所有用户(企业内部IM,联系人直接来源于system_users)
        List<AdminUserDO> users = userMapper.selectList();

        // 查询当前用户的联系人设置
        List<ImContactSettingDO> settings = contactSettingMapper.selectListByUserId(userId);
        Map<Long, ImContactSettingDO> settingMap = settings.stream()
                .collect(Collectors.toMap(ImContactSettingDO::getContactId, s -> s));

        // 通过 user_dept 映射表获取用户实际部门（与 getContactPageByDept 保持一致）
        List<Long> allUserIds = users.stream()
                .filter(user -> !user.getId().equals(userId))
                .map(AdminUserDO::getId)
                .collect(Collectors.toList());
        Map<Long, Long> userToActualDeptMap = buildUserToActualDeptMap(allUserIds);

        // 转换为VO并填充设置信息，按 limit 截断
        return users.stream()
                .filter(user -> !user.getId().equals(userId)) // 排除自己
                .map(user -> {
                    Long actualDeptId = userToActualDeptMap.get(user.getId());
                    AppImContactRespVO respVO = buildContactRespVO(user, actualDeptId);

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
                .limit(limit)
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

        String keyword = StrUtil.trimToNull(reqVO.getKeyword());
        List<AdminUserDO> users;
        Map<Long, Long> userToActualDeptMap;

        if (StrUtil.isNotBlank(keyword)) {
            // 关键字搜索模式：全量搜索用户，返回所有匹配用户（不限部门范围）
            // 3a. 全量按关键字搜索用户（不限定部门）
            users = userMapper.selectListByNickname(keyword);
            if (users == null || users.isEmpty()) {
                return PageResult.empty();
            }

            // 3b. 查出这些用户与部门的关联关系，建立 userId -> 部门ID 映射
            List<Long> matchedUserIds = users.stream()
                    .map(AdminUserDO::getId)
                    .collect(Collectors.toList());
            List<UserDeptRespVO> userDeptList = userDeptMapper.selectListByUserIds(matchedUserIds);
            userToActualDeptMap = new LinkedHashMap<>();
            if (userDeptList != null && !userDeptList.isEmpty()) {
                for (UserDeptRespVO ud : userDeptList) {
                    if (ud != null && ud.getUserId() != null && ud.getDeptId() != null) {
                        userToActualDeptMap.putIfAbsent(ud.getUserId(), ud.getDeptId());
                    }
                }
            }
            // 对于没有部门关联的用户，使用其主部门ID
            for (AdminUserDO user : users) {
                if (!userToActualDeptMap.containsKey(user.getId()) && user.getDeptId() != null) {
                    userToActualDeptMap.put(user.getId(), user.getDeptId());
                }
            }
        } else {
            // 无关键字模式：先查部门用户关联，再查用户（保持原逻辑）
            List<UserDeptDO> userDeptList = userDeptMapper.selectListByDeptIds(deptIds);
            if (userDeptList == null || userDeptList.isEmpty()) {
                return PageResult.empty();
            }
            userToActualDeptMap = new LinkedHashMap<>();
            for (UserDeptDO ud : userDeptList) {
                if (ud != null && ud.getUserId() != null && ud.getDeptId() != null) {
                    userToActualDeptMap.putIfAbsent(ud.getUserId(), ud.getDeptId());
                }
            }
            List<Long> contactIds = new ArrayList<>(userToActualDeptMap.keySet());
            if (contactIds.isEmpty()) {
                return PageResult.empty();
            }
            users = userMapper.selectBatchIds(contactIds);
        }

        if (users == null || users.isEmpty()) {
            return PageResult.empty();
        }

        // 4. 排序（按昵称 + ID）
        users.sort(Comparator
                .comparing((AdminUserDO u) -> u.getNickname() != null ? u.getNickname() : "")
                .thenComparing(u -> u.getId() != null ? u.getId() : 0L));

        long total = users.size();

        // 5. 内存分页
        int pageNo = reqVO.getPageNo() != null ? reqVO.getPageNo() : 1;
        int pageSize = reqVO.getPageSize() != null ? reqVO.getPageSize() : 10;
        if (pageNo < 1) {
            pageNo = 1;
        }
        if (pageSize < 1) {
            pageSize = 10;
        }
        int fromIndex = (pageNo - 1) * pageSize;
        if (fromIndex >= users.size()) {
            return new PageResult<>(Collections.emptyList(), total);
        }
        int toIndex = Math.min(fromIndex + pageSize, users.size());
        List<AdminUserDO> pageUsers = users.subList(fromIndex, toIndex);

        // 6. 查询当前用户的联系人设置
        List<ImContactSettingDO> settings = contactSettingMapper.selectListByUserId(userId);
        Map<Long, ImContactSettingDO> settingMap = settings.stream()
                .collect(Collectors.toMap(ImContactSettingDO::getContactId, s -> s, (a, b) -> a));

        // 7. 转换为VO（使用实际部门ID而非用户主部门ID）
        List<AppImContactRespVO> voList = pageUsers.stream()
                .map(u -> {
                    Long actualDeptId = userToActualDeptMap.get(u.getId());
                    AppImContactRespVO respVO = buildContactRespVO(u, actualDeptId);
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

        // 2. 查询这些部门下的用户ID（保留userId->deptId映射，用于返回实际部门而非用户主部门）
        List<UserDeptDO> userDeptList = userDeptMapper.selectListByDeptIds(deptIds);
        if (userDeptList == null || userDeptList.isEmpty()) {
            return new ArrayList<>();
        }
        // 建立 userId -> 实际部门ID 的映射（一个用户可能在多个部门，取第一个匹配）
        Map<Long, Long> userToActualDeptMap = new LinkedHashMap<>();
        for (UserDeptDO ud : userDeptList) {
            if (ud != null && ud.getUserId() != null && ud.getDeptId() != null) {
                userToActualDeptMap.putIfAbsent(ud.getUserId(), ud.getDeptId());
            }
        }
        List<Long> contactIds = new ArrayList<>(userToActualDeptMap.keySet());
        if (contactIds.isEmpty()) {
            return new ArrayList<>();
        }

        // 3. 查询联系人用户信息
        List<AdminUserDO> users = userMapper.selectBatchIds(contactIds);

        // 4. 查询当前用户的联系人设置
        List<ImContactSettingDO> settings = contactSettingMapper.selectListByUserId(userId);
        Map<Long, ImContactSettingDO> settingMap = settings.stream()
                .collect(Collectors.toMap(ImContactSettingDO::getContactId, s -> s, (a, b) -> a));

        // 5. 转换为VO并填充设置信息（使用实际部门ID而非用户主部门ID）
        return users.stream()
                .filter(u -> u != null && u.getId() != null)
                .map(u -> {
                    Long actualDeptId = userToActualDeptMap.get(u.getId());
                    AppImContactRespVO respVO = buildContactRespVO(u, actualDeptId);
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
        return searchContactsPage(userId, keyword, 1, 50).getList();
    }

    @Override
    public PageResult<AppImContactRespVO> searchContactsPage(Long userId, String keyword, Integer pageNo, Integer pageSize) {
        String keywordTrimmed = StrUtil.trimToEmpty(keyword);
        if (StrUtil.isBlank(keywordTrimmed)) {
            return PageResult.empty();
        }
        int finalPageNo = pageNo != null && pageNo > 0 ? pageNo : 1;
        int finalPageSize = pageSize != null && pageSize > 0 ? Math.min(pageSize, 50) : 20;
        long offset = (long) (finalPageNo - 1) * finalPageSize;

        // DB 侧模糊过滤 + 分页，避免全量用户加载到内存
        Long total = userMapper.countByNicknameLike(keywordTrimmed, userId);
        if (total == null || total <= 0L) {
            return PageResult.empty();
        }
        List<AdminUserDO> users = userMapper.selectListByNicknameLikePage(keywordTrimmed, userId, offset, finalPageSize);

        // 查询当前用户的联系人设置
        List<ImContactSettingDO> settings = contactSettingMapper.selectListByUserId(userId);
        Map<Long, ImContactSettingDO> settingMap = settings.stream()
                .collect(Collectors.toMap(ImContactSettingDO::getContactId, s -> s, (a, b) -> a));

        // 通过 user_dept 映射表获取用户实际部门
        List<Long> matchedUserIds = users.stream()
                .map(AdminUserDO::getId)
                .collect(Collectors.toList());
        Map<Long, Long> userToActualDeptMap = buildUserToActualDeptMap(matchedUserIds);

        // 过滤并转换
        List<AppImContactRespVO> list = users.stream()
                .map(user -> {
                    Long actualDeptId = userToActualDeptMap.get(user.getId());
                    AppImContactRespVO respVO = buildContactRespVO(user, actualDeptId);

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
        return new PageResult<>(list, total);
    }

    @Override
    public AppImContactRespVO getContact(Long userId, Long contactId) {
        // 查询联系人用户信息
        AdminUserDO user = userMapper.selectById(contactId);
        if (user == null) {
            throw exception(CONTACT_NOT_EXISTS);
        }

        // 通过 user_dept 映射表获取用户实际部门
        Map<Long, Long> userToActualDeptMap = buildUserToActualDeptMap(Collections.singletonList(contactId));
        Long actualDeptId = userToActualDeptMap.get(contactId);
        AppImContactRespVO respVO = buildContactRespVO(user, actualDeptId);

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
    public List<AppImContactRespVO> getStarContacts(Long userId, Integer limit) {
        // 查询星标联系人设置
        List<ImContactSettingDO> settings = contactSettingMapper.selectListByUserIdAndStar(userId);
        
        // 查询联系人信息
        List<Long> contactIds = settings.stream()
                .map(ImContactSettingDO::getContactId)
                .collect(Collectors.toList());
        
        if (contactIds.isEmpty()) {
            return new ArrayList<>();
        }

        // 按 limit 截断
        if (contactIds.size() > limit) {
            contactIds = contactIds.subList(0, limit);
        }

        List<AdminUserDO> users = userMapper.selectBatchIds(contactIds);
        Map<Long, ImContactSettingDO> settingMap = settings.stream()
                .collect(Collectors.toMap(ImContactSettingDO::getContactId, s -> s));

        // 通过 user_dept 映射表获取用户实际部门（与 getContactPageByDept 保持一致）
        Map<Long, Long> userToActualDeptMap = buildUserToActualDeptMap(contactIds);

        return users.stream()
                .map(user -> {
                    Long actualDeptId = userToActualDeptMap.get(user.getId());
                    AppImContactRespVO respVO = buildContactRespVO(user, actualDeptId);

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
     * 通过 user_dept 映射表构建 userId -> 实际部门ID 的映射
     * 对于没有映射关系的用户，回退到 user 主部门ID
     */
    private Map<Long, Long> buildUserToActualDeptMap(List<Long> userIds) {
        if (userIds == null || userIds.isEmpty()) {
            return Collections.emptyMap();
        }
        List<UserDeptRespVO> userDeptList = userDeptMapper.selectListByUserIds(userIds);
        Map<Long, Long> userToActualDeptMap = new LinkedHashMap<>();
        if (userDeptList != null && !userDeptList.isEmpty()) {
            for (UserDeptRespVO ud : userDeptList) {
                if (ud != null && ud.getUserId() != null && ud.getDeptId() != null) {
                    userToActualDeptMap.putIfAbsent(ud.getUserId(), ud.getDeptId());
                }
            }
        }
        // 对于没有部门关联的用户，使用其主部门ID
        List<AdminUserDO> users = userMapper.selectBatchIds(userIds);
        if (users != null) {
            for (AdminUserDO user : users) {
                if (!userToActualDeptMap.containsKey(user.getId()) && user.getDeptId() != null) {
                    userToActualDeptMap.put(user.getId(), user.getDeptId());
                }
            }
        }
        return userToActualDeptMap;
    }

    /**
     * 构建联系人响应VO
     */
    private AppImContactRespVO buildContactRespVO(AdminUserDO user) {
        return buildContactRespVO(user, user.getDeptId());
    }

    private AppImContactRespVO buildContactRespVO(AdminUserDO user, Long actualDeptId) {
        AppImContactRespVO respVO = new AppImContactRespVO();
        respVO.setId(user.getId());
        respVO.setNickname(user.getNickname());
        respVO.setAvatar(user.getAvatar());
        respVO.setDeptId(actualDeptId);
        
        // 查询部门信息
        if (actualDeptId != null) {
            DeptDO dept = deptMapper.selectById(actualDeptId);
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
