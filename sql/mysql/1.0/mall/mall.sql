-- ----------------------------
-- 删除商品模块相关表
-- ----------------------------
DROP TABLE IF EXISTS `product_comment`;
DROP TABLE IF EXISTS `product_favorite`;
DROP TABLE IF EXISTS `product_browse_history`;
DROP TABLE IF EXISTS `product_sku`;
DROP TABLE IF EXISTS `product_spu`;
DROP TABLE IF EXISTS `product_brand`;
DROP TABLE IF EXISTS `product_category`;
DROP TABLE IF EXISTS `product_property_value`;
DROP TABLE IF EXISTS `product_property`;

-- ----------------------------
-- 商品属性项
-- ----------------------------
CREATE TABLE `product_property` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '名称',
  `remark` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '备注',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品属性项';

-- ----------------------------
-- 商品属性值
-- ----------------------------
CREATE TABLE `product_property_value` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `property_id` bigint NOT NULL DEFAULT '0' COMMENT '属性项的编号',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '名称',
  `remark` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '备注',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_property_id` (`property_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品属性值';

-- ----------------------------
-- 商品分类
-- ----------------------------
CREATE TABLE `product_category` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '分类编号',
  `parent_id` bigint NOT NULL DEFAULT '0' COMMENT '父分类编号',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '分类名称',
  `pic_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '移动端分类图',
  `sort` int NOT NULL DEFAULT '0' COMMENT '分类排序',
  `status` int NOT NULL DEFAULT '0' COMMENT '开启状态',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品分类';

-- ----------------------------
-- 商品品牌
-- ----------------------------
CREATE TABLE `product_brand` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '品牌编号',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '品牌名称',
  `pic_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '品牌图片',
  `sort` int NOT NULL DEFAULT '0' COMMENT '品牌排序',
  `description` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '品牌描述',
  `status` int NOT NULL DEFAULT '0' COMMENT '状态',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品品牌';

-- ----------------------------
-- 商品 SPU
-- ----------------------------
CREATE TABLE `product_spu` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '商品 SPU 编号',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商品名称',
  `keyword` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '关键字',
  `introduction` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商品简介',
  `description` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '商品详情',
  `category_id` bigint NOT NULL DEFAULT '0' COMMENT '商品分类编号',
  `brand_id` bigint NOT NULL DEFAULT '0' COMMENT '商品品牌编号',
  `pic_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商品封面图',
  `slider_pic_urls` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '商品轮播图，JSON 格式',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序字段',
  `status` int NOT NULL DEFAULT '0' COMMENT '商品状态',
  `spec_type` bit(1) NOT NULL DEFAULT b'0' COMMENT '规格类型：false-单规格，true-多规格',
  `price` int NOT NULL DEFAULT '0' COMMENT '商品价格（最低 SKU）',
  `market_price` int NOT NULL DEFAULT '0' COMMENT '市场价（最低 SKU）',
  `cost_price` int NOT NULL DEFAULT '0' COMMENT '成本价（最低 SKU）',
  `stock` int NOT NULL DEFAULT '0' COMMENT '库存（总和）',
  `delivery_types` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '配送方式数组，JSON 格式',
  `delivery_template_id` bigint NOT NULL DEFAULT '0' COMMENT '物流配置模板编号',
  `give_integral` int NOT NULL DEFAULT '0' COMMENT '赠送积分',
  `sub_commission_type` bit(1) NOT NULL DEFAULT b'0' COMMENT '分销类型：false-默认，true-自行设置',
  `sales_count` int NOT NULL DEFAULT '0' COMMENT '商品销量',
  `virtual_sales_count` int NOT NULL DEFAULT '0' COMMENT '虚拟销量',
  `browse_count` int NOT NULL DEFAULT '0' COMMENT '浏览量',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_category_id` (`category_id`),
  KEY `idx_brand_id` (`brand_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品 SPU';

-- ----------------------------
-- 商品 SKU
-- ----------------------------
CREATE TABLE `product_sku` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '商品 SKU 编号',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT 'SPU 编号',
  `properties` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '属性数组，JSON 格式',
  `price` int NOT NULL DEFAULT '0' COMMENT '商品价格，单位：分',
  `market_price` int NOT NULL DEFAULT '0' COMMENT '市场价，单位：分',
  `cost_price` int NOT NULL DEFAULT '0' COMMENT '成本价，单位：分',
  `bar_code` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商品条码',
  `pic_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '图片地址',
  `stock` int NOT NULL DEFAULT '0' COMMENT '库存',
  `weight` decimal(10,3) NOT NULL DEFAULT '0.000' COMMENT '商品重量，单位：kg',
  `volume` decimal(10,3) NOT NULL DEFAULT '0.000' COMMENT '商品体积，单位：m^3',
  `first_brokerage_price` int NOT NULL DEFAULT '0' COMMENT '一级分销佣金，单位：分',
  `second_brokerage_price` int NOT NULL DEFAULT '0' COMMENT '二级分销佣金，单位：分',
  `sales_count` int NOT NULL DEFAULT '0' COMMENT '商品销量',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_spu_id` (`spu_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品 SKU';

-- ----------------------------
-- 商品浏览记录
-- ----------------------------
CREATE TABLE `product_browse_history` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '记录编号',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SPU 编号',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `user_deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '用户是否删除',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_spu_id` (`spu_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品浏览记录';

-- ----------------------------
-- 商品收藏
-- ----------------------------
CREATE TABLE `product_favorite` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SPU 编号',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_spu` (`user_id`, `spu_id`, `deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品收藏';

-- ----------------------------
-- 商品评论
-- ----------------------------
CREATE TABLE `product_comment` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '评论编号',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '评价人的用户编号',
  `user_nickname` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '评价人名称',
  `user_avatar` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '评价人头像',
  `anonymous` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否匿名',
  `order_id` bigint NOT NULL DEFAULT '0' COMMENT '交易订单编号',
  `order_item_id` bigint NOT NULL DEFAULT '0' COMMENT '交易订单项编号',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SPU 编号',
  `spu_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商品 SPU 名称',
  `sku_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SKU 编号',
  `sku_pic_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商品 SKU 图片地址',
  `sku_properties` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '属性数组，JSON 格式',
  `visible` bit(1) NOT NULL DEFAULT b'1' COMMENT '是否可见',
  `scores` int NOT NULL DEFAULT '5' COMMENT '评分星级',
  `description_scores` int NOT NULL DEFAULT '5' COMMENT '描述星级',
  `benefit_scores` int NOT NULL DEFAULT '5' COMMENT '服务星级',
  `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '评论内容',
  `pic_urls` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '评论图片地址数组，JSON 格式',
  `reply_status` bit(1) NOT NULL DEFAULT b'0' COMMENT '商家是否回复',
  `reply_user_id` bigint NOT NULL DEFAULT '0' COMMENT '回复管理员编号',
  `reply_content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '商家回复内容',
  `reply_time` datetime NULL DEFAULT NULL COMMENT '商家回复时间',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_spu_id` (`spu_id`),
  KEY `idx_sku_id` (`sku_id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品评论';



-- ----------------------------
-- 删除 promotion 模块相关表（按逻辑顺序）
-- ----------------------------
DROP TABLE IF EXISTS `promotion_kefu_message`;
DROP TABLE IF EXISTS `promotion_kefu_conversation`;
DROP TABLE IF EXISTS `promotion_diy_page`;
DROP TABLE IF EXISTS `promotion_diy_template`;
DROP TABLE IF EXISTS `promotion_seckill_product`;
DROP TABLE IF EXISTS `promotion_seckill_config`;
DROP TABLE IF EXISTS `promotion_seckill_activity`;
DROP TABLE IF EXISTS `promotion_reward_activity`;
DROP TABLE IF EXISTS `promotion_point_product`;
DROP TABLE IF EXISTS `promotion_point_activity`;
DROP TABLE IF EXISTS `promotion_discount_product`;
DROP TABLE IF EXISTS `promotion_discount_activity`;
DROP TABLE IF EXISTS `promotion_coupon`;
DROP TABLE IF EXISTS `promotion_coupon_template`;
DROP TABLE IF EXISTS `promotion_combination_record`;
DROP TABLE IF EXISTS `promotion_combination_product`;
DROP TABLE IF EXISTS `promotion_combination_activity`;
DROP TABLE IF EXISTS `promotion_bargain_help`;
DROP TABLE IF EXISTS `promotion_bargain_record`;
DROP TABLE IF EXISTS `promotion_bargain_activity`;
DROP TABLE IF EXISTS `promotion_banner`;
DROP TABLE IF EXISTS `promotion_article`;
DROP TABLE IF EXISTS `promotion_article_category`;

-- ----------------------------
-- 文章分类
-- ----------------------------
CREATE TABLE `promotion_article_category` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '文章分类编号',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '文章分类名称',
  `pic_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '图标地址',
  `status` int NOT NULL DEFAULT '0' COMMENT '状态',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='文章分类';

-- ----------------------------
-- 文章管理
-- ----------------------------
CREATE TABLE `promotion_article` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '文章管理编号',
  `category_id` bigint NOT NULL DEFAULT '0' COMMENT '分类编号',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT '关联商品编号',
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '文章标题',
  `author` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '文章作者',
  `pic_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '文章封面图片地址',
  `introduction` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '文章简介',
  `browse_count` int NOT NULL DEFAULT '0' COMMENT '浏览次数',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序',
  `status` int NOT NULL DEFAULT '0' COMMENT '状态',
  `recommend_hot` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否热门(小程序)',
  `recommend_banner` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否轮播图(小程序)',
  `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '文章内容',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_category_id` (`category_id`),
  KEY `idx_spu_id` (`spu_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='文章管理';

-- ----------------------------
-- Banner
-- ----------------------------
CREATE TABLE `promotion_banner` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '标题',
  `url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '跳转链接',
  `pic_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '图片链接',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序',
  `status` int NOT NULL DEFAULT '0' COMMENT '状态',
  `position` int NOT NULL DEFAULT '0' COMMENT '定位',
  `memo` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '备注',
  `browse_count` int NOT NULL DEFAULT '0' COMMENT '点击次数',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_position` (`position`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='banner';

-- ----------------------------
-- 砍价活动
-- ----------------------------
CREATE TABLE `promotion_bargain_activity` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '砍价活动编号',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '砍价活动名称',
  `start_time` datetime NOT NULL COMMENT '活动开始时间',
  `end_time` datetime NOT NULL COMMENT '活动结束时间',
  `status` int NOT NULL DEFAULT '0' COMMENT '活动状态',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SPU 编号',
  `sku_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SKU 编号',
  `bargain_first_price` int NOT NULL DEFAULT '0' COMMENT '砍价起始价格，单位：分',
  `bargain_min_price` int NOT NULL DEFAULT '0' COMMENT '砍价底价，单位：分',
  `stock` int NOT NULL DEFAULT '0' COMMENT '砍价库存',
  `total_stock` int NOT NULL DEFAULT '0' COMMENT '砍价总库存',
  `help_max_count` int NOT NULL DEFAULT '0' COMMENT '砍价人数',
  `bargain_count` int NOT NULL DEFAULT '0' COMMENT '帮砍次数',
  `total_limit_count` int NOT NULL DEFAULT '0' COMMENT '总限购数量',
  `random_min_price` int NOT NULL DEFAULT '0' COMMENT '用户每次砍价的最小金额，单位：分',
  `random_max_price` int NOT NULL DEFAULT '0' COMMENT '用户每次砍价的最大金额，单位：分',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_spu_id` (`spu_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='砍价活动';

-- ----------------------------
-- 砍价记录
-- ----------------------------
CREATE TABLE `promotion_bargain_record` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `activity_id` bigint NOT NULL DEFAULT '0' COMMENT '砍价活动编号',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SPU 编号',
  `sku_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SKU 编号',
  `bargain_first_price` int NOT NULL DEFAULT '0' COMMENT '砍价起始价格，单位：分',
  `bargain_price` int NOT NULL DEFAULT '0' COMMENT '当前砍价，单位：分',
  `status` int NOT NULL DEFAULT '0' COMMENT '砍价状态',
  `end_time` datetime NULL DEFAULT NULL COMMENT '结束时间',
  `order_id` bigint NOT NULL DEFAULT '0' COMMENT '订单编号',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_activity_id` (`activity_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='砍价记录';

-- ----------------------------
-- 砍价助力
-- ----------------------------
CREATE TABLE `promotion_bargain_help` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `activity_id` bigint NOT NULL DEFAULT '0' COMMENT '砍价活动编号',
  `record_id` bigint NOT NULL DEFAULT '0' COMMENT '砍价记录编号',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `reduce_price` int NOT NULL DEFAULT '0' COMMENT '减少价格，单位：分',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_activity_id` (`activity_id`),
  KEY `idx_record_id` (`record_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='砍价助力';

-- ----------------------------
-- 拼团活动
-- ----------------------------
CREATE TABLE `promotion_combination_activity` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '活动编号',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '拼团名称',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SPU 编号',
  `total_limit_count` int NOT NULL DEFAULT '0' COMMENT '总限购数量',
  `single_limit_count` int NOT NULL DEFAULT '0' COMMENT '单次限购数量',
  `start_time` datetime NOT NULL COMMENT '开始时间',
  `end_time` datetime NOT NULL COMMENT '结束时间',
  `user_size` int NOT NULL DEFAULT '0' COMMENT '几人团',
  `virtual_group` bit(1) NOT NULL DEFAULT b'0' COMMENT '虚拟成团',
  `status` int NOT NULL DEFAULT '0' COMMENT '活动状态',
  `limit_duration` int NOT NULL DEFAULT '0' COMMENT '限制时长（小时）',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_spu_id` (`spu_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='拼团活动';

-- ----------------------------
-- 拼团商品
-- ----------------------------
CREATE TABLE `promotion_combination_product` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `activity_id` bigint NOT NULL DEFAULT '0' COMMENT '拼团活动编号',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SPU 编号',
  `sku_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SKU 编号',
  `combination_price` int NOT NULL DEFAULT '0' COMMENT '拼团价格，单位分',
  `activity_status` int NOT NULL DEFAULT '0' COMMENT '拼团商品状态',
  `activity_start_time` datetime NULL DEFAULT NULL COMMENT '活动开始时间点',
  `activity_end_time` datetime NULL DEFAULT NULL COMMENT '活动结束时间点',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_activity_id` (`activity_id`),
  KEY `idx_spu_id` (`spu_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='拼团商品';

-- ----------------------------
-- 拼团记录
-- ----------------------------
CREATE TABLE `promotion_combination_record` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号，主键自增',
  `activity_id` bigint NOT NULL DEFAULT '0' COMMENT '拼团活动编号',
  `combination_price` int NOT NULL DEFAULT '0' COMMENT '拼团商品单价',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT 'SPU 编号',
  `spu_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商品名字',
  `pic_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商品图片',
  `sku_id` bigint NOT NULL DEFAULT '0' COMMENT 'SKU 编号',
  `count` int NOT NULL DEFAULT '0' COMMENT '购买的商品数量',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `nickname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '用户昵称',
  `avatar` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '用户头像',
  `head_id` bigint NOT NULL DEFAULT '0' COMMENT '团长编号',
  `status` int NOT NULL DEFAULT '0' COMMENT '开团状态',
  `order_id` bigint NOT NULL DEFAULT '0' COMMENT '订单编号',
  `user_size` int NOT NULL DEFAULT '0' COMMENT '开团需要人数',
  `user_count` int NOT NULL DEFAULT '0' COMMENT '已加入拼团人数',
  `virtual_group` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否虚拟成团',
  `expire_time` datetime NULL DEFAULT NULL COMMENT '过期时间',
  `start_time` datetime NULL DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime NULL DEFAULT NULL COMMENT '结束时间',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_activity_id` (`activity_id`),
  KEY `idx_head_id` (`head_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='拼团记录';

-- ----------------------------
-- 优惠券模板
-- ----------------------------
CREATE TABLE `promotion_coupon_template` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '模板编号，自增唯一',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '优惠劵名',
  `description` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '优惠券说明',
  `status` int NOT NULL DEFAULT '0' COMMENT '状态',
  `total_count` int NOT NULL DEFAULT '-1' COMMENT '发放数量',
  `take_limit_count` int NOT NULL DEFAULT '-1' COMMENT '每人限领个数',
  `take_type` int NOT NULL DEFAULT '0' COMMENT '领取方式',
  `use_price` int NOT NULL DEFAULT '0' COMMENT '是否设置满多少金额可用，单位：分',
  `product_scope` int NOT NULL DEFAULT '0' COMMENT '商品范围',
  `product_scope_values` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '商品范围编号的数组，JSON 格式',
  `validity_type` int NOT NULL DEFAULT '0' COMMENT '生效日期类型',
  `valid_start_time` datetime NULL DEFAULT NULL COMMENT '固定日期 - 生效开始时间',
  `valid_end_time` datetime NULL DEFAULT NULL COMMENT '固定日期 - 生效结束时间',
  `fixed_start_term` int NULL DEFAULT NULL COMMENT '领取日期 - 开始天数',
  `fixed_end_term` int NULL DEFAULT NULL COMMENT '领取日期 - 结束天数',
  `discount_type` int NOT NULL DEFAULT '0' COMMENT '折扣类型',
  `discount_percent` int NOT NULL DEFAULT '0' COMMENT '折扣百分比',
  `discount_price` int NOT NULL DEFAULT '0' COMMENT '优惠金额，单位：分',
  `discount_limit_price` int NOT NULL DEFAULT '0' COMMENT '折扣上限',
  `take_count` int NOT NULL DEFAULT '0' COMMENT '领取优惠券的数量',
  `use_count` int NOT NULL DEFAULT '0' COMMENT '使用优惠券的次数',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='优惠劵模板';

-- ----------------------------
-- 优惠券
-- ----------------------------
CREATE TABLE `promotion_coupon` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '优惠劵编号',
  `template_id` bigint NOT NULL DEFAULT '0' COMMENT '优惠劵模板编号',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '优惠劵名',
  `status` int NOT NULL DEFAULT '0' COMMENT '优惠码状态',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `take_type` int NOT NULL DEFAULT '0' COMMENT '领取类型',
  `use_price` int NOT NULL DEFAULT '0' COMMENT '是否设置满多少金额可用，单位：分',
  `valid_start_time` datetime NOT NULL COMMENT '生效开始时间',
  `valid_end_time` datetime NOT NULL COMMENT '生效结束时间',
  `product_scope` int NOT NULL DEFAULT '0' COMMENT '商品范围',
  `product_scope_values` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '商品范围编号的数组，JSON 格式',
  `discount_type` int NOT NULL DEFAULT '0' COMMENT '折扣类型',
  `discount_percent` int NOT NULL DEFAULT '0' COMMENT '折扣百分比',
  `discount_price` int NOT NULL DEFAULT '0' COMMENT '优惠金额，单位：分',
  `discount_limit_price` int NOT NULL DEFAULT '0' COMMENT '折扣上限',
  `use_order_id` bigint NOT NULL DEFAULT '0' COMMENT '使用订单号',
  `use_time` datetime NULL DEFAULT NULL COMMENT '使用时间',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_template_id` (`template_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='优惠劵';

-- ----------------------------
-- 限时折扣活动
-- ----------------------------
CREATE TABLE `promotion_discount_activity` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '活动编号，主键自增',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '活动标题',
  `status` int NOT NULL DEFAULT '0' COMMENT '状态',
  `start_time` datetime NOT NULL COMMENT '开始时间',
  `end_time` datetime NOT NULL COMMENT '结束时间',
  `remark` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '备注',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='限时折扣活动';

-- ----------------------------
-- 限时折扣商品
-- ----------------------------
CREATE TABLE `promotion_discount_product` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号，主键自增',
  `activity_id` bigint NOT NULL DEFAULT '0' COMMENT '限时折扣活动的编号',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SPU 编号',
  `sku_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SKU 编号',
  `discount_type` int NOT NULL DEFAULT '0' COMMENT '折扣类型',
  `discount_percent` int NOT NULL DEFAULT '0' COMMENT '折扣百分比',
  `discount_price` int NOT NULL DEFAULT '0' COMMENT '优惠金额，单位：分',
  `activity_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '活动标题',
  `activity_status` int NOT NULL DEFAULT '0' COMMENT '活动状态',
  `activity_start_time` datetime NULL DEFAULT NULL COMMENT '活动开始时间点',
  `activity_end_time` datetime NULL DEFAULT NULL COMMENT '活动结束时间点',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_activity_id` (`activity_id`),
  KEY `idx_spu_id` (`spu_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='限时折扣商品';

-- ----------------------------
-- 积分商城活动
-- ----------------------------
CREATE TABLE `promotion_point_activity` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '积分商城活动编号',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT '积分商城活动商品',
  `status` int NOT NULL DEFAULT '0' COMMENT '活动状态',
  `remark` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '备注',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序',
  `stock` int NOT NULL DEFAULT '0' COMMENT '积分商城活动库存',
  `total_stock` int NOT NULL DEFAULT '0' COMMENT '积分商城活动总库存',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_spu_id` (`spu_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='积分商城活动';

-- ----------------------------
-- 积分商城商品
-- ----------------------------
CREATE TABLE `promotion_point_product` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '积分商城商品编号',
  `activity_id` bigint NOT NULL DEFAULT '0' COMMENT '积分商城活动 id',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SPU 编号',
  `sku_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SKU 编号',
  `count` int NOT NULL DEFAULT '0' COMMENT '可兑换次数',
  `point` int NOT NULL DEFAULT '0' COMMENT '所需兑换积分',
  `price` int NOT NULL DEFAULT '0' COMMENT '所需兑换金额，单位：分',
  `stock` int NOT NULL DEFAULT '0' COMMENT '积分商城商品库存',
  `activity_status` int NOT NULL DEFAULT '0' COMMENT '积分商城商品状态',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_activity_id` (`activity_id`),
  KEY `idx_spu_id` (`spu_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='积分商城商品';

-- ----------------------------
-- 满减送活动
-- ----------------------------
CREATE TABLE `promotion_reward_activity` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '活动编号，主键自增',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '活动标题',
  `status` int NOT NULL DEFAULT '0' COMMENT '状态',
  `start_time` datetime NOT NULL COMMENT '开始时间',
  `end_time` datetime NOT NULL COMMENT '结束时间',
  `remark` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '备注',
  `condition_type` int NOT NULL DEFAULT '0' COMMENT '条件类型',
  `product_scope` int NOT NULL DEFAULT '0' COMMENT '商品范围',
  `product_scope_values` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '商品 SPU 编号的数组，JSON 格式',
  `rules` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '优惠规则的数组，JSON 格式',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='满减送活动';

-- ----------------------------
-- 秒杀活动
-- ----------------------------
CREATE TABLE `promotion_seckill_activity` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '秒杀活动编号',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT '秒杀活动商品',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '秒杀活动名称',
  `status` int NOT NULL DEFAULT '0' COMMENT '活动状态',
  `remark` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '备注',
  `start_time` datetime NOT NULL COMMENT '活动开始时间',
  `end_time` datetime NOT NULL COMMENT '活动结束时间',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序',
  `config_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '秒杀时段 id，JSON 格式',
  `total_limit_count` int NOT NULL DEFAULT '0' COMMENT '总限购数量',
  `single_limit_count` int NOT NULL DEFAULT '0' COMMENT '单次限够数量',
  `stock` int NOT NULL DEFAULT '0' COMMENT '秒杀库存',
  `total_stock` int NOT NULL DEFAULT '0' COMMENT '秒杀总库存',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_spu_id` (`spu_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='秒杀活动';

-- ----------------------------
-- 秒杀时段
-- ----------------------------
CREATE TABLE `promotion_seckill_config` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '秒杀时段名称',
  `start_time` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '开始时间点（HH:mm）',
  `end_time` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '结束时间点（HH:mm）',
  `slider_pic_urls` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '秒杀轮播图，JSON 格式',
  `status` int NOT NULL DEFAULT '0' COMMENT '状态',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='秒杀时段';

-- ----------------------------
-- 秒杀参与商品
-- ----------------------------
CREATE TABLE `promotion_seckill_product` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '秒杀参与商品编号',
  `activity_id` bigint NOT NULL DEFAULT '0' COMMENT '秒杀活动 id',
  `config_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '秒杀时段 id，JSON 格式',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SPU 编号',
  `sku_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SKU 编号',
  `seckill_price` int NOT NULL DEFAULT '0' COMMENT '秒杀金额，单位：分',
  `stock` int NOT NULL DEFAULT '0' COMMENT '秒杀库存',
  `activity_status` int NOT NULL DEFAULT '0' COMMENT '秒杀商品状态',
  `activity_start_time` datetime NULL DEFAULT NULL COMMENT '活动开始时间点',
  `activity_end_time` datetime NULL DEFAULT NULL COMMENT '活动结束时间点',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_activity_id` (`activity_id`),
  KEY `idx_spu_id` (`spu_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='秒杀参与商品';

-- ----------------------------
-- 装修模板
-- ----------------------------
CREATE TABLE `promotion_diy_template` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '装修模板编号',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '模板名称',
  `used` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否使用',
  `used_time` datetime NULL DEFAULT NULL COMMENT '使用时间',
  `remark` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '备注',
  `preview_pic_urls` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '预览图，JSON 格式',
  `property` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'uni-app 底部导航属性，JSON 格式',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='装修模板';

-- ----------------------------
-- 装修页面
-- ----------------------------
CREATE TABLE `promotion_diy_page` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '装修页面编号',
  `template_id` bigint NULL DEFAULT NULL COMMENT '装修模板编号',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '页面名称',
  `remark` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '备注',
  `preview_pic_urls` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '预览图，多个逗号分隔，JSON 格式',
  `property` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '页面属性，JSON 格式',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_template_id` (`template_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='装修页面';

-- ----------------------------
-- 客服会话
-- ----------------------------
CREATE TABLE `promotion_kefu_conversation` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '会话所属用户',
  `last_message_time` datetime NULL DEFAULT NULL COMMENT '最后聊天时间',
  `last_message_content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '最后聊天内容',
  `last_message_content_type` int NOT NULL DEFAULT '0' COMMENT '最后发送的消息类型',
  `admin_pinned` bit(1) NOT NULL DEFAULT b'0' COMMENT '管理端置顶',
  `user_deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '用户是否可见',
  `admin_deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '管理员是否可见',
  `admin_unread_message_count` int NOT NULL DEFAULT '0' COMMENT '管理员未读消息数',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='客服会话';

-- ----------------------------
-- 客服消息
-- ----------------------------
CREATE TABLE `promotion_kefu_message` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `conversation_id` bigint NOT NULL DEFAULT '0' COMMENT '会话编号',
  `sender_id` bigint NOT NULL DEFAULT '0' COMMENT '发送人编号',
  `sender_type` int NOT NULL DEFAULT '0' COMMENT '发送人类型',
  `receiver_id` bigint NOT NULL DEFAULT '0' COMMENT '接收人编号',
  `receiver_type` int NOT NULL DEFAULT '0' COMMENT '接收人类型',
  `content_type` int NOT NULL DEFAULT '0' COMMENT '消息类型',
  `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '消息',
  `read_status` bit(1) NOT NULL DEFAULT b'0' COMMENT '是/否已读',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_conversation_id` (`conversation_id`),
  KEY `idx_sender_id` (`sender_id`),
  KEY `idx_receiver_id` (`receiver_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='客服消息';


-- ----------------------------
-- 删除统计相关表
-- ----------------------------
DROP TABLE IF EXISTS `product_statistics`;
DROP TABLE IF EXISTS `trade_statistics`;

-- ----------------------------
-- 商品统计表
-- ----------------------------
CREATE TABLE `product_statistics` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号，主键自增',
  `time` date NOT NULL COMMENT '统计日期',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SPU 编号',
  `browse_count` int NOT NULL DEFAULT '0' COMMENT '浏览量',
  `browse_user_count` int NOT NULL DEFAULT '0' COMMENT '访客量',
  `favorite_count` int NOT NULL DEFAULT '0' COMMENT '收藏数量',
  `cart_count` int NOT NULL DEFAULT '0' COMMENT '加购数量',
  `order_count` int NOT NULL DEFAULT '0' COMMENT '下单件数',
  `order_pay_count` int NOT NULL DEFAULT '0' COMMENT '支付件数',
  `order_pay_price` int NOT NULL DEFAULT '0' COMMENT '支付金额，单位：分',
  `after_sale_count` int NOT NULL DEFAULT '0' COMMENT '退款件数',
  `after_sale_refund_price` int NOT NULL DEFAULT '0' COMMENT '退款金额，单位：分',
  `browse_convert_percent` int NOT NULL DEFAULT '0' COMMENT '访客支付转化率（百分比）',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_time_spu_id` (`time`, `spu_id`, `deleted`),
  KEY `idx_spu_id` (`spu_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品统计';

-- ----------------------------
-- 交易统计表
-- ----------------------------
CREATE TABLE `trade_statistics` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号，主键自增',
  `time` datetime NOT NULL COMMENT '统计日期',
  `order_create_count` int NOT NULL DEFAULT '0' COMMENT '创建订单数',
  `order_pay_count` int NOT NULL DEFAULT '0' COMMENT '支付订单商品数',
  `order_pay_price` int NOT NULL DEFAULT '0' COMMENT '总支付金额，单位：分',
  `after_sale_count` int NOT NULL DEFAULT '0' COMMENT '退款订单数',
  `after_sale_refund_price` int NOT NULL DEFAULT '0' COMMENT '总退款金额，单位：分',
  `brokerage_settlement_price` int NOT NULL DEFAULT '0' COMMENT '佣金金额（已结算），单位：分',
  `wallet_pay_price` int NOT NULL DEFAULT '0' COMMENT '总支付金额（余额），单位：分',
  `recharge_pay_count` int NOT NULL DEFAULT '0' COMMENT '充值订单数',
  `recharge_pay_price` int NOT NULL DEFAULT '0' COMMENT '充值金额，单位：分',
  `recharge_refund_count` int NOT NULL DEFAULT '0' COMMENT '充值退款订单数',
  `recharge_refund_price` int NOT NULL DEFAULT '0' COMMENT '充值退款金额，单位：分',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_time` (`time`, `deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='交易统计';



-- ----------------------------
-- 删除 trade 模块相关表（按依赖倒序）
-- ----------------------------
DROP TABLE IF EXISTS `trade_order_log`;
DROP TABLE IF EXISTS `trade_order_item`;
DROP TABLE IF EXISTS `trade_order`;
DROP TABLE IF EXISTS `trade_delivery_pick_up_store`;
DROP TABLE IF EXISTS `trade_delivery_express_template_free`;
DROP TABLE IF EXISTS `trade_delivery_express_template_charge`;
DROP TABLE IF EXISTS `trade_delivery_express_template`;
DROP TABLE IF EXISTS `trade_delivery_express`;
DROP TABLE IF EXISTS `trade_config`;
DROP TABLE IF EXISTS `trade_cart`;
DROP TABLE IF EXISTS `trade_brokerage_withdraw`;
DROP TABLE IF EXISTS `trade_brokerage_user`;
DROP TABLE IF EXISTS `trade_brokerage_record`;
DROP TABLE IF EXISTS `trade_after_sale_log`;
DROP TABLE IF EXISTS `trade_after_sale`;

-- ----------------------------
-- 售后订单
-- ----------------------------
CREATE TABLE `trade_after_sale` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '售后编号，主键自增',
  `no` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '售后单号',
  `status` int NOT NULL DEFAULT '0' COMMENT '退款状态',
  `way` int NOT NULL DEFAULT '0' COMMENT '售后方式',
  `type` int NOT NULL DEFAULT '0' COMMENT '售后类型',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `apply_reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '申请原因',
  `apply_description` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '补充描述',
  `apply_pic_urls` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '补充凭证图片，JSON 格式',

  `order_id` bigint NOT NULL DEFAULT '0' COMMENT '交易订单编号',
  `order_no` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '订单流水号',
  `order_item_id` bigint NOT NULL DEFAULT '0' COMMENT '交易订单项编号',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SPU 编号',
  `spu_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商品 SPU 名称',
  `sku_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SKU 编号',
  `properties` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '属性数组，JSON 格式',
  `pic_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商品图片',
  `count` int NOT NULL DEFAULT '0' COMMENT '退货商品数量',

  `audit_time` datetime NULL DEFAULT NULL COMMENT '审批时间',
  `audit_user_id` bigint NOT NULL DEFAULT '0' COMMENT '审批人',
  `audit_reason` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '审批备注',

  `refund_price` int NOT NULL DEFAULT '0' COMMENT '退款金额，单位：分',
  `pay_refund_id` bigint NOT NULL DEFAULT '0' COMMENT '支付退款编号',
  `refund_time` datetime NULL DEFAULT NULL COMMENT '退款时间',

  `logistics_id` bigint NOT NULL DEFAULT '0' COMMENT '退货物流公司编号',
  `logistics_no` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '退货物流单号',
  `delivery_time` datetime NULL DEFAULT NULL COMMENT '退货时间',
  `receive_time` datetime NULL DEFAULT NULL COMMENT '收货时间',
  `receive_reason` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '收货备注',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_no` (`no`, `deleted`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='售后订单';

-- ----------------------------
-- 售后日志
-- ----------------------------
CREATE TABLE `trade_after_sale_log` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `user_type` int NOT NULL DEFAULT '0' COMMENT '用户类型',
  `after_sale_id` bigint NOT NULL DEFAULT '0' COMMENT '售后编号',
  `before_status` int NOT NULL DEFAULT '0' COMMENT '操作前状态',
  `after_status` int NOT NULL DEFAULT '0' COMMENT '操作后状态',
  `operate_type` int NOT NULL DEFAULT '0' COMMENT '操作类型',
  `content` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '操作明细',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_after_sale_id` (`after_sale_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='交易售后日志';

-- ----------------------------
-- 佣金记录
-- ----------------------------
CREATE TABLE `trade_brokerage_record` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `biz_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '业务编号',
  `biz_type` int NOT NULL DEFAULT '0' COMMENT '业务类型',
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '标题',
  `description` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '说明',
  `price` int NOT NULL DEFAULT '0' COMMENT '金额',
  `total_price` int NOT NULL DEFAULT '0' COMMENT '当前总佣金',
  `status` int NOT NULL DEFAULT '0' COMMENT '状态',
  `frozen_days` int NOT NULL DEFAULT '0' COMMENT '冻结时间（天）',
  `unfreeze_time` datetime NULL DEFAULT NULL COMMENT '解冻时间',
  `source_user_level` int NOT NULL DEFAULT '0' COMMENT '来源用户等级',
  `source_user_id` bigint NOT NULL DEFAULT '0' COMMENT '来源用户编号',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_biz_id` (`biz_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='佣金记录';

-- ----------------------------
-- 分销用户
-- ----------------------------
CREATE TABLE `trade_brokerage_user` (
  `id` bigint NOT NULL COMMENT '用户编号',
  `bind_user_id` bigint NOT NULL DEFAULT '0' COMMENT '推广员编号',
  `bind_user_time` datetime NULL DEFAULT NULL COMMENT '推广员绑定时间',
  `brokerage_enabled` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否有分销资格',
  `brokerage_time` datetime NULL DEFAULT NULL COMMENT '成为分销员时间',
  `brokerage_price` int NOT NULL DEFAULT '0' COMMENT '可用佣金',
  `frozen_price` int NOT NULL DEFAULT '0' COMMENT '冻结佣金',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='分销用户';

-- ----------------------------
-- 佣金提现
-- ----------------------------
CREATE TABLE `trade_brokerage_withdraw` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `price` int NOT NULL DEFAULT '0' COMMENT '提现金额，单位：分',
  `fee_price` int NOT NULL DEFAULT '0' COMMENT '提现手续费，单位：分',
  `total_price` int NOT NULL DEFAULT '0' COMMENT '当前总佣金，单位：分',
  `type` int NOT NULL DEFAULT '0' COMMENT '提现类型',
  `user_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '提现姓名',
  `user_account` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '提现账号',
  `qr_code_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '收款码',
  `bank_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '银行名称',
  `bank_address` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '开户地址',
  `status` int NOT NULL DEFAULT '0' COMMENT '状态',
  `audit_reason` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '审核驳回原因',
  `audit_time` datetime NULL DEFAULT NULL COMMENT '审核时间',
  `remark` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '备注',
  `pay_transfer_id` bigint NOT NULL DEFAULT '0' COMMENT '转账单编号',
  `transfer_channel_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '转账渠道',
  `transfer_time` datetime NULL DEFAULT NULL COMMENT '转账成功时间',
  `transfer_error_msg` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '转账错误提示',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='佣金提现';

-- ----------------------------
-- 购物车
-- ----------------------------
CREATE TABLE `trade_cart` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号，唯一自增',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SPU 编号',
  `sku_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SKU 编号',
  `count` int NOT NULL DEFAULT '0' COMMENT '商品购买数量',
  `selected` bit(1) NOT NULL DEFAULT b'1' COMMENT '是否选中',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_spu_sku` (`user_id`, `spu_id`, `sku_id`, `deleted`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='购物车';

-- ----------------------------
-- 交易中心配置
-- ----------------------------
CREATE TABLE `trade_config` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '自增主键',

  `after_sale_refund_reasons` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '售后的退款理由，JSON 格式',
  `after_sale_return_reasons` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '售后的退货理由，JSON 格式',

  `delivery_express_free_enabled` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否启用全场包邮',
  `delivery_express_free_price` int NOT NULL DEFAULT '0' COMMENT '全场包邮的最小金额，单位：分',
  `delivery_pick_up_enabled` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否开启自提',

  `brokerage_enabled` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否启用分佣',
  `brokerage_enabled_condition` int NOT NULL DEFAULT '0' COMMENT '分佣模式',
  `brokerage_bind_mode` int NOT NULL DEFAULT '0' COMMENT '分销关系绑定模式',
  `brokerage_poster_urls` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '分销海报图地址数组，JSON 格式',
  `brokerage_first_percent` int NOT NULL DEFAULT '0' COMMENT '一级返佣比例',
  `brokerage_second_percent` int NOT NULL DEFAULT '0' COMMENT '二级返佣比例',
  `brokerage_withdraw_min_price` int NOT NULL DEFAULT '0' COMMENT '用户提现最低金额',
  `brokerage_withdraw_fee_percent` int NOT NULL DEFAULT '0' COMMENT '用户提现手续费百分比',
  `brokerage_frozen_days` int NOT NULL DEFAULT '0' COMMENT '佣金冻结时间(天)',
  `brokerage_withdraw_types` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '提现方式，JSON 格式',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='交易中心配置';

-- ----------------------------
-- 快递公司
-- ----------------------------
CREATE TABLE `trade_delivery_express` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号，自增',
  `code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '快递公司 code',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '快递公司名称',
  `logo` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '快递公司 logo',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序',
  `status` int NOT NULL DEFAULT '0' COMMENT '状态',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`, `deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='快递公司';

-- ----------------------------
-- 快递运费模板
-- ----------------------------
CREATE TABLE `trade_delivery_express_template` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号，自增',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '模板名称',
  `charge_mode` int NOT NULL DEFAULT '0' COMMENT '配送计费方式',
  `sort` int NOT NULL DEFAULT '0' COMMENT '排序',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='快递运费模板';

-- ----------------------------
-- 快递运费模板计费配置
-- ----------------------------
CREATE TABLE `trade_delivery_express_template_charge` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号，自增',
  `template_id` bigint NOT NULL DEFAULT '0' COMMENT '配送模板编号',
  `area_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '配送区域编号列表，JSON 格式',
  `charge_mode` int NOT NULL DEFAULT '0' COMMENT '配送计费方式',
  `start_count` decimal(10,3) NOT NULL DEFAULT '0.000' COMMENT '首件数量',
  `start_price` int NOT NULL DEFAULT '0' COMMENT '起步价，单位：分',
  `extra_count` decimal(10,3) NOT NULL DEFAULT '0.000' COMMENT '续件数量',
  `extra_price` int NOT NULL DEFAULT '0' COMMENT '额外价，单位：分',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_template_id` (`template_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='快递运费模板计费配置';

-- ----------------------------
-- 快递运费模板包邮配置
-- ----------------------------
CREATE TABLE `trade_delivery_express_template_free` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `template_id` bigint NOT NULL DEFAULT '0' COMMENT '配送模板编号',
  `area_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '配送区域编号列表，JSON 格式',
  `free_price` int NOT NULL DEFAULT '0' COMMENT '包邮金额，单位：分',
  `free_count` int NOT NULL DEFAULT '0' COMMENT '包邮件数',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_template_id` (`template_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='快递运费模板包邮配置';

-- ----------------------------
-- 自提门店
-- ----------------------------
CREATE TABLE `trade_delivery_pick_up_store` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '门店名称',
  `introduction` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '门店简介',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '门店手机',
  `area_id` int NOT NULL DEFAULT '0' COMMENT '区域编号',
  `detail_address` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '门店详细地址',
  `logo` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '门店 logo',
  `opening_time` time NULL DEFAULT NULL COMMENT '营业开始时间',
  `closing_time` time NULL DEFAULT NULL COMMENT '营业结束时间',
  `latitude` double NOT NULL DEFAULT '0' COMMENT '纬度',
  `longitude` double NOT NULL DEFAULT '0' COMMENT '经度',
  `verify_user_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '核销员工用户编号数组，JSON 格式',
  `status` int NOT NULL DEFAULT '0' COMMENT '门店状态',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='自提门店';

-- ----------------------------
-- 交易订单
-- ----------------------------
CREATE TABLE `trade_order` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '订单编号，主键自增',
  `no` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '订单流水号',
  `type` int NOT NULL DEFAULT '0' COMMENT '订单类型',
  `terminal` int NOT NULL DEFAULT '0' COMMENT '订单来源',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `user_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '用户 IP',
  `user_remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '用户备注',
  `status` int NOT NULL DEFAULT '0' COMMENT '订单状态',
  `product_count` int NOT NULL DEFAULT '0' COMMENT '购买的商品数量',
  `finish_time` datetime NULL DEFAULT NULL COMMENT '订单完成时间',
  `cancel_time` datetime NULL DEFAULT NULL COMMENT '订单取消时间',
  `cancel_type` int NOT NULL DEFAULT '0' COMMENT '取消类型',
  `remark` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商家备注',
  `comment_status` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否评价',
  `brokerage_user_id` bigint NOT NULL DEFAULT '0' COMMENT '推广人编号',

  `pay_order_id` bigint NOT NULL DEFAULT '0' COMMENT '支付订单编号',
  `pay_status` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否已支付',
  `pay_time` datetime NULL DEFAULT NULL COMMENT '付款时间',
  `pay_channel_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '支付渠道',

  `total_price` int NOT NULL DEFAULT '0' COMMENT '商品原价，单位：分',
  `discount_price` int NOT NULL DEFAULT '0' COMMENT '优惠金额，单位：分',
  `delivery_price` int NOT NULL DEFAULT '0' COMMENT '运费金额，单位：分',
  `adjust_price` int NOT NULL DEFAULT '0' COMMENT '订单调价，单位：分',
  `pay_price` int NOT NULL DEFAULT '0' COMMENT '应付金额（总），单位：分',

  `delivery_type` int NOT NULL DEFAULT '0' COMMENT '配送方式',
  `logistics_id` bigint NOT NULL DEFAULT '0' COMMENT '发货物流公司编号',
  `logistics_no` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '发货物流单号',
  `delivery_time` datetime NULL DEFAULT NULL COMMENT '发货时间',
  `receive_time` datetime NULL DEFAULT NULL COMMENT '收货时间',
  `receiver_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '收件人名称',
  `receiver_mobile` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '收件人手机',
  `receiver_area_id` int NOT NULL DEFAULT '0' COMMENT '收件人地区编号',
  `receiver_detail_address` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '收件人详细地址',

  `pick_up_store_id` bigint NOT NULL DEFAULT '0' COMMENT '自提门店编号',
  `pick_up_verify_code` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '自提核销码',

  `refund_status` int NOT NULL DEFAULT '0' COMMENT '售后状态',
  `refund_price` int NOT NULL DEFAULT '0' COMMENT '退款金额，单位：分',

  `coupon_id` bigint NOT NULL DEFAULT '0' COMMENT '优惠劵编号',
  `coupon_price` int NOT NULL DEFAULT '0' COMMENT '优惠劵减免金额，单位：分',
  `use_point` int NOT NULL DEFAULT '0' COMMENT '使用的积分',
  `point_price` int NOT NULL DEFAULT '0' COMMENT '积分抵扣的金额，单位：分',
  `give_point` int NOT NULL DEFAULT '0' COMMENT '赠送的积分',
  `refund_point` int NOT NULL DEFAULT '0' COMMENT '退还的使用的积分',
  `vip_price` int NOT NULL DEFAULT '0' COMMENT 'VIP 减免金额，单位：分',
  `give_coupon_template_counts` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '赠送的优惠劵，JSON 格式',
  `give_coupon_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '赠送的优惠劵编号，JSON 格式',

  `seckill_activity_id` bigint NOT NULL DEFAULT '0' COMMENT '秒杀活动编号',
  `bargain_activity_id` bigint NOT NULL DEFAULT '0' COMMENT '砍价活动编号',
  `bargain_record_id` bigint NOT NULL DEFAULT '0' COMMENT '砍价记录编号',
  `combination_activity_id` bigint NOT NULL DEFAULT '0' COMMENT '拼团活动编号',
  `combination_head_id` bigint NOT NULL DEFAULT '0' COMMENT '拼团团长编号',
  `combination_record_id` bigint NOT NULL DEFAULT '0' COMMENT '拼团记录编号',
  `point_activity_id` bigint NOT NULL DEFAULT '0' COMMENT '积分商城活动的编号',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_no` (`no`, `deleted`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_pay_status` (`pay_status`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='交易订单';

-- ----------------------------
-- 交易订单项
-- ----------------------------
CREATE TABLE `trade_order_item` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `order_id` bigint NOT NULL DEFAULT '0' COMMENT '订单编号',
  `cart_id` bigint NOT NULL DEFAULT '0' COMMENT '购物车项编号',

  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SPU 编号',
  `spu_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商品 SPU 名称',
  `sku_id` bigint NOT NULL DEFAULT '0' COMMENT '商品 SKU 编号',
  `properties` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '属性数组，JSON 格式',
  `pic_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商品图片',
  `count` int NOT NULL DEFAULT '0' COMMENT '购买数量',
  `comment_status` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否评价',

  `price` int NOT NULL DEFAULT '0' COMMENT '商品原价（单），单位：分',
  `discount_price` int NOT NULL DEFAULT '0' COMMENT '优惠金额（总），单位：分',
  `delivery_price` int NOT NULL DEFAULT '0' COMMENT '运费金额（总），单位：分',
  `adjust_price` int NOT NULL DEFAULT '0' COMMENT '订单调价（总），单位：分',
  `pay_price` int NOT NULL DEFAULT '0' COMMENT '应付金额（总），单位：分',

  `coupon_price` int NOT NULL DEFAULT '0' COMMENT '优惠劵减免金额，单位：分',
  `point_price` int NOT NULL DEFAULT '0' COMMENT '积分抵扣的金额，单位：分',
  `use_point` int NOT NULL DEFAULT '0' COMMENT '使用的积分',
  `give_point` int NOT NULL DEFAULT '0' COMMENT '赠送的积分',
  `vip_price` int NOT NULL DEFAULT '0' COMMENT 'VIP 减免金额，单位：分',

  `after_sale_id` bigint NOT NULL DEFAULT '0' COMMENT '售后单编号',
  `after_sale_status` int NOT NULL DEFAULT '0' COMMENT '售后状态',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_after_sale_id` (`after_sale_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='交易订单项';

-- ----------------------------
-- 订单日志
-- ----------------------------
CREATE TABLE `trade_order_log` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `user_type` int NOT NULL DEFAULT '0' COMMENT '用户类型',
  `order_id` bigint NOT NULL DEFAULT '0' COMMENT '订单号',
  `before_status` int NOT NULL DEFAULT '0' COMMENT '操作前状态',
  `after_status` int NOT NULL DEFAULT '0' COMMENT '操作后状态',
  `operate_type` int NOT NULL DEFAULT '0' COMMENT '操作类型',
  `content` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '订单日志信息',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单日志';



-- ----------------------------
-- 删除 member 模块相关表（按逻辑倒序）
-- ----------------------------
DROP TABLE IF EXISTS `member_sign_in_record`;
DROP TABLE IF EXISTS `member_sign_in_config`;
DROP TABLE IF EXISTS `member_point_record`;
DROP TABLE IF EXISTS `member_level_record`;
DROP TABLE IF EXISTS `member_level`;
DROP TABLE IF EXISTS `member_experience_record`;
DROP TABLE IF EXISTS `member_group`;
DROP TABLE IF EXISTS `member_config`;
DROP TABLE IF EXISTS `member_address`;
DROP TABLE IF EXISTS `member_tag`;
DROP TABLE IF EXISTS `member_user`;

-- ----------------------------
-- 会员用户
-- ----------------------------
CREATE TABLE `member_user` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `mobile` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '手机',
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '加密后的密码',
  `status` int NOT NULL DEFAULT '0' COMMENT '帐号状态',
  `register_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '注册 IP',
  `register_terminal` int NOT NULL DEFAULT '0' COMMENT '注册终端',
  `login_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '最后登录IP',
  `login_date` datetime NULL DEFAULT NULL COMMENT '最后登录时间',

  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '用户昵称',
  `avatar` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '用户头像',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '真实名字',
  `sex` int NOT NULL DEFAULT '0' COMMENT '性别',
  `birthday` datetime NULL DEFAULT NULL COMMENT '出生日期',
  `area_id` int NOT NULL DEFAULT '0' COMMENT '所在地',
  `mark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '用户备注',

  `point` int NOT NULL DEFAULT '0' COMMENT '积分',
  `tag_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '会员标签列表，JSON 格式',
  `level_id` bigint NOT NULL DEFAULT '0' COMMENT '会员级别编号',
  `experience` int NOT NULL DEFAULT '0' COMMENT '会员经验',
  `group_id` bigint NOT NULL DEFAULT '0' COMMENT '用户分组编号',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_mobile` (`mobile`, `deleted`),
  KEY `idx_status` (`status`),
  KEY `idx_group_id` (`group_id`),
  KEY `idx_level_id` (`level_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会员用户';

-- ----------------------------
-- 会员标签
-- ----------------------------
CREATE TABLE `member_tag` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '标签名称',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会员标签';

-- ----------------------------
-- 用户收件地址
-- ----------------------------
CREATE TABLE `member_address` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '收件人名称',
  `mobile` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '手机号',
  `area_id` bigint NOT NULL DEFAULT '0' COMMENT '地区编号',
  `detail_address` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '收件详细地址',
  `default_status` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否默认',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户收件地址';

-- ----------------------------
-- 会员配置
-- ----------------------------
CREATE TABLE `member_config` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `point_trade_deduct_enable` bit(1) NOT NULL DEFAULT b'0' COMMENT '积分抵扣开关',
  `point_trade_deduct_unit_price` int NOT NULL DEFAULT '0' COMMENT '积分抵扣，单位：分',
  `point_trade_deduct_max_price` int NOT NULL DEFAULT '0' COMMENT '积分抵扣最大值',
  `point_trade_give_point` int NOT NULL DEFAULT '0' COMMENT '1 元赠送多少分',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会员配置';

-- ----------------------------
-- 用户分组
-- ----------------------------
CREATE TABLE `member_group` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '名称',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '备注',
  `status` int NOT NULL DEFAULT '0' COMMENT '状态',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户分组';

-- ----------------------------
-- 会员经验记录
-- ----------------------------
CREATE TABLE `member_experience_record` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `biz_type` int NOT NULL DEFAULT '0' COMMENT '业务类型',
  `biz_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '业务编号',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '标题',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '描述',
  `experience` int NOT NULL DEFAULT '0' COMMENT '经验',
  `total_experience` int NOT NULL DEFAULT '0' COMMENT '变更后的经验',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_biz_id` (`biz_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会员经验记录';

-- ----------------------------
-- 会员等级
-- ----------------------------
CREATE TABLE `member_level` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '等级名称',
  `level` int NOT NULL DEFAULT '0' COMMENT '等级',
  `experience` int NOT NULL DEFAULT '0' COMMENT '升级经验',
  `discount_percent` int NOT NULL DEFAULT '100' COMMENT '享受折扣（100 = 100%）',
  `icon` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '等级图标',
  `background_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '等级背景图',
  `status` int NOT NULL DEFAULT '0' COMMENT '状态',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_level` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会员等级';

-- ----------------------------
-- 会员等级记录
-- ----------------------------
CREATE TABLE `member_level_record` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `level_id` bigint NOT NULL DEFAULT '0' COMMENT '等级编号',
  `level` int NOT NULL DEFAULT '0' COMMENT '会员等级',
  `discount_percent` int NOT NULL DEFAULT '100' COMMENT '享受折扣',
  `experience` int NOT NULL DEFAULT '0' COMMENT '升级经验',
  `user_experience` int NOT NULL DEFAULT '0' COMMENT '会员此时的经验',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '备注',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '描述',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会员等级记录';

-- ----------------------------
-- 用户积分记录
-- ----------------------------
CREATE TABLE `member_point_record` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `biz_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '业务编码',
  `biz_type` int NOT NULL DEFAULT '0' COMMENT '业务类型',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '积分标题',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '积分描述',
  `point` int NOT NULL DEFAULT '0' COMMENT '变动积分',
  `total_point` int NOT NULL DEFAULT '0' COMMENT '变动后的积分',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_biz_id` (`biz_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户积分记录';

-- ----------------------------
-- 签到规则
-- ----------------------------
CREATE TABLE `member_sign_in_config` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '规则自增主键',
  `day` int NOT NULL DEFAULT '0' COMMENT '签到第 x 天',
  `point` int NOT NULL DEFAULT '0' COMMENT '奖励积分',
  `experience` int NOT NULL DEFAULT '0' COMMENT '奖励经验',
  `status` int NOT NULL DEFAULT '0' COMMENT '状态',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_day` (`day`, `deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='签到规则';

-- ----------------------------
-- 签到记录
-- ----------------------------
CREATE TABLE `member_sign_in_record` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '签到用户',
  `day` int NOT NULL DEFAULT '0' COMMENT '第几天签到',
  `point` int NOT NULL DEFAULT '0' COMMENT '签到的积分',
  `experience` int NOT NULL DEFAULT '0' COMMENT '签到的经验',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='签到记录';


-- ----------------------------
-- 删除 pay 模块相关表（按依赖倒序）
-- ----------------------------
DROP TABLE IF EXISTS `pay_wallet_transaction`;
DROP TABLE IF EXISTS `pay_wallet_recharge`;
DROP TABLE IF EXISTS `pay_wallet_recharge_package`;
DROP TABLE IF EXISTS `pay_wallet`;
DROP TABLE IF EXISTS `pay_transfer`;
DROP TABLE IF EXISTS `pay_refund`;
DROP TABLE IF EXISTS `pay_order_extension`;
DROP TABLE IF EXISTS `pay_order`;
DROP TABLE IF EXISTS `pay_notify_log`;
DROP TABLE IF EXISTS `pay_notify_task`;
DROP TABLE IF EXISTS `pay_demo_withdraw`;
DROP TABLE IF EXISTS `pay_demo_order`;
DROP TABLE IF EXISTS `pay_channel`;
DROP TABLE IF EXISTS `pay_app`;

-- ----------------------------
-- 支付应用
-- ----------------------------
CREATE TABLE `pay_app` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '应用编号，数据库自增',
  `app_key` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '应用标识',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '应用名',
  `status` int NOT NULL DEFAULT '0' COMMENT '状态',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '备注',
  `order_notify_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '支付结果的回调地址',
  `refund_notify_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '退款结果的回调地址',
  `transfer_notify_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '转账结果的回调地址',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_app_key` (`app_key`, `deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付应用';

-- ----------------------------
-- 支付渠道
-- ----------------------------
CREATE TABLE `pay_channel` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '渠道编号，数据库自增',
  `code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '渠道编码',
  `status` int NOT NULL DEFAULT '0' COMMENT '状态',
  `fee_rate` double NOT NULL DEFAULT '0.0' COMMENT '渠道费率，单位：百分比',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '备注',
  `app_id` bigint NOT NULL DEFAULT '0' COMMENT '应用编号',
  `config` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '支付渠道配置，JSON 格式',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_app_id` (`app_id`),
  KEY `idx_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付渠道';

-- ----------------------------
-- 示例订单
-- ----------------------------
CREATE TABLE `pay_demo_order` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '订单编号，自增',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `spu_id` bigint NOT NULL DEFAULT '0' COMMENT '商品编号',
  `spu_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商品名称',
  `price` int NOT NULL DEFAULT '0' COMMENT '价格，单位：分',
  `pay_status` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否支付',
  `pay_order_id` bigint NOT NULL DEFAULT '0' COMMENT '支付订单编号',
  `pay_time` datetime NULL DEFAULT NULL COMMENT '付款时间',
  `pay_channel_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '支付渠道',

  `pay_refund_id` bigint NOT NULL DEFAULT '0' COMMENT '支付退款单号',
  `refund_price` int NOT NULL DEFAULT '0' COMMENT '退款金额，单位：分',
  `refund_time` datetime NULL DEFAULT NULL COMMENT '退款完成时间',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='示例订单';

-- ----------------------------
-- 示例提现订单
-- ----------------------------
CREATE TABLE `pay_demo_withdraw` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '提现单编号，自增',
  `subject` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '提现标题',
  `price` int NOT NULL DEFAULT '0' COMMENT '提现金额，单位：分',
  `user_account` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '收款人账号',
  `user_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '收款人姓名',
  `type` int NOT NULL DEFAULT '0' COMMENT '提现方式',
  `status` int NOT NULL DEFAULT '0' COMMENT '提现状态',
  `pay_transfer_id` bigint NOT NULL DEFAULT '0' COMMENT '转账单编号',
  `transfer_channel_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '转账渠道',
  `transfer_time` datetime NULL DEFAULT NULL COMMENT '转账成功时间',
  `transfer_error_msg` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '转账错误提示',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='示例提现订单';

-- ----------------------------
-- 支付通知任务
-- ----------------------------
CREATE TABLE `pay_notify_task` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号，自增',
  `app_id` bigint NOT NULL DEFAULT '0' COMMENT '应用编号',
  `type` int NOT NULL DEFAULT '0' COMMENT '通知类型',
  `data_id` bigint NOT NULL DEFAULT '0' COMMENT '数据编号',
  `merchant_order_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商户订单编号',
  `merchant_refund_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商户退款编号',
  `merchant_transfer_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商户转账编号',
  `status` int NOT NULL DEFAULT '0' COMMENT '通知状态',
  `next_notify_time` datetime NULL DEFAULT NULL COMMENT '下一次通知时间',
  `last_execute_time` datetime NULL DEFAULT NULL COMMENT '最后一次执行时间',
  `notify_times` int NOT NULL DEFAULT '0' COMMENT '当前通知次数',
  `max_notify_times` int NOT NULL DEFAULT '0' COMMENT '最大可通知次数',
  `notify_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '通知地址',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_status_next_time` (`status`, `next_notify_time`),
  KEY `idx_app_id` (`app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付通知';

-- ----------------------------
-- 支付通知日志
-- ----------------------------
CREATE TABLE `pay_notify_log` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '日志编号，自增',
  `task_id` bigint NOT NULL DEFAULT '0' COMMENT '通知任务编号',
  `notify_times` int NOT NULL DEFAULT '0' COMMENT '第几次被通知',
  `response` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'HTTP 响应结果',
  `status` int NOT NULL DEFAULT '0' COMMENT '支付通知状态',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_task_id` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商户支付、退款等的通知 Log';

-- ----------------------------
-- 支付订单
-- ----------------------------
CREATE TABLE `pay_order` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '订单编号，数据库自增',
  `app_id` bigint NOT NULL DEFAULT '0' COMMENT '应用编号',
  `channel_id` bigint NOT NULL DEFAULT '0' COMMENT '渠道编号',
  `channel_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '渠道编码',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `user_type` int NOT NULL DEFAULT '0' COMMENT '用户类型',
  `merchant_order_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商户订单编号',
  `subject` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商品标题',
  `body` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商品描述信息',
  `notify_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '异步通知地址',
  `price` int NOT NULL DEFAULT '0' COMMENT '支付金额，单位：分',
  `channel_fee_rate` double NOT NULL DEFAULT '0.0' COMMENT '渠道手续费，单位：百分比',
  `channel_fee_price` int NOT NULL DEFAULT '0' COMMENT '渠道手续金额，单位：分',
  `status` int NOT NULL DEFAULT '0' COMMENT '支付状态',
  `user_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '用户 IP',
  `expire_time` datetime NULL DEFAULT NULL COMMENT '订单失效时间',
  `success_time` datetime NULL DEFAULT NULL COMMENT '订单支付成功时间',
  `extension_id` bigint NOT NULL DEFAULT '0' COMMENT '支付成功的订单拓展单编号',
  `no` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '支付成功的外部订单号',
  `refund_price` int NOT NULL DEFAULT '0' COMMENT '退款总金额，单位：分',
  `channel_user_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '渠道用户编号',
  `channel_order_no` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '渠道订单号',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_merchant_order_id` (`app_id`, `merchant_order_id`, `deleted`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_success_time` (`success_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付订单';

-- ----------------------------
-- 支付订单拓展
-- ----------------------------
CREATE TABLE `pay_order_extension` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '订单拓展编号，数据库自增',
  `no` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '外部订单号',
  `order_id` bigint NOT NULL DEFAULT '0' COMMENT '订单号',
  `channel_id` bigint NOT NULL DEFAULT '0' COMMENT '渠道编号',
  `channel_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '渠道编码',
  `user_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '用户 IP',
  `status` int NOT NULL DEFAULT '0' COMMENT '支付状态',
  `channel_extras` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '支付渠道的额外参数，JSON 格式',
  `channel_error_code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '调用渠道的错误码',
  `channel_error_msg` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '调用渠道报错时，错误信息',
  `channel_notify_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '支付渠道的同步/异步通知的内容',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_no` (`no`, `deleted`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付订单拓展';

-- ----------------------------
-- 支付退款单
-- ----------------------------
CREATE TABLE `pay_refund` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '退款单编号，数据库自增',
  `no` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '外部退款号',
  `app_id` bigint NOT NULL DEFAULT '0' COMMENT '应用编号',
  `channel_id` bigint NOT NULL DEFAULT '0' COMMENT '渠道编号',
  `channel_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '渠道编码',
  `order_id` bigint NOT NULL DEFAULT '0' COMMENT '订单编号',
  `order_no` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '支付订单编号',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `user_type` int NOT NULL DEFAULT '0' COMMENT '用户类型',
  `merchant_order_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商户订单编号',
  `merchant_refund_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商户退款订单号',
  `notify_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '异步通知地址',
  `status` int NOT NULL DEFAULT '0' COMMENT '退款状态',
  `pay_price` int NOT NULL DEFAULT '0' COMMENT '支付金额，单位：分',
  `refund_price` int NOT NULL DEFAULT '0' COMMENT '退款金额，单位：分',
  `reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '退款原因',
  `user_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '用户 IP',
  `channel_order_no` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '渠道订单号',
  `channel_refund_no` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '渠道退款单号',
  `success_time` datetime NULL DEFAULT NULL COMMENT '退款成功时间',
  `channel_error_code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '调用渠道的错误码',
  `channel_error_msg` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '调用渠道的错误提示',
  `channel_notify_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '支付渠道的同步/异步通知的内容',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_no` (`no`, `deleted`),
  UNIQUE KEY `uk_merchant_refund_id` (`app_id`, `merchant_refund_id`, `deleted`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付退款单';

-- ----------------------------
-- 转账单
-- ----------------------------
CREATE TABLE `pay_transfer` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `no` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '转账单号',
  `app_id` bigint NOT NULL DEFAULT '0' COMMENT '应用编号',
  `channel_id` bigint NOT NULL DEFAULT '0' COMMENT '转账渠道编号',
  `channel_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '转账渠道编码',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户编号',
  `user_type` int NOT NULL DEFAULT '0' COMMENT '用户类型',
  `merchant_transfer_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '商户转账单编号',
  `subject` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '转账标题',
  `price` int NOT NULL DEFAULT '0' COMMENT '转账金额，单位：分',
  `user_account` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '收款人账号',
  `user_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '收款人姓名',
  `status` int NOT NULL DEFAULT '0' COMMENT '转账状态',
  `success_time` datetime NULL DEFAULT NULL COMMENT '订单转账成功时间',
  `notify_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '异步通知地址',
  `user_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '用户 IP',
  `channel_extras` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '渠道的额外参数，JSON 格式',
  `channel_transfer_no` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '渠道转账单号',
  `channel_error_code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '调用渠道的错误码',
  `channel_error_msg` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '调用渠道的错误提示',
  `channel_notify_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '渠道的同步/异步通知的内容',
  `channel_package_info` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '渠道 package 信息',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_no` (`no`, `deleted`),
  UNIQUE KEY `uk_merchant_transfer_id` (`app_id`, `merchant_transfer_id`, `deleted`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='转账单';

-- ----------------------------
-- 会员钱包
-- ----------------------------
CREATE TABLE `pay_wallet` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT '用户 id',
  `user_type` int NOT NULL DEFAULT '0' COMMENT '用户类型',
  `balance` int NOT NULL DEFAULT '0' COMMENT '余额，单位分',
  `freeze_price` int NOT NULL DEFAULT '0' COMMENT '冻结金额，单位分',
  `total_expense` int NOT NULL DEFAULT '0' COMMENT '累计支出，单位分',
  `total_recharge` int NOT NULL DEFAULT '0' COMMENT '累计充值，单位分',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user` (`user_id`, `user_type`, `deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会员钱包';

-- ----------------------------
-- 会员钱包充值套餐
-- ----------------------------
CREATE TABLE `pay_wallet_recharge_package` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '套餐名',
  `pay_price` int NOT NULL DEFAULT '0' COMMENT '支付金额',
  `bonus_price` int NOT NULL DEFAULT '0' COMMENT '赠送金额',
  `status` int NOT NULL DEFAULT '0' COMMENT '状态',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会员钱包充值套餐';

-- ----------------------------
-- 会员钱包充值
-- ----------------------------
CREATE TABLE `pay_wallet_recharge` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `wallet_id` bigint NOT NULL DEFAULT '0' COMMENT '钱包编号',
  `total_price` int NOT NULL DEFAULT '0' COMMENT '用户实际到账余额',
  `pay_price` int NOT NULL DEFAULT '0' COMMENT '实际支付金额',
  `bonus_price` int NOT NULL DEFAULT '0' COMMENT '钱包赠送金额',
  `package_id` bigint NOT NULL DEFAULT '0' COMMENT '充值套餐编号',
  `pay_status` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否已支付',
  `pay_order_id` bigint NOT NULL DEFAULT '0' COMMENT '支付订单编号',
  `pay_channel_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '支付成功的支付渠道',
  `pay_time` datetime NULL DEFAULT NULL COMMENT '订单支付时间',
  `pay_refund_id` bigint NOT NULL DEFAULT '0' COMMENT '支付退款单编号',
  `refund_total_price` int NOT NULL DEFAULT '0' COMMENT '退款金额，包含赠送金额',
  `refund_pay_price` int NOT NULL DEFAULT '0' COMMENT '退款支付金额',
  `refund_bonus_price` int NOT NULL DEFAULT '0' COMMENT '退款钱包赠送金额',
  `refund_time` datetime NULL DEFAULT NULL COMMENT '退款时间',
  `refund_status` int NOT NULL DEFAULT '0' COMMENT '退款状态',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  KEY `idx_wallet_id` (`wallet_id`),
  KEY `idx_pay_order_id` (`pay_order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会员钱包充值';

-- ----------------------------
-- 会员钱包流水
-- ----------------------------
CREATE TABLE `pay_wallet_transaction` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '编号',
  `no` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '流水号',
  `wallet_id` bigint NOT NULL DEFAULT '0' COMMENT '钱包编号',
  `biz_type` int NOT NULL DEFAULT '0' COMMENT '关联业务分类',
  `biz_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '关联业务编号',
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '流水说明',
  `price` int NOT NULL DEFAULT '0' COMMENT '交易金额，单位分',
  `balance` int NOT NULL DEFAULT '0' COMMENT '交易后余额，单位分',

  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_no` (`no`, `deleted`),
  KEY `idx_wallet_id` (`wallet_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会员钱包流水';