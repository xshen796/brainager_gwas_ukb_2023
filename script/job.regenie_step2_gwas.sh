#!/bin/sh
#$ -cwd
#$ -m beas
#$ -l h_vmem=8G
#$ -pe sharedmem 16
#$ -l h_rt=48:00:00
. /etc/profile.d/modules.sh

cd /exports/igmm/eddie/GenScotDepression/shen/ActiveProject/Collab/brainager_gwas_ukb_2023

/exports/igmm/eddie/GenScotDepression/shen/Tools/regenie/regenie_v2.2.4.gz_x86_64_Centos7_mkl \
  --step 2 \
  --bed data/JC_BRAIN_AGE/ukb_brain_age \
  --ref-first \
  --phenoFile data/brainPAD \
  --covarFile data/brainager_covars \
  --covarColList genotyping_array,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,PC11,PC12,PC13,PC14,PC15,PC16,PC17,PC18,PC19,PC20,scanner_x,scanner_y,scanner_z,scanner_table,img_assessment_centre,sex \
  --catCovarList genotyping_array,img_assessment_centre,sex \
  --approx \
  --gz \
  --pred results/brainPAD_step1_pred.list \
  --bsize 400 \
  --threads 32 \
  --out results/brainPAD_step2
