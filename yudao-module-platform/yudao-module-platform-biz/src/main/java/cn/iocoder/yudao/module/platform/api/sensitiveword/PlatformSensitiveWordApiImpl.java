package cn.iocoder.yudao.module.platform.api.sensitiveword;

import cn.iocoder.yudao.module.platform.service.sensitiveword.PlatformSensitiveWordService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;

/**
 * 敏感词 API 实现类
 *
 * @author 永不言败
 */
@Service
public class PlatformSensitiveWordApiImpl implements SensitiveWordApi {

    @Resource
    private PlatformSensitiveWordService platformSensitiveWordService;

    @Override
    public List<String> validateText(String text, List<String> tags) {
        return platformSensitiveWordService.validateText(text, tags);
    }

    @Override
    public boolean isTextValid(String text, List<String> tags) {
        return platformSensitiveWordService.isTextValid(text, tags);
    }
}
