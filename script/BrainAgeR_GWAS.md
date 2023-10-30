BrainAgeR gap GWAS
================
X Shen
30 October, 2023

## Summary

  - Phenotype: Brain age difference (against chronological age, not
    standardised). Brain age etimation from BrainAgeR version 2.
    Chronological age was reported at the imaging assessment. Those who
    had a brain PAD \>50 or \< -50 yrs were removed
    (data/JC\_BRAIN\_AGE/brain\_age\_pheno.file and the formatted
    version at data/JC\_BRAIN\_AGE/brain\_age\_pheno1.file)

  - Covariates - fixed effects: genotyping array, batch, sex, imaging
    assessment centre, scanner positions, first 20 PCs.

  - Covariates - random effect: GRM (estimated from autosomal genotype,
    MAF \> 0.01, data/JC\_BRAIN\_AGE/ukb\_brainage\_grm.\*)

  - Genetic data imputed version 3 released by UKB
    (data/JC\_BRAIN\_AGE/ukb\_brain\_age.bim/bed/fam)

  - Sample: White British (some may be related)

**N = 16021** were included in the GWAS

## Prepare covariats

Set up directories and copy data to scratch space

``` bash
mkdir $myscratch/ukb_brainager
ln -s $myscratch/ukb_brainager data/ukb_brainager

# ukb genetic data
cp /exports/igmm/datastore/GenScotDepression/users/shen/bakup.dat/ukb_genotype/autosome.qc.maf01.hwe5e-6.geno02.mind02.snps* $myscratch/ukb_brainager

# ukb latest phenotypes
cp /exports/igmm/datastore/GenScotDepression/data/ukb/phenotypes/fields/2022-11-phenotypes-ukb670429-v0.7.1/ $myscratch/ukb_brainager

# Related White British
cp /exports/igmm/eddie/GenScotDepression/data/ukb/genetics/gwas/BOLT/whitebritish_centre_array_flashpcs_457k.tsv.gz data/
```

Check phenotype file and remove non-white-British subjects

``` r
# phenotype
brainPAD = fread(here::here('data/JC_BRAIN_AGE/brain_age_pheno.file'))
# white british IDs
bolt_covars = read_tsv('/exports/igmm/eddie/GenScotDepression/data/ukb/genetics/gwas/BOLT/whitebritish_centre_array_flashpcs_457k.tsv.gz') %>% 
  select(FID,IID,genotyping_array)

cat(paste0(sum(brainPAD$id %in% bolt_covars$IID)/nrow(brainPAD)*100,'% of the sample are white British'))

brainPAD %>% 
  left_join(.,bolt_covars,by=c('id'='IID')) %>% 
  select(FID,IID=id,brain_age_diff) %>% 

write_tsv(.,file=here::here('data/brainPAD'))

hist(brainPAD$brain_age_diff)

plot(brainPAD$brain_age_diff)

# save another version without outliers
brainPAD %>% 
  left_join(.,bolt_covars,by=c('id'='IID')) %>% 
  select(FID,IID=id,brain_age_diff) %>% 
  filter(abs(brain_age_diff)<50) %>% 
  write_tsv(.,file=here::here('data/brainPAD_LessThan50yrs'))
```

Covariates

``` r
# Load ukb covariates from phenotype files
con_duck <- dbConnect(duckdb::duckdb(), here::here("/exports/igmm/eddie/GenScotDepression/data/ukb/phenotypes/fields/2022-11-phenotypes-ukb670429-v0.7.1/ukb670429.duckdb"),read_only=T)
baseline = tbl(con_duck,'BaselineCharacteristics') %>% 
  select(f.eid,sex=f.31.0.0)
recruitment = tbl(con_duck,'Recruitment') %>% 
  select(f.eid,age_img = f.21003.2.0,img_assessment_centre=f.54.2.0)
imaging = tbl(con_duck,'Imaging') %>% 
  select(f.eid,scanner_x = f.25756.2.0,scanner_y = f.25757.2.0,scanner_z = f.25758.2.0,scanner_table = f.25759.2.0)

img.gwas = left_join(imaging,recruitment,by='f.eid') %>% 
  left_join(.,baseline,by='f.eid') %>% 
  collect() 

# add bolt covars
ukb.covar.2023 = dbReadTable(con_duck, "Genotypes") %>% 
  select(f.eid, f.22009.0.1:f.22009.0.20) %>% 
  rename_with(~ gsub("f.22009.0.", "PC", .x, fixed = TRUE))
bolt_covars_40PC = bolt_covars %>% 
  select(FID,IID,genotyping_array) %>% 
  left_join(.,ukb.covar.2023,by=c('IID'='f.eid'))
regenie_covars = bolt_covars_40PC %>% 
  as.data.frame %>% 
  left_join(.,img.gwas,by=c('IID'='f.eid')) %>% 
  filter(!is.na(scanner_x)) %>% 
  mutate(sex=ifelse(sex=='Male',1,0)) %>% 
  select(-age_img)

write_tsv(regenie_covars,file=here::here('data/brainager_covars'))

dbDisconnect(con_duck, shutdown=TRUE)
```

## Run GWAS

Software:
regenie

``` bash
cd /exports/igmm/eddie/GenScotDepression/shen/ActiveProject/Collab/brainager_gwas_ukb_2023

qsub script/job.regenie_step1_gwas.sh
qsub -N "brainager_step2" -hold_jid "brainager_step1" script/job.regenie_step2_gwas.sh
```
