package com.shengyu.module.system.service.im.spi;

import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.websocket.core.service.SensitiveWordFilterService;
import com.shengyu.module.system.service.sensitiveword.SensitiveWordService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;

/**
 * System 模块 - 敏感词过滤服务实现
 * 
 * 实现 WebSocket 中间件的 SensitiveWordFilterService SPI 接口
 * 集成系统的敏感词服务，对IM消息进行敏感词过滤
 * 
 * 【过滤策略】
 * 1. 检测文本中的敏感词
 * 2. 将敏感词替换为 ***
 * 3. 记录敏感词日志（用于审计）
 * 
 * 【性能优化】
 * 1. 敏感词服务内部使用 DFA 算法，时间复杂度 O(n)
 * 2. 敏感词库缓存在内存中，避免频繁查询数据库
 * 3. 支持按标签分类过滤（可扩展）
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class SystemSensitiveWordFilterServiceImpl implements SensitiveWordFilterService {

    @Resource
    private SensitiveWordService sensitiveWordService;

    @Override
    public String filter(String text) {
        if (StrUtil.isBlank(text)) {
            return text;
        }

        try {
            // 1. 检测文本中的敏感词
            List<String> invalidWords = sensitiveWordService.validateText(text, null);
            
            if (invalidWords == null || invalidWords.isEmpty()) {
                return text;
            }

            // 2. 替换敏感词为 ***
            String filtered = text;
            for (String word : invalidWords) {
                filtered = filtered.replace(word, "***");
            }

            // 3. 记录敏感词日志
            log.warn("[SensitiveWordFilter] 检测到敏感词, 原文长度: {}, 敏感词数量: {}, 敏感词: {}", 
                    text.length(), invalidWords.size(), invalidWords);

            return filtered;

        } catch (Exception e) {
            log.error("[SensitiveWordFilter] 敏感词过滤失败, 返回原文", e);
            return text;
        }
    }

    @Override
    public boolean containsSensitiveWord(String text) {
        if (StrUtil.isBlank(text)) {
            return false;
        }

        try {
            // 使用敏感词服务的 isTextValid 方法
            // 注意：isTextValid 返回 true 表示文本合法（不包含敏感词）
            boolean isValid = sensitiveWordService.isTextValid(text, null);
            return !isValid; // 取反：true 表示包含敏感词

        } catch (Exception e) {
            log.error("[SensitiveWordFilter] 检查敏感词失败", e);
            return false;
        }
    }

}
