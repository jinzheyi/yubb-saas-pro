package com.shengyu.module.system.controller.app.im;

import cn.hutool.core.util.StrUtil;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;

@Tag(name = "移动端 - IM 搜索")
@RestController
@RequestMapping("/system/im/search")
@Validated
@DataPermission(enable = false)
public class AppImSearchController {

    @Value("${im.search.hot-keywords:}")
    private String hotKeywords;

    @GetMapping("/hot")
    @Operation(summary = "获取热门搜索词")
    @Parameter(name = "limit", description = "返回条数", required = false)
    public CommonResult<List<String>> getHotSearch(@RequestParam(value = "limit", required = false) Integer limit) {
        int finalLimit = limit != null && limit > 0 ? limit : 10;

        List<String> list = parseHotKeywords(hotKeywords);
        if (list.isEmpty()) {
            list = Arrays.asList("工作汇报", "会议通知", "项目文档", "周报");
        }
        if (list.size() <= finalLimit) {
            return success(list);
        }
        return success(new ArrayList<>(list.subList(0, finalLimit)));
    }

    private List<String> parseHotKeywords(String value) {
        if (StrUtil.isBlank(value)) {
            return new ArrayList<>();
        }
        String normalized = value.replace('\n', ',').replace('\r', ',').replace('，', ',').replace(';', ',').replace('；', ',');
        String[] parts = normalized.split(",");
        List<String> result = new ArrayList<>();
        for (String p : parts) {
            if (StrUtil.isBlank(p)) {
                continue;
            }
            String s = StrUtil.trim(p);
            if (StrUtil.isBlank(s)) {
                continue;
            }
            result.add(s);
        }
        return result;
    }

}
