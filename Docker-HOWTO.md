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
前端镜像构建固定使用 `pnpm@9.15.9`，避免 Corepack 自动拉取与 Node 20 不兼容的最新版 pnpm。

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

阿里云生产单机建议不要直接改仓库里的 `docker.env` 写真实密码。可以在服务器复制生产模板：

```shell
cp deploy/aliyun/docker.prod.env.example docker.prod.env
vi docker.prod.env
docker compose --env-file docker.prod.env -f docker-compose.yml -f deploy/aliyun/docker-compose.prod-host.yml up -d server kkfileview admin-vue3 platform-vue3
```

该模板默认复用宿主机 MySQL/Redis，并把前端构建时的 API 域名指向 `apisaas.shengyukj.top`。

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
- `apisaas.shengyukj.top` 同时承载 `/admin-api`、`/platform-api`、`/app-api`，并将 IM WebSocket `/ws` 反代到 `127.0.0.1:9000`
- `im.shengyukj.top` -> 钰信 Flutter Web 页面，反代到 `127.0.0.1:8082`
- `rtc.shengyukj.top` -> LiveKit 信令反代到 `127.0.0.1:7880`；同时放行 `7881/tcp`、`7882/udp`、`3478/udp`、`41000-41040/udp`

如需 HTTPS，可用 Certbot/阿里云证书，把 TLS 终止放在 Nginx。阿里云 ECS 还需要在安全组入方向放行 `443/tcp`，否则 Nginx 本机监听正常但公网浏览器会一直超时。

低成本证书建议：

- 可自动化：使用 Let's Encrypt + Certbot，适合 Nginx 自建反代，证书约 90 天有效并可自动续期。
- 阿里云控制台：个人测试证书免费版每个实名认证主体每自然年有额度，但通常是单域名、约 90 天，ECS 自建 Nginx 仍需要下载/部署或购买部署服务。

HTTPS 切换后，前端和后端通信也要同步切换：

- App API：`https://apisaas.shengyukj.top/app-api`
- App IM WebSocket：`wss://apisaas.shengyukj.top/ws`
- LiveKit：`wss://rtc.shengyukj.top`
- 文件预览：`https://preview.shengyukj.top`

在 `443/tcp` 未放行前，不要强制把 HTTP 重定向到 HTTPS，否则现有 HTTP 入口会跳到不可达的 HTTPS。

首次运行会自动构建容器。可以通过`docker compose build [service]`来手动构建所有或某个docker镜像

`--env-file docker.env`为可选参数，只是展示了通过`.env`文件配置容器启动的环境变量，`docker-compose.yml`本身已经提供足够的默认参数来正常运行系统。

## 服务器的宿主机端口映射

- admin（租户端）ui: http://localhost:${ADMIN_HOST_PORT:-8080}
- platform（平台端）ui: http://localhost:${PLATFORM_HOST_PORT:-8081}
- api server: http://localhost:48080
- mysql: root/123456, port: 3306
- redis: port: 6379
