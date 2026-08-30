package com.shengyu.module.system.service.im.push;

import cn.hutool.json.JSONUtil;
import com.shengyu.module.system.config.FcmPushProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class FcmV1Client {
    private final FcmPushProperties properties;
    private final FcmAccessTokenProvider accessTokenProvider;
    public FcmDispatchStatus send(String token, Map<String, Object> message) {
        if (!properties.configured()) return FcmDispatchStatus.NOT_CONFIGURED;
        try {
            String accessToken = accessTokenProvider.getAccessToken();
            if (accessToken == null || accessToken.isEmpty()) return FcmDispatchStatus.NOT_CONFIGURED;
            if (properties.isDryRun()) return FcmDispatchStatus.DELIVERED;
            HttpURLConnection connection = (HttpURLConnection) new URL("https://fcm.googleapis.com/v1/projects/" + properties.getProjectId() + "/messages:send").openConnection();
            connection.setRequestMethod("POST"); connection.setDoOutput(true);
            connection.setConnectTimeout(properties.getConnectTimeoutMs()); connection.setReadTimeout(properties.getReadTimeoutMs());
            connection.setRequestProperty("Authorization", "Bearer " + accessToken);
            connection.setRequestProperty("Content-Type", "application/json; charset=utf-8");
            try (OutputStream out = connection.getOutputStream()) { out.write(JSONUtil.toJsonStr(Collections.singletonMap("message", message)).getBytes(StandardCharsets.UTF_8)); }
            int code = connection.getResponseCode();
            if (code >= 200 && code < 300) return FcmDispatchStatus.DELIVERED;
            String response = read(connection.getErrorStream());
            if (code == 404 || (code == 400 && response.contains("UNREGISTERED")) || response.contains("INVALID_ARGUMENT")) return FcmDispatchStatus.PERMANENT_FAILURE;
            return code >= 500 || code == 429 ? FcmDispatchStatus.RETRYABLE_FAILURE : FcmDispatchStatus.PERMANENT_FAILURE;
        } catch (IOException e) { log.warn("[FcmV1] delivery transport failure, projectId={}", properties.getProjectId()); return FcmDispatchStatus.RETRYABLE_FAILURE; }
        catch (Exception e) { log.warn("[FcmV1] credential/configuration failure, projectId={}", properties.getProjectId()); return FcmDispatchStatus.NOT_CONFIGURED; }
    }
    private String read(InputStream input) throws IOException { if (input == null) return ""; try (BufferedReader r = new BufferedReader(new InputStreamReader(input, StandardCharsets.UTF_8))) { StringBuilder b = new StringBuilder(); String line; while ((line = r.readLine()) != null) b.append(line); return b.toString(); } }
}
