# ShengYu SaaS 阿里云生产上线手册

本文是当前生产环境的最终上线记录和后续发布入口。下次代码变更需要上线时，直接引用本文件即可按现有环境完成构建、上传、部署、验证和回滚。

## 服务器现状

- SSH：使用本机别名 `aliyun-saas-prod` 连接生产服务器。
- 系统：Alibaba Cloud Linux 3。
- 部署根目录：`/opt/shengyu/saas-deploy`。
- LiveKit 目录：`/opt/shengyu/livekit`。
- 旧非容器部署目录：`/usr/www/app/saas`，仅作为历史回滚参考。
- MySQL：宿主机安装运行，容器不要重复部署 MySQL。
- Redis：宿主机安装运行，容器不要重复部署 Redis。
- Nginx：宿主机安装运行，负责公网域名、HTTPS、反向代理。
- Docker：后端、两个 Vue 前端、Flutter Web、kkFileView、LiveKit 均以容器方式运行。

## 域名与端口

- `saas.shengyukj.top`：租户管理 Vue 前端，Nginx 代理到 `127.0.0.1:8080`。
- `saasadmin.shengyukj.top`：平台管理 Vue 前端，Nginx 代理到 `127.0.0.1:8081`。
- `apisaas.shengyukj.top`：后端统一 API 和 IM WebSocket。
  - `/admin-api` -> `127.0.0.1:48080`
  - `/platform-api` -> `127.0.0.1:48080`
  - `/app-api` -> `127.0.0.1:48080`
  - `/ws` -> `127.0.0.1:9000`
- `im.shengyukj.top`：钰信 Flutter Web，Nginx 代理到 `127.0.0.1:8082`。
- `preview.shengyukj.top`：kkFileView，Nginx 代理到 `127.0.0.1:48090`。
- `rtc.shengyukj.top`：LiveKit signaling，Nginx 代理到 `127.0.0.1:7880`。
- LiveKit 直连端口：`7881/tcp`、`7882/udp`、`3478/udp`、`41000-41040/udp`。

## HTTPS

- 证书：Let’s Encrypt 多域名证书。
- 证书文件：
  - `/etc/letsencrypt/live/saas.shengyukj.top/fullchain.pem`
  - `/etc/letsencrypt/live/saas.shengyukj.top/privkey.pem`
- 当前证书覆盖：`saas.shengyukj.top`、`saasadmin.shengyukj.top`、`apisaas.shengyukj.top`、`preview.shengyukj.top`、`im.shengyukj.top`、`rtc.shengyukj.top`。
- `certbot-renew.timer` 已启用，用于自动续期。
- Nginx 已启用 HTTP 到 HTTPS 的 `301` 跳转。

## 运行容器

- `shengyu-server`：后端服务，宿主机端口 `48080`、`9000`。
- `shengyu-admin-vue3`：租户管理前端，宿主机端口 `8080`。
- `shengyu-platform-vue3`：平台管理前端，宿主机端口 `8081`。
- `shengyu-im-flutter-web`：钰信 Flutter Web，宿主机端口 `8082`。
- `shengyu-kkfileview`：文件预览，宿主机端口 `48090`。
- `shengyu-livekit`：LiveKit，宿主机端口 `7880`、`7881`、`7882/udp`、`3478/udp`、`41000-41040/udp`。

## 关键配置

- 后端生产环境变量：`/opt/shengyu/saas-deploy/docker.prod.env`，权限保持 `600`。
- LiveKit 生产环境变量：`/opt/shengyu/livekit/livekit.prod.env`，权限保持 `600`。
- 配置基准：后端行为先看 `shengyu-server/src/main/resources/application-local.yaml`，App/Flutter 域名先看 `shengyu-ui/shengyu-ui-admin-flutter/lib/app/config/app_config.dart`；上线前需要把对应变更同步到 `application-dev.yaml`、`deploy/aliyun/nginx/*.conf` 和生产环境变量文件。
- 后端 API：`https://apisaas.shengyukj.top/app-api`。
- IM WebSocket：`wss://apisaas.shengyukj.top/ws`。
- LiveKit URL：`wss://rtc.shengyukj.top`。
- kkFileView URL：`https://preview.shengyukj.top`。
- Flutter Web 浏览器入口：`https://im.shengyukj.top`。
- `im.shengyukj.top` 只作为 Flutter Web 页面域名，不作为 App API 域名。
- `apisaas.shengyukj.top` 的 Nginx 站点块必须配置 `client_max_body_size 200m;`，与后端 `spring.servlet.multipart.max-file-size=200MB` 保持一致，避免真机拍照图片上传被 Nginx 拦截为 `413`。
- `application-dev.yaml` 当前随生产容器加载，不能保留 natapp/yunai 这类临时回调域名；支付回调默认使用 `https://apisaas.shengyukj.top/admin-api/pay/notify/*`，特殊环境通过 `SHENGYU_PAY_*_NOTIFY_URL` 覆盖。
- `docker-compose.yml` 需要显式透传 `SHENGYU_CAPTCHA_ENABLE`、`SHENGYU_SECURITY_MOCK_ENABLE`、`SHENGYU_ACCESS_LOG_ENABLE`、`SHENGYU_PAY_*_NOTIFY_URL`，保证生产只改 `docker.prod.env` 也能覆盖 dev 配置。
- `im.shengyukj.top` 的公网 Nginx 只代理 Flutter Web 页面到 `127.0.0.1:8082`，API 和 WebSocket 必须走 `apisaas.shengyukj.top`，避免 App 页面域名和后端域名混用。

## 上线前检查

```bash
git status --short
rg -n "natapp|yunai|example\\.com|http://apisaas|ws://apisaas|im\\.shengyukj\\.top.*/app-api" \
  shengyu-server/src/main/resources/application-dev.yaml \
  shengyu-ui/shengyu-ui-admin-flutter/lib/app/config/app_config.dart \
  deploy/aliyun/nginx \
  docker-compose.yml \
  deploy/aliyun/docker.prod.env.example \
  deploy/aliyun/livekit.prod.env.example
mvn -pl shengyu-server -am clean package -DskipTests
```

如果改了前端：

```bash
cd shengyu-ui/shengyu-ui-admin-vue3
pnpm install
pnpm build:prod

cd ../shengyu-ui-platform-vue3
pnpm install
pnpm build:pro
```

如果改了 Flutter Web：

```bash
cd shengyu-ui/shengyu-ui-admin-flutter
flutter pub get
flutter build web --release \
  --dart-define=API_BASE_URL=https://apisaas.shengyukj.top/app-api \
  --dart-define=SOCKET_URL=wss://apisaas.shengyukj.top/ws \
  --dart-define=NETWORK_PROBE_URL=https://apisaas.shengyukj.top/app-api \
  --dart-define=NETWORK_PROBE_HOST=apisaas.shengyukj.top
```

Flutter Web 生产构建后确认：

- `web/index.html` 和 `build/web/index.html` 标题为 `钰信`。
- `build/web/main.dart.js` 不包含 `http://apisaas.shengyukj.top` 或 `ws://apisaas.shengyukj.top`。
- Web 端不要强依赖 Drift SQLite 磁盘缓存；浏览器端优先使用内存缓存，避免 `sqlite3.wasm` 兼容问题影响页面渲染。
- Flutter Web Nginx 配置中 `index.html`、`main.dart.js`、`flutter_bootstrap.js`、`flutter.js`、`flutter_service_worker.js` 不应长缓存。
- Flutter Web 应优先使用本地 `canvaskit/`，避免生产访问 Google gstatic 导致白屏或慢启动。

## 移动端打包

移动端同样以 `app_config.dart` 为域名基准，打包时显式传入线上域名，避免本地调试参数混入安装包。

Android APK：

```bash
cd shengyu-ui/shengyu-ui-admin-flutter
flutter pub get
flutter build apk --release \
  --dart-define=API_BASE_URL=https://apisaas.shengyukj.top/app-api \
  --dart-define=SOCKET_URL=wss://apisaas.shengyukj.top/ws \
  --dart-define=NETWORK_PROBE_URL=https://apisaas.shengyukj.top/app-api \
  --dart-define=NETWORK_PROBE_HOST=apisaas.shengyukj.top
```

iOS：

```bash
cd shengyu-ui/shengyu-ui-admin-flutter
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://apisaas.shengyukj.top/app-api \
  --dart-define=SOCKET_URL=wss://apisaas.shengyukj.top/ws \
  --dart-define=NETWORK_PROBE_URL=https://apisaas.shengyukj.top/app-api \
  --dart-define=NETWORK_PROBE_HOST=apisaas.shengyukj.top
```

- iOS 使用 Firebase 相关插件后，最低系统版本为 iOS 15.0。
- 真正可安装或分发的 IPA 必须使用 Apple 证书和 Provisioning Profile 签名；没有证书时只能执行 `flutter build ios --release --no-codesign` 生成未签名的 `Runner.app`。
- 当前 Flutter stable SDK 不支持 `flutter build hap`，仓库也没有 `ohos`/`harmony` 工程；鸿蒙包需要先接入鸿蒙 Flutter SDK 和 Harmony 工程后再打 HAP/APP。

## 部署步骤

在本机完成构建后，将产物上传到服务器并在 `/opt/shengyu/saas-deploy` 中重建镜像。当前服务器已具备 Compose 覆盖文件：

```bash
cd /opt/shengyu/saas-deploy
docker compose --env-file docker.prod.env \
  -f docker-compose.yml \
  -f docker-compose.prod-host.yml \
  up -d --build server admin-vue3 platform-vue3 im-flutter-web kkfileview
```

LiveKit 单独部署：

```bash
cd /opt/shengyu/livekit
docker compose --env-file livekit.prod.env \
  -f docker-compose.livekit-prod-host.yml \
  up -d livekit
```

如果变更了 Nginx：

```bash
nginx -t
systemctl reload nginx
```

## 数据库升级

- 增量 SQL 放在 `sql/mysql/1.0/prod_add.sql` 或后续版本对应增量文件。
- 执行生产 SQL 前必须备份数据库。
- 当前历史备份位置示例：`/opt/shengyu/backups/shengyu-saas-20260905230217-before-prod-add.sql`。

## 验证命令

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep shengyu

curl -I https://saas.shengyukj.top/
curl -I https://saasadmin.shengyukj.top/
curl -I https://im.shengyukj.top/
curl -I https://preview.shengyukj.top/
curl -I https://rtc.shengyukj.top/

curl -sS -H "Content-Type: application/json" \
  -d '{"username":"jin_zheyicn@qq.com","password":"wrong-password","deviceType":20,"deviceId":"deploy-check","clientVersion":"web"}' \
  https://apisaas.shengyukj.top/app-api/system/auth/login

curl -sS -H "Content-Type: application/json" \
  -d '{"username":"jin_zheyicn@qq.com","password":"wrong-password"}' \
  https://apisaas.shengyukj.top/admin-api/system/auth/login

dd if=/dev/zero of=/tmp/upload-3m.bin bs=1M count=3
curl -sS -o /tmp/upload-check-response.txt -w "%{http_code}\n" \
  -F "file=@/tmp/upload-3m.bin;filename=upload-check.jpg;type=image/jpeg" \
  -F "directory=im/chat/deploy-check/image" \
  https://apisaas.shengyukj.top/app-api/infra/file/upload-and-return-id
cat /tmp/upload-check-response.txt
```

预期：

- App 登录接口不要求图形验证码，错误信息应透传服务端 `msg`。
- Web 管理端登录继续遵循图形验证码开关。
- `http://im.shengyukj.top/` 应跳转到 HTTPS。
- `https://im.shengyukj.top/` 标题应为 `钰信`。
- 3MB 上传检查不应返回 Nginx `413 Request Entity Too Large`，即使因未登录返回业务错误，也说明请求已越过 Nginx 限制。

## 回滚

- Nginx 回滚：从 `/opt/shengyu/backups/` 中恢复最近一次对应域名配置，然后执行 `nginx -t && systemctl reload nginx`。
- 容器回滚：服务器保留历史镜像层时，可先给历史镜像打 tag，再 `docker compose up -d --force-recreate --no-deps <service>`。
- 数据库回滚：使用执行增量 SQL 前的备份文件恢复。

## 当前已知修复

- App 登录已与 Web 管理端验证码校验解耦。
- Flutter Web 登录错误展示已改为优先显示服务端返回的 `msg/message`。
- Flutter Web 页面标题和登录品牌已调整为 `钰信`。
- `profile_page.dart` 已修复错误的本地化字段调用：使用 `departmentFallback`，不再调用不存在的 `profileDepartmentFallback`。
- Flutter Web 的 Nginx 缓存策略已调整，入口 JS 和 service worker 不再长缓存。
- 真机图片上传服务器异常已定位为 Nginx 默认请求体大小限制；`apisaas.shengyukj.top` 已显式配置 `client_max_body_size 200m;`。
