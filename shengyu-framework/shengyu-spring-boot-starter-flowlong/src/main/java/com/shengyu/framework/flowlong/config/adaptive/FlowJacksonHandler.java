/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.framework.flowlong.config.adaptive;

import cn.hutool.core.text.CharSequenceUtil;
import com.fasterxml.jackson.core.type.TypeReference;
import com.shengyu.framework.flowlong.engine.assist.Assert;
import com.shengyu.framework.flowlong.engine.handler.FlowJsonHandler;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import java.util.Collections;
import java.util.Map;

/**
 * Jackson JSON 解析处理器接口
 *
 * <p>
 * <a href="https://aizuda.com">官网</a>尊重知识产权，不允许非法使用，后果自负
 * </p>
 *
 * @author hubin
 * @since 1.0
 */
public class FlowJacksonHandler implements FlowJsonHandler {
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    static {
        OBJECT_MAPPER.registerModule(new JavaTimeModule());
        OBJECT_MAPPER.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        OBJECT_MAPPER.setSerializationInclusion(JsonInclude.Include.NON_EMPTY);
    }

    @Override
    public String toJson(Object object) {
        if (null == object) {
            return null;
        }
        try {
            return OBJECT_MAPPER.writeValueAsString(object);
        } catch (JsonProcessingException e) {
            throw Assert.throwable(e);
        }
    }

    @Override
    public <T> T fromJson(String jsonString, Class<T> clazz) {
        if (null == jsonString || null == clazz) {
            return null;
        }
        try {
            return OBJECT_MAPPER.readValue(jsonString, clazz);
        } catch (JsonProcessingException e) {
            throw Assert.throwable(e);
        }
    }

    @Override
    public Map<String, Object> obj2map(Object obj) {
        if (obj == null) {
            return Collections.emptyMap();
        }
        return OBJECT_MAPPER.convertValue(obj, new TypeReference<Map<String, Object>>() {});
    }

    @Override
    public Map<String, Object> str2map(String str) {
        if (CharSequenceUtil.isBlank(str)) {
            return Collections.emptyMap();
        }
        try {
            return OBJECT_MAPPER.readValue(str, new TypeReference<Map<String, Object>>() {});
        } catch (JsonProcessingException e) {
            throw Assert.throwable(e);
        }
    }

}
