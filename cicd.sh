# 使用示例

# 参数
DingtalkToken=${DingtalkToken:-3fc9a5f488d1de93bcd35b3d8b6a6c8fd16dc7cfdc99f8692f5ffc4554dfcc7c}
API_KEY="5e5e94fa4453d5e055739cf37cb280ee"

while [ $# -gt 0 ]; do
  case "$1" in
    --dingtalk_token=*)
      DingtalkToken="${1#*=}"; shift 1;;
    *)
      echo "Unknown arg: $1" >&2
      print_usage
      exit 1;;
  esac
done

# 编译android
ohpm install --all --registry https://ohpm.openharmony.cn/ohpm/ --strict_ssl true
hvigorw --sync -p product=default --analyze=normal --parallel --incremental --daemon
hvigorw assembleHap -p product=internal -p buildMode=debug


# 上传到蒲公英&&推送钉钉
# =============== 1) 获取 COS Token ===============
RESPONSE=$(curl -s -X POST "https://www.pgyer.com/apiv2/app/getCOSToken" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "_api_key=${API_KEY}" \
  --data-urlencode "buildType=hap" \
  -w "\nHTTP_STATUS:%{http_code}"
)
HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1 | cut -d":" -f2)
BODY=$(echo "$RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
echo "上传第(1)步：获取 COS Token 成功"
ENDPOINT="$(echo "$BODY" | jq -r '.data.endpoint // empty')"
SIGNATURE="$(echo "$BODY" | jq -r '.data.params.signature // empty')"
SEC_TOKEN="$(echo "$BODY" | jq -r '.data.params["x-cos-security-token"] // empty')"
BUILD_KEY="$(echo "$BODY" | jq -r '.data.params.key // empty')"
if [[ -z "$ENDPOINT" || -z "$SIGNATURE" || -z "$SEC_TOKEN" || -z "$BUILD_KEY" ]]; then
  echo "获取 COS Token 失败：字段缺失或接口返回异常"
  echo "Response Code: $HTTP_STATUS"
  echo "Response: $BODY"
  exit 1
fi
# =============== 2) 找到 HAP 并上传 ===============
HAP_DIR="entry/build/internal/outputs/default/"
find "$HAP_DIR" -maxdepth 1 -type f > /dev/null 2>&1 || true
HAP_PATH="$(find "$HAP_DIR" -maxdepth 1 -type f -name '*-signed.hap' | tail -n 1)"
if [[ -z "${HAP_PATH:-}" || ! -f "$HAP_PATH" ]]; then
  echo "未找到 hap：$HAP_DIR/*.hap"
  exit 1
fi
echo "正在上传，hap路径: $HAP_PATH"
UPLOAD_RESP="$(curl -# -X POST "$ENDPOINT" \
  --form-string "signature=${SIGNATURE}" \
  --form-string "x-cos-security-token=${SEC_TOKEN}" \
  --form-string "key=${BUILD_KEY}" \
  -F "file=@${HAP_PATH};type=application/octet-stream" \
  -w "\nHTTP_STATUS:%{http_code}"
)"
UPLOAD_HTTP_STATUS="$(echo "$UPLOAD_RESP" | sed -n 's/^HTTP_STATUS://p')"
UPLOAD_BODY="$(echo "$UPLOAD_RESP" | sed '/^HTTP_STATUS:/d')"
echo "上传第(2)步：上传程序包成功"
# =============== 3) 轮询构建信息 buildInfo ===============
TRY_COUNT=0
MAX_RETRY=10
BUILD_INFO=""
LAST_QUERY_RESP=""
while [[ $TRY_COUNT -lt $MAX_RETRY ]]; do
  TRY_COUNT=$((TRY_COUNT + 1))
  echo "第 ${TRY_COUNT} 次查询构建状态..."
  LAST_QUERY_RESP=$(curl -s "https://www.pgyer.com/apiv2/app/buildInfo?_api_key=${API_KEY}&buildKey=${BUILD_KEY}")
  CODE=$(echo "$LAST_QUERY_RESP" | jq -r '.code // empty')
  if [[ "$CODE" == "1246" || "$CODE" == "1247" ]]; then
    echo "构建处理中，5秒后重试..."
    sleep 5
  elif [[ "$CODE" == "0" ]]; then
    BUILD_INFO=$(echo "$LAST_QUERY_RESP" | jq -r '.data')
    echo "上传第(3)步: 获取构建状态成功"
    break
  else
    echo "构建失败或未知状态，code=$CODE"
    echo "$LAST_QUERY_RESP" | jq '.' || echo "$LAST_QUERY_RESP"
    break
  fi
done
# =============== 4) 构建结果处理 & 钉钉通知 ===============
BUILD_RESULT="SUCCESS"
if [[ -z "$BUILD_INFO" ]]; then
  echo "达到最大重试次数或未获取到构建信息"
  BUILD_RESULT="FAILURE"
fi
get_now_time() {
  date "+%Y-%m-%d %H:%M:%S"
}
dingding() {
  local p_title="$1"
  local p_text="$2"
  local webhook="$3"
  local payload
  payload=$(jq -n --arg title "$p_title" --arg text "$p_text" '{
    msgtype: "markdown",
    markdown: { title: $title, text: $text },
    at: { atMobiles: [], isAtAll: false }
  }')
  local resp
  resp=$(curl -sS -X POST "$webhook" -H "Content-Type: application/json" -d "$payload" || true)
  echo "上传第(4)步: 推送钉钉通知成功"
}
JOB_NAME="OhosDemo"
GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
if [[ "$GIT_BRANCH" == "HEAD" || -z "$GIT_BRANCH" ]]; then
  GIT_BRANCH="$(git name-rev --name-only HEAD 2>/dev/null | sed 's#remotes/origin/##' | sed 's#~[0-9]*##')"
fi
BUILD_URL=""
SUCCESS_TIME="$(get_now_time)"
if [[ "$BUILD_RESULT" == "SUCCESS" ]]; then
  BUILD_SHORTCUT_URL=$(echo "$BUILD_INFO" | jq -r '.buildShortcutUrl // empty')
  BUILD_QR_URL=$(echo "$BUILD_INFO" | jq -r '.buildQRCodeURL // empty')
  APP_VERSION=$(echo "$BUILD_INFO" | jq -r '.buildVersion // empty')
  APP_VERSION_NO=$(echo "$BUILD_INFO" | jq -r '.buildVersionNo // empty')
  HAP_DOWNLOAD_URL="https://www.pgyer.com/${BUILD_SHORTCUT_URL}"
  HAP_DOWNLOAD_URL="${HAP_DOWNLOAD_URL/pgyer/xcxwo}"
  HAP_QR_CODE="${BUILD_QR_URL/pgyer/xcxwo}"
  echo "二维码: $BUILD_QR_URL"
  WEBHOOK_SUCCESS="${WEBHOOK_SUCCESS:-https://oapi.dingtalk.com/robot/send?access_token=${DingtalkToken}}"

  MSG=$(cat <<EOF
应用名称：${JOB_NAME}（构建成功）

构建分支：${GIT_BRANCH}

构建版本：${APP_VERSION}_${APP_VERSION_NO}

构建时间：${SUCCESS_TIME}

下载链接：[地址](${HAP_DOWNLOAD_URL})
![](${HAP_QR_CODE})
EOF
)
  dingding "OhosDemo" "$MSG" "$WEBHOOK_SUCCESS"
else
  WEBHOOK_FAIL="${WEBHOOK_FAIL:-https://oapi.dingtalk.com/robot/send?access_token=${DingtalkToken}}"
  MSG=$(cat <<EOF
应用名称：${JOB_NAME}（构建失败）

构建分支：${GIT_BRANCH}

构建时间：$(get_now_time)

[查看详情](${BUILD_URL})
EOF
)
  dingding "OhosDemo" "$MSG" "$WEBHOOK_FAIL"
  # 构建失败仍然退出非0，方便 Jenkins 标红
  exit 1
fi