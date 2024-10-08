CORPUS='news'

FORGET="../data/$CORPUS/raw/forget.txt"
RETAIN="../data/$CORPUS/raw/retain1.txt"


TARGET_DIR='/mnt/data/yuhaoliu/models/hf_models/MUSE-news_target'
LLAMA_DIR='/mnt/data/yuhaoliu/models/hf_models/Llama-2-7b-hf'

MAX_LEN=2048
EPOCHS=10
LR='1e-5'
PER_DEVICE_BATCH_SIZE=1 # 8 GPUs
FT_EPOCHS=10
FT_LR='1e-5'


for algo in 'ga' 'ga_gdr' 'ga_klr' 'npo' 'npo_gdr' 'npo_klr'; do
    accelerate launch \
        --use_deepspeed \
        --deepspeed_config_file /mnt/data/yuhaoliu/code/muse_bench/baselines/config/deepspeed_stage_3.json \
        unlearn.py \
        --algo $algo \
        --model_dir $TARGET_DIR --tokenizer_dir $LLAMA_DIR \
        --data_file $FORGET --retain_data_file $RETAIN \
        --out_dir "./ckpt/$CORPUS/$algo" \
        --max_len $MAX_LEN --epochs $EPOCHS --lr $LR \
        --per_device_batch_size $PER_DEVICE_BATCH_SIZE
    current_dir=$(pwd)
    cd "./ckpt/$CORPUS/$algo"
    find . -type d -name 'global_step*' -exec rm -rf {} +
    cd $current_dir
done


python unlearn.py \
    --algo 'tv' \
    --model_dir $TARGET_DIR --tokenizer_dir $LLAMA_DIR \
    --data_file $FORGET --retain_data_file $RETAIN \
    --out_dir "./ckpt/$CORPUS/tv" \
    --max_len $MAX_LEN --epochs $FT_EPOCHS --lr $FT_LR \
    --per_device_batch_size $PER_DEVICE_BATCH_SIZE \
    --alpha 5.0
