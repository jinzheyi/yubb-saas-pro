package com.shengyu.module.im.enums;

import com.shengyu.framework.common.exception.ErrorCode;

/**
 * IM模块错误码枚举类
 *
 * im 模块，使用 1-003-000-000 段
 *
 * @author 圣钰科技
 */
public interface ErrorCodeConstants {

    // ========== IM 通用 1-003-000-000 ==========
    ErrorCode IM_COMMON_ERROR = new ErrorCode(1_003_000_000, "IM通用错误");
    ErrorCode IM_PARAM_ERROR = new ErrorCode(1_003_000_001, "参数错误");
    ErrorCode IM_NOT_LOGIN = new ErrorCode(1_003_000_002, "未登录或登录已过期");
    ErrorCode IM_NO_PERMISSION = new ErrorCode(1_003_000_003, "没有权限操作");

    // ========== IM 消息 1-003-001-000 ==========
    ErrorCode IM_MESSAGE_NOT_EXISTS = new ErrorCode(1_003_001_000, "消息不存在");
    ErrorCode IM_MESSAGE_SEND_FAILED = new ErrorCode(1_003_001_001, "消息发送失败");
    ErrorCode IM_MESSAGE_RECEIVER_NOT_EXISTS = new ErrorCode(1_003_001_002, "接收者不存在");
    ErrorCode IM_MESSAGE_CONTENT_EMPTY = new ErrorCode(1_003_001_003, "消息内容不能为空");
    ErrorCode IM_MESSAGE_RECALL_FAILED = new ErrorCode(1_003_001_004, "消息撤回失败");
    ErrorCode IM_MESSAGE_RECALL_TIMEOUT = new ErrorCode(1_003_001_005, "消息超过撤回时间限制");
    ErrorCode IM_MESSAGE_DELETE_FAILED = new ErrorCode(1_003_001_006, "消息删除失败");
    ErrorCode IM_MESSAGE_ENCRYPT_FAILED = new ErrorCode(1_003_001_007, "消息加密失败");
    ErrorCode IM_MESSAGE_DECRYPT_FAILED = new ErrorCode(1_003_001_008, "消息解密失败");

    // ========== IM 群组 1-003-002-000 ==========
    ErrorCode IM_GROUP_NOT_EXISTS = new ErrorCode(1_003_002_000, "群组不存在");
    ErrorCode IM_GROUP_CREATE_FAILED = new ErrorCode(1_003_002_001, "群组创建失败");
    ErrorCode IM_GROUP_JOIN_FAILED = new ErrorCode(1_003_002_002, "加入群组失败");
    ErrorCode IM_GROUP_EXIT_FAILED = new ErrorCode(1_003_002_003, "退出群组失败");
    ErrorCode IM_GROUP_DISSOLVE_FAILED = new ErrorCode(1_003_002_004, "解散群组失败");
    ErrorCode IM_GROUP_NOT_OWNER = new ErrorCode(1_003_002_005, "不是群主，没有权限操作");
    ErrorCode IM_GROUP_NOT_ADMIN = new ErrorCode(1_003_002_006, "不是管理员，没有权限操作");
    ErrorCode IM_GROUP_MEMBER_NOT_EXISTS = new ErrorCode(1_003_002_007, "群成员不存在");
    ErrorCode IM_GROUP_NAME_DUPLICATE = new ErrorCode(1_003_002_008, "已经存在该名字的群组");
    ErrorCode IM_GROUP_MEMBER_LIMIT = new ErrorCode(1_003_002_009, "群组成员数量已达上限");
    ErrorCode IM_GROUP_ALREADY_JOINED = new ErrorCode(1_003_002_010, "已经加入该群组");

    // ========== IM 用户 1-003-003-000 ==========
    ErrorCode IM_USER_NOT_EXISTS = new ErrorCode(1_003_003_000, "用户不存在");
    ErrorCode IM_USER_STATUS_UPDATE_FAILED = new ErrorCode(1_003_003_001, "用户状态更新失败");
    ErrorCode IM_USER_DISABLED = new ErrorCode(1_003_003_002, "用户已被禁用");

    // ========== IM 连接 1-003-004-000 ==========
    ErrorCode IM_CONNECTION_FAILED = new ErrorCode(1_003_004_000, "连接失败");
    ErrorCode IM_CONNECTION_CLOSED = new ErrorCode(1_003_004_001, "连接已关闭");
    ErrorCode IM_CONNECTION_TIMEOUT = new ErrorCode(1_003_004_002, "连接超时");

    // ========== IM 文件 1-003-005-000 ==========
    ErrorCode IM_FILE_UPLOAD_FAILED = new ErrorCode(1_003_005_000, "文件上传失败");
    ErrorCode IM_FILE_DOWNLOAD_FAILED = new ErrorCode(1_003_005_001, "文件下载失败");
    ErrorCode IM_FILE_NOT_EXISTS = new ErrorCode(1_003_005_002, "文件不存在");
    ErrorCode IM_FILE_SIZE_EXCEED = new ErrorCode(1_003_005_003, "文件大小超过限制");
    ErrorCode IM_FILE_TYPE_NOT_SUPPORTED = new ErrorCode(1_003_005_004, "不支持的文件类型");

    // ========== IM 认证 1-003-006-000 ==========
    ErrorCode IM_AUTH_FAILED = new ErrorCode(1_003_006_000, "认证失败");
    ErrorCode IM_AUTH_TOKEN_INVALID = new ErrorCode(1_003_006_001, "无效的token");
    ErrorCode IM_AUTH_TOKEN_EXPIRED = new ErrorCode(1_003_006_002, "token已过期");
    ErrorCode IM_AUTH_TOKEN_EMPTY = new ErrorCode(1_003_006_003, "token不能为空");
    ErrorCode IM_AUTH_USER_TYPE_NOT_SUPPORTED = new ErrorCode(1_003_006_004, "不支持的用户类型");

}
