# Local Docker Deploy

目标：在本地（Mac Intel/Apple Silicon/Windows/Linux）用 Docker 一键启动：

- mysql
- redis
- shengyu-server
- kkfileview
- admin-vue3
- platform-vue3

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

## 2. 启动本地全套

在本目录执行：

```bash
docker compose --env-file docker.local.env -f docker-compose.local.yml up -d
```

查看状态：

```bash
docker compose -f docker-compose.local.yml ps
```

## 3. 健康检查

- 后端：`http://localhost:48080/actuator/health`
- 租户端：`http://localhost:8080/`
- 平台端：`http://localhost:8081/`
- kkFileView：`http://localhost:48090/onlinePreview`

## 4. 常用命令

停止并清理容器（不会删除 volume 数据）：

```bash
docker compose --env-file docker.local.env -f docker-compose.local.yml down
```

重新构建并启动：

```bash
docker compose --env-file docker.local.env -f docker-compose.local.yml up -d --build
```
