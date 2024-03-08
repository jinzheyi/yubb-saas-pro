package cn.iocoder.yudao.framework.web.core.filter;

import cn.hutool.core.util.StrUtil;
import cn.iocoder.yudao.framework.web.config.WebProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.servlet.http.HttpServletRequest;

/**
 * 过滤 /center-api 等 平台端API 请求的过滤器
 *
 * @author zhusy
 * @since 2022/7/26
 */
@RequiredArgsConstructor
public abstract class PlatformApiRequestFilter extends OncePerRequestFilter {

    protected final WebProperties webProperties;

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        // 只过滤 API 请求的地址
        return !StrUtil.startWithAny(request.getRequestURI(), webProperties.getPlatformApi().getPrefix());
    }

}
