#!/bin/bash

# IM 即时通讯 REST API 测试脚本
# 使用方法: ./test-api.sh

# 配置
BASE_URL="http://localhost:48080/app-api"
TENANT_ID="1"

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 打印分隔线
print_separator() {
    echo "=================================================="
}

# 打印测试标题
print_title() {
    echo -e "${YELLOW}$1${NC}"
    print_separator
}

# 打印成功消息
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    ((PASSED_TESTS++))
}

# 打印失败消息
print_error() {
    echo -e "${RED}✗ $1${NC}"
    ((FAILED_TESTS++))
}

# 执行 HTTP 请求
http_request() {
    local method=$1
    local url=$2
    local data=$3
    local token=$4
    
    ((TOTAL_TESTS++))
    
    if [ -z "$token" ]; then
        # 无需认证的请求
        if [ -z "$data" ]; then
            response=$(curl -s -w "\n%{http_code}" -X $method \
                -H "Content-Type: application/json" \
                -H "tenant-id: $TENANT_ID" \
                "$BASE_URL$url")
        else
            response=$(curl -s -w "\n%{http_code}" -X $method \
                -H "Content-Type: application/json" \
                -H "tenant-id: $TENANT_ID" \
                -d "$data" \
                "$BASE_URL$url")
        fi
    else
        # 需要认证的请求
        if [ -z "$data" ]; then
            response=$(curl -s -w "\n%{http_code}" -X $method \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $token" \
                -H "tenant-id: $TENANT_ID" \
                "$BASE_URL$url")
        else
            response=$(curl -s -w "\n%{http_code}" -X $method \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $token" \
                -H "tenant-id: $TENANT_ID" \
                -d "$data" \
                "$BASE_URL$url")
        fi
    fi
    
    # 分离响应体和状态码
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "$body"
    return $http_code
}

# 检查服务是否启动
check_service() {
    print_title "检查服务状态"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:48080/actuator/health)
    
    if [ "$response" = "200" ]; then
        print_success "服务已启动"
        return 0
    else
        print_error "服务未启动或无法访问"
        echo "请先启动后端服务: cd shengyu-server && mvn spring-boot:run -Dspring-boot.run.profiles=local"
        exit 1
    fi
}

# 登录获取 Token
login() {
    print_title "登录获取 Token"
    
    response=$(http_request "POST" "/system/auth/login" \
        '{"username":"admin","password":"admin123"}')
    
    # 提取 token
    token=$(echo $response | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
    
    if [ -n "$token" ]; then
        print_success "登录成功，Token: ${token:0:20}..."
        echo "$token"
    else
        print_error "登录失败"
        echo "响应: $response"
        exit 1
    fi
}

# 测试会话管理接口
test_conversation_api() {
    local token=$1
    
    print_title "测试会话管理接口"
    
    # 1. 获取会话列表
    echo "1. 获取会话列表"
    response=$(http_request "GET" "/system/im/conversation/list" "" "$token")
    if echo "$response" | grep -q '"code":0'; then
        print_success "获取会话列表成功"
    else
        print_error "获取会话列表失败: $response"
    fi
    echo ""
    
    # 2. 创建会话
    echo "2. 创建会话"
    response=$(http_request "POST" "/system/im/conversation/create" \
        '{"targetId":2,"conversationType":1}' "$token")
    if echo "$response" | grep -q '"code":0'; then
        print_success "创建会话成功"
        conversation_id=$(echo $response | grep -o '"data":[0-9]*' | grep -o '[0-9]*')
        echo "会话ID: $conversation_id"
    else
        print_error "创建会话失败: $response"
        conversation_id=""
    fi
    echo ""
    
    # 3. 标记会话已读
    if [ -n "$conversation_id" ]; then
        echo "3. 标记会话已读"
        response=$(http_request "PUT" "/system/im/conversation/mark-read?id=$conversation_id" "" "$token")
        if echo "$response" | grep -q '"code":0'; then
            print_success "标记会话已读成功"
        else
            print_error "标记会话已读失败: $response"
        fi
        echo ""
    fi
    
    # 4. 获取未读消息总数
    echo "4. 获取未读消息总数"
    response=$(http_request "GET" "/system/im/conversation/unread-count" "" "$token")
    if echo "$response" | grep -q '"code":0'; then
        print_success "获取未读消息总数成功"
    else
        print_error "获取未读消息总数失败: $response"
    fi
    echo ""
}

# 测试消息管理接口
test_message_api() {
    local token=$1
    
    print_title "测试消息管理接口"
    
    # 1. 获取消息列表
    echo "1. 获取消息列表"
    response=$(http_request "GET" "/system/im/message/page?pageNo=1&pageSize=20" "" "$token")
    if echo "$response" | grep -q '"code":0'; then
        print_success "获取消息列表成功"
    else
        print_error "获取消息列表失败: $response"
    fi
    echo ""
    
    # 2. 获取未读消息数
    echo "2. 获取未读消息数"
    response=$(http_request "GET" "/system/im/message/unread-count" "" "$token")
    if echo "$response" | grep -q '"code":0'; then
        print_success "获取未读消息数成功"
    else
        print_error "获取未读消息数失败: $response"
    fi
    echo ""
}

# 测试联系人管理接口
test_contact_api() {
    local token=$1
    
    print_title "测试联系人管理接口"
    
    # 1. 获取联系人列表
    echo "1. 获取联系人列表"
    response=$(http_request "GET" "/system/im/contact/list" "" "$token")
    if echo "$response" | grep -q '"code":0'; then
        print_success "获取联系人列表成功"
    else
        print_error "获取联系人列表失败: $response"
    fi
    echo ""
    
    # 2. 搜索联系人
    echo "2. 搜索联系人"
    response=$(http_request "GET" "/system/im/contact/search?keyword=admin" "" "$token")
    if echo "$response" | grep -q '"code":0'; then
        print_success "搜索联系人成功"
    else
        print_error "搜索联系人失败: $response"
    fi
    echo ""
    
    # 3. 获取星标联系人
    echo "3. 获取星标联系人"
    response=$(http_request "GET" "/system/im/contact/list-star" "" "$token")
    if echo "$response" | grep -q '"code":0'; then
        print_success "获取星标联系人成功"
    else
        print_error "获取星标联系人失败: $response"
    fi
    echo ""
}

# 测试群组管理接口
test_group_api() {
    local token=$1
    
    print_title "测试群组管理接口"
    
    # 1. 获取群组列表
    echo "1. 获取群组列表"
    response=$(http_request "GET" "/system/im/group/list" "" "$token")
    if echo "$response" | grep -q '"code":0'; then
        print_success "获取群组列表成功"
    else
        print_error "获取群组列表失败: $response"
    fi
    echo ""
    
    # 2. 创建群组
    echo "2. 创建群组"
    response=$(http_request "POST" "/system/im/group/create" \
        '{"name":"测试群组","memberIds":[2]}' "$token")
    if echo "$response" | grep -q '"code":0'; then
        print_success "创建群组成功"
        group_id=$(echo $response | grep -o '"data":[0-9]*' | grep -o '[0-9]*')
        echo "群组ID: $group_id"
    else
        print_error "创建群组失败: $response"
        group_id=""
    fi
    echo ""
    
    # 3. 获取群组信息
    if [ -n "$group_id" ]; then
        echo "3. 获取群组信息"
        response=$(http_request "GET" "/system/im/group/get?id=$group_id" "" "$token")
        if echo "$response" | grep -q '"code":0'; then
            print_success "获取群组信息成功"
        else
            print_error "获取群组信息失败: $response"
        fi
        echo ""
        
        # 4. 获取群成员列表
        echo "4. 获取群成员列表"
        response=$(http_request "GET" "/system/im/group/member/list?groupId=$group_id" "" "$token")
        if echo "$response" | grep -q '"code":0'; then
            print_success "获取群成员列表成功"
        else
            print_error "获取群成员列表失败: $response"
        fi
        echo ""
    fi
}

# 打印测试结果统计
print_summary() {
    print_separator
    print_title "测试结果统计"
    echo "总测试数: $TOTAL_TESTS"
    echo -e "${GREEN}通过: $PASSED_TESTS${NC}"
    echo -e "${RED}失败: $FAILED_TESTS${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}所有测试通过! ✓${NC}"
    else
        echo -e "${RED}部分测试失败，请检查日志${NC}"
    fi
    print_separator
}

# 主函数
main() {
    echo "=========================================="
    echo "  IM 即时通讯 REST API 测试"
    echo "=========================================="
    echo ""
    
    # 检查服务
    check_service
    echo ""
    
    # 登录获取 Token
    token=$(login)
    echo ""
    
    # 测试各模块接口
    test_conversation_api "$token"
    test_message_api "$token"
    test_contact_api "$token"
    test_group_api "$token"
    
    # 打印测试结果
    print_summary
}

# 执行主函数
main
