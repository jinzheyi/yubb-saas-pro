package com.shengyu.module.infra.framework.filepreview.core;

import cn.hutool.core.util.StrUtil;
import cn.hutool.http.HttpRequest;
import cn.hutool.http.HttpResponse;
import com.shengyu.module.infra.framework.filepreview.config.ImFilePreviewProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.DisposableBean;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.TimeUnit;

@Component
@RequiredArgsConstructor
@Slf4j
public class KkFileViewProcessRunner implements ApplicationRunner, DisposableBean {

    private final ImFilePreviewProperties filePreviewProperties;

    private volatile Process process;
    private volatile boolean startedByApp = false;

    @Override
    public void run(ApplicationArguments args) {
        ImFilePreviewProperties.Kkfileview properties = filePreviewProperties.getKkfileview();
        if (!properties.isEnabled() || !properties.isAutoStart()) {
            return;
        }
        String baseUrl = StrUtil.blankToDefault(properties.getBaseUrl(), "").trim();
        if (baseUrl.isEmpty()) {
            log.warn("[kkFileView] 已开启 auto-start，但 base-url 为空，跳过启动");
            return;
        }
        if (isServiceReachable(baseUrl)) {
            log.info("[kkFileView] 服务已可用，无需重复启动，baseUrl={}", baseUrl);
            return;
        }
        String startupCommand = StrUtil.blankToDefault(properties.getStartupCommand(), "").trim();
        if (startupCommand.isEmpty()) {
            log.warn("[kkFileView] 已开启 auto-start，但 startup-command 为空，跳过启动");
            return;
        }

        try {
            ProcessBuilder builder = new ProcessBuilder(buildShellCommand(startupCommand));
            String workingDirectory = StrUtil.blankToDefault(properties.getWorkingDirectory(), "").trim();
            if (!workingDirectory.isEmpty()) {
                builder.directory(new File(workingDirectory));
            }
            builder.redirectErrorStream(true);
            process = builder.start();
            startedByApp = true;
            consumeOutput(process);
            log.info("[kkFileView] 已发起启动命令：{}", startupCommand);

            if (awaitReady(properties, baseUrl)) {
                log.info("[kkFileView] 启动成功，baseUrl={}", baseUrl);
                return;
            }
            log.error("[kkFileView] 在 {} 秒内未就绪，baseUrl={}",
                    properties.getStartupTimeoutSeconds(), baseUrl);
            stopProcess();
        } catch (Exception e) {
            log.error("[kkFileView] 自动启动失败", e);
            stopProcess();
        }
    }

    private List<String> buildShellCommand(String startupCommand) {
        String osName = System.getProperty("os.name", "").toLowerCase(Locale.ROOT);
        if (osName.contains("win")) {
            return Arrays.asList("cmd", "/c", startupCommand);
        }
        return Arrays.asList("sh", "-c", startupCommand);
    }

    private void consumeOutput(Process runningProcess) {
        Thread thread = new Thread(() -> {
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(runningProcess.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    log.info("[kkFileView] {}", line);
                }
            } catch (Exception e) {
                log.debug("[kkFileView] 读取输出流结束: {}", e.getMessage());
            }
        }, "kkfileview-output");
        thread.setDaemon(true);
        thread.start();
    }

    private boolean awaitReady(ImFilePreviewProperties.Kkfileview properties, String baseUrl) throws InterruptedException {
        long deadline = System.currentTimeMillis() + properties.getStartupTimeoutSeconds() * 1000L;
        int interval = Math.max(properties.getReadyCheckIntervalMillis(), 200);
        while (System.currentTimeMillis() < deadline) {
            if (isServiceReachable(baseUrl)) {
                return true;
            }
            Process current = process;
            if (current != null && !current.isAlive()) {
                log.error("[kkFileView] 进程已提前退出，exitCode={}", current.exitValue());
                return false;
            }
            Thread.sleep(interval);
        }
        return false;
    }

    private boolean isServiceReachable(String baseUrl) {
        try (HttpResponse response = HttpRequest.get(baseUrl)
                .timeout(2000)
                .setFollowRedirects(true)
                .execute()) {
            return response.getStatus() < 500;
        } catch (Exception e) {
            return false;
        }
    }

    private void stopProcess() {
        Process current = process;
        process = null;
        if (current == null) {
            return;
        }
        current.destroy();
        try {
            if (!current.waitFor(10, TimeUnit.SECONDS)) {
                current.destroyForcibly();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            current.destroyForcibly();
        }
    }

    @Override
    public void destroy() {
        ImFilePreviewProperties.Kkfileview properties = filePreviewProperties.getKkfileview();
        if (!startedByApp || !properties.isStopOnShutdown()) {
            return;
        }
        stopProcess();
        log.info("[kkFileView] 已随应用关闭自动停止");
    }
}
