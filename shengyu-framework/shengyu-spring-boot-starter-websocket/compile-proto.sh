#!/bin/bash

# Protobuf 编译脚本
# 用于将 .proto 文件编译成 Java 类

# 设置变量
PROTO_DIR="src/main/proto"
JAVA_OUT_DIR="src/main/java"

# 检查 protoc 是否安装
if ! command -v protoc &> /dev/null; then
    echo "错误: protoc 未安装"
    echo "请先安装 Protocol Buffers 编译器"
    echo "下载地址: https://github.com/protocolbuffers/protobuf/releases"
    exit 1
fi

# 检查 proto 目录是否存在
if [ ! -d "$PROTO_DIR" ]; then
    echo "错误: proto 目录不存在: $PROTO_DIR"
    exit 1
fi

# 创建输出目录
mkdir -p "$JAVA_OUT_DIR"

# 编译 proto 文件
echo "开始编译 Protobuf 文件..."
protoc --java_out="$JAVA_OUT_DIR" --proto_path="$PROTO_DIR" "$PROTO_DIR"/*.proto

# 检查编译结果
if [ $? -eq 0 ]; then
    echo "编译成功！"
    echo "生成的 Java 文件位于: $JAVA_OUT_DIR/com/shengyu/framework/websocket/core/protocol/"
else
    echo "编译失败！"
    exit 1
fi
