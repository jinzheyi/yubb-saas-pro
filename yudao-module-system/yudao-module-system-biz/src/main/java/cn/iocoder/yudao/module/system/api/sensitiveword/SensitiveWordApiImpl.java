package cn.iocoder.yudao.module.system.api.sensitiveword;

import cn.iocoder.yudao.module.system.service.sensitiveword.SensitiveWordService;
import java.util.List;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;

/**
 * 敏感词 API 实现类
 *
 * @author 永不言败
 */
@Service
public class SensitiveWordApiImpl implements SensitiveWordApi {

    @Resource
    private SensitiveWordService sensitiveWordService;

    @Override
    public List<String> validateText(String text, List<String> tags) {
        return sensitiveWordService.validateText(text, tags);
    }

    @Override
    public boolean isTextValid(String text, List<String> tags) {
        return sensitiveWordService.isTextValid(text, tags);
    }
}
