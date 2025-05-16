import os
from huggingface_hub import list_repo_files
import math

# === 配置 ===
REPO_ID = os.environ.get('REPO_ID')
REPO_TYPE = "dataset"
GROUP_SIZE = 20  # 每批 prefix 数量
FILE_LIST_PATH = os.environ.get('REPO_ID')
BATCH_PREFIX = "group_batch_"

# === 获取所有文件 ===
print(f"📥 获取仓库文件列表：{REPO_ID}")
all_files = list_repo_files(REPO_ID, repo_type=REPO_TYPE)

# === 写完整文件列表 ===
with open(FILE_LIST_PATH, "w") as f:
    for file in all_files:
        f.write(file + "\n")
print(f"✅ 已写入文件列表到：{FILE_LIST_PATH}")

# === 提取唯一 prefix（例如 a/b/c.tar.gz.part-aa -> a/b/c.tar.gz）===
prefixes = set()
for file in all_files:
    if ".tar.gz.part-" in file:
        prefix = file.split(".part-")[0]
        prefixes.add(prefix)

sorted_prefixes = sorted(prefixes)
print(f"🧩 发现 {len(sorted_prefixes)} 个有效前缀")

# === 按批写入 ===
total_batches = math.ceil(len(sorted_prefixes) / GROUP_SIZE)

for i in range(total_batches):
    batch = sorted_prefixes[i * GROUP_SIZE : (i + 1) * GROUP_SIZE]
    fname = f"{BATCH_PREFIX}{i:02}.txt"
    with open(fname, "w") as f:
        for prefix in batch:
            f.write(prefix + "\n")
    print(f"✅ 写入批次：{fname} ({len(batch)} 个 prefix)")
