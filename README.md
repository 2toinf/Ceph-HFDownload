# Intro
本工具适用于从hf上多进程下载数据集，并实时解压上传到ceph上，减少本地空间临时占用，脚本目前支持split过的.tar.gz类型数据，其他数据类型可通过简单修改download.sh中的代码实现支持

# Usage

1. 通过环境变量设置目标repo_id, 目标ceph路径, 临时meta文件存储路径
```
export REPO_ID=""
export REMOTE=""
export FILE_LIST_PATH="./filelist.txt"
```
2. 使用prepare_hf_split.py获取目标repo的文件list以及对应group
```
python prepare_hf_split.py
```
- 注意你可以通过设置
```
GROUP_SIZE = 20  # 每批 prefix 数量
```
来控制每个进程负责的文件数量，以此来控制进程个数 
3. 提交你的所有任务
```
sh submit_all_batch.sh
```
