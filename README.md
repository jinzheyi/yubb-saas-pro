<p align="center">
 <img src="https://img.shields.io/badge/Spring%20Boot-2.7.18-blue.svg" alt="Spring Boot">
 <img src="https://img.shields.io/badge/Vue-3.5-brightgreen.svg" alt="Vue">
 <img src="https://img.shields.io/badge/JDK-8-orange.svg" alt="JDK">
 <img src="https://img.shields.io/badge/MySQL-8.0-blue.svg" alt="MySQL">
 <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
</p>

<h1 align="center">圣钰 SaaS Pro - 企业级多租户管理系统</h1>

<p align="center">
  <b>基于 Spring Boot + Vue 3 的现代化 SaaS 平台解决方案</b>
</p>

如果这个项目让你有所收获，记得 Star 关注哦，这对我是非常不错的鼓励与支持。

---

## 📖 项目简介

圣钰 SaaS Pro 是一个功能完善的企业级多租户管理系统，基于芋道开源系统进行深度定制开发（已获作者授权）。系统采用前后端分离架构，支持平台端和租户端双端管理，内置完整的权限管理、工作流引擎、即时通讯等企业级功能。

### 核心特性

- 🎯 **多租户架构**：完善的租户隔离机制，支持租户独立配置
- 🔐 **权限管理**：基于 RBAC 的细粒度权限控制，支持数据权限
- 📱 **多端支持**：Web 端（Vue3）+ 移动端（uni-app x）全覆盖
- 💬 **即时通讯**：基于 Netty + Protobuf 的高性能 IM 系统
- 🔄 **工作流引擎**：集成 FlowLong 工作流，支持可视化流程设计
- 🔌 **插件市场**：灵活的插件体系架构，支持功能扩展
- 🎨 **低代码支持**：表单设计器、代码生成器、报表设计器

## 🎯 系统架构

![圣钰SaaS系统架构图](%E5%9C%A3%E9%92%B0SaaS%E6%9E%B6%E6%9E%84%E5%9B%BE.png)

### 技术栈

**后端技术**
- Spring Boot 2.7.18
- MyBatis-Plus（ORM 框架）
- Spring Security + OAuth2（认证授权）
- Redis（缓存）
- MySQL 8.0（数据库）
- Netty（即时通讯）
- Protobuf（消息协议）
- FlowLong（工作流引擎）
- XXL-Job（定时任务）

**前端技术**
- Vue 3.5 + TypeScript
- Vite 5.1（构建工具）
- Element Plus 2.11（UI 组件库）
- Pinia（状态管理）
- Axios（HTTP 客户端）
- ECharts（数据可视化）
- BPMN.js（流程设计器）

**移动端技术**
- uni-app x（跨平台框架）
- uni-ui（组件库）

## 🚀 快速开始

### 环境要求

- JDK 8+
- Maven 3.6+
- MySQL 8.0+
- Redis 6.0+
- Node.js 16+
- pnpm 8.6+

### 本地开发

1. **克隆项目**
```bash
git clone https://gitee.com/jinzheyi/yubb-saas-pro.git
cd yubb-saas-pro
```

2. **初始化数据库**
```bash
# 导入数据库脚本
mysql -u root -p < sql/mysql/1.0/shengyu-saas.sql
```

3. **启动后端服务**
```bash
# 修改配置文件 shengyu-server/src/main/resources/application-local.yaml
# 配置数据库和 Redis 连接信息

# 编译并启动
mvn clean install
cd shengyu-server
mvn spring-boot:run
```

4. **启动前端项目**

租户端：
```bash
cd shengyu-ui/shengyu-ui-admin-vue3
pnpm install
pnpm front
```

平台端：
```bash
cd shengyu-ui/shengyu-ui-platform-vue3
pnpm install
pnpm front
```

### Docker 部署

```bash
# 使用 Docker Compose 一键启动
docker-compose up -d
```

访问地址：
- 租户端：http://localhost:8080
- 平台端：http://localhost:8081
- 后端接口：http://localhost:48080

## 🌐 在线体验

### 官网地址
[http://shengyukj.top/](http://shengyukj.top/)

官网提供完整的系统文档和使用指南

### 演示环境

**平台端**
- 地址：[http://saasadmin.shengyukj.top](http://saasadmin.shengyukj.top)
- 账号：test / 123456

**租户端**
- 地址：[http://saas.shengyukj.top](http://saas.shengyukj.top)
- 账号：jin_zheyicn@qq.com / shengyukj578503

## 📋 功能模块

### 平台端功能

- **租户管理**：租户创建、配置、套餐管理
- **用户管理**：平台用户管理、权限分配
- **系统配置**：字典管理、参数配置、菜单管理
- **基础设施**：文件管理、代码生成、接口文档、系统监控
- **日志中心**：操作日志、登录日志、访问日志、错误日志
- **消息管理**：短信管理、邮件管理、站内信

### 租户端功能

- **组织架构**：部门管理、岗位管理、用户管理
- **权限管理**：角色管理、菜单管理、数据权限
- **工作流**：流程设计、流程分类、表单设计、任务管理
- **即时通讯**：单聊、群聊、消息推送（支持 50w+ 并发连接）
- **插件市场**：插件浏览、安装、配置
- **业务功能**：根据租户需求定制

### 移动端功能（uni-app x）

- 企业通讯录
- 即时消息
- 工作台
- 个人中心
- 多语言支持（中文/英文）

## 📁 项目结构

```
yubb-saas-pro/
├── shengyu-dependencies/          # 依赖版本管理
├── shengyu-framework/             # 框架核心组件
│   ├── shengyu-common/           # 通用工具类
│   ├── shengyu-spring-boot-starter-web/        # Web 核心配置
│   ├── shengyu-spring-boot-starter-security/   # 安全认证
│   ├── shengyu-spring-boot-starter-mybatis/    # 数据库持久层
│   ├── shengyu-spring-boot-starter-redis/      # Redis 缓存
│   ├── shengyu-spring-boot-starter-websocket/  # 即时通讯
│   ├── shengyu-spring-boot-starter-flowlong/   # 工作流引擎
│   └── ...                       # 其他组件
├── shengyu-module-system/         # 租户端业务模块
│   ├── shengyu-module-system-api/ # 对外 API
│   └── shengyu-module-system-biz/ # 业务实现
├── shengyu-module-platform/       # 平台端业务模块
│   ├── shengyu-module-platform-api/
│   └── shengyu-module-platform-biz/
├── shengyu-module-infra/          # 基础设施模块
│   ├── shengyu-module-infra-api/
│   └── shengyu-module-infra-biz/
├── shengyu-server/                # 服务启动模块
├── shengyu-ui/                    # 前端项目
│   ├── shengyu-ui-admin-vue3/    # 租户端前端
│   ├── shengyu-ui-platform-vue3/ # 平台端前端
│   └── shengyu-ui-admin-uniappx/ # 移动端
└── sql/                           # 数据库脚本
```

## 🎨 系统截图

详见项目 `shengyu-ui/shengyu-ui-platform-vue3/.image/` 目录

## 📊 版本说明

### 📓 登记开源版

获取方式：
- 在 Gitee/GitHub 平台为项目点赞
- 在登记平台进行使用登记（仅用于宣传，不会骚扰用户）

### 💎 商用 Pro 版

获取方式：付费购买

| 功能项 | 功能描述 | 登记开源版 | 商用 Pro 版 | 备注 |
|--------|---------|-----------|------------|------|
| 平台端 | 平台端相关业务功能 | ✅ | ✅ | |
| 租户端 | 租户端相关业务功能 | ✅ | ✅ | |
| 商用授权 | 是否允许商用 | ✅ | ✅ | |
| 申请软著 | 二开后是否可申请软著 | ✅ | ✅ | |
| 插件市场 | 集成插件体系架构 | ✅ | ✅ | |
| 租户切换 | 钉钉/企业微信模式动态切换 | ✅ | ✅ | |
| 二次授权 | 二开后可否再授权给客户 | ❌ | ✅ | 登记版仅限自用 |
| 官网插件 | 官网新插件免费集成 | ❌ | ✅ | |
| 需求定制 | 合理需求开发支持 | ❌ | ✅ | |
| 技术支持 | 二次开发问题协助 | ❌ | ✅ | 购买后半年内 |
| 升级协助 | 版本升级技术支持 | ❌ | ✅ | 购买后半年内 |
| VIP 群 | 专属技术交流群 | ❌ | ✅ | |

## 🎯 规划路线

![规划脑图](%E8%A7%84%E5%88%92%E8%84%91%E5%9B%BE.png)

（规划持续更新中）

## 🔧 开发指南

### 后端开发规范

**包结构**
- 按功能模块组织代码，每个模块包含 `controller`、`service`、`mapper`、`dal` 等子包
- 业务逻辑在 `service` 层实现，`controller` 仅负责请求响应
- `mapper` 负责数据库操作，`dal` 定义实体类

**命名规范**
- 类名：大驼峰（如 `UserServiceImpl`）
- 方法名：小驼峰（如 `getUserById`）
- 表名/字段名：下划线命名（如 `user_info`, `create_time`）

**编码规范**
- 所有 public 方法必须有 Javadoc 注释
- 控制器方法需标注 `@Operation`（Swagger 注解）
- Service 层使用 `@Transactional` 管理事务
- 接口返回值统一使用 `CommonResult`
- 分页使用 `PageParam`，前端传 `pageNo` / `pageSize`

**数据库规范**
- 所有租户业务表必须包含以下字段：
```sql
`id` bigint NOT NULL AUTO_INCREMENT COMMENT 'ID',
`creator` varchar(64) NULL DEFAULT '' COMMENT '创建者',
`create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
`updater` varchar(64) NULL DEFAULT '' COMMENT '更新者',
`update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
`deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
`tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
```

### 前端开发规范

**技术栈**
- Vue 3 + TypeScript + Vite
- Element Plus（UI 组件库）
- Pinia（状态管理）
- Vue Router（路由管理）

**目录结构**
```
src/
├── api/          # API 接口
├── assets/       # 静态资源
├── components/   # 公共组件
├── layout/       # 布局组件
├── router/       # 路由配置
├── store/        # 状态管理
├── styles/       # 全局样式
├── utils/        # 工具函数
└── views/        # 页面组件
```

**编码规范**
- 组件名使用 PascalCase
- 使用 TypeScript 进行类型约束
- 使用 Composition API 编写组件
- 统一使用 `<script setup>` 语法

## 🔌 核心组件说明

### 即时通讯中间件（WebSocket）

基于 Netty + Protobuf 的高性能 IM 系统：
- 单机支持 50w+ TCP 连接
- 支持 WebSocket（Web/小程序）和 Protobuf（移动端）双协议
- 完善的多租户隔离机制
- SPI 接口设计，业务逻辑可扩展

详见：[shengyu-framework/shengyu-spring-boot-starter-websocket/README.md](shengyu-framework/shengyu-spring-boot-starter-websocket/README.md)

### 工作流引擎（FlowLong）

集成 FlowLong 工作流引擎：
- 可视化流程设计器
- 支持流程分类、表单设计
- 任务管理、流程实例管理
- 支持流程转办配置

### 插件市场

灵活的插件体系架构：
- 插件浏览、安装、配置
- 租户级别的插件管理
- 插件订单管理

## 📝 开发文档

详细的开发文档请访问：[http://shengyukj.top/](http://shengyukj.top/)

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 📄 开源协议

本项目采用 [MIT](LICENSE) 开源协议

## 💬 联系我们

- 官网：[http://shengyukj.top/](http://shengyukj.top/)
- Gitee：[https://gitee.com/jinzheyi/yubb-saas-pro](https://gitee.com/jinzheyi/yubb-saas-pro)
- GitHub：[https://github.com/jinzheyi/yubb-saas-pro](https://github.com/jinzheyi/yubb-saas-pro)

## ⭐ Star History

如果这个项目对你有帮助，请给我们一个 Star ⭐

---

**版本**：v2025.09-jdk8-SNAPSHOT  
**作者**：圣钰科技  
**更新时间**：2026年2月


