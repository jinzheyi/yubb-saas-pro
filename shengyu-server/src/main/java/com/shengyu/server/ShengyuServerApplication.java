package com.shengyu.server;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * 项目的启动类
 *
 * 如果你碰到启动的问题，请认真阅读 http://shengyukj.top/guide/explain/experience 文章
 * 如果你碰到启动的问题，请认真阅读 http://shengyukj.top/guide/explain/experience 文章
 * 如果你碰到启动的问题，请认真阅读 http://shengyukj.top/guide/explain/experience 文章
 *
 * @author 圣钰科技
 */
@SuppressWarnings("SpringComponentScan") // 忽略 IDEA 无法识别 ${shengyu.info.base-package}
@SpringBootApplication(scanBasePackages = {"${shengyu.info.base-package}.server", "${shengyu.info.base-package}.module"})
public class ShengyuServerApplication {

    public static void main(String[] args) {
        // 如果你碰到启动的问题，请认真阅读 http://shengyukj.top/guide/explain/experience 文章
        // 如果你碰到启动的问题，请认真阅读 http://shengyukj.top/guide/explain/experience 文章
        // 如果你碰到启动的问题，请认真阅读 http://shengyukj.top/guide/explain/experience 文章

        SpringApplication.run(ShengyuServerApplication.class, args);
//        new SpringApplicationBuilder(ShengyuServerApplication.class)
//                .applicationStartup(new BufferingApplicationStartup(20480))
//                .run(args);

        // 如果你碰到启动的问题，请认真阅读 http://shengyukj.top/guide/explain/experience 文章
        // 如果你碰到启动的问题，请认真阅读 http://shengyukj.top/guide/explain/experience 文章
        // 如果你碰到启动的问题，请认真阅读 http://shengyukj.top/guide/explain/experience 文章
    }

}
