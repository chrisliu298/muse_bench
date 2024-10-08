CORPUS='news'

TARGET_DIR='/mnt/data/yuhaoliu/models/hf_models/MUSE-news_target'
LLAMA_DIR='/mnt/data/yuhaoliu/models/hf_models/Llama-2-7b-hf'

CRIT='sust'
MAX_LEN=2048
PER_DEVICE_BATCH_SIZE=1

# Iterative unlearning methods
LR='1e-5'
RETAIN="../data/$CORPUS/raw/retain1.txt"
STEP_ALGOS=('ga' 'ga_gdr' 'ga_klr' 'npo' 'npo_gdr' 'npo_klr')
# EPOCHS=('1' '7' '10' '1' '10' '10')
EPOCHS=('1' '1' '1' '1' '1' '1')
STEPS_PER_EPOCH='120'
for i in ${!STEP_ALGOS[*]}; do 
    algo=${STEP_ALGOS[$i]}
    epoch=${EPOCHS[$i]}
    model_dir="./ckpt/$CORPUS/$algo/checkpoint-$((epoch * STEPS_PER_EPOCH))"
    for k in '2' '3' '4'; do
        out_dir="./ckpt/$CORPUS/$CRIT/$algo/$k"
        accelerate launch \
            --use_deepspeed \
            --deepspeed_config_file /mnt/data/yuhaoliu/code/muse_bench/baselines/config/deepspeed_stage_3.json \
            unlearn.py \
            --algo $algo \
            --model_dir $model_dir --out_dir $out_dir \
            --data_file "../data/$CORPUS/$CRIT/forget_$k.txt" \
            --epochs 10 --lr $LR \
            --retain_data_file $RETAIN --tokenizer_dir $LLAMA_DIR --max_len $MAX_LEN --per_device_batch_size $PER_DEVICE_BATCH_SIZE
        model_dir=$out_dir
    done
done
