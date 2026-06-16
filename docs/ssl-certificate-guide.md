# SSL/TLS 证书获取与部署指南

> 适用于本项目 wss:// 启用（等保三级合规要求）
> 创建时间：2026-06-16

---

## 一、证书类型选择

| 场景 | 证书类型 | 费用 | 推荐 |
|------|----------|------|------|
| **生产环境（等保三级）** | 正规 CA 签发的 OV/EV 证书 | 免费~数千/年 | ✅ Let's Encrypt（免费）或 阿里云/腾讯云（付费） |
| **内网/测试环境** | 自签名证书 | 免费 | ✅ 使用 OpenSSL 生成 |
| **等保三级（国密）** | SM2 国密证书 | 需联系国密 CA | 天威诚信、CFCA 等 |

---

## 二、方案 A：Let's Encrypt 免费证书（生产推荐 ⭐⭐⭐⭐⭐）

### 2.1 前置条件

- 拥有一个正式域名（如 `im.example.com`）
- 域名已解析到服务器 IP
- 服务器有 80/443 端口访问权限
- 安装 `certbot` 工具

### 2.2 获取证书

```bash
# 1. 安装 certbot
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install certbot

# CentOS/RHEL
sudo yum install certbot

# macOS (开发环境)
brew install certbot

# 2. 获取证书（ standalone 模式，需要暂停占用 80 端口的服务）
sudo certbot certonly --standalone -d im.example.com --email admin@example.com --agree-tos

# 或使用 DNS 验证（无需开放 80 端口）
sudo certbot certonly --manual --preferred-challenges dns -d im.example.com
```

### 2.3 转换证书为 PKCS12 格式

Let's Encrypt 生成的证书是 PEM 格式，需要转换为 Java 使用的 PKCS12 (`.p12`) 格式：

```bash
# Let's Encrypt 证书路径
# 证书文件: /etc/letsencrypt/live/im.example.com/fullchain.pem
# 私钥文件: /etc/letsencrypt/live/im.example.com/privkey.pem

# 转换为 PKCS12
sudo openssl pkcs12 -export \
  -in /etc/letsencrypt/live/im.example.com/fullchain.pem \
  -inkey /etc/letsencrypt/live/im.example.com/privkey.pem \
  -out /tmp/im-server.p12 \
  -name im-server \
  -passout pass:changeit

# 将生成的 p12 文件复制到项目 resources 目录
cp /tmp/im-server.p12 /path/to/project/shengyu-module-system/shengyu-module-system-biz/src/main/resources/
```

### 2.4 配置 application.yaml

```yaml
shengyu:
  netty:
    ssl-enabled: true
    ssl-key-store: classpath:im-server.p12
    ssl-key-store-password: changeit
    ssl-key-store-type: PKCS12
```

### 2.5 自动续期（Let's Encrypt 证书有效期 90 天）

```bash
# 创建续期脚本
cat > /etc/cron.monthly/certbot-renew.sh << 'EOF'
#!/bin/bash
certbot renew --quiet --post-hook "
  # 重新转换证书
  openssl pkcs12 -export \
    -in /etc/letsencrypt/live/im.example.com/fullchain.pem \
    -inkey /etc/letsencrypt/live/im.example.com/privkey.pem \
    -out /path/to/resources/im-server.p12 \
    -name im-server \
    -passout pass:changeit
  
  # 重启服务
  systemctl restart shengyu-saas
"
EOF

chmod +x /etc/cron.monthly/certbot-renew.sh
```

---

## 三、方案 B：云厂商免费证书（阿里云/腾讯云）

### 3.1 阿里云免费 SSL 证书

1. 登录 [阿里云 SSL 证书服务](https://yundun.console.aliyun.com/?p=cas)
2. 点击"免费证书" → "购买证书" → 选择"免费版"
3. 填写域名信息，完成 DNS 验证
4. 下载证书，选择"JKS"或"PFX"格式
5. 将下载的 `.pfx` 文件重命名为 `im-server.p12`，放入项目 resources 目录

### 3.2 腾讯云免费 SSL 证书

1. 登录 [腾讯云 SSL 证书管理](https://console.cloud.tencent.com/ssl)
2. 点击"申请免费证书"
3. 填写域名信息，完成 DNS 验证
4. 下载证书，选择"Tomcat"格式（包含 `.jks` 和 `.txt` 密码文件）
5. 将 `.jks` 文件转换为 `.p12`（如果需要）：

```bash
keytool -importkeystore \
  -srckeystore your_domain.jks \
  -srcstoretype JKS \
  -destkeystore im-server.p12 \
  -deststoretype PKCS12 \
  -deststorepass changeit
```

---

## 四、方案 C：自签名证书（仅开发/测试环境）

### 4.1 使用 OpenSSL 生成自签名证书

```bash
# 1. 生成私钥
openssl genrsa -out server.key 2048

# 2. 生成 CSR（证书签名请求）
openssl req -new -key server.key -out server.csr \
  -subj "/C=CN/ST=Beijing/L=Beijing/O=ShengYu/OU=IT/CN=localhost"

# 3. 生成自签名证书（有效期 365 天）
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

# 4. 转换为 PKCS12 格式
openssl pkcs12 -export \
  -in server.crt \
  -inkey server.key \
  -out keystore.p12 \
  -name localhost \
  -passout pass:changeit

# 5. 清理临时文件
rm server.key server.csr server.crt
```

### 4.2 使用 Java keytool 一键生成

```bash
keytool -genkeypair \
  -alias im-server \
  -keyalg RSA \
  -keysize 2048 \
  -storetype PKCS12 \
  -keystore keystore.p12 \
  -validity 365 \
  -storepass changeit \
  -dname "CN=localhost, OU=IT, O=ShengYu, L=Beijing, ST=Beijing, C=CN"
```

### 4.3 配置开发环境

```yaml
shengyu:
  netty:
    ssl-enabled: true
    ssl-key-store: classpath:keystore.p12
    ssl-key-store-password: changeit
    ssl-key-store-type: PKCS12
```

> ⚠️ 自签名证书在生产环境中会导致客户端证书校验失败，仅适用于开发测试。
> Flutter 客户端需要配置允许自签名证书（见下方）。

### 4.4 Flutter 客户端允许自签名证书（仅开发环境）

在 `im_socket_client.dart` 中配置证书校验回调：

```dart
import 'dart:io';

// 在连接前设置（仅开发环境）
HttpOverrides.global = _DevHttpOverrides();

class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
```

---

## 五、方案 D：国密 SM2 证书（等保三级/政企合规）

### 5.1 国密 CA 机构

| 机构 | 官网 | 说明 |
|------|------|------|
| 天威诚信 | https://www.itrus.com.cn | 国内知名国密 CA |
| CFCA | https://www.cfca.com.cn | 中国金融认证中心 |
| 上海 CA | https://www.sheca.com | 上海市数字证书认证中心 |
| 北京 CA | https://www.bjca.org.cn | 北京市数字认证中心 |

### 5.2 国密证书要求

- **签名证书**：SM2 算法，用于身份认证和消息签名
- **加密证书**：SM2 算法，用于密钥交换和数据加密
- **协议**：TLCP（GB/T 38636-2020），即国密 TLS 协议

### 5.3 国密 TLS 配置

国密 TLCP 需要使用支持国密算法的 Java 版本和 Netty 扩展：

```xml
<!-- 添加 BouncyCastle 国密 Provider -->
<dependency>
    <groupId>org.bouncycastle</groupId>
    <artifactId>bcprov-jdk15on</artifactId>
    <version>1.70</version>
</dependency>
<dependency>
    <groupId>org.bouncycastle</groupId>
    <artifactId>bctls-jdk15on</artifactId>
    <version>1.70</version>
</dependency>
```

> ⚠️ 国密 TLCP 需要替换 Netty 的 SslContext 构建逻辑，使用 `BouncyCastleJsseProvider`。
> 具体实施请联系安全团队或使用项目中的 `sm2-ssl-context-builder` 模块（待开发）。

---

## 六、证书验证

### 6.1 验证 PKCS12 证书

```bash
# 查看证书信息
keytool -list -v -keystore keystore.p12 -storetype PKCS12 -storepass changeit

# 输出应包含：
# - 别名 (Alias name)
# - 创建日期
# - 条目类型 (PrivateKeyEntry)
# - 证书链长度
# - 有效期（notBefore / notAfter）
```

### 6.2 验证 wss:// 连接

```bash
# 使用 wscat 测试 WebSocket SSL 连接
npm install -g wscat
wscat -c wss://im.example.com:9000/ws

# 或使用 websocat
websocat wss://im.example.com:9000/ws
```

### 6.3 验证证书有效期

```bash
# OpenSSL 检查证书到期时间
echo | openssl s_client -connect im.example.com:9000 2>/dev/null | openssl x509 -noout -dates
```

---

## 七、生产环境注意事项

1. **证书安全**：
   - 不要将 `keystore.p12` 和密码提交到 Git
   - 使用环境变量或密钥管理服务（如阿里云 KMS、HashiCorp Vault）存储密码
   - 建议配置：
     ```yaml
     shengyu:
       netty:
         ssl-key-store-password: ${NETTY_SSL_PASSWORD}
     ```

2. **证书续期**：
   - Let's Encrypt 证书有效期 90 天，必须设置自动续期
   - 云厂商免费证书通常有效期 1 年，到期前需手动或自动续期
   - 建议设置监控告警，证书到期前 30 天提醒

3. **端口配置**：
   - wss:// 默认端口 443（推荐生产环境）
   - 开发环境可使用自定义端口（如 9443）
   - 确保防火墙开放对应端口

4. **证书链完整性**：
   - 使用 `fullchain.pem` 而非 `cert.pem`，确保包含中间证书
   - 客户端校验失败通常是因为证书链不完整

5. **等保三级合规**：
   - 必须使用正规 CA 签发的证书（不接受自签名）
   - 建议启用国密算法支持（SM2/SM3/SM4）
   - 需要定期更新证书并保留审计记录

---

## 八、快速参考

| 操作 | 命令 |
|------|------|
| 生成自签名证书（一键） | `keytool -genkeypair -alias im-server -keyalg RSA -keysize 2048 -storetype PKCS12 -keystore keystore.p12 -validity 365 -storepass changeit -dname "CN=localhost, OU=IT, O=ShengYu, L=Beijing, ST=Beijing, C=CN"` |
| PEM → PKCS12 | `openssl pkcs12 -export -in fullchain.pem -inkey privkey.pem -out keystore.p12 -name im-server -passout pass:changeit` |
| 查看证书信息 | `keytool -list -v -keystore keystore.p12 -storetype PKCS12 -storepass changeit` |
| Let's Encrypt 获取 | `sudo certbot certonly --standalone -d im.example.com` |
| 测试 wss:// 连接 | `wscat -c wss://im.example.com:9000/ws` |
