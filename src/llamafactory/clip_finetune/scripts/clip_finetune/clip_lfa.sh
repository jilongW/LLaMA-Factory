#!/bin/bash

# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# custom config

TRAINER=CLIP_LFA
DATASET=$1
CFG=$2  # rn50, rn101, vit_b32 or vit_b16
ACCEPT=$3
DEVICE=$4
USE_OPTUNA=$5
device=0
if [ -z $ACCEPT ]; then
    ACCEPT=0
fi
if [ -z $DEVICE ]; then
    DEVICE="cuda"
    device=0
fi
if [ -z $USE_OPTUNA ]; then
    USE_OPTUNA=0
fi
if [ $DEVICE = "XPU" ]; then
    device=1
    ZE_AFFINITY_MASK=0 python train.py \
    --root ${DATA} \
    --trainer ${TRAINER} \
    --dataset-config-file configs/datasets/${DATASET}.yaml \
    --config-file configs/trainers/clip_finetune/${CFG}_tip.yaml \
    --output-dir output/${TRAINER}/${CFG}/${DATASET} \
    --xpu $device \
    --seed 123 \
    --use-optuna $USE_OPTUNA \
    --eval-only \
    TRAINER.COOP.ACC $ACCEPT \
    TRAINER.COOP.N_CTX 16 \
    TRAINER.COOP.CSC True \
    TRAINER.COOP.CLASS_TOKEN_POSITION end \
    DATASET.NUM_SHOTS 16
else
    # CUDA_VISIBLE_DEVICES=0 python train.py \
    # --root ${DATA} \
    # --trainer ${TRAINER} \
    # --dataset-config-file configs/datasets/${DATASET}.yaml \
    # --config-file configs/trainers/clip_finetune/${CFG}_lfa.yaml \
    # --output-dir output/${TRAINER}/${CFG}/${DATASET} \
    # --xpu $device \
    # --seed 123 \
    # --use-optuna $USE_OPTUNA \
    # --eval-only \
    # TRAINER.COOP.ACC $ACCEPT \
    # TRAINER.COOP.N_CTX 16 \
    # TRAINER.COOP.CSC True \
    # TRAINER.COOP.CLASS_TOKEN_POSITION end \
    # DATASET.NUM_SHOTS 16
    for bs in 32  64  128
    do
        for lr in 5e-4 1e-3 2e-3 4e-3
        do
            echo "bs: $bs, lr: $lr"
            CUDA_VISIBLE_DEVICES=0 python train.py \
                --root ${DATA} \
                --trainer ${TRAINER} \
                --dataset-config-file configs/datasets/${DATASET}.yaml \
                --config-file configs/trainers/clip_finetune/${CFG}_lfa.yaml \
                --output-dir output/${TRAINER}/${CFG}/${DATASET} \
                --xpu $device \
                --seed 123 \
                --use-optuna $USE_OPTUNA \
                --eval-only \
                DATALOADER.TRAIN_X.BATCH_SIZE $bs \
                OPTIM.LR $lr \
                TRAINER.COOP.ACC $ACCEPT \
                TRAINER.COOP.N_CTX 16 \
                TRAINER.COOP.CSC True \
                TRAINER.COOP.CLASS_TOKEN_POSITION end \
                DATASET.NUM_SHOTS 0
            rm -rf output/*
        done
    done
fi
