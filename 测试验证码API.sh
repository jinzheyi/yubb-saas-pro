#!/bin/bash

# 测试验证码 API - 检查后端是否返回 secretKey

echo "========================================="
echo "测试验证码 API"
echo "========================================="
echo ""

# 后端地址（根据实际情况修改）
BASE_URL="http://localhost:48080/admin-api"

echo "1. 测试获取验证码（GET）"
echo "请求: POST ${BASE_URL}/system/captcha/get"
echo ""

# 发送请求
RESPONSE=$(curl -s -X POST "${BASE_URL}/system/captcha/get" \
  -H "Content-Type: application/json" \
  -d '{"captchaType":"blockPuzzle"}')

echo "响应:"
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
echo ""

# 检查是否包含 secretKey
if echo "$RESPONSE" | grep -q "secretKey"; then
    SECRET_KEY=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['repData'].get('secretKey', 'null'))" 2>/dev/null)
    if [ "$SECRET_KEY" != "null" ] && [ -n "$SECRET_KEY" ]; then
        echo "✅ 成功：后端返回了 secretKey: $SECRET_KEY"
    else
        echo "❌ 失败：secretKey 为空"
    fi
else
    echo "❌ 失败：响应中没有 secretKey 字段"
fi

echo ""
echo "========================================="
echo "测试完成"
echo "========================================="
echo ""
echo "如果看到 ✅，说明后端配置正确"
echo "如果看到 ❌，请检查："
echo "  1. 后端服务是否启动"
echo "  2. application.yaml 中是否配置了 aes-status: true"
echo "  3. 重启后端服务"
