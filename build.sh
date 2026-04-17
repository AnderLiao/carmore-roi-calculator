#!/bin/bash
# CARMORE ROI Calculator — 混淆建構腳本
# 用法：bash build.sh
# 功能：從開發版 ROI_Calculator_PH.html 產出混淆版 index.html

set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$DIR/ROI_Calculator_PH.html"
OUT="$DIR/index.html"
TMP_JS="$DIR/_tmp.js"
TMP_OBF="$DIR/_tmp-obfuscated.js"

echo "=== CARMORE ROI Calculator Build ==="

# 1. 檢查開發版存在
if [ ! -f "$SRC" ]; then
  echo "ERROR: $SRC not found"
  exit 1
fi

# 2. 提取 <script> 內容
echo "[1/4] Extracting JavaScript..."
sed -n '/<script>/,/<\/script>/p' "$SRC" | sed '1d;$d' > "$TMP_JS"

# 3. 混淆 JavaScript
echo "[2/4] Obfuscating JavaScript..."
javascript-obfuscator "$TMP_JS" \
  --output "$TMP_OBF" \
  --compact true \
  --control-flow-flattening true \
  --control-flow-flattening-threshold 0.5 \
  --dead-code-injection true \
  --dead-code-injection-threshold 0.2 \
  --string-array true \
  --string-array-encoding base64 \
  --string-array-threshold 0.75 \
  --rename-globals false \
  --self-defending false \
  --split-strings true \
  --split-strings-chunk-length 5 \
  --reserved-names "calculate,toggleTip,tip,renderRec"

# 4. 組合最終 HTML
echo "[3/4] Building index.html..."
# 取 <script> 之前的 HTML
sed '/<script>/,$d' "$SRC" > "$OUT"
# 插入混淆後的 JS
echo "<script>" >> "$OUT"
cat "$TMP_OBF" >> "$OUT"
echo "" >> "$OUT"
echo "</script>" >> "$OUT"
echo "</body>" >> "$OUT"
echo "</html>" >> "$OUT"

# 5. 清理暫存
rm -f "$TMP_JS" "$TMP_OBF"

# 6. 完成
SRC_SIZE=$(wc -c < "$SRC" | tr -d ' ')
OUT_SIZE=$(wc -c < "$OUT" | tr -d ' ')
echo "[4/4] Done!"
echo "  Source:  $SRC ($SRC_SIZE bytes)"
echo "  Output:  $OUT ($OUT_SIZE bytes)"
echo ""
echo "Next: Upload index.html to Cloudflare Pages"
