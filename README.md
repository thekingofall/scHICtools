# scHICprocess

A Python package for processing single-cell Hi-C data using HiC-Pro pipeline.

## Installation

```
pip install scHICtools
```

## Usage

```
scHICtools
   -n 1 \  # 选择配置文件类型 (1: scCARE.txt, 2: SCCARE_INlaIIl.txt)
    -p my_project \  # 项目名称
    -i /path/to/input \  # 输入目录
    -t /path/to/trim \  # 修剪目录
    -o /path/to/output \  # 输出目录
    -j /path/to/logs \  # 日志目录
    -u 10 \  # CPU线程数
    -e hicpro3 \  # Conda环境名称
    --HiC_Pro /path/to/HiC-Pro \  # HiC-Pro可执行文件路径
    --SentEmail /path/to/SentEmail.py \  # SentEmail.py脚本路径
    --SummaryScript /path/to/hicpro_summary_trans.pl \  # 摘要脚本路径
    --JuiceboxScript /path/to/hicpro2juicebox.sh \  # Juicebox转换脚本路径
    --JuicerTools /path/to/juicer_tools.jar \  # JuicerTools路径
    --GenomeSizes /path/to/hg19.sizes \  # 基因组大小文件路径
    --GenomeBed /path/to/HG19mboi.bed  # 基因组bed文件路径
```


