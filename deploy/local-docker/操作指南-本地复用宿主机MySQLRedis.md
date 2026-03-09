# 操作指南（本地复用宿主机 MySQL/Redis，不迁移数据）

适用场景：你本地 Mac 已经运行 MySQL/Redis（并且不想迁移数据），你希望 Docker 只负责启动：

- 后端 `shengyu-server`
- 文件预览 `kkFileView`
- 租户端 `admin-vue3`
- 平台端 `platform-vue3`

本目录使用的文件：

- `docker-compose.host.yml`：复用宿主机 MySQL/Redis 的 compose
- `docker.host.env`：本地数据库/Redis/端口配置（只改这个文件即可）

---

## 0. 前置确认（你已经确认了 MySQL）

- MySQL：库名/账号/密码 = `shengyu-saas / root / password`
- Redis：请确认是否有密码、使用哪个 database（默认按 `application-local.yaml`：`database=0` 且无密码）

如果你的 Redis 有密码或 database 不是 0，只改 `docker.host.env` 这两行：

- `REDIS_DATABASE=...`
- `REDIS_PASSWORD=...`

---

## 1. 打开终端并进入目录

在 IDE 的 Terminal 里，进入项目目录下的：

- `deploy/local-docker`

（你也可以在 Finder/IDE 里右键该目录，选择在终端打开）

---

## 2. 第一次启动前：构建后端 jar（必须做一次）

在“项目根目录”（也就是包含 `pom.xml` 的目录）执行：

```bash
docker volume create --name shengyu-maven-repo

docker run -it --rm --name shengyu-maven \
  -v shengyu-maven-repo:/root/.m2 \
  -v $PWD:/usr/src/mymaven \
  -w /usr/src/mymaven \
  maven mvn clean install package '-Dmaven.test.skip=true'
```

说明：

- 这是为了让 `shengyu-server` 的 Dockerfile 可以拿到已打包的产物。
- 后端代码有变更时，建议重新执行一次。

---

## 3. 启动（复用宿主机 MySQL/Redis）

在 `deploy/local-docker` 目录执行：

```bash
docker compose --env-file docker.host.env -f docker-compose.host.yml up -d
```

查看容器状态：

```bash
docker compose -f docker-compose.host.yml ps
```

---

## 4. 验证是否启动成功

在浏览器打开：

- 后端健康检查：`http://localhost:48080/actuator/health`
- 租户端：`http://localhost:8080/`
- 平台端：`http://localhost:8081/`
- kkFileView：`http://localhost:48090/onlinePreview`

---

## 5. 停止/重启/重建

停止（保留容器网络，清理容器）：

```bash
docker compose --env-file docker.host.env -f docker-compose.host.yml down
```

重启（常用）：

```bash
docker compose --env-file docker.host.env -f docker-compose.host.yml up -d
```

重新构建镜像并启动（前端/后端 Dockerfile 改了时用）：

```bash
docker compose --env-file docker.host.env -f docker-compose.host.yml up -d --build
```

---

## 6. 如果启动失败，如何把信息发给我

把下面两段命令输出复制粘贴给我：

### 6.1 查看状态

```bash
docker compose -f docker-compose.host.yml ps
```

### 6.2 查看后端日志（最关键）

```bash
docker logs shengyu-server-local --tail 200
```

如果是前端打不开，再补两条：

```bash
docker logs shengyu-admin-vue3-local --tail 200

docker logs shengyu-platform-vue3-local --tail 200
```
