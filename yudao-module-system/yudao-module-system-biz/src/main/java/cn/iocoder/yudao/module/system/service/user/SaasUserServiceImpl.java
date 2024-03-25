package cn.iocoder.yudao.module.system.service.user;

import static cn.iocoder.yudao.framework.common.exception.util.ServiceExceptionUtil.exception;
import static cn.iocoder.yudao.module.system.enums.ErrorCodeConstants.USER_NOT_EXISTS;

import cn.iocoder.yudao.module.system.dal.dataobject.user.SaasUserDO;
import cn.iocoder.yudao.module.system.dal.mysql.user.SaasUserMapper;
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
    public SaasUserDO getUserByAccount(String account) {
        return saasUserMapper.selectByAccount(account);
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

}
