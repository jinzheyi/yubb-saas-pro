package com.shengyu.framework.banner.core;

import cn.hutool.core.thread.ThreadUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.util.ClassUtils;

import java.util.concurrent.TimeUnit;

/**
 * 项目启动成功后，提供文档相关的地址
 *
 * @author 圣钰科技
 */
@Slf4j
public class BannerApplicationRunner implements ApplicationRunner {

    @Override
    public void run(ApplicationArguments args) {
        ThreadUtil.execute(() -> {
            ThreadUtil.sleep(1, TimeUnit.SECONDS); // 延迟 1 秒，保证输出到结尾
            log.info("\n----------------------------------------------------------\n\t" +
                            "项目启动成功！\n\t" +
                            "文档地址: \t{} \n\t" +
                            "----------------------------------------------------------",
                    "http://www.shengyukj.top");
//            // 支付平台
//            if (isNotPresent("com.shengyu.module.pay.framework.pay.config.PayConfiguration")) {
//                System.out.println("[支付系统 shengyu-module-pay - 已禁用][参考 https://doc.iocoder.cn/pay/build/ 开启]");
//            }
        });
    }

    private static boolean isNotPresent(String className) {
        return !ClassUtils.isPresent(className, ClassUtils.getDefaultClassLoader());
    }

}
