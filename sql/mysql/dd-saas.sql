DROP TABLE IF EXISTS `system_saas_user`;
CREATE TABLE `system_saas_user`  (
   `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
   `username` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '邮箱，第一登录方式账号没有用手机号是因为邮箱验证免费',
   `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '密码',
   `open_id` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '用户唯一标识值',
   `default_tenant` bigint NULL COMMENT '默认所属租户，这个租户是指每次选定的租户，即记录上次登录的租户',
   `my_tenant` bigint NOT NULL COMMENT '我的租户（每个注册的用户都会拥有一个自己的租户，是这个租户的超管）',
   `mobile` varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '手机号码',
   `sex` tinyint DEFAULT '0' COMMENT '用户性别',
   `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '创建者',
   `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
   `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
   `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
   `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
   PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '租户saas单一用户表' ROW_FORMAT = DYNAMIC;

alter table system_users add saas_user_id bigint NOT NULL DEFAULT '0' COMMENT '所属SaaS用户表id';
alter table system_users add `open_account` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '在当前租户下用户唯一标识值';
ALTER TABLE system_users DROP username;
ALTER TABLE system_users DROP password;
ALTER TABLE system_users DROP email;
ALTER TABLE system_users DROP mobile;
ALTER TABLE system_users DROP sex;

ALTER TABLE system_social_user_bind CHANGE user_id `saas_user_id` bigint NOT NULL COMMENT '所属SaaS用户表编号';

alter table system_social_client rename as tenant_social_client;
alter table system_social_user rename as tenant_social_user;
alter table system_social_user_bind rename as tenant_social_user_bind;

alter table system_sms_channel rename as tenant_sms_channel;
alter table system_sms_code rename as tenant_sms_code;
alter table system_sms_log rename as tenant_sms_log;
alter table system_sms_template rename as tenant_sms_template;

alter table system_mail_account rename as tenant_mail_account;
alter table system_mail_log rename as tenant_mail_log;
alter table system_mail_template rename as tenant_mail_template;



