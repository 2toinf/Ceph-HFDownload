#!/bin/bash

# === 传参：group 文件 ===
GROUP_FILE="$1"

# 环境变量从外部传入
# REPO_ID, REMOTE, FILE_LIST_PATH 必须提前 export

while IFS= read -r PREFIX || [[ -n "$PREFIX" ]]; do
    bash ./download.sh "$PREFIX"
done < "$GROUP_FILE"
