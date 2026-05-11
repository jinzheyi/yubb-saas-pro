package com.shengyu.module.infra.framework.filepreview.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "im.file-preview")
@Data
public class ImFilePreviewProperties {

    private final Kkfileview kkfileview = new Kkfileview();

    @Data
    public static class Kkfileview {

        /**
         * 是否启用 kkFileView 预览策略。
         */
        private boolean enabled = true;

        /**
         * 应用启动时是否自动拉起 kkFileView 进程。
         */
        private boolean autoStart = false;

        /**
         * kkFileView 对外访问基地址。
         */
        private String baseUrl = "http://127.0.0.1:48090";

        /**
         * kkFileView 拉取业务文件时使用的源站基地址。
         * 仅替换下载链接的协议、主机和端口，路径与查询参数保持不变。
         * 例如 Docker 环境可配置为 http://host.docker.internal:48080
         */
        private String sourceBaseUrl;

        /**
         * 启动命令，例如 java -jar kkFileView.jar --server.port=48090
         */
        private String startupCommand;

        /**
         * 启动工作目录。
         */
        private String workingDirectory;

        /**
         * 启动就绪超时时间（秒）。
         */
        private int startupTimeoutSeconds = 45;

        /**
         * 就绪探测间隔（毫秒）。
         */
        private int readyCheckIntervalMillis = 1000;

        /**
         * 应用关闭时是否同步关闭当前应用拉起的 kkFileView 进程。
         */
        private boolean stopOnShutdown = true;
    }
}
