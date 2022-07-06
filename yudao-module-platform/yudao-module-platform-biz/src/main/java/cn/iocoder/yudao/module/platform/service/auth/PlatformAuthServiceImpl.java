package cn.iocoder.yudao.module.platform.service.auth;

import cn.iocoder.yudao.module.platform.controller.admin.auth.vo.AuthLoginReqVO;
import cn.iocoder.yudao.module.platform.controller.admin.auth.vo.AuthLoginRespVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Auth Service 实现类
 *
 * @author 朱述勇
 * @since 2022/7/6 2:17 PM
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 */
@Slf4j
@Service
public class PlatformAuthServiceImpl implements PlatformAuthService {

    @Override
    public AuthLoginRespVO login(AuthLoginReqVO reqVO) {
        return null;
    }

}
