#!/bin/bash
# scripts/check_i18n.sh
# 检查 ARB 文件翻译完整性（macOS 兼容）
# 用法: bash scripts/check_i18n.sh
# 返回: 0=通过, 1=失败

# Get script directory for consistent path resolution
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ARB_DIR="$PROJECT_DIR/lib/l10n/arb"
TEMPLATE_FILE="$ARB_DIR/app_en.arb"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔍 Checking i18n translation integrity...${NC}"

if [ ! -d "$ARB_DIR" ]; then
  echo -e "${RED}❌ ARB directory not found: $ARB_DIR${NC}"
  exit 1
fi

# 提取翻译 key（排除 @@ 和 @@@ 开头的元数据/分区 key）
# macOS 兼容：使用 -E 扩展正则而非 -P
extract_keys() {
  grep -oE '"[^"@]+"' "$1" \
    | sed 's/^"//;s/"$//' \
    | grep -v '^@' \
    | grep -v '^@@@' \
    | sort
}

if [ ! -f "$TEMPLATE_FILE" ]; then
  echo -e "${RED}❌ Template file not found: $TEMPLATE_FILE${NC}"
  exit 1
fi

template_keys=$(extract_keys "$TEMPLATE_FILE")
template_count=$(echo "$template_keys" | wc -l | tr -d ' ')
echo "📝 Template (en): $template_count keys"

errors=0
warnings=0

for arb_file in "$ARB_DIR"/app_*.arb; do
  filename=$(basename "$arb_file")
  if [ "$filename" = "app_en.arb" ]; then
    continue
  fi

  locale=$(grep -oE '"@@locale": *"[^"]+"' "$arb_file" | sed 's/.*"@@locale": *"//;s/"$//' || echo "unknown")
  locale_keys=$(extract_keys "$arb_file")
  locale_count=$(echo "$locale_keys" | wc -l | tr -d ' ')
  echo "📝 Translation ($locale): $locale_count keys"

  # 检查缺失翻译
  missing=$(comm -23 <(echo "$template_keys") <(echo "$locale_keys"))
  if [ -n "$missing" ]; then
    missing_count=$(echo "$missing" | wc -l | tr -d ' ')
    echo -e "${RED}❌ [$locale] Missing $missing_count translations:${NC}"
    echo "$missing" | head -20
    if [ "$missing_count" -gt 20 ]; then
      echo "... and $((missing_count - 20)) more"
    fi
    errors=$((errors + 1))
  fi

  # 检查多余 key
  extra=$(comm -13 <(echo "$template_keys") <(echo "$locale_keys"))
  if [ -n "$extra" ]; then
    extra_count=$(echo "$extra" | wc -l | tr -d ' ')
    echo -e "${YELLOW}⚠️  [$locale] Has $extra_count extra keys:${NC}"
    echo "$extra" | head -10
    if [ "$extra_count" -gt 10 ]; then
      echo "... and $((extra_count - 10)) more"
    fi
    warnings=$((warnings + 1))
  fi
done

echo ""
echo -e "${GREEN}🔧 Checking placeholder metadata consistency...${NC}"

for arb_file in "$ARB_DIR"/app_*.arb; do
  filename=$(basename "$arb_file")
  locale=$(grep -oE '"@@locale": *"[^"]+"' "$arb_file" | sed 's/.*"@@locale": *"//;s/"$//' || echo "unknown")

  # 用简单方式：检查所有 key，看是否有对应的 @keyName
  all_keys=$(extract_keys "$arb_file")
  meta_keys=$(grep -oE '"@[^"@]+"' "$arb_file" \
    | sed 's/^"@//;s/"$//' \
    | sort -u)
  
  # 检查有 placeholder 但缺少 @metadata 的 key
  # 简化处理：只检查 key 是否在 meta_keys 中
  missing_meta_count=0
  while IFS= read -r key; do
    # 检查这个 key 对应的 value 是否包含占位符
    value=$(grep -A1 "\"$key\"" "$arb_file" | head -1 | grep -oE ': *"[^"]*"' | sed 's/^: *"//;s/"$//' || true)
    if echo "$value" | grep -qE '\{'; then
      if ! echo "$meta_keys" | grep -qx "$key"; then
        if [ $missing_meta_count -eq 0 ]; then
          echo -e "${YELLOW}⚠️  [$locale] Keys with placeholders but missing @metadata:${NC}"
        fi
        echo "  - $key"
        missing_meta_count=$((missing_meta_count + 1))
        if [ $missing_meta_count -ge 10 ]; then
          echo "  ... and more"
          break
        fi
      fi
    fi
  done <<< "$all_keys"
  
  if [ $missing_meta_count -gt 0 ]; then
    warnings=$((warnings + 1))
  fi
done

echo ""

if [ $errors -gt 0 ]; then
  echo -e "${RED}❌ i18n check failed with $errors error(s) and $warnings warning(s)${NC}"
  exit 1
fi

if [ $warnings -gt 0 ]; then
  echo -e "${YELLOW}⚠️  i18n check passed with $warnings warning(s)${NC}"
  exit 0
fi

echo -e "${GREEN}✅ i18n integrity check passed${NC}"
exit 0
