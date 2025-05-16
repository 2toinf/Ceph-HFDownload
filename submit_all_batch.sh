#!/bin/bash



for GROUP_FILE in group_batch_*; do
    echo "[$i] srun 启动批任务：$GROUP_FILE"
    srun -p mozi-S1 -N1 bash ./slurm_submit.sh "$GROUP_FILE" &
    sleep 1s
done

wait
echo "✅ 所有批处理完成"
