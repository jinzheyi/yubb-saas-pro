-- ----------------------------
-- Table structure for plug_order
-- ----------------------------
DROP TABLE IF EXISTS `plug_order`;
CREATE TABLE `plug_order`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '订单id',
  `order_no` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '订单编号',
  `total_amount` decimal(10, 2) COMMENT '支付金额，单位：钰豆',
  `pay_amount` decimal(10,2) COMMENT '应付金额（实际支付金额）',
  `promotion_amount` decimal(10,2) COMMENT '促销优化金额（促销价、满减、阶梯价）',
  `discount_amount` decimal(10,2) COMMENT '管理员后台调整订单使用的折扣金额',
  `order_type` int(1) NOT NULL COMMENT '订单类型：0->正常订单；1->赠送订单',
  `order_status` tinyint NOT NULL COMMENT '订单状态 未付款,已付款,已安装',
  `user_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户 IP',
  `user_id` bigint NOT NULL COMMENT '购买者编号',
  `expire_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '订单失效时间',
  `success_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '订单支付成功时间',
  `integration` bigint COMMENT '可以获得的积分',
  `growth` bigint COMMENT '可以获得的成长值',
  `note` varchar(500) COMMENT '订单备注',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '订单';

-- ----------------------------
-- Table structure for plug_order_item
-- ----------------------------
DROP TABLE IF EXISTS `plug_order_item`;
CREATE TABLE `plug_order_item`  (
   `id` bigint NOT NULL AUTO_INCREMENT COMMENT '订单项id',
   `order_id` bigint NOT NULL COMMENT '订单id',
   `app_id` bigint NOT NULL COMMENT '应用id',
   `app_pic` varchar(500) COMMENT '应用图片',
   `app_name` varchar(200) COMMENT '应用名称',
   `app_sn` varchar(64) COMMENT '商品条码',
   `app_price` decimal(10,2) COMMENT '原单价',
   `pay_num` int COMMENT '购买数量',
   `promotion_amount` decimal(10,2) COMMENT '促销优化金额（促销价、满减、阶梯价）',
   `discount_amount` decimal(10,2) COMMENT '管理员后台调整订单使用的折扣金额',
   `gift_integration` bigint not null default 0 COMMENT '商品赠送积分',
   `gift_growth` bigint not null default 0 COMMENT '商品赠送成长值',
   `app_info` JSON COMMENT '应用业务信息',
   `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
   `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
   `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
   `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
   `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
   `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
   PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '订单项';

-- ----------------------------
-- Table structure for plug_goods
-- ----------------------------
DROP TABLE IF EXISTS `plug_goods`;
CREATE TABLE `plug_goods`  (
`id` bigint NOT NULL AUTO_INCREMENT COMMENT '应用编号',
`app_pic` varchar(500) COMMENT '应用图片',
`app_name` varchar(200) COMMENT '应用名称',
`app_outline` varchar(200) COMMENT '应用概要',
`app_sn` varchar(64) COMMENT '商品条码',
`app_price` decimal(10,2) COMMENT '原价',
`pay_price` decimal(10,2) COMMENT '售价',
`app_num` int COMMENT '数量',
`gift_integration` bigint not null default 0 COMMENT '商品赠送积分',
`gift_growth` bigint not null default 0 COMMENT '商品赠送成长值',
`app_status` tinyint NOT NULL COMMENT '状态 上下架',
`app_info` JSON COMMENT '应用业务信息',
`app_contents` longtext COMMENT '商品祥情描述',
`creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
`create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
`updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
`update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
`deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '应用商品';