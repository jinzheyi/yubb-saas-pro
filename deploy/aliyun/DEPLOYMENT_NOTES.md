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
- LiveKit 直连端口：`7881/tcp`、`7882/udp`、`443/udp`、`41000-41040/udp`。
- 阿里云安全组必须按协议放通 LiveKit 端口：`443/tcp` 用于 HTTPS 信令入口，`443/udp` 用于 TURN 中继，`7881/tcp`、`7882/udp`、`41000-41040/udp` 用于 WebRTC 媒体链路。

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
- `shengyu-livekit`：LiveKit，宿主机端口 `7880`、`7881`、`7882/udp`、`443/udp`、`41000-41040/udp`。

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

## 钰信版本更新中心

- 版本更新管理属于平台层，后台入口为 `系统管理 -> 应用版本`，菜单权限前缀为 `system:app-release`。
- 移动端和 Flutter Web 使用免租户公开接口 `GET /app-api/system/app-release/check` 检查更新，参数固定包含 `appKey=yuxin`、`platform`、`channel=prod`、当前版本号和构建号。
- Android 正式用户当前采用整包 APK 更新：平台发布记录中的 `packageUrl` 应填写 HTTPS 可下载地址，建议同步填写 `sha256` 用于客户端下载后校验。
- iOS、鸿蒙和 Flutter Web 当前只打开平台配置的下载/分发地址；Dart OTA 补丁能力属于二期，后台字段已预留但生产不要发布 `PATCH` 类型记录。
- 启动进入 App 主界面会自动检查一次版本。普通更新只在“设置 -> 关于钰信”显示红点和详情；强制更新会弹出不可关闭更新框。
- 上线新增或变更此功能时，需要先执行数据库增量 `sql/mysql/1.0/prod_add.sql`，否则平台后台没有菜单和数据表。

### Android 单服务器分发与日常发版

当前阶段不需要应用商店或第三方分发平台。所有 Android APK 统一由现有 HTTPS 域名提供：

`https://preview.shengyukj.top/app/<文件名>.apk`

公网 Nginx 的 `preview.shengyukj.top` 站点中，`/app/` 必须静态映射到服务器目录 `/opt/shengyu/downloads/yuxin/`；其他 URL 继续代理给 kkFileView。对应的版本库模板是 `deploy/aliyun/nginx/preview-container.conf`。首次配置或迁移服务器时执行：

```bash
sudo install -d -m 755 /opt/shengyu/downloads/yuxin
sudo cp /etc/nginx/conf.d/preview.conf \
  /etc/nginx/conf.d/preview.conf.bak.$(date +%Y%m%d%H%M%S)
# 按 deploy/aliyun/nginx/preview-container.conf 将 location /app/ 块加入 preview.conf 的 80/443 server 中
sudo nginx -t && sudo systemctl reload nginx
curl -I https://preview.shengyukj.top/app/not-found.apk # 预期 404，不应被 kkFileView 接管
```

Android 首次正式安装与本次体验：

1. Android 更新必须使用同一发布签名。当前发布密钥位于本机 `shengyu-ui/shengyu-ui-admin-flutter/android/app/yuxin-release.jks`，配置位于 `android/key.properties`，两者均被 Git 忽略且权限为 `600`。
2. 此密钥的 SHA-256 证书指纹为 `2F:C6:B0:56:FC:96:11:79:FE:00:C4:F6:F4:51:46:C3:CF:9B:68:85:B4:9B:70:CF:D0:3C:CA:1C:4C:82:AE:5D`。密钥密码已保存到本机 macOS 钥匙串项目 `shengyu-im-android-release-keystore-password`，账户名 `yuxin-release`。请将 JKS 与密码各自做离线加密备份；丢失后无法给已安装用户正常升级。
3. 已安装旧调试签名包的测试手机，第一次必须先卸载旧包，再安装同一发布签名的首装 APK；以后都可在 App 内升级，无须再连电脑。
4. 本次体验先安装 `yuxin-android-1.0.0+1-release.apk`，再打开“设置 -> 关于钰信 -> 检查更新”。后台发布 `1.0.1 (2)` 后，App 会显示新版本，点击“立即更新”即可下载和唤起 Android 系统安装页。

每次 Android 发版先构建安装包，然后在平台后台的版本表单中上传。上传专用接口会将文件归档到后端文件存储，并自动回填下载地址、字节大小和 SHA-256；这些字段依然允许人工修改，以支持外部商店或第三方分发链接。

生产文件存储固定挂载为宿主机 `/opt/shengyu/saas-deploy/data/file` 到后端容器 `/usr/www/app/saas/file`。该目录同时承载后端本地文件客户端存储的文件，升级或重建 `shengyu-server` 容器时必须保留，禁止清理。

```bash
cd shengyu-ui/shengyu-ui-admin-flutter
/Users/zsy/app/flutter/bin/flutter build apk --release \
  --dart-define=API_BASE_URL=https://apisaas.shengyukj.top/app-api \
  --dart-define=SOCKET_URL=wss://apisaas.shengyukj.top/ws \
  --dart-define=NETWORK_PROBE_URL=https://apisaas.shengyukj.top/app-api \
  --dart-define=NETWORK_PROBE_HOST=apisaas.shengyukj.top
```

随后进入 `https://saasadmin.shengyukj.top` 的 `系统管理 -> 应用版本 -> 新增`。选择平台后，点击“安装包上传”上传本次构建的 APK；等待提示“发行信息已自动回填”后，再补充版本说明并保存。当前生产环境单次上传上限为 `200MB`，钰信 APK 约 `145MB`，可直接使用。

不同平台的上传和分发规则：

| 平台 | 后台允许上传 | 用户点击更新后的行为 | 正式发行建议 |
| --- | --- | --- | --- |
| Android | `.apk` | 下载、校验 SHA-256，并唤起系统安装页 | 直接上传正式签名 APK；也可填写 HTTPS APK 直链。 |
| iOS | `.ipa` | 打开配置的地址 | 优先填写 TestFlight、App Store、MDM 或企业分发页；IPA 必须有有效 Apple 签名，后台不会绕过 Apple 分发规则。 |
| 鸿蒙 | `.hap`、`.app` | 打开配置的地址 | 鸿蒙客户端工程接入后可上传 HAP/APP 或填写华为应用市场/企业分发链接。 |

当前客户端未接入 Dart OTA 执行器，表单中的 Dart OTA 项已标为二期不可选，生产版本只使用“整包更新”。

主要字段填写规则：

| 页面字段 | Android 正式发行填写规则 | 本次体验值 |
| --- | --- | --- |
| 应用标识 | 固定 `yuxin` | `yuxin` |
| 渠道 | 固定 `prod` | `prod` |
| 平台 | 选择 `Android` | `Android` |
| 更新类型 | 一期固定选 `整包更新` | `整包更新` |
| 版本名 | 与 `pubspec.yaml` 的 `version` 中 `+` 前一致 | `1.0.1` |
| 构建号 | 与 `+` 后的数字一致，必须大于已发布构建号 | `2` |
| 最低可用构建号 | 普通更新填当前最低仍允许使用的版本；强制淘汰旧版时调高 | `1` |
| 强制更新 | 普通功能更新关闭；安全/协议不兼容才打开 | 关闭 |
| 更新标题、更新日志 | 给用户看的简短中文说明 | `钰信 1.0.1 更新`、`正式更新链路体验` |
| 安装包上传 | Android 选择本次 `app-release.apk`；iOS 选择已签名 IPA；鸿蒙选择 HAP/APP | 本次 APK |
| 下载/跳转地址 | 上传后自动生成；也可人工替换成平台对应的商店或分发链接 | 自动生成 |
| 包大小(Byte) | 上传后自动计算；外部链接可按发行方给出的实际值修改 | 自动生成 |
| SHA-256 | 上传后自动计算；Android 建议保留，外部链接可填写发行方提供值或留空 | 自动生成 |
| 内部备注 | 运维记录，不向用户展示 | `首个在线更新体验包` |

点击“确定”只会保存为草稿；在列表确认版本、链接、大小和 SHA-256 无误后，再点击“发布”。发布后使用以下接口核验，`hasUpdate` 为 `true` 才会向 `1.0.0 (1)` 客户端提供更新：

```bash
curl -sS 'https://apisaas.shengyukj.top/app-api/system/app-release/check?appKey=yuxin&platform=android&channel=prod&versionName=1.0.0&versionCode=1'
```

普通更新的“推送”是 App 在进入主界面时自动检查并在“关于钰信”显示更新提示；它不是系统通知。用户也可以随时在“关于钰信”手动点“检查更新”。强制更新才会立即显示不可跳过的更新对话框。

出现问题时，先在后台点击“暂停”即可停止继续下发该版本；不要删除已发布记录，也不要替换同名 APK。需要修复时重新构建更高的构建号、上传新文件、创建并发布新记录。

### 2026-09-08 首次在线更新体验记录

- 首装 APK：`shengyu-ui/shengyu-ui-admin-flutter/build/distributions/20260907-235610-release/yuxin-android-1.0.0+1-release.apk`，版本 `1.0.0 (1)`，SHA-256 `ad4a2b25b27a1ec0d8f678e7be62cc82ac6312490b7b6752844c3be170163205`。
- 已发布更新 APK：`shengyu-ui/shengyu-ui-admin-flutter/build/distributions/20260908-000000-online-update/yuxin-android-1.0.1+2-release.apk`，版本 `1.0.1 (2)`，大小 `151945511` bytes，SHA-256 `d7367140948c503e4cb3e89a34993d88ef78a21a1f368798025ebc325da1626e`。
- 生产下载地址：`https://preview.shengyukj.top/app/yuxin-android-1.0.1+2-release.apk`。
- 生产发布记录：`yuxin / android / prod / 1.0.1 / 2 / FULL / PUBLISHED`，普通更新，最低可用构建号 `1`。发布前数据备份：`/opt/shengyu/backups/platform_app_release-20260908001415-before-1.0.1.sql`。
- 体验顺序：手机若已有旧调试包，先卸载；安装上述 `1.0.0 (1)` 首装 APK；打开钰信并进入“设置 -> 关于钰信 -> 检查更新”；看到 `1.0.1` 后点“立即更新”，在 Android 系统安装页确认安装。
- iOS 归档：`shengyu-ui/shengyu-ui-admin-flutter/build/distributions/20260908-000000-online-update/yuxin-ios-1.0.1+2-unsigned.ipa`，未签名，不要配置到 iOS 发布记录。获取 Apple Distribution 证书和 Provisioning Profile 后，改为签名 IPA 并用 TestFlight 或 App Store 分发。

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

在本机完成构建后，将产物上传到服务器并在 `/opt/shengyu/saas-deploy` 中重建镜像。当前服务器已具备 Compose 覆盖文件，Docker Hub 网络正常时优先使用：

```bash
cd /opt/shengyu/saas-deploy
docker compose --env-file docker.prod.env \
  -f docker-compose.yml \
  -f docker-compose.prod-host.yml \
  up -d --build server admin-vue3 platform-vue3 im-flutter-web kkfileview
```

如果服务器访问 Docker Hub 超时或被拒，且本次只是替换已构建好的后端 Jar、平台端静态文件、Flutter Web 静态文件，可使用当前生产可用的容器内产物替换方式：

```bash
# 后端：先上传 shengyu-server.jar 到 /opt/shengyu/saas-deploy/shengyu-server/target/shengyu-server.jar
docker cp /opt/shengyu/saas-deploy/shengyu-server/target/shengyu-server.jar \
  shengyu-server:/shengyu-server/app.jar
docker restart shengyu-server

# 平台端：先在本机执行 VITE_OUT_DIR=dist-platform 的生产构建，再将 dist-platform 内容复制进容器
docker exec shengyu-platform-vue3 sh -c \
  'ts=$(date +%Y%m%d%H%M%S); mv /usr/share/nginx/html /usr/share/nginx/html.bak.$ts; mkdir -p /usr/share/nginx/html'
docker cp - shengyu-platform-vue3:/usr/share/nginx/html
docker exec shengyu-platform-vue3 nginx -s reload

# Flutter Web：先在本机执行 flutter build web，再将 build/web 内容复制进容器
docker exec shengyu-im-flutter-web sh -c \
  'ts=$(date +%Y%m%d%H%M%S); mv /usr/share/nginx/html /usr/share/nginx/html.bak.$ts; mkdir -p /usr/share/nginx/html'
docker cp - shengyu-im-flutter-web:/usr/share/nginx/html
docker exec shengyu-im-flutter-web nginx -s reload
```

从 macOS 传 Flutter Web tar 包时需要禁用扩展属性，避免容器文件系统不支持 `com.apple.quarantine`：

```bash
COPYFILE_DISABLE=1 tar --no-xattrs -C shengyu-ui/shengyu-ui-admin-flutter/build/web -czf - . | \
  ssh aliyun-saas-prod 'docker cp - shengyu-im-flutter-web:/usr/share/nginx/html'
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
- 本次版本更新中心增量会创建 `platform_app_release` 表，并写入平台菜单 `应用版本` 及查询、创建、更新、删除、发布、暂停权限。

## 验证命令

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep shengyu

curl -I https://saas.shengyukj.top/
curl -I https://saasadmin.shengyukj.top/
curl -I https://im.shengyukj.top/
curl -I https://preview.shengyukj.top/
curl -I https://rtc.shengyukj.top/
nc -vz -w 5 rtc.shengyukj.top 7881
nc -vzu -w 5 rtc.shengyukj.top 7882
nc -vzu -w 5 rtc.shengyukj.top 443

curl -sS -H "Content-Type: application/json" \
  -d '{"username":"jin_zheyicn@qq.com","password":"wrong-password","deviceType":20,"deviceId":"deploy-check","clientVersion":"web"}' \
  https://apisaas.shengyukj.top/app-api/system/auth/login

curl -sS -H "Content-Type: application/json" \
  -d '{"username":"jin_zheyicn@qq.com","password":"wrong-password"}' \
  https://apisaas.shengyukj.top/admin-api/system/auth/login

curl -sS "https://apisaas.shengyukj.top/app-api/system/app-release/check?appKey=yuxin&platform=android&channel=prod&versionName=1.0.0&versionCode=1"

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
- 平台后台 `系统管理 -> 应用版本` 应可打开列表页；发布高版本记录后，钰信 App “设置 -> 关于钰信”应能检查到更新。
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
- 用户详情页发消息/发起语音视频通话已修复：创建单聊成员时必须写入当前租户 `tenant_id`，避免对方会话列表能看到但进入提示“会话不存在”；详情页发起通话按单聊会话两端用户校验，不再要求被叫方已提前生成 `im_chat_user` 成员行。
- 若生产出现历史单聊会话成员缺失，先备份数据库，再按 `im_conversation_user_state` 中的当前租户状态补齐缺失的 `im_chat_user` 行；最近一次备份：`/opt/shengyu/backups/shengyu-saas-20260907170821-before-chat-user-tenant-repair.sql`。
- 1v1 通话主叫端 30 秒无人接听时，Flutter 客户端会调用 `/app-api/system/im/call/timeout`，由后端落库为 `TIMEOUT/MISSED` 并广播 `call.timeout` 给双方；服务端 `CallLifecycleJob` 仍作为兜底，避免被叫端持续响铃。
