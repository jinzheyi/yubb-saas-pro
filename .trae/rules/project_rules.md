# 项目开发规范（Project Rules）

## 项目基本信息
- **项目名称**：Yubb SaaS Pro
- **Git 地址**：https://gitee.com/jinzheyi/yubb-saas-pro
- **技术栈**：
  - 后端：Spring Boot 2.x, JDK 8, MyBatis-Plus, Auth2（rbac权限控制）
  - 前端：Vue 3, TypeScript, Pinia, Element Plus, uni-appx（app端）, uni-ui（app端组件库）,uni-appx（app端组件库）
  - 数据库：MySQL 8.0
  - 构建工具：Maven（后端）、Vite（前端）

## 后端规范
### 包结构
- **包结构**：
  - 后端代码按功能模块组织，每个模块对应一个包。
  - 每个模块包含 `controller`、`service`、`mapper`、`entity` 等子包。
  - 所有业务逻辑都在 `service` 包中实现，`controller` 仅负责接收请求和返回响应。
  - `mapper` 包用于数据库操作，`entity` 包定义数据库表映射的 Java 类。


### 编码规范
- **命名**：
  - 类名：大驼峰（如 `UserServiceImpl`）
  - 方法名：小驼峰（如 `getUserById`）
  - 表名/字段名：下划线命名（如 `user_info`, `create_time`）
- **注释**：
  - 所有 public 方法必须有 Javadoc。
  - 控制器方法需标注 `@ApiOperation`（Swagger）。
- **事务**：在 Service 层使用 `@Transactional`。
- **分页**：使用 com.shengyu.framework.common.pojo.PageParam 进行分页，前端传 `pageNo` / `pageSize`。
- **开发规范**：
使用 Alibaba Java Code Style（IntelliJ IDEA 插件）。
- **接口规范**：
  - 所有接口必须有 Swagger 注解（`@Operation`）。例如参考com.shengyu.module.system.controller.admin.dept.PostController
  - 接口返回值必须是 com.shengyu.framework.common.pojo.CommonResult。
- **功能开发**：
  - 已经开发好的功能模块不要重复开发以及不要修改已有的功能模块。
  - 新增功能模块时，需要在 `project_rules.md` 中添加相关规范。

### 目录结构（src/）
./
├─Docker-HOWTO.md
├─docker.env
├─http-client.env.json
├─Jenkinsfile
├─LICENSE
├─lombok.config
├─README.md                        #项目说明
├─sql                              #sql文件
|  ├─mysql                         #mysql版本
|  |   ├─1.0
|  |   |  ├─quartz.sql
|  |   |  └shengyu-saas.sql
├─shengyu-ui                          #前端汇总
|     ├─shengyu-ui-platform-vue3      #平台端前端
|     ├─shengyu-ui-admin-vue3         #租户端前端
|     ├─shengyu-ui-admin-uniappx      #租户app端前端
├─shengyu-server                      #服务端启动模块
|       ├─Dockerfile
|       ├─src
|       |  ├─test
|       |  |  ├─java
|       |  |  |  ├─com
|       |  |  |  |  ├─shengyu         #改包工具类
|       |  ├─main
|       |  |  ├─resources
|       |  |  |     ├─application-dev.yaml                #开发环境
|       |  |  |     ├─application-local.yaml              #本地环境
|       |  |  |     └application.yaml                     #全局环境
|       |  |  ├─java
|       |  |  |  ├─com
|       |  |  |  |  ├─shengyu
|       |  |  |  |  |    ├─server
|       |  |  |  |  |    |   ├─controller
├─shengyu-module-system                                   #租户端模块
|           ├─shengyu-module-system-biz                   #租户端业务子模块
|           |             ├─src
|           |             |  ├─main
|           |             |  |  ├─java
|           |             |  |  |  ├─com
|           |             |  |  |  |  ├─shengyu
|           |             |  |  |  |  |    ├─module
|           |             |  |  |  |  |    |   ├─system
|           |             |  |  |  |  |    |   |   ├─util                    #工具包
|           |             |  |  |  |  |    |   |   ├─service                 #业务接口与实现
|           |             |  |  |  |  |    |   |   ├─job                     #定时任务
|           |             |  |  |  |  |    |   |   ├─framework               #核心配置
|           |             |  |  |  |  |    |   |   ├─dal                     #实体类
|           |             |  |  |  |  |    |   |   ├─convert                 #转换模块
|           |             |  |  |  |  |    |   |   ├─controller              #控制器
|           |             |  |  |  |  |    |   |   |     ├─app               #app端
|           |             |  |  |  |  |    |   |   |     ├─admin             #web端
|           |             |  |  |  |  |    |   |   ├─api                     #对外api接口实现
|           ├─shengyu-module-system-api                  #租户端对外api
├─shengyu-module-platform                                #平台端模块
|            ├─shengyu-module-platform-biz               #平台端业务子模块
|            |              ├─src
|            |              |  ├─main
|            |              |  |  ├─java
|            |              |  |  |  ├─com
|            |              |  |  |  |  ├─shengyu
|            |              |  |  |  |  |    ├─module
|            |              |  |  |  |  |    |   ├─platform
|            |              |  |  |  |  |    |   |    ├─util                 #工具包
|            |              |  |  |  |  |    |   |    ├─service              #业务接口与实现
|            |              |  |  |  |  |    |   |    ├─mq                   #mq
|            |              |  |  |  |  |    |   |    ├─framework            #核心配置
|            |              |  |  |  |  |    |   |    ├─dal                  #实体类
|            |              |  |  |  |  |    |   |    ├─convert              #转换模块
|            |              |  |  |  |  |    |   |    ├─controller           #控制器
|            |              |  |  |  |  |    |   |    |     ├─platform       #app端
|            |              |  |  |  |  |    |   |    |     ├─app            #web端
|            |              |  |  |  |  |    |   |    ├─api                  #对外api接口实现
|            ├─shengyu-module-platform-api              #平台端对外api
├─shengyu-module-infra                                  #基础模块
|          ├─shengyu-module-infra-biz                   #平台端基础模块：文件管理、监控管理、接口管理、代码生成等
|          ├─shengyu-module-infra-api                   #平台端基础模块对外api
├─shengyu-framework                                     #封装的核心组件
|         ├─shengyu-spring-boot-starter-websocket       #websocket
|         ├─shengyu-spring-boot-starter-web             #web核心配置
|         ├─shengyu-spring-boot-starter-test            #测试配置
|         ├─shengyu-spring-boot-starter-security        #权限核心模块
|         ├─shengyu-spring-boot-starter-redis           #redis核心模块
|         ├─shengyu-spring-boot-starter-protection
|         ├─shengyu-spring-boot-starter-mybatis         #orm持久层核心模块
|         ├─shengyu-spring-boot-starter-mq              #mq消息封装
|         ├─shengyu-spring-boot-starter-monitor         #监控   
|         ├─shengyu-spring-boot-starter-job             #定时任务核心
|         ├─shengyu-spring-boot-starter-file            #文件处理
|         ├─shengyu-spring-boot-starter-excel           #excel处理核心封装
|         ├─shengyu-spring-boot-starter-desensitize     #敏感次管理核心
|         ├─shengyu-spring-boot-starter-captcha         #验证码组件
|         ├─shengyu-spring-boot-starter-biz-tenant      #租户配置核心
|         ├─shengyu-spring-boot-starter-biz-sms         #短信核心
|         ├─shengyu-spring-boot-starter-biz-pay         #支付核心
|         ├─shengyu-spring-boot-starter-biz-operatelog  #日志处理
|         ├─shengyu-spring-boot-starter-biz-ip          #ip处理
|         ├─shengyu-spring-boot-starter-biz-error-code  #错误码封装
|         ├─shengyu-spring-boot-starter-biz-dict        #字典处理
|         ├─shengyu-spring-boot-starter-biz-data-permission  #数据权限核心
|         ├─shengyu-spring-boot-starter-banner          #启动banner
|         ├─shengyu-common                              #全局工具包
├─shengyu-dependencies                                  #依赖包版本管理
├─bin
|  └deploy.sh                       #部署脚本

### 数据库规范
- **数据库**：MySQL 8.0
- **数据库设计**：
  - 数据库表名采用下划线命名法（如 `user_info`）。
  - 所有租户业务的表必须包含以下字段：
  ```sql
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',