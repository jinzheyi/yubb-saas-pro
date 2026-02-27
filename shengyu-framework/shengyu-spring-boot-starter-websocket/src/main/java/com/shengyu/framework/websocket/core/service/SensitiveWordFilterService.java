package com.shengyu.framework.websocket.core.service;

/**
 * 敏感词过滤服务接口（SPI）
 * 
 * 【架构设计】
 * 这是一个可选的 SPI 接口，由业务模块根据需要实现。
 * 
 * 中间件不提供默认实现，如果业务模块没有实现此接口，则不进行敏感词过滤。
 * 业务模块可以实现此接口来提供敏感词过滤能力。
 * 
 * 【实现方式】
 * 在业务模块中创建实现类：
 * 
 * <pre>
 * &#64;Service
 * public class SystemSensitiveWordFilterServiceImpl implements SensitiveWordFilterService {
 *     
 *     &#64;Autowired
 *     private SensitiveWordService sensitiveWordService;
 *     
 *     &#64;Override
 *     public String filter(String text) {
 *         List&lt;String&gt; invalidWords = sensitiveWordService.validateText(text, null);
 *         if (invalidWords.isEmpty()) {
 *             return text;
 *         }
 *         // 替换敏感词为 ***
 *         String filtered = text;
 *         for (String word : invalidWords) {
 *             filtered = filtered.replace(word, "***");
 *         }
 *         return filtered;
 *     }
 * }
 * </pre>
 *
 * @author 圣钰科技
 */
public interface SensitiveWordFilterService {

    /**
     * 过滤文本中的敏感词
     * 
     * @param text 原始文本
     * @return 过滤后的文本
     */
    String filter(String text);

    /**
     * 检查文本是否包含敏感词
     * 
     * @param text 文本
     * @return true-包含敏感词，false-不包含
     */
    boolean containsSensitiveWord(String text);

}
