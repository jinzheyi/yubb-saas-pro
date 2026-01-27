# Protobuf 编译指南

## 一、为什么需要编译 Protobuf

本项目使用 Protobuf 作为消息序列化协议，需要将 `.proto` 文件编译成 Java 类才能使用。

## 二、编译前准备

### 2.1 安装 Protobuf 编译器

#### Windows（推荐方式）

**方式一：下载预编译的二进制包（推荐）**

1. 访问 GitHub Releases 页面：
   ```
   https://github.com/protocolbuffers/protobuf/releases
   ```

2. 找到最新版本（如 v28.3），下载 **Windows 预编译包**：
   ```
   protoc-28.3-win64.zip
   ```
   **注意**：文件名格式为 `protoc-版本号-win64.zip`，不要下载源码包（`protobuf-版本号.zip`）

3. 解压到任意目录，如 `D:\app\protoc`
   解压后目录结构应该是：
   ```
   D:\app\protoc\
   ├── bin\
   │   └── protoc.exe          ← 这是编译器
   ├── include\
   │   └── google\
   │       └── protobuf\
   └── readme.txt
   ```

4. 将 `D:\app\protoc\bin` 添加到系统环境变量 PATH：
   - 右键"此电脑" → 属性 → 高级系统设置 → 环境变量
   - 在"系统变量"中找到 Path，点击编辑
   - 新建，输入 `D:\app\protoc\bin`
   - 确定保存

5. **重启命令行窗口**（重要！）

**方式二：使用 Maven 插件（无需手动安装）**

如果不想手动安装 protoc，可以使用 Maven 插件自动下载和编译。
参见本文档第五章节。

**当前问题解决**：

您下载的 `protobuf-33.4` 是源码包，需要重新下载：
1. 删除 `D:\app\protobuf-33.4` 目录
2. 重新下载 `protoc-28.3-win64.zip`（注意是 protoc 开头，不是 protobuf）
3. 解压到 `D:\app\protoc`

#### Linux/Mac
```bash
# Ubuntu/Debian
sudo apt-get install protobuf-compiler

# CentOS/RHEL
sudo yum install protobuf-compiler

# Mac
brew install protobuf
```

### 2.2 验证安装
```bash
protoc --version
# 应该输出: libprotoc 3.x.x
```

## 三、编译 Protobuf

### 3.1 使用脚本编译（推荐）

#### Windows
```cmd
cd shengyu-framework\shengyu-spring-boot-starter-websocket
compile-proto.bat
```

#### Linux/Mac
```bash
cd shengyu-framework/shengyu-spring-boot-starter-websocket
chmod +x compile-proto.sh
./compile-proto.sh
```

### 3.2 手动编译

```bash
# 进入项目目录
cd shengyu-framework/shengyu-spring-boot-starter-websocket

# 编译 proto 文件
protoc --java_out=src/main/java src/main/proto/im_message.proto
```

## 四、编译后的文件

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

## 五、使用 Maven 插件自动编译（可选）

在 `pom.xml` 中添加 protobuf-maven-plugin：

```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.xolstice.maven.plugins</groupId>
            <artifactId>protobuf-maven-plugin</artifactId>
            <version>0.6.1</version>
            <configuration>
                <protocArtifact>com.google.protobuf:protoc:3.21.7:exe:${os.detected.classifier}</protocArtifact>
                <protoSourceRoot>${project.basedir}/src/main/proto</protoSourceRoot>
                <outputDirectory>${project.basedir}/src/main/java</outputDirectory>
                <clearOutputDirectory>false</clearOutputDirectory>
            </configuration>
            <executions>
                <execution>
                    <goals>
                        <goal>compile</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

然后执行：
```bash
mvn protobuf:compile
```

## 六、常见问题

### 6.1 protoc 命令不存在

**问题**：执行 `protoc --version` 提示命令不存在

**解决**：
1. 检查是否正确安装 protobuf-compiler
2. 检查环境变量 PATH 是否包含 protoc 所在目录
3. 重启终端或 IDE

### 6.2 编译失败：找不到 proto 文件

**问题**：`src/main/proto/im_message.proto: File not found`

**解决**：
1. 检查当前目录是否正确
2. 确保 proto 文件路径正确

### 6.3 生成的文件位置不对

**问题**：生成的 Java 文件不在 `src/main/java` 目录

**解决**：
1. 检查 `--java_out` 参数是否正确
2. 检查 proto 文件中的 `java_package` 选项

### 6.4 IDE 无法识别生成的类

**问题**：编译成功但 IDE 提示找不到类

**解决**：
1. 刷新 IDE 项目（IntelliJ IDEA: File -> Invalidate Caches / Restart）
2. 重新导入 Maven 项目
3. 确保 `src/main/java` 被标记为源代码目录

## 七、注意事项

1. **每次修改 proto 文件后都需要重新编译**
2. **生成的 Java 文件不要手动修改**（会被覆盖）
3. **建议将生成的文件加入版本控制**（方便其他开发者使用）
4. **如果使用 Maven 插件，建议在 CI/CD 中自动编译**

## 八、相关文件

- `src/main/proto/im_message.proto` - Protobuf 协议定义
- `compile-proto.bat` - Windows 编译脚本
- `compile-proto.sh` - Linux/Mac 编译脚本

---

**更新时间**：2026年1月27日  
**版本**：v1.0.0
