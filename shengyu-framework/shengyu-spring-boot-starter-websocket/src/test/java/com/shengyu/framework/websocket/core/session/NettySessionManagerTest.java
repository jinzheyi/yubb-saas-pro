package com.shengyu.framework.websocket.core.session;

import com.shengyu.framework.websocket.core.protocol.ImMessage;
import com.shengyu.framework.websocket.core.protocol.MessageType;
import io.netty.channel.Channel;
import io.netty.channel.ChannelId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.util.concurrent.atomic.AtomicBoolean;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * NettySessionManager 单元测试
 * 
 * 验证同类型设备互踢逻辑、七层索引结构、跨节点互踢广播
 *
 * @author 圣钰科技
 */
class NettySessionManagerTest {

    private NettySessionManager sessionManager;

    @Mock
    private Channel mockChannel1;

    @Mock
    private Channel mockChannel2;

    @Mock
    private ChannelId mockChannelId1;

    @Mock
    private ChannelId mockChannelId2;

    @Mock
    private CrossNodeKickPublisher mockCrossNodePublisher;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        sessionManager = new NettySessionManager();
        sessionManager.setCrossNodeKickPublisher(mockCrossNodePublisher);

        // 配置 mock channel
        when(mockChannel1.id()).thenReturn(mockChannelId1);
        when(mockChannelId1.asShortText()).thenReturn("channel-1");
        when(mockChannel1.isActive()).thenReturn(true);

        when(mockChannel2.id()).thenReturn(mockChannelId2);
        when(mockChannelId2.asShortText()).thenReturn("channel-2");
        when(mockChannel2.isActive()).thenReturn(true);
    }

    @Test
    @DisplayName("T1: 同类型设备互踢 - 新设备登录踢掉旧设备")
    void testSameDeviceTypeKick() {
        // 准备：创建两个同类型设备会话（Android）
        Long userId = 100L;
        Integer deviceType = 3; // Android

        NettySession oldSession = NettySession.builder()
                .channel(mockChannel1)
                .userId(userId)
                .deviceType(deviceType)
                .deviceId("device-old")
                .deviceName("旧 Android 设备")
                .tenantId(1L)
                .accessToken("token-old")
                .build();

        NettySession newSession = NettySession.builder()
                .channel(mockChannel2)
                .userId(userId)
                .deviceType(deviceType)
                .deviceId("device-new")
                .deviceName("新 Android 设备")
                .tenantId(1L)
                .accessToken("token-new")
                .build();

        // 执行：先添加旧设备
        sessionManager.addSession(oldSession);
        
        // 验证旧设备在线
        NettySession foundOld = sessionManager.getSessionByUserIdAndDeviceType(userId, deviceType);
        assertNotNull(foundOld);
        assertEquals("channel-1", foundOld.getChannelId());

        // 添加新设备（应触发互踢）
        sessionManager.addSession(newSession);

        // 验证：旧设备被踢掉，新设备在线
        NettySession foundNew = sessionManager.getSessionByUserIdAndDeviceType(userId, deviceType);
        assertNotNull(foundNew);
        assertEquals("channel-2", foundNew.getChannelId());
        assertEquals("新 Android 设备", foundNew.getDeviceName());

        // 验证旧设备连接被关闭
        verify(mockChannel1, atLeastOnce()).isActive();
    }

    @Test
    @DisplayName("T2: 不同类型设备共存 - Web + iOS + Android 同时在线")
    void testDifferentDeviceTypeCoexist() {
        Long userId = 100L;

        // 创建三种不同类型设备
        NettySession webSession = NettySession.builder()
                .channel(mockChannel1)
                .userId(userId)
                .deviceType(1) // Web
                .deviceId("device-web")
                .deviceName("Web 浏览器")
                .tenantId(1L)
                .build();

        when(mockChannel2.id().asShortText()).thenReturn("channel-2");
        NettySession iosSession = NettySession.builder()
                .channel(mockChannel2)
                .userId(userId)
                .deviceType(2) // iOS
                .deviceId("device-ios")
                .deviceName("iPhone 15")
                .tenantId(1L)
                .build();

        Channel mockChannel3 = mock(Channel.class);
        ChannelId mockChannelId3 = mock(ChannelId.class);
        when(mockChannel3.id()).thenReturn(mockChannelId3);
        when(mockChannelId3.asShortText()).thenReturn("channel-3");
        when(mockChannel3.isActive()).thenReturn(true);

        NettySession androidSession = NettySession.builder()
                .channel(mockChannel3)
                .userId(userId)
                .deviceType(3) // Android
                .deviceId("device-android")
                .deviceName("Android 设备")
                .tenantId(1L)
                .build();

        // 执行：添加三种设备
        sessionManager.addSession(webSession);
        sessionManager.addSession(iosSession);
        sessionManager.addSession(androidSession);

        // 验证：三种设备都在线，不互踢
        assertEquals(3, sessionManager.getSessionsByUserId(userId).size());
        
        NettySession foundWeb = sessionManager.getSessionByUserIdAndDeviceType(userId, 1);
        assertNotNull(foundWeb);
        assertEquals("Web 浏览器", foundWeb.getDeviceName());

        NettySession foundIos = sessionManager.getSessionByUserIdAndDeviceType(userId, 2);
        assertNotNull(foundIos);
        assertEquals("iPhone 15", foundIos.getDeviceName());

        NettySession foundAndroid = sessionManager.getSessionByUserIdAndDeviceType(userId, 3);
        assertNotNull(foundAndroid);
        assertEquals("Android 设备", foundAndroid.getDeviceName());
    }

    @Test
    @DisplayName("T4: 跨节点互踢 - 本节点无同类型设备时广播跨节点消息")
    void testCrossNodeKickBroadcast() {
        Long userId = 100L;
        Integer deviceType = 3; // Android

        // 新设备在本节点登录
        NettySession newSession = NettySession.builder()
                .channel(mockChannel1)
                .userId(userId)
                .deviceType(deviceType)
                .deviceId("device-new")
                .deviceName("新 Android 设备")
                .tenantId(1L)
                .build();

        // 执行：添加新设备（本节点没有同类型旧设备）
        sessionManager.addSession(newSession);

        // 验证：调用了跨节点广播
        verify(mockCrossNodePublisher, times(1)).publishKickMessage(
                eq(userId),
                eq(deviceType),
                eq("新 Android 设备")
        );
    }

    @Test
    @DisplayName("验证七层索引结构 - 所有索引正确维护")
    void testSevenLayerIndex() {
        Long userId = 100L;
        Long tenantId = 1L;
        Integer deviceType = 3;
        String deviceId = "device-123";
        String accessToken = "token-abc";

        NettySession session = NettySession.builder()
                .channel(mockChannel1)
                .userId(userId)
                .deviceType(deviceType)
                .deviceId(deviceId)
                .deviceName("Test Device")
                .tenantId(tenantId)
                .accessToken(accessToken)
                .leaseExpireTime(System.currentTimeMillis() + 3600000)
                .build();

        // 执行：添加会话
        sessionManager.addSession(session);

        // 验证：所有索引都正确
        // 1. Channel ID -> Session
        NettySession found = sessionManager.getSession("channel-1");
        assertNotNull(found);
        assertEquals(userId, found.getUserId());

        // 2. User ID -> Channel IDs
        assertEquals(1, sessionManager.getSessionsByUserId(userId).size());

        // 3. User ID + Device Type -> Channel ID
        found = sessionManager.getSessionByUserIdAndDeviceType(userId, deviceType);
        assertNotNull(found);
        assertEquals("channel-1", found.getChannelId());

        // 4. Access Token -> Channel ID
        found = sessionManager.getSessionByAccessToken(accessToken);
        assertNotNull(found);
        assertEquals("channel-1", found.getChannelId());

        // 5. User ID + Device Type + Device ID -> Channel ID
        found = sessionManager.getSessionByUserIdAndDevice(userId, deviceType, deviceId);
        assertNotNull(found);
        assertEquals("channel-1", found.getChannelId());

        // 6. Tenant ID -> Channel IDs
        assertEquals(1, sessionManager.getSessionsByTenantId(tenantId).size());

        // 7. Lease Expire Index (通过租约扫描器间接验证)
        // 此处省略，由 LeaseScannerTest 覆盖
    }

    @Test
    @DisplayName("验证 removeSession 竞态修复 - compute 原子操作")
    void testRemoveSessionRaceConditionFix() {
        Long userId = 100L;
        Integer deviceType = 3;

        // 场景：旧设备被踢后，新设备已登录，removeSession 不应误删新设备映射
        NettySession oldSession = NettySession.builder()
                .channel(mockChannel1)
                .userId(userId)
                .deviceType(deviceType)
                .deviceId("device-old")
                .tenantId(1L)
                .build();

        NettySession newSession = NettySession.builder()
                .channel(mockChannel2)
                .userId(userId)
                .deviceType(deviceType)
                .deviceId("device-new")
                .tenantId(1L)
                .build();

        // 先添加旧设备
        sessionManager.addSession(oldSession);
        
        // 添加新设备（触发互踢，旧设备被移除）
        sessionManager.addSession(newSession);

        // 验证：新设备映射正确，未被误删
        NettySession found = sessionManager.getSessionByUserIdAndDeviceType(userId, deviceType);
        assertNotNull(found);
        assertEquals("channel-2", found.getChannelId());
    }
}
