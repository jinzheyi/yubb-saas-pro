package com.shengyu.module.system.enums;

import com.shengyu.framework.common.exception.ErrorCode;

/**
 * 错误码枚举类
 *
 * system 系统，使用 1-002-000-000 段
 * platform 系统，使用 1-001-000-000 段
 */
public interface ErrorCodeConstants {

    // ========== 扩展租户模块 1001000000 ==========
    ErrorCode TENANT_MENU_USED = new ErrorCode(1_001_000_000, "租户正在使用该菜单，请给租户重新设置没有选择该菜单的套餐后再尝试删除");

    // ========== 插件应用模块 1001001000 ==========
    ErrorCode PLUG_APP_NOT_EXISTS = new ErrorCode(1_001_001_000, "插件应用不存在");
    ErrorCode PLUG_ORDER_NOT_EXISTS = new ErrorCode(1_001_001_001, "插件订单不存在");
    ErrorCode PLUG_ORDER_ITEM_NOT_EXISTS = new ErrorCode(1_001_001_002, "订单项不存在");
    ErrorCode PLUG_TENANT_NOT_EXISTS = new ErrorCode(1_001_001_003, "租户应用不存在");
    ErrorCode PLUG_APP_DISABLE = new ErrorCode(1_001_001_004, "插件应用已下架或已禁用，无法下单");
    ErrorCode PLUG_TENANT_EXISTS = new ErrorCode(1_001_001_005, "租户应用中已存在该插件");
    ErrorCode PLUG_TENANT_APP_SN_NOT_EXISTS = new ErrorCode(1_001_001_006, "当前租户没有任何应用插件授权");
    ErrorCode PLUG_TENANT_APP_NOT_AUTHORIZE = new ErrorCode(1_001_001_007, "当前租户需要获取：{} 等应用插件授权才能使用该功能");
    ErrorCode PLUG_TENANT_APP_DISABLE = new ErrorCode(1_001_001_008, "当前系统管理员下架了该：{} 插件应用");
    ErrorCode PLUG_TENANT_APP_ENABLE = new ErrorCode(1_001_001_009, "该：{} 插件应用已被平台运营方停用");
    ErrorCode PLUG_APP_MENU = new ErrorCode(1_001_001_010, "添加插件应用菜单时,所属应用插件条码必传");
    ErrorCode PLUG_APP_SN_EXISTS = new ErrorCode(1_001_001_011, "已存在该模块条码插件应用");
    ErrorCode PLUG_ORDER_ORDER_STATUS = new ErrorCode(1_001_001_012, "该笔插件订单已完成审核，请勿重复操作");
    ErrorCode PLUG_ORDER_ORDER_STATUS_EXISTS = new ErrorCode(1_001_001_013, "当前存在未审批通过或待审批的插件订单，不能下单");
    ErrorCode PLUG_ORDER_ORDER_NO_PASS_STATUS = new ErrorCode(1_001_001_014, "审核不通过的订单才能重新申请提交审核");



    // ========== AUTH 模块 1-002-000-000 ==========
    ErrorCode AUTH_LOGIN_BAD_CREDENTIALS = new ErrorCode(1_002_000_000, "登录失败，账号密码不正确");
    ErrorCode AUTH_LOGIN_USER_DISABLED = new ErrorCode(1_002_000_001, "登录失败，账号被禁用");
    ErrorCode AUTH_LOGIN_CAPTCHA_CODE_ERROR = new ErrorCode(1_002_000_004, "验证码不正确，原因：{}");
    ErrorCode AUTH_THIRD_LOGIN_NOT_BIND = new ErrorCode(1_002_000_005, "未绑定账号，需要进行绑定");
    ErrorCode AUTH_TOKEN_EXPIRED = new ErrorCode(1_002_000_006, "Token 已经过期");
    ErrorCode AUTH_MOBILE_NOT_EXISTS = new ErrorCode(1_002_000_007, "手机号不存在");
    ErrorCode AUTH_TENANT_EXCEPTION = new ErrorCode(1_002_000_008, "当前用户登录的租户数据异常或切换的租户用户已被禁用");
    ErrorCode AUTH_TO_TENANT_EXCEPTION = new ErrorCode(1_002_000_009, "切换租户失败，对应用户已被禁用或已删除");
    ErrorCode AUTH_LOGIN_EXCEPTION = new ErrorCode(1_002_000_010, "当前登录账号所属租户信息已被【删除/禁用】或所属用户已被【删除/禁用】");

    // ========== 菜单模块 1-002-001-000 ==========
    ErrorCode MENU_NAME_DUPLICATE = new ErrorCode(1_002_001_000, "已经存在该名字的菜单");
    ErrorCode MENU_PARENT_NOT_EXISTS = new ErrorCode(1_002_001_001, "父菜单不存在");
    ErrorCode MENU_PARENT_ERROR = new ErrorCode(1_002_001_002, "不能设置自己为父菜单");
    ErrorCode MENU_NOT_EXISTS = new ErrorCode(1_002_001_003, "菜单不存在");
    ErrorCode MENU_EXISTS_CHILDREN = new ErrorCode(1_002_001_004, "存在子菜单，无法删除");
    ErrorCode MENU_PARENT_NOT_DIR_OR_MENU = new ErrorCode(1_002_001_005, "父菜单的类型必须是目录或者菜单");
    ErrorCode MENU_COMPONENT_NAME_DUPLICATE = new ErrorCode(1_002_001_006, "已经存在该组件名的菜单");

    // ========== 角色模块 1-002-002-000 ==========
    ErrorCode ROLE_NOT_EXISTS = new ErrorCode(1_002_002_000, "角色不存在");
    ErrorCode ROLE_NAME_DUPLICATE = new ErrorCode(1_002_002_001, "已经存在名为【{}】的角色");
    ErrorCode ROLE_CODE_DUPLICATE = new ErrorCode(1_002_002_002, "已经存在编码为【{}】的角色");
    ErrorCode ROLE_CAN_NOT_UPDATE_SYSTEM_TYPE_ROLE = new ErrorCode(1_002_002_003, "不能操作类型为系统内置的角色");
    ErrorCode ROLE_IS_DISABLE = new ErrorCode(1_002_002_004, "名字为【{}】的角色已被禁用");
    ErrorCode ROLE_ADMIN_CODE_ERROR = new ErrorCode(1_002_002_005, "编码【{}】不能使用");

    // ========== 用户模块 1-002-003-000 ==========
    ErrorCode USER_USERNAME_EXISTS = new ErrorCode(1_002_003_000, "用户账号已经存在");
    ErrorCode USER_MOBILE_EXISTS = new ErrorCode(1_002_003_001, "手机号已经存在");
    ErrorCode USER_EMAIL_EXISTS = new ErrorCode(1_002_003_002, "邮箱已经存在");
    ErrorCode USER_NOT_EXISTS = new ErrorCode(1_002_003_003, "用户不存在");
    ErrorCode USER_IMPORT_LIST_IS_EMPTY = new ErrorCode(1_002_003_004, "导入用户数据不能为空！");
    ErrorCode USER_PASSWORD_FAILED = new ErrorCode(1_002_003_005, "用户密码校验失败");
    ErrorCode USER_IS_DISABLE = new ErrorCode(1_002_003_006, "名字为【{}】的用户已被禁用");
    ErrorCode USER_COUNT_MAX = new ErrorCode(1_002_003_008, "创建用户失败，原因：超过租户最大租户配额({})！");
    ErrorCode USER_ADMIN = new ErrorCode(1_002_003_009, "不能操作超管用户！");
    ErrorCode USER_CREATE_SAAS_EXISTS = new ErrorCode(1_002_003_010, "添加用户时，邮箱账号和手机号不能都为空");
    ErrorCode USER_SAAS_USERNAME_NOT_EXISTS = new ErrorCode(1_002_003_011, "邮箱账号对应体系用户不存在");
    ErrorCode USER_SAAS_MOBILE_NOT_EXISTS = new ErrorCode(1_002_003_012, "手机号对应体系用户不存在");
    ErrorCode USER_SAAS_ID_UNIQUE = new ErrorCode(1_002_003_013, "输入的邮箱账号或手机号已被昵称为【{}】员工绑定");

    // ========== 部门模块 1-002-004-000 ==========
    ErrorCode DEPT_NAME_DUPLICATE = new ErrorCode(1_002_004_000, "已经存在该名字的部门");
    ErrorCode DEPT_PARENT_NOT_EXITS = new ErrorCode(1_002_004_001,"父级部门不存在");
    ErrorCode DEPT_NOT_FOUND = new ErrorCode(1_002_004_002, "当前部门不存在");
    ErrorCode DEPT_EXITS_CHILDREN = new ErrorCode(1_002_004_003, "存在子部门，无法删除");
    ErrorCode DEPT_PARENT_ERROR = new ErrorCode(1_002_004_004, "不能设置自己为父部门");
    ErrorCode DEPT_EXISTS_USER = new ErrorCode(1_002_004_005, "部门中存在员工，无法删除");
    ErrorCode DEPT_NOT_ENABLE = new ErrorCode(1_002_004_006, "部门({})不处于开启状态，不允许选择");
    ErrorCode DEPT_PARENT_IS_CHILD = new ErrorCode(1_002_004_007, "不能设置自己的子部门为父部门");

    // ========== 岗位模块 1-002-005-000 ==========
    ErrorCode POST_NOT_FOUND = new ErrorCode(1_002_005_000, "当前岗位不存在");
    ErrorCode POST_NOT_ENABLE = new ErrorCode(1_002_005_001, "岗位({}) 不处于开启状态，不允许选择");
    ErrorCode POST_NAME_DUPLICATE = new ErrorCode(1_002_005_002, "已经存在该名字的岗位");
    ErrorCode POST_CODE_DUPLICATE = new ErrorCode(1_002_005_003, "已经存在该标识的岗位");

    // ========== 字典类型 1-002-006-000 ==========
    ErrorCode DICT_TYPE_NOT_EXISTS = new ErrorCode(1_002_006_001, "当前字典类型不存在");
    ErrorCode DICT_TYPE_NOT_ENABLE = new ErrorCode(1_002_006_002, "字典类型不处于开启状态，不允许选择");
    ErrorCode DICT_TYPE_NAME_DUPLICATE = new ErrorCode(1_002_006_003, "已经存在该名字的字典类型");
    ErrorCode DICT_TYPE_TYPE_DUPLICATE = new ErrorCode(1_002_006_004, "已经存在该类型的字典类型");
    ErrorCode DICT_TYPE_HAS_CHILDREN = new ErrorCode(1_002_006_005, "无法删除，该字典类型还有字典数据");

    // ========== 字典数据 1-002-007-000 ==========
    ErrorCode DICT_DATA_NOT_EXISTS = new ErrorCode(1_002_007_001, "当前字典数据不存在");
    ErrorCode DICT_DATA_NOT_ENABLE = new ErrorCode(1_002_007_002, "字典数据({})不处于开启状态，不允许选择");
    ErrorCode DICT_DATA_VALUE_DUPLICATE = new ErrorCode(1_002_007_003, "已经存在该值的字典数据");

    // ========== 通知公告 1-002-008-000 ==========
    ErrorCode NOTICE_NOT_FOUND = new ErrorCode(1_002_008_001, "当前通知公告不存在");

    // ========== 短信渠道 1-002-011-000 ==========
    ErrorCode SMS_CHANNEL_NOT_EXISTS = new ErrorCode(1_002_011_000, "短信渠道不存在");
    ErrorCode SMS_CHANNEL_DISABLE = new ErrorCode(1_002_011_001, "短信渠道不处于开启状态，不允许选择");
    ErrorCode SMS_CHANNEL_HAS_CHILDREN = new ErrorCode(1_002_011_002, "无法删除，该短信渠道还有短信模板");

    // ========== 短信模板 1-002-012-000 ==========
    ErrorCode SMS_TEMPLATE_NOT_EXISTS = new ErrorCode(1_002_012_000, "短信模板不存在");
    ErrorCode SMS_TEMPLATE_CODE_DUPLICATE = new ErrorCode(1_002_012_001, "已经存在编码为【{}】的短信模板");
    ErrorCode SMS_TEMPLATE_API_ERROR = new ErrorCode(1_002_012_002, "短信 API 模板调用失败，原因是：{}");
    ErrorCode SMS_TEMPLATE_API_AUDIT_CHECKING = new ErrorCode(1_002_012_003, "短信 API 模版无法使用，原因：审批中");
    ErrorCode SMS_TEMPLATE_API_AUDIT_FAIL = new ErrorCode(1_002_012_004, "短信 API 模版无法使用，原因：审批不通过，{}");
    ErrorCode SMS_TEMPLATE_API_NOT_FOUND = new ErrorCode(1_002_012_005, "短信 API 模版无法使用，原因：模版不存在");

    // ========== 短信发送 1-002-013-000 ==========
    ErrorCode SMS_SEND_MOBILE_NOT_EXISTS = new ErrorCode(1_002_013_000, "手机号不存在");
    ErrorCode SMS_SEND_MOBILE_TEMPLATE_PARAM_MISS = new ErrorCode(1_002_013_001, "模板参数({})缺失");
    ErrorCode SMS_SEND_TEMPLATE_NOT_EXISTS = new ErrorCode(1_002_013_002, "短信模板不存在");

    // ========== 短信验证码 1-002-014-000 ==========
    ErrorCode SMS_CODE_NOT_FOUND = new ErrorCode(1_002_014_000, "验证码不存在");
    ErrorCode SMS_CODE_EXPIRED = new ErrorCode(1_002_014_001, "验证码已过期");
    ErrorCode SMS_CODE_USED = new ErrorCode(1_002_014_002, "验证码已使用");
    ErrorCode SMS_CODE_NOT_CORRECT = new ErrorCode(1_002_014_003, "验证码不正确");
    ErrorCode SMS_CODE_EXCEED_SEND_MAXIMUM_QUANTITY_PER_DAY = new ErrorCode(1_002_014_004, "超过每日短信发送数量");
    ErrorCode SMS_CODE_SEND_TOO_FAST = new ErrorCode(1_002_014_005, "短信发送过于频率");
    ErrorCode SMS_CODE_IS_EXISTS = new ErrorCode(1_002_014_006, "手机号已被使用");
    ErrorCode SMS_CODE_IS_UNUSED = new ErrorCode(1_002_014_007, "验证码未被使用");

    // ========== 租户信息 1-002-015-000 ==========
    ErrorCode TENANT_NOT_EXISTS = new ErrorCode(1_002_015_000, "租户不存在");
    ErrorCode TENANT_DISABLE = new ErrorCode(1_002_015_001, "名字为【{}】的租户已被禁用");
    ErrorCode TENANT_EXPIRE = new ErrorCode(1_002_015_002, "名字为【{}】的租户已过期");
    ErrorCode TENANT_CAN_NOT_UPDATE_SYSTEM = new ErrorCode(1_002_015_003, "系统租户不能进行修改、删除等操作！");
    ErrorCode TENANT_NAME_DUPLICATE = new ErrorCode(1_002_015_004, "名字为【{}】的租户已存在");
    ErrorCode TENANT_WEBSITE_DUPLICATE = new ErrorCode(1_002_015_005, "域名为【{}】的租户已存在");

    // ========== 租户套餐 1-002-016-000 ==========
    ErrorCode TENANT_PACKAGE_NOT_EXISTS = new ErrorCode(1_002_016_000, "租户套餐不存在");
    ErrorCode TENANT_PACKAGE_USED = new ErrorCode(1_002_016_001, "租户正在使用该套餐，请给租户重新设置套餐后再尝试删除");
    ErrorCode TENANT_PACKAGE_DISABLE = new ErrorCode(1_002_016_002, "名字为【{}】的租户套餐已被禁用");

    // ========== 错误码模块 1-002-017-000 ==========
    ErrorCode ERROR_CODE_NOT_EXISTS = new ErrorCode(1_002_017_000, "错误码不存在");
    ErrorCode ERROR_CODE_DUPLICATE = new ErrorCode(1_002_017_001, "已经存在编码为【{}】的错误码");

    // ========== 社交用户 1-002-018-000 ==========
    ErrorCode SOCIAL_USER_AUTH_FAILURE = new ErrorCode(1_002_018_000, "社交授权失败，原因是：{}");
    ErrorCode SOCIAL_USER_NOT_FOUND = new ErrorCode(1_002_018_001, "社交授权失败，找不到对应的用户");

    ErrorCode SOCIAL_CLIENT_WEIXIN_MINI_APP_PHONE_CODE_ERROR = new ErrorCode(1_002_018_200, "获得手机号失败");
    ErrorCode SOCIAL_CLIENT_WEIXIN_MINI_APP_QRCODE_ERROR = new ErrorCode(1_002_018_201, "获得小程序码失败");
    ErrorCode SOCIAL_CLIENT_WEIXIN_MINI_APP_SUBSCRIBE_TEMPLATE_ERROR = new ErrorCode(1_002_018_202, "获得小程序订阅消息模版失败");
    ErrorCode SOCIAL_CLIENT_WEIXIN_MINI_APP_SUBSCRIBE_MESSAGE_ERROR = new ErrorCode(1_002_018_203, "发送小程序订阅消息失败");
    ErrorCode SOCIAL_CLIENT_WEIXIN_MINI_APP_ORDER_UPLOAD_SHIPPING_INFO_ERROR = new ErrorCode(1_002_018_204, "上传微信小程序发货信息失败");
    ErrorCode SOCIAL_CLIENT_WEIXIN_MINI_APP_ORDER_NOTIFY_CONFIRM_RECEIVE_ERROR = new ErrorCode(1_002_018_205, "上传微信小程序订单收货信息失败");
    ErrorCode SOCIAL_CLIENT_NOT_EXISTS = new ErrorCode(1_002_018_210, "社交客户端不存在");
    ErrorCode SOCIAL_CLIENT_UNIQUE = new ErrorCode(1_002_018_211, "社交客户端已存在配置");

    // ========== 系统敏感词 1-002-019-000 =========
    ErrorCode SENSITIVE_WORD_NOT_EXISTS = new ErrorCode(1_002_019_000, "系统敏感词在所有标签中都不存在");
    ErrorCode SENSITIVE_WORD_EXISTS = new ErrorCode(1_002_019_001, "系统敏感词已在标签中存在");

    // ========== OAuth2 客户端 1-002-020-000 =========
    ErrorCode OAUTH2_CLIENT_NOT_EXISTS = new ErrorCode(1_002_020_000, "OAuth2 客户端不存在");
    ErrorCode OAUTH2_CLIENT_EXISTS = new ErrorCode(1_002_020_001, "OAuth2 客户端编号已存在");
    ErrorCode OAUTH2_CLIENT_DISABLE = new ErrorCode(1_002_020_002, "OAuth2 客户端已禁用");
    ErrorCode OAUTH2_CLIENT_AUTHORIZED_GRANT_TYPE_NOT_EXISTS = new ErrorCode(1_002_020_003, "不支持该授权类型");
    ErrorCode OAUTH2_CLIENT_SCOPE_OVER = new ErrorCode(1_002_020_004, "授权范围过大");
    ErrorCode OAUTH2_CLIENT_REDIRECT_URI_NOT_MATCH = new ErrorCode(1_002_020_005, "无效 redirect_uri: {}");
    ErrorCode OAUTH2_CLIENT_CLIENT_SECRET_ERROR = new ErrorCode(1_002_020_006, "无效 client_secret: {}");

    // ========== OAuth2 授权 1-002-021-000 =========
    ErrorCode OAUTH2_GRANT_CLIENT_ID_MISMATCH = new ErrorCode(1_002_021_000, "client_id 不匹配");
    ErrorCode OAUTH2_GRANT_REDIRECT_URI_MISMATCH = new ErrorCode(1_002_021_001, "redirect_uri 不匹配");
    ErrorCode OAUTH2_GRANT_STATE_MISMATCH = new ErrorCode(1_002_021_002, "state 不匹配");
    ErrorCode OAUTH2_GRANT_CODE_NOT_EXISTS = new ErrorCode(1_002_021_003, "code 不存在");

    // ========== OAuth2 授权 1-002-022-000 =========
    ErrorCode OAUTH2_CODE_NOT_EXISTS = new ErrorCode(1_002_022_000, "code 不存在");
    ErrorCode OAUTH2_CODE_EXPIRE = new ErrorCode(1_002_022_001, "code 已过期");

    // ========== 邮箱账号 1-002-023-000 ==========
    ErrorCode MAIL_ACCOUNT_NOT_EXISTS = new ErrorCode(1_002_023_000, "邮箱账号不存在");
    ErrorCode MAIL_ACCOUNT_RELATE_TEMPLATE_EXISTS = new ErrorCode(1_002_023_001, "无法删除，该邮箱账号还有邮件模板");

    // ========== 邮件模版 1-002-024-000 ==========
    ErrorCode MAIL_TEMPLATE_NOT_EXISTS = new ErrorCode(1_002_024_000, "邮件模版不存在");
    ErrorCode MAIL_TEMPLATE_CODE_EXISTS = new ErrorCode(1_002_024_001, "邮件模版 code({}) 已存在");

    // ========== 邮件发送 1-002-025-000 ==========
    ErrorCode MAIL_SEND_TEMPLATE_PARAM_MISS = new ErrorCode(1_002_025_000, "模板参数({})缺失");
    ErrorCode MAIL_SEND_MAIL_NOT_EXISTS = new ErrorCode(1_002_025_001, "邮箱不存在");

    // ========== IM 即时通讯 1-002-030-000 ==========
    // 会话相关 1-002-030-000
    ErrorCode CONVERSATION_NOT_EXISTS = new ErrorCode(1_002_030_000, "会话不存在");
    ErrorCode CONVERSATION_CREATE_FAILED = new ErrorCode(1_002_030_001, "创建会话失败");
    
    // 消息相关 1-002-030-100
    ErrorCode MESSAGE_NOT_EXISTS = new ErrorCode(1_002_030_100, "消息不存在");
    ErrorCode MESSAGE_SEND_FAILED = new ErrorCode(1_002_030_101, "消息发送失败");
    ErrorCode MESSAGE_RECALL_TIMEOUT = new ErrorCode(1_002_030_102, "消息撤回超时");
    ErrorCode MESSAGE_RECALL_PERMISSION_DENIED = new ErrorCode(1_002_030_103, "无权撤回该消息");
    ErrorCode MESSAGE_STATUS_INVALID = new ErrorCode(1_002_030_104, "消息状态转换无效");
    ErrorCode MESSAGE_TYPE_NOT_SUPPORTED = new ErrorCode(1_002_030_105, "暂不支持的消息类型");
    ErrorCode STICKER_NOT_EXISTS = new ErrorCode(1_002_030_106, "自定义表情不存在");
    ErrorCode STICKER_COLLECT_NOT_SUPPORTED = new ErrorCode(1_002_030_107, "该消息暂不支持添加到表情");
    
    // 群组相关 1-002-030-200
    ErrorCode GROUP_NOT_EXISTS = new ErrorCode(1_002_030_200, "群组不存在");
    ErrorCode GROUP_MEMBER_NOT_EXISTS = new ErrorCode(1_002_030_201, "群成员不存在");
    ErrorCode GROUP_PERMISSION_DENIED = new ErrorCode(1_002_030_202, "无权操作该群组");
    ErrorCode GROUP_MEMBER_LIMIT = new ErrorCode(1_002_030_203, "群成员数量已达上限");
    ErrorCode GROUP_DISSOLVED = new ErrorCode(1_002_030_204, "群组已解散");
    ErrorCode GROUP_OWNER_CANNOT_QUIT = new ErrorCode(1_002_030_205, "群主不能退出群组，请先转让群主");
    ErrorCode GROUP_INVITE_CODE_INVALID = new ErrorCode(1_002_030_206, "邀请码无效");
    ErrorCode GROUP_MEMBER_ALREADY_EXISTS = new ErrorCode(1_002_030_207, "您已经是群成员");
    ErrorCode GROUP_MEMBER_FULL = new ErrorCode(1_002_030_208, "群人数已达上限");
    ErrorCode GROUP_JOIN_NEED_APPROVAL = new ErrorCode(1_002_030_209, "加入该群需要审批");
    ErrorCode GROUP_INVITE_CODE_NOT_EXISTS = new ErrorCode(1_002_030_210, "邀请码不存在");
    ErrorCode GROUP_JOIN_REQUEST_NOT_EXISTS = new ErrorCode(1_002_030_211, "加群申请不存在");
    ErrorCode GROUP_JOIN_REQUEST_STATUS_INVALID = new ErrorCode(1_002_030_212, "加群申请状态已变更");
    ErrorCode GROUP_JOIN_REQUEST_ALREADY_PENDING = new ErrorCode(1_002_030_213, "您已提交过加群申请，请等待管理员处理");
    ErrorCode GROUP_MUTED_ALL = new ErrorCode(1_002_030_214, "当前群已开启全员禁言");
    ErrorCode GROUP_MEMBER_MUTED = new ErrorCode(1_002_030_215, "您已被禁言，暂时无法发送消息");
    ErrorCode GROUP_INVITE_CODE_DISABLED = new ErrorCode(1_002_030_216, "邀请码已失效");
    ErrorCode GROUP_INVITE_CODE_EXPIRED = new ErrorCode(1_002_030_217, "邀请码已过期");
    ErrorCode GROUP_INVITE_CODE_USAGE_LIMIT_REACHED = new ErrorCode(1_002_030_218, "邀请码使用次数已达上限");
    ErrorCode GROUP_INVITE_CODE_TENANT_MISMATCH = new ErrorCode(1_002_030_219, "当前邀请码不属于本租户");
    ErrorCode GROUP_INVITE_CODE_RATE_LIMIT_EXCEEDED = new ErrorCode(1_002_030_220, "操作过于频繁，请稍后再试");
    ErrorCode GROUP_JOIN_REQUEST_RATE_LIMIT_EXCEEDED = new ErrorCode(1_002_030_221, "入群申请提交过于频繁，请稍后再试");
    ErrorCode GROUP_MEMBER_KICKED_OUT = new ErrorCode(1_002_030_222, "你已被移出群聊，无法执行此操作");
    ErrorCode GROUP_MEMBER_QUITTED = new ErrorCode(1_002_030_223, "你已退出该群聊，无法执行此操作");
    ErrorCode GROUP_MEMBER_ALREADY_REMOVED = new ErrorCode(1_002_030_224, "你已不在群聊中，无法执行此操作");
    
    // 群文件相关 1-002-030-250
    ErrorCode GROUP_FILE_NOT_EXISTS = new ErrorCode(1_002_030_250, "群文件不存在");
    ErrorCode NOT_GROUP_MEMBER = new ErrorCode(1_002_030_251, "您不是该群成员");
    
    // 联系人相关 1-002-030-300
    ErrorCode CONTACT_NOT_EXISTS = new ErrorCode(1_002_030_300, "联系人不存在");
    ErrorCode CONTACT_SETTING_UPDATE_FAILED = new ErrorCode(1_002_030_301, "联系人设置更新失败");
    
    // 通知相关 1-002-030-400
    ErrorCode NOTIFICATION_NOT_EXISTS = new ErrorCode(1_002_030_400, "通知不存在");
    ErrorCode NOTIFICATION_PERMISSION_DENIED = new ErrorCode(1_002_030_401, "无权操作该通知");
    
    // 通话相关 1-002-030-500
    ErrorCode CALL_RECORD_NOT_EXISTS = new ErrorCode(1_002_030_500, "通话记录不存在");
    ErrorCode CALL_PERMISSION_DENIED = new ErrorCode(1_002_030_501, "无权操作该通话");

    // ========== 站内信模版 1-002-026-000 ==========
    ErrorCode NOTIFY_TEMPLATE_NOT_EXISTS = new ErrorCode(1_002_026_000, "站内信模版不存在");
    ErrorCode NOTIFY_TEMPLATE_CODE_DUPLICATE = new ErrorCode(1_002_026_001, "已经存在编码为【{}】的站内信模板");

    // ========== 站内信模版 1-002-027-000 ==========

    // ========== 站内信发送 1-002-028-000 ==========
    ErrorCode NOTIFY_SEND_TEMPLATE_PARAM_MISS = new ErrorCode(1_002_028_000, "模板参数({})缺失");

    // ========== 流程相关 1-002-029-000 ==========
    ErrorCode FLOW_1_002_029_000 = new ErrorCode(1_002_029_000, "父分类不能为子分类，请重新选择父分类");
    ErrorCode FLOW_1_002_029_001 = new ErrorCode(1_002_029_001, "主键不存在无法更新");
    ErrorCode FLOW_1_002_029_002 = new ErrorCode(1_002_029_002, "不允许删除所有");
    ErrorCode FLOW_1_002_029_003 = new ErrorCode(1_002_029_003, "存在子类不允许删除");
    ErrorCode FLOW_1_002_029_004 = new ErrorCode(1_002_029_004, "存在关联表单模板不允许删除");
    ErrorCode FLOW_1_002_029_005 = new ErrorCode(1_002_029_005, "请选择设置流程处理人信息");
    ErrorCode FLOW_1_002_029_006 = new ErrorCode(1_002_029_006, "当前用户无操作权限");
    ErrorCode FLOW_1_002_029_007 = new ErrorCode(1_002_029_007, "创建流程者没有选择部门信息");
    ErrorCode FLOW_1_002_029_008 = new ErrorCode(1_002_029_008, "请设置发起人部门层级主管信息");
    ErrorCode FLOW_1_002_029_009 = new ErrorCode(1_002_029_009, "未找到任何主管信息");
    ErrorCode FLOW_1_002_029_010 = new ErrorCode(1_002_029_010, "主键不存在无法更新");
    ErrorCode FLOW_1_002_029_011 = new ErrorCode(1_002_029_011, "业务表单配置内容有误");
    ErrorCode FLOW_1_002_029_012 = new ErrorCode(1_002_029_012, "当前ID执行任务不存在");
    ErrorCode FLOW_1_002_029_013 = new ErrorCode(1_002_029_013, "指定用户不存在");
    ErrorCode FLOW_1_002_029_014 = new ErrorCode(1_002_029_014, "用户【{}】已抄送，请勿重复操作");
    ErrorCode FLOW_1_002_029_015 = new ErrorCode(1_002_029_015, "流程实例已结束");
    ErrorCode FLOW_1_002_029_016 = new ErrorCode(1_002_029_016, "该审批流程不允许撤回");
    ErrorCode FLOW_1_002_029_017 = new ErrorCode(1_002_029_017, "发起人节点不允许继续撤回");
    ErrorCode FLOW_1_002_029_018 = new ErrorCode(1_002_029_018, "未发现指定审批流程");
    ErrorCode FLOW_1_002_029_019 = new ErrorCode(1_002_029_019, "未发现指定业务流程表单模板");
    ErrorCode FLOW_1_002_029_020 = new ErrorCode(1_002_029_020, "当前流程实例不存在");
    ErrorCode FLOW_1_002_029_021 = new ErrorCode(1_002_029_021, "指定ID任务已执行完成");
    ErrorCode FLOW_1_002_029_022 = new ErrorCode(1_002_029_022, "保存保单内容失败");
    ErrorCode FLOW_1_002_029_023 = new ErrorCode(1_002_029_023, "指定流程模型不存在");
    ErrorCode FLOW_1_002_029_024 = new ErrorCode(1_002_029_024, "节点【{}】发起人自选未设置处理人员");
    ErrorCode FLOW_1_002_029_025 = new ErrorCode(1_002_029_025, "节点【{}】未设置处理人员");
    ErrorCode FLOW_1_002_029_026 = new ErrorCode(1_002_029_026, "流程启动失败");
    ErrorCode FLOW_1_002_029_027 = new ErrorCode(1_002_029_027, "保存保单失败");
    ErrorCode FLOW_1_002_029_028 = new ErrorCode(1_002_029_028, "流程已执行结束不允许删除");
    ErrorCode FLOW_1_002_029_029 = new ErrorCode(1_002_029_029, "未发现指定流程模型");
    ErrorCode FLOW_1_002_029_030 = new ErrorCode(1_002_029_030, "流程定义分类ID不存在");
    ErrorCode FLOW_1_002_029_031 = new ErrorCode(1_002_029_031, "模型节点名称不允许重复");
    ErrorCode FLOW_1_002_029_032 = new ErrorCode(1_002_029_032, "自动通过节点配置错误，请确保包含在条件分支节点中");
    ErrorCode FLOW_1_002_029_033 = new ErrorCode(1_002_029_033, "自动拒绝节点配置错误，请确保包含在条件分支节点中");
    ErrorCode FLOW_1_002_029_034 = new ErrorCode(1_002_029_034, "路由节点必须配置错误，请确保配置路由分支");
    ErrorCode FLOW_1_002_029_035 = new ErrorCode(1_002_029_035, "子流程节点配置错误，请确保已选择子流程");
    ErrorCode FLOW_1_002_029_036 = new ErrorCode(1_002_029_036, "必须存在两个以上节点");
    ErrorCode FLOW_1_002_029_037 = new ErrorCode(1_002_029_037, "存在多个条件表达式为空");
    ErrorCode FLOW_1_002_029_038 = new ErrorCode(1_002_029_038, "存在多个条件子节点为空");
    ErrorCode FLOW_1_002_029_039 = new ErrorCode(1_002_029_039, "存在条件节点KEY重复");
    ErrorCode FLOW_1_002_029_040 = new ErrorCode(1_002_029_040, "必须存在审批节点");
    ErrorCode FLOW_1_002_029_041 = new ErrorCode(1_002_029_041, "流程定义管理权限保存失败");
    ErrorCode FLOW_1_002_029_042 = new ErrorCode(1_002_029_042, "流程发起人参与者信息保持失败");
    ErrorCode FLOW_1_002_029_043 = new ErrorCode(1_002_029_043, "流程定义配置保存失败");
    ErrorCode FLOW_1_002_029_044 = new ErrorCode(1_002_029_044, "流程唯一标识key不允许重复");
    ErrorCode FLOW_1_002_029_045 = new ErrorCode(1_002_029_045, "无权限编辑操作审批流程");
    ErrorCode FLOW_1_002_029_046 = new ErrorCode(1_002_029_046, "流程顺序保存失败");
    ErrorCode FLOW_1_002_029_047 = new ErrorCode(1_002_029_047, "流程分类顺序保存失败");
    ErrorCode FLOW_1_002_029_048 = new ErrorCode(1_002_029_048, "流程模型节点查询异常");
    ErrorCode FLOW_1_002_029_049 = new ErrorCode(1_002_029_049, "分类名称已存在，请更换其它名称");
    ErrorCode FLOW_1_002_029_050 = new ErrorCode(1_002_029_050, "主键不存在无法更新");
    ErrorCode FLOW_1_002_029_051 = new ErrorCode(1_002_029_051, "存在流程定义关联不允许删除");
    ErrorCode FLOW_1_002_029_052 = new ErrorCode(1_002_029_052, "抄送节点配置错误，请配置处理人或允许抄送自选");
    ErrorCode FLOW_1_002_029_053 = new ErrorCode(1_002_029_053, "无该任务的操作权限");
    ErrorCode FLOW_1_002_029_054 = new ErrorCode(1_002_029_054, "请登录后再操作审批流程");
    ErrorCode FLOW_1_002_029_055 = new ErrorCode(1_002_029_055, "无权限编辑操作审批流程");
    ErrorCode FLOW_1_002_029_056 = new ErrorCode(1_002_029_056, "指定成员审批配置错误，请确保配置处理人员");
    ErrorCode FLOW_1_002_029_057 = new ErrorCode(1_002_029_057, "指定用户ID不能为空");
    ErrorCode FLOW_1_002_029_058 = new ErrorCode(1_002_029_058, "转办人员不能设置为自己");
    ErrorCode FLOW_1_002_029_059 = new ErrorCode(1_002_029_059, "转办时间待办人不能为空");
    ErrorCode FLOW_1_002_029_060 = new ErrorCode(1_002_029_060, "转交人员不能设置为自己");
    ErrorCode FLOW_1_002_029_061 = new ErrorCode(1_002_029_061, "流程任务ID和流程历史任务不能都为空");
    ErrorCode FLOW_1_002_029_062 = new ErrorCode(1_002_029_062, "当前ID执行任务不存在");
    ErrorCode FLOW_1_002_029_063 = new ErrorCode(1_002_029_063, "当前ID执行历史任务不存在");
    ErrorCode FLOW_1_002_029_064 = new ErrorCode(1_002_029_064, "用户【{}】已传阅，请勿重复操作");
    ErrorCode FLOW_1_002_029_065 = new ErrorCode(1_002_029_065, "历史任务参与者信息不存在");
    ErrorCode FLOW_1_002_029_066 = new ErrorCode(1_002_029_066, "没有走过发起人节点的流程不允许继续撤回");
    ErrorCode FLOW_1_002_029_067 = new ErrorCode(1_002_029_067, "撤回失败,请联系管理员");
    ErrorCode FLOW_1_002_029_068 = new ErrorCode(1_002_029_068, "非发起人不允许撤回");


}
