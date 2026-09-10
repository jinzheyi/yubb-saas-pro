package com.shengyu.module.system.service.user;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.AUTH_LOGIN_BAD_CREDENTIALS;
import static com.shengyu.module.system.enums.ErrorCodeConstants.USER_NOT_EXISTS;

import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.util.string.StrUtils;
import com.shengyu.module.system.dal.dataobject.user.SaasUserDO;
import com.shengyu.module.system.dal.mysql.user.SaasUserMapper;
import com.google.common.annotations.VisibleForTesting;
import javax.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * @author zhusy
 * @description: 后台SaaS用户接口实现
 * @date 2024/3/17 23:25
 */
@Service
@Slf4j
public class SaasUserServiceImpl implements SaasUserService{

    @Resource
    private SaasUserMapper saasUserMapper;

    @Resource
    private PasswordEncoder passwordEncoder;

    @Override
    public SaasUserDO getUserByUsername(String username) {
        return saasUserMapper.selectByUsername(username);
    }

    @Override
    public boolean isPasswordMatch(String rawPassword, String encodedPassword) {
        return passwordEncoder.matches(rawPassword, encodedPassword);
    }

    @Override
    public SaasUserDO getUser(Long id) {
        return saasUserMapper.selectById(id);
    }

    @Override
    public void updateUserDefaultTenant(Long id, Long defaultTenant) {
        // 校验用户存在
        validateUserExists(id);
        // 更新上一次登录的租户id
        SaasUserDO updateObj = new SaasUserDO();
        updateObj.setId(id);
        updateObj.setDefaultTenant(defaultTenant);
        saasUserMapper.updateById(updateObj);
    }

    @VisibleForTesting
    void validateUserExists(Long id) {
        if (id == null) {
            return;
        }
        SaasUserDO user = saasUserMapper.selectById(id);
        if (user == null) {
            throw exception(USER_NOT_EXISTS);
        }
    }

    @Override
    public SaasUserDO getUserByMobile(String mobile) {
        return saasUserMapper.selectByMobile(mobile);
    }

    @Override
    public SaasUserDO registerOrValidateEmailUser(String username, String password, String mobile) {
        String email = StrUtil.trim(username).toLowerCase();
        SaasUserDO user = saasUserMapper.selectByUsername(email);
        if (user != null) {
            if (!passwordEncoder.matches(password, user.getPassword())) {
                throw exception(AUTH_LOGIN_BAD_CREDENTIALS);
            }
            return user;
        }

        SaasUserDO createObj = new SaasUserDO();
        createObj.setUsername(email);
        createObj.setPassword(passwordEncoder.encode(password));
        initializeSelfRegisteredAuditFields(createObj);
        if (StrUtil.isNotBlank(mobile)) {
            createObj.setMobile(StrUtil.trim(mobile));
        }
        saasUserMapper.insert(createObj);
        completeSelfRegisteredAuditFields(createObj);
        createObj.setOpenId(StrUtils.uniqueId(createObj.getId()));
        saasUserMapper.updateById(createObj);
        return createObj;
    }

    @Override
    public SaasUserDO registerOrGetVerifiedEmailUser(String username, String generatedPassword, String mobile) {
        String email = StrUtil.trim(username).toLowerCase();
        SaasUserDO user = saasUserMapper.selectByUsername(email);
        if (user != null) {
            return user;
        }
        SaasUserDO createObj = new SaasUserDO();
        createObj.setUsername(email);
        createObj.setPassword(passwordEncoder.encode(generatedPassword));
        initializeSelfRegisteredAuditFields(createObj);
        if (StrUtil.isNotBlank(mobile)) {
            createObj.setMobile(StrUtil.trim(mobile));
        }
        saasUserMapper.insert(createObj);
        completeSelfRegisteredAuditFields(createObj);
        createObj.setOpenId(StrUtils.uniqueId(createObj.getId()));
        saasUserMapper.updateById(createObj);
        return createObj;
    }

    /**
     * 邮箱自助注册没有既有登录人。先使用系统操作者使插入可审计，拿到用户编号后再回写为用户本人。
     */
    private void initializeSelfRegisteredAuditFields(SaasUserDO user) {
        user.setCreator("0");
        user.setUpdater("0");
    }

    private void completeSelfRegisteredAuditFields(SaasUserDO user) {
        String userId = String.valueOf(user.getId());
        user.setCreator(userId);
        user.setUpdater(userId);
    }

}
