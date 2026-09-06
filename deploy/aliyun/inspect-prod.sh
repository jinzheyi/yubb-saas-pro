#!/usr/bin/env bash
set -euo pipefail

echo "===== host ====="
date
hostnamectl 2>/dev/null || true
uname -a
whoami
pwd

echo
echo "===== network listeners ====="
ss -lntp 2>/dev/null || netstat -lntp 2>/dev/null || true

echo
echo "===== docker ====="
docker version 2>/dev/null || true
docker compose version 2>/dev/null || docker-compose version 2>/dev/null || true
docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true
docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedSince}}\t{{.Size}}' 2>/dev/null || true
docker network ls 2>/dev/null || true
docker volume ls 2>/dev/null || true

echo
echo "===== compose files ====="
find /opt /srv /usr/local/src /usr/www /www -maxdepth 5 \
  \( -name 'docker-compose*.yml' -o -name 'docker-compose*.yaml' -o -name 'compose*.yml' -o -name 'compose*.yaml' -o -name 'docker.env' -o -name '*.env' \) \
  -type f 2>/dev/null | sort || true

echo
echo "===== java / shengyu processes ====="
ps -ef | grep -E 'shengyu|java|kkfile|nginx|docker' | grep -v grep || true

echo
echo "===== likely app directories ====="
for dir in /usr/local/src/saas /usr/www/app/saas /www/wwwroot /opt/shengyu /srv/shengyu; do
  if [ -e "$dir" ]; then
    echo "--- $dir"
    ls -lah "$dir" || true
    find "$dir" -maxdepth 3 -type f 2>/dev/null | sort | head -300 || true
  fi
done

echo
echo "===== nginx ====="
nginx -v 2>&1 || true
nginx -T 2>/dev/null \
  | sed -E \
      -e 's/(password|passwd|secret|token|api[_-]?key|access[_-]?key|private[_-]?key)([[:space:]]*[:=][[:space:]]*|[[:space:]]+)[^;[:space:]]+/\1\2REDACTED/Ig' \
      -e 's#(ssl_certificate_key[[:space:]]+)[^;]+#\1REDACTED#Ig' \
  || true

echo
echo "===== health probes ====="
for url in \
  http://127.0.0.1:48080/actuator/health \
  http://127.0.0.1:8080/ \
  http://127.0.0.1:8081/ \
  http://127.0.0.1:48090/onlinePreview; do
  printf '%s -> ' "$url"
  curl -k -I -m 5 -s -o /dev/null -w '%{http_code}\n' "$url" || echo "000"
done
