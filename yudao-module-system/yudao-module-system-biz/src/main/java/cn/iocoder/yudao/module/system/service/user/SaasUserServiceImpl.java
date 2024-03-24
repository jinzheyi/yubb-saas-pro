package cn.iocoder.yudao.module.system.service.user;

import cn.iocoder.yudao.module.system.dal.dataobject.user.SaasUserDO;
import cn.iocoder.yudao.module.system.dal.mysql.user.SaasUserMapper;
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

}
