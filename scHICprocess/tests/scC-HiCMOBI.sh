#!/bin/bash

Project_name="scC-HiCMOBI"
input_dir="Run1_fastq"
trim_dir="Run2_trim"
output_dir="Run3_hic"
current_time=$(date +"%Y%m%d-%H%M%S")
logfile="${Project_name}_${current_time}_log.txt"

mkdir -p Run0_log
{
##  mkdir -p Run1_fastq && for i in {61..66}; do cat raw_add/scc-HiC-${i}_L*_1.fq.gz > Run1_fastq/scc-HiC-${i}_all_1.fq.gz; cat raw_add/scc-HiC-${i}_L*_2.fq.gz > Run1_fastq/scc-HiC-${i}_all_2.fq.gz; done
mkdir -p ${trim_dir}
# mkdir -p ${output_dir}

cd $input_dir
rename _1 _R1 *
rename _2 _R2 *
rename .fastq.gz .fq.gz *
cd ..
for sample in $(ls ${input_dir}/*_R1.fq.gz | rev | cut -d "_" -f 2- | rev | sort | uniq); do
    echo "trim_galore -q 20 --phred33 --stringency 3 --length 20 -e 0.1 --paired ${sample}_R1.fq.gz ${sample}_R2.fq.gz --gzip -o ${trim_dir}" >> Run2_trim_script.sh
done

ParaFly -c Run2_trim_script.sh -CPU 10

cd ${trim_dir}

rename _val_1 "" *
rename _val_2 "" *

for sample in $(ls ../${input_dir}/*_R1.fq.gz | xargs -n 1 basename | rev | cut -d "_" -f 2- | rev | sort | uniq); do
    mkdir -p ${sample}
    mv ${sample}* ${sample}
done

cd ..


# for sample in $(ls ../${input_dir}/*_R1.fq.gz | xargs -n 1 basename | rev | cut -d "_" -f 2- | rev | sort | uniq); do
/home/maolp/mao/Biosoft/HiC-Pro-3.1.0/bin/HiC-Pro -i ${trim_dir}  -o ${output_dir} -c /home/maolp/mao/Codeman/Project/DIPC/scCARE.txt
perl  /home/maolp/mao/Codeman/Project/DIPC/scCARE-seq/Processing_Hi-C/hicpro_summary_trans.pl ${output_dir}  > ${Project_name}_Summary.txt

python /home/maolp/mao/Codeman/All_Archived_Project/SentEmail.py ${Project_name} ${Project_name}_Summary.txt


cd ${output_dir}/hic_results/data;for i in *;do echo $i;cd ${i}*;mkdir -p ${i};ls *all*;bash /home/maolp/mao/Biosoft/HiC-Pro-3.1.0/bin/utils/hicpro2juicebox.sh -i *.allValidPairs -g /home/maolp/mao/Ref/AllnewstarRef/Homo/HG19/hg19.sizes -j /home/maolp/mao/Biosoft/juicer_tools_1.22.01.jar -r /home/maolp/mao/Ref/AllnewstarRef/Homo/HG19/HG19mboi.bed -o ${i};cd ..;done

python /home/maolp/mao/Codeman/All_Archived_Project/SentEmail.py "${Project_name}_trans" "end"

} | tee -a Run0_log/${logfile}
