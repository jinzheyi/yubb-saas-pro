package com.shengyu.module.system.service.im.push;

import com.google.auth.oauth2.AccessToken;
import com.google.auth.oauth2.GoogleCredentials;
import com.shengyu.module.system.config.FcmPushProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Collections;

/** Caches only the short-lived OAuth bearer, never logs or exposes key JSON. */
@Component
@RequiredArgsConstructor
public class FcmAccessTokenProvider {
    private static final String FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
    private final FcmPushProperties properties;
    private GoogleCredentials credentials;

    public synchronized String getAccessToken() throws Exception {
        if (!properties.configured()) return null;
        if (credentials == null) {
            try (InputStream input = Files.newInputStream(Paths.get(properties.getCredentialFile()))) {
                credentials = GoogleCredentials.fromStream(input)
                        .createScoped(Collections.singleton(FCM_SCOPE));
            }
        }
        credentials.refreshIfExpired();
        AccessToken token = credentials.getAccessToken();
        return token == null ? null : token.getTokenValue();
    }
}
