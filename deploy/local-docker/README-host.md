# Local Docker Deploy (Reuse Host MySQL/Redis)

目标：本地复用宿主机（Mac）已经运行的 MySQL/Redis，不迁移数据；Docker 仅启动：

- shengyu-server
- kkfileview
- admin-vue3
- platform-vue3

## 0. 前置条件（必须满足）

- 宿主机 MySQL 已启动，并可通过 `127.0.0.1:3306` 访问
- 宿主机 Redis 已启动，并可通过 `127.0.0.1:6379` 访问
- 你的本地库名/账号密码与 `docker.host.env` 一致（默认按 `application-local.yaml`）

说明：Docker 容器访问宿主机在 Mac 上可直接使用 `host.docker.internal`。

## 1. 先构建后端 jar

在项目根目录执行（只需首次/代码变更后执行）：

```bash
docker volume create --name shengyu-maven-repo

docker run -it --rm --name shengyu-maven \
  -v shengyu-maven-repo:/root/.m2 \
  -v $PWD:/usr/src/mymaven \
  -w /usr/src/mymaven \
  maven mvn clean install package '-Dmaven.test.skip=true'
```

## 2. 启动（复用宿主机 MySQL/Redis）

在本目录执行：

```bash
docker compose --env-file docker.host.env -f docker-compose.host.yml up -d
```

查看状态：

```bash
docker compose -f docker-compose.host.yml ps
```

## 3. 验证

- 后端：`http://localhost:48080/actuator/health`
- 租户端：`http://localhost:8080/`
- 平台端：`http://localhost:8081/`
- kkFileView：`http://localhost:48090/onlinePreview`

## 4. 常见问题

- MySQL/Redis 连接失败：先确认 `docker.host.env` 里的库名/账号/密码/redis 库索引与宿主机实际一致
- 端口冲突：如果你本地已经有服务占用 48080/8080/8081/48090，可在 `docker.host.env` 改对应 HOST_PORT
