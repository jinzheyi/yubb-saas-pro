#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
env_file="${script_dir}/.env"

if [[ ! -f "${env_file}" ]]; then
  echo "缺少 ${env_file}，请先复制 .env.local.example 并配置密钥。" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${env_file}"
set +a

: "${IM_CALL_LIVEKIT_URL:?IM_CALL_LIVEKIT_URL 未配置}"
: "${IM_CALL_LIVEKIT_API_KEY:?IM_CALL_LIVEKIT_API_KEY 未配置}"
: "${IM_CALL_LIVEKIT_API_SECRET:?IM_CALL_LIVEKIT_API_SECRET 未配置}"
if [[ "${IM_CALL_LIVEKIT_ALLOW_INSECURE:-false}" != "true" || "${IM_CALL_LIVEKIT_URL}" != ws://* ]]; then
  echo "本地联调必须使用 ws:// 且设置 IM_CALL_LIVEKIT_ALLOW_INSECURE=true。" >&2
  exit 1
fi

detect_ip() {
  local interface_name
  interface_name="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"
  if [[ -n "${interface_name}" ]]; then
    ipconfig getifaddr "${interface_name}" 2>/dev/null || true
  fi
}

livekit_node_ip="$(detect_ip)"
livekit_node_ip="${livekit_node_ip:-${LIVEKIT_NODE_IP:-}}"
if [[ -z "${livekit_node_ip}" ]]; then
  echo "无法自动识别局域网 IPv4；请执行 LIVEKIT_NODE_IP=192.168.x.x ./start-local.sh。" >&2
  exit 1
fi

echo "LiveKit 将发布可路由媒体地址: ${livekit_node_ip}"
LIVEKIT_NODE_IP="${livekit_node_ip}" LIVEKIT_USE_EXTERNAL_IP=false \
  docker compose --env-file "${env_file}" -f "${script_dir}/docker-compose.yml" up -d --remove-orphans

"${script_dir}/verify-network.sh"
