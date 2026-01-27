@echo off
REM Protobuf 编译脚本（Windows）
REM 用于将 .proto 文件编译成 Java 类

REM 设置变量
set PROTO_DIR=src\main\proto
set JAVA_OUT_DIR=src\main\java

REM 检查 protoc 是否安装
where protoc >nul 2>nul
if %errorlevel% neq 0 (
    echo 错误: protoc 未安装
    echo 请先安装 Protocol Buffers 编译器
    echo 下载地址: https://github.com/protocolbuffers/protobuf/releases
    exit /b 1
)

REM 检查 proto 目录是否存在
if not exist "%PROTO_DIR%" (
    echo 错误: proto 目录不存在: %PROTO_DIR%
    exit /b 1
)

REM 创建输出目录
if not exist "%JAVA_OUT_DIR%" mkdir "%JAVA_OUT_DIR%"

REM 编译 proto 文件
echo 开始编译 Protobuf 文件...
protoc --java_out=%JAVA_OUT_DIR% --proto_path=%PROTO_DIR% %PROTO_DIR%\*.proto

REM 检查编译结果
if %errorlevel% equ 0 (
    echo 编译成功！
    echo 生成的 Java 文件位于: %JAVA_OUT_DIR%\com\shengyu\framework\websocket\core\protocol\
) else (
    echo 编译失败！
    exit /b 1
)

pause
