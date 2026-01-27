# 如何编译 Protobuf - 简明指南

## 推荐方式：使用 Maven 插件（最简单）

我已经在 `pom.xml` 中配置好了 protobuf-maven-plugin，您只需要执行：

### 方式一：使用 Maven 命令

```bash
# 进入项目根目录
cd D:\jxctkj\ideaProject\sy-saas\yubb-saas-pro

# 编译 Protobuf
mvn clean compile -pl shengyu-framework/shengyu-spring-boot-starter-websocket
```

或者只编译 websocket 模块：

```bash
cd shengyu-framework\shengyu-spring-boot-starter-websocket
mvn protobuf:compile
```

### 方式二：使用 IDEA

1. 打开 IDEA
2. 找到右侧的 Maven 面板
3. 展开 `shengyu-spring-boot-starter-websocket`
4. 展开 `Plugins` → `protobuf`
5. 双击 `protobuf:compile`

### 验证是否成功

编译成功后，会在以下目录生成 Java 类：

```
src/main/java/com/shengyu/framework/websocket/core/protocol/
├── ImMessage.java
├── ImMessageProto.java
├── MessageHeader.java
├── MessageType.java
├── AuthRequest.java
├── AuthResponse.java
├── TextMessage.java
├── ImageMessage.java
├── VoiceMessage.java
├── VideoMessage.java
├── FileMessage.java
├── LocationMessage.java
├── ReadReceiptMessage.java
└── RecallMessage.java
```

## 关于您下载的 protobuf-33.4

您下载的是 **源码包**（protobuf-33.4），不是预编译的二进制包。

**区别**：
- ❌ `protobuf-33.4.zip` - 源码包（需要自己编译）
- ✅ `protoc-28.3-win64.zip` - 预编译包（直接可用）

**建议**：
1. 删除 `D:\app\protobuf-33.4` 目录
2. 使用上面的 Maven 方式编译（推荐）
3. 或者重新下载正确的预编译包

## 如果 Maven 方式失败

如果 Maven 插件无法自动下载 protoc，可以手动安装：

### 1. 下载正确的文件

访问：https://github.com/protocolbuffers/protobuf/releases

找到最新版本（如 v28.3），下载：
```
protoc-28.3-win64.zip  ← 注意是 protoc 开头
```

### 2. 解压

解压到 `D:\app\protoc`，目录结构应该是：
```
D:\app\protoc\
├── bin\
│   └── protoc.exe    ← 这个文件必须存在
├── include\
└── readme.txt
```

### 3. 配置环境变量

1. 右键"此电脑" → 属性 → 高级系统设置 → 环境变量
2. 在"系统变量"中找到 Path，点击编辑
3. 新建，输入 `D:\app\protoc\bin`
4. 确定保存
5. **重启命令行窗口**

### 4. 验证安装

```cmd
protoc --version
```

应该输出：`libprotoc 28.3`

### 5. 手动编译

```cmd
cd D:\jxctkj\ideaProject\sy-saas\yubb-saas-pro\shengyu-framework\shengyu-spring-boot-starter-websocket
compile-proto.bat
```

## 常见问题

### Q1: Maven 编译时提示找不到 protoc

**A**: 检查网络连接，Maven 需要从中央仓库下载 protoc。如果网络有问题，使用手动安装方式。

### Q2: 生成的文件在哪里？

**A**: 在 `src/main/java/com/shengyu/framework/websocket/core/protocol/` 目录

### Q3: 需要将生成的文件提交到 Git 吗？

**A**: 建议提交，这样其他开发者不需要重新编译。

### Q4: 修改了 proto 文件后怎么办？

**A**: 重新执行 `mvn protobuf:compile` 或 `compile-proto.bat`

## 总结

**最简单的方式**：
```bash
cd shengyu-framework\shengyu-spring-boot-starter-websocket
mvn protobuf:compile
```

这个命令会：
1. 自动下载 protoc 编译器
2. 编译 proto 文件
3. 生成 Java 类到正确的目录

**无需手动下载和安装任何东西！**

---

**更新时间**：2026年1月27日
