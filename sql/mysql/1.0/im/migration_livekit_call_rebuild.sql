-- LiveKit 通话替换式重构。历史记录只用于展示，不再参与 RTC 或信令处理。
-- 执行前请在客户数据库备份；生产通过正式迁移工具登记版本。

ALTER TABLE im_call_record
    ADD COLUMN provider VARCHAR(24) NOT NULL DEFAULT 'LIVEKIT' COMMENT 'RTC 提供方：LIVEKIT；历史数据仅用于展示' AFTER room_id,
    ADD COLUMN call_mode VARCHAR(16) NOT NULL DEFAULT 'DIRECT' COMMENT 'DIRECT/GROUP' AFTER provider,
    ADD COLUMN owner_id BIGINT NULL COMMENT '通话创建者，群通话拥有结束全体权限' AFTER call_mode,
    ADD COLUMN livekit_room VARCHAR(128) NULL COMMENT 'LiveKit 房间名' AFTER owner_id,
    ADD COLUMN connected_at DATETIME NULL COMMENT '媒体双方/首个群成员连接时间' AFTER end_time,
    ADD COLUMN state_version INT NOT NULL DEFAULT 0 COMMENT '通话事件版本，客户端去重与状态对账' AFTER state,
    ADD UNIQUE KEY uk_im_call_livekit_room (livekit_room),
    ADD KEY idx_im_call_provider_state (tenant_id, provider, state),
    ADD KEY idx_im_call_owner_state (tenant_id, owner_id, state);

ALTER TABLE im_call_participant
    ADD COLUMN invite_state VARCHAR(16) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING/ACCEPTED/REJECTED/BUSY/TIMEOUT' AFTER status,
    ADD COLUMN join_state VARCHAR(16) NOT NULL DEFAULT 'NOT_JOINED' COMMENT 'NOT_JOINED/JOINED/LEFT' AFTER invite_state,
    MODIFY COLUMN device_id VARCHAR(128) NULL COMMENT '实际加入设备',
    ADD COLUMN joined_at DATETIME NULL AFTER join_state,
    ADD COLUMN left_at DATETIME NULL AFTER joined_at;

CREATE TABLE IF NOT EXISTS im_call_event_outbox (
    id BIGINT NOT NULL AUTO_INCREMENT,
    tenant_id BIGINT NOT NULL,
    call_id VARCHAR(64) NOT NULL,
    event_type VARCHAR(64) NOT NULL,
    event_version INT NOT NULL,
    recipient_id BIGINT NULL,
    payload JSON NOT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'PENDING',
    retry_count INT NOT NULL DEFAULT 0,
    next_retry_at DATETIME NULL,
    published_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_im_call_outbox_event (call_id, event_version, event_type, recipient_id),
    KEY idx_im_call_outbox_pending (status, next_retry_at)
) COMMENT='IM 通话事件事务 outbox';
