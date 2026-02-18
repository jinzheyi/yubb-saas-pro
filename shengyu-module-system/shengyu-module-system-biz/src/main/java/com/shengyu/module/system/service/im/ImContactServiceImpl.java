package com.shengyu.module.system.service.im;

import cn.hutool.core.util.StrUtil;
import cn.hutool.extra.pinyin.PinyinUtil;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.system.controller.app.im.vo.contact.AppImContactRespVO;
import com.shengyu.module.system.controller.app.im.vo.contact.AppImContactSettingUpdateReqVO;
import com.shengyu.module.system.dal.dataobject.dept.DeptDO;
import com.shengyu.module.system.dal.dataobject.im.ImContactSettingDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;

import java.util.ArrayList;
import com.shengyu.module.system.dal.mysql.dept.DeptMapper;
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
                        respVO.setRemarkName(setting.getRemarkName());
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
                .filter(user -> {
                    // 按姓名或备注名搜索
                    if (StrUtil.contains(user.getNickname(), keyword)) {
                        return true;
                    }
                    ImContactSettingDO setting = settingMap.get(user.getId());
                    return setting != null && StrUtil.contains(setting.getRemarkName(), keyword);
                })
                .map(user -> {
                    AppImContactRespVO respVO = buildContactRespVO(user);
                    
                    // 填充个性化设置
                    ImContactSettingDO setting = settingMap.get(user.getId());
                    if (setting != null) {
                        respVO.setRemarkName(setting.getRemarkName());
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
            respVO.setRemarkName(setting.getRemarkName());
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
                        respVO.setRemarkName(setting.getRemarkName());
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
        
        // 获取拼音首字母
        if (StrUtil.isNotBlank(user.getNickname())) {
            String firstChar = PinyinUtil.getFirstLetter(user.getNickname(), "");
            respVO.setPinyin(firstChar.toUpperCase());
        }
        
        return respVO;
    }

}
