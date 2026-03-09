# Docker Build & Up

目标: 快速部署体验系统，帮助了解系统之间的依赖关系。
依赖：Docker + docker compose v2。

## 功能文件列表

```text
.
├── Docker-HOWTO.md                 
├── docker-compose.yml              
├── docker.env                      <-- 提供docker-compose环境变量配置
├── shengyu-server
│   └── Dockerfile
└── shengyu-ui
    ├── shengyu-ui-admin-vue3        <-- 租户端（Vue3）
    └── shengyu-ui-platform-vue3     <-- 平台端（Vue3）
```

## 构建 jar 包

```shell
# 创建maven缓存volume
docker volume create --name shengyu-maven-repo

docker run -it --rm --name shengyu-maven \
    -v shengyu-maven-repo:/root/.m2 \
    -v $PWD:/usr/src/mymaven \
    -w /usr/src/mymaven \
    maven mvn clean install package '-Dmaven.test.skip=true'
```

## 构建启动服务

```shell
docker compose --env-file docker.env up -d
```

若生产仅希望容器化后端 + kkFileView（MySQL/Redis 继续使用宿主机已安装服务），也可以只启动：

```shell
docker compose --env-file docker.env up -d server kkfileview
```

并在 `docker.env` 中按注释将：

- `MASTER_DATASOURCE_URL` 改为 `host.docker.internal:3306`
- `REDIS_HOST` 改为 `host.docker.internal`
- `REDIS_DATABASE` 改为生产实际使用的库索引（你现网为 `1`）

## kkFileView（文件在线预览服务）

kkFileView 用于 Office/PDF 等文件的在线预览（服务端转换 + 浏览器渲染）。本项目已在 `docker-compose.yml` 中内置 `kkfileview` 服务。

### 可配置项（集中在 docker.env）

- `KKFILEVIEW_HOST_PORT`：宿主机端口（默认 `48090`）
- `KKFILEVIEW_JAVA_OPTS`：kkFileView JVM 参数（默认 `-Xms512m -Xmx1024m`）

### 本地验证

启动后，访问：

- `http://localhost:${KKFILEVIEW_HOST_PORT:-48090}/onlinePreview`

如果能看到 kkFileView 页面（或返回页面 HTML），说明服务可用。

---

## 阿里云 Linux 服务器部署（带域名，最小可用）

说明：下面步骤假设你已经有一台 Linux 服务器并已绑定域名解析。

### 1. 服务器准备

- 安装 Docker + Docker Compose v2
- 服务器安全组放行：
  - `48080`（后端 API，或后续由 Nginx 反代到 80/443）
  - `8080`（管理后台前端，或后续由 Nginx 反代到 80/443）
  - `48090`（kkFileView，或后续由 Nginx 反代）

说明（生产单机常见情况）：若你的服务器上已经通过宿主机方式运行了 MySQL/Redis（占用 3306/6379），则不建议在本 compose 中再对 MySQL/Redis 做宿主机端口映射，否则会端口冲突。

### 2. 启动

在项目根目录执行：

```shell
docker compose --env-file docker.env up -d
```

查看运行状态：

```shell
docker compose ps
```

### 3. 健康检查（必须做，确认 compose 仍有效）

- 后端：`http://<你的域名或服务器IP>:48080/actuator/health`
- 租户端（admin）：`http://<你的域名或服务器IP>:${ADMIN_HOST_PORT:-8080}/`
- 平台端（platform）：`http://<你的域名或服务器IP>:${PLATFORM_HOST_PORT:-8081}/`
- kkFileView：`http://<你的域名或服务器IP>:${KKFILEVIEW_HOST_PORT:-48090}/onlinePreview`

若三者都可访问，则说明当前 compose 在你的机器上是有效的。

### 4.（推荐）用 Nginx 统一域名入口（避免端口暴露/便于 HTTPS）

你现网 Nginx 域名规划（权威）：

- `saas.shengyukj.top`（租户端）静态目录 `/usr/www/app/saas/dist-admin`
- `saasadmin.shengyukj.top`（平台端）静态目录 `/usr/www/app/saas/dist-platform`
- `apisaas.shengyukj.top`（API）反代到 `127.0.0.1:48080`，并转发：
  - `/admin-api`
  - `/platform-api`

可选（文件预览域名建议）：

- `preview.shengyukj.top` -> 反代到 `127.0.0.1:${KKFILEVIEW_HOST_PORT:-48090}`

如需 HTTPS，可用 Certbot/阿里云证书，把 TLS 终止放在 Nginx。

首次运行会自动构建容器。可以通过`docker compose build [service]`来手动构建所有或某个docker镜像

`--env-file docker.env`为可选参数，只是展示了通过`.env`文件配置容器启动的环境变量，`docker-compose.yml`本身已经提供足够的默认参数来正常运行系统。

## 服务器的宿主机端口映射

- admin（租户端）ui: http://localhost:${ADMIN_HOST_PORT:-8080}
- platform（平台端）ui: http://localhost:${PLATFORM_HOST_PORT:-8081}
- api server: http://localhost:48080
- mysql: root/123456, port: 3306
- redis: port: 6379
