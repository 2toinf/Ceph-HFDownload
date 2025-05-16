#!/bin/bash

# === 输入 ===
PREFIX="$1"
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY
# === 路径配置 ===
TMP_DIR="./tmp/hf_parts_$SLURM_JOB_ID"
UNPACK_DIR="$TMP_DIR/unpacked"
LOG_DIR="./logs"
FAILED_LOG="./failed_merge_upload.txt"
mkdir -p "$TMP_DIR" "$UNPACK_DIR" "$LOG_DIR"

# === 日志文件 ===
BASENAME=$(basename "$PREFIX" .tar.gz)
PREFIX_DIR=$(dirname "$PREFIX")
LOG_FILE="$LOG_DIR/${SLURM_JOB_ID}.log"
mkdir -p "$(dirname "$LOG_FILE")"

# === 环境变量（由外部脚本 export）===
# REPO_ID, REMOTE, FILE_LIST_PATH

# === 日志函数 ===
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

download_with_retry() {
    local PART="$1"
    local RETRIES=10
    local WAIT=5
    local COUNT=1

    while [ "$COUNT" -le "$RETRIES" ]; do
        log "📥 尝试下载（$COUNT/$RETRIES):$PART"
        if huggingface-cli download "$REPO_ID" --repo-type=dataset --include "$PART" --local-dir "$TMP_DIR"; then
            log "✅ 下载成功：$PART"
            return 0
        else
            log "下载失败：$PART(第 $COUNT 次)"
            sleep "$WAIT"
        fi
        COUNT=$((COUNT + 1))
    done

    log "❌ 最终下载失败：$PART"
    echo "$PREFIX - 下载失败" >> "$FAILED_LOG"
    return 1
}



# === 开始处理 ===
log "🔍 处理文件组：$PREFIX"

PART_FILES=$(grep "^$PREFIX" "$FILE_LIST_PATH")
PART_COUNT=$(echo "$PART_FILES" | wc -l)
if [ "$PART_COUNT" -gt 10 ]; then
    log "❌ 分段文件数过多：$PART_COUNT（限制为10），任务终止"
    echo "$PREFIX - 分段文件过多 ($PART_COUNT)" >> "$FAILED_LOG"
    exit 1
fi


export HF_ENDPOINT="https://hf-mirror.com/" 
# === 下载所有分段 ===
for PART in $PART_FILES; do
    if ! download_with_retry "$PART"; then
        rm -rf "$TMP_DIR"
        exit 1
    fi
done

# === 解压 ===
DEST_DIR="$UNPACK_DIR/$PREFIX_DIR/$BASENAME/"
mkdir -p "$DEST_DIR"
log "📦 解压到 $DEST_DIR"
if ! cat $TMP_DIR/$PREFIX_DIR/$BASENAME.tar.gz.part-* | tar -xzvf - -C "$DEST_DIR" >>"$LOG_FILE" 2>&1; then
    log "❌ 解压失败"
    echo "$PREFIX - 解压失败" >> "$FAILED_LOG"
    rm -rf "$TMP_DIR"
    exit 1
fi

# === 上传 ===
TARGET_PATH="$REMOTE/$PREFIX_DIR/$BASENAME/"
log "☁️ 上传到 $TARGET_PATH"
if ! /mnt/petrelfs/zhengjinliang/rclone-v1.68.1-linux-amd64/rclone copy "$DEST_DIR" "$TARGET_PATH" --progress >>"$LOG_FILE" 2>&1; then
    log "❌ 上传失败"
    echo "$PREFIX - 上传失败" >> "$FAILED_LOG"
    rm -rf "$TMP_DIR"
    exit 1
fi

# === 清理 ===
log "🧹 清理 $TMP_DIR"
rm -rf "$TMP_DIR"

log "✅ 完成处理：$PREFIX"
