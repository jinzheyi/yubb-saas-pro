#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
env_file="${script_dir}/.env"

if [[ ! -f "${env_file}" ]]; then
  echo "缺少 ${env_file}" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${env_file}"
set +a

: "${IM_CALL_LIVEKIT_URL:?IM_CALL_LIVEKIT_URL 未配置}"
: "${IM_CALL_LIVEKIT_API_KEY:?IM_CALL_LIVEKIT_API_KEY 未配置}"
: "${IM_CALL_LIVEKIT_API_SECRET:?IM_CALL_LIVEKIT_API_SECRET 未配置}"

signal_authority="${IM_CALL_LIVEKIT_URL#*://}"
signal_authority="${signal_authority%%/*}"
signal_host="${signal_authority%%:*}"
signal_port="${signal_authority##*:}"
if [[ "${signal_port}" == "${signal_authority}" ]]; then
  [[ "${IM_CALL_LIVEKIT_URL}" == wss://* ]] && signal_port=443 || signal_port=80
fi
[[ "${IM_CALL_LIVEKIT_URL}" == wss://* ]] && health_scheme=https || health_scheme=http

curl --fail --silent --show-error --max-time 5 "${health_scheme}://${signal_authority}/" >/dev/null
nc -z -w 5 "${signal_host}" 7881

livekit_container="$(docker compose --env-file "${env_file}" -f "${script_dir}/docker-compose.yml" ps -q livekit)"
if [[ -z "${livekit_container}" ]]; then
  echo "LiveKit 容器未运行" >&2
  exit 1
fi

advertised_ip="$(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "${livekit_container}" | awk -F= '$1=="NODE_IP"{print $2}')"
if [[ -z "${advertised_ip}" || "${advertised_ip}" == 172.* ]]; then
  echo "LiveKit NODE_IP 不可供真机访问: ${advertised_ip:-空}" >&2
  exit 1
fi

default_interface="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"
current_lan_ip="$(ipconfig getifaddr "${default_interface}" 2>/dev/null || true)"
if [[ -n "${current_lan_ip}" && "${advertised_ip}" != "${current_lan_ip}" ]]; then
  echo "LiveKit NODE_IP 已过期: container=${advertised_ip}, current-lan=${current_lan_ip}" >&2
  echo "请执行 ${script_dir}/start-local.sh 重新发布当前局域网 ICE 地址。" >&2
  exit 1
fi

echo "LiveKit 校验通过：signal=${signal_host}:${signal_port}, rtc-tcp=7881, node-ip=${advertised_ip}"
echo "UDP 7882、3478、41000-41040 必须继续由同一 Wi-Fi 真机或生产网络探针验证。"
