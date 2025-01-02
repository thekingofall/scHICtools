#!/bin/bash

# =============================================================================
# 脚本名称: run_hicpro_pipeline.sh
# 描述: 合并两个HiC-Pro运行脚本，允许选择配置文件和调整其他参数。
# 使用方法:
#   ./run_hicpro_pipeline.sh [选项]
#
# 选项:
#   -n <1|2>               选择配置文件类型（1: scCARE.txt, 2: SCCARE_INlaIIl.txt），默认: 1
#   -p <项目名称>           项目名称（默认: scC-HiCMOBI）
#   -i <输入目录>           输入目录（默认: Run1_fastq）
#   -t <修剪目录>           修剪目录（默认: Run2_trim）
#   -o <输出目录>           输出目录（默认: Run3_hic）
#   -j <日志目录>           日志目录（默认: Run0_log）
#   -u <CPU数量>            并行CPU数量（默认: 10）
#   -e <Conda环境>          Conda环境名称（默认: hicpro3）
#   --HiC-Pro <路径>        HiC-Pro可执行文件路径（默认: /home/maolp/mao/Biosoft/HiC-Pro-3.1.0/bin/HiC-Pro）
#   --SentEmail <路径>      SentEmail.py脚本路径（默认: /home/maolp/mao/Codeman/All_Archived_Project/SentEmail.py）
#   --SummaryScript <路径>  hicpro_summary_trans.pl脚本路径（默认: /home/maolp/mao/Codeman/Project/DIPC/scCARE-seq/Processing_Hi-C/hicpro_summary_trans.pl）
#   --JuiceboxScript <路径> hicpro2juicebox.sh脚本路径（默认: /home/maolp/mao/Biosoft/HiC-Pro-3.1.0/bin/utils/hicpro2juicebox.sh）
#   --JuicerTools <路径>    Juicer_tools.jar路径（默认: /home/maolp/mao/Biosoft/juicer_tools_1.22.01.jar）
#   --GenomeSizes <路径>    hg19.sizes文件路径（默认: /home/maolp/mao/Ref/AllnewstarRef/Homo/HG19/hg19.sizes）
#   --GenomeBed <路径>      hg19mboi.bed文件路径（默认: /home/maolp/mao/Ref/AllnewstarRef/Homo/HG19/HG19mboi.bed）
#   -h                      显示帮助信息
# =============================================================================

# 默认参数
Project_name="scC-HiCMOBI"
input_dir="Run1_fastq"
trim_dir="Run2_trim"
output_dir="Run3_hic"
log_dir="Run0_log"
cpu=10
conda_env="hicpro3"

# 默认软件路径
default_HiC_Pro_path="/home/maolp/mao/Biosoft/HiC-Pro-3.1.0/bin/HiC-Pro"
default_SentEmail_path="/home/maolp/mao/Codeman/All_Archived_Project/SentEmail.py"
default_SummaryScript_path="/home/maolp/mao/Codeman/Project/DIPC/scCARE-seq/Processing_Hi-C/hicpro_summary_trans.pl"
default_JuiceboxScript_path="/home/maolp/mao/Biosoft/HiC-Pro-3.1.0/bin/utils/hicpro2juicebox.sh"
default_JuicerTools_path="/home/maolp/mao/Biosoft/juicer_tools_1.22.01.jar"
default_GenomeSizes_path="/home/maolp/mao/Ref/AllnewstarRef/Homo/HG19/hg19.sizes"
default_GenomeBed_path="/home/maolp/mao/Ref/AllnewstarRef/Homo/HG19/HG19mboi.bed"

HiC_Pro_path="$default_HiC_Pro_path"
SentEmail_path="$default_SentEmail_path"
SummaryScript_path="$default_SummaryScript_path"
JuiceboxScript_path="$default_JuiceboxScript_path"
JuicerTools_path="$default_JuicerTools_path"
GenomeSizes_path="$default_GenomeSizes_path"
GenomeBed_path="$default_GenomeBed_path"

# 默认配置文件
config_type=1
config_file="/home/maolp/mao/Codeman/Project/DIPC/scCARE.txt"

# 显示帮助信息
usage() {
    echo "用法: \$0 [选项]"
    echo
    echo "选项:"
    echo "  -n <1|2>               选择配置文件类型（1: scCARE.txt, 2: SCCARE_INlaIIl.txt），默认: 1"
    echo "  -p <项目名称>           项目名称（默认: $Project_name）"
    echo "  -i <输入目录>           输入目录（默认: $input_dir）"
    echo "  -t <修剪目录>           修剪目录（默认: $trim_dir）"
    echo "  -o <输出目录>           输出目录（默认: $output_dir）"
    echo "  -j <日志目录>           日志目录（默认: $log_dir）"
    echo "  -u <CPU数量>            并行CPU数量（默认: $cpu）"
    echo "  -e <Conda环境>          Conda环境名称（默认: $conda_env）"
    echo "  --HiC-Pro <路径>        HiC-Pro可执行文件路径（默认: $default_HiC_Pro_path）"
    echo "  --SentEmail <路径>      SentEmail.py脚本路径（默认: $default_SentEmail_path）"
    echo "  --SummaryScript <路径>  hicpro_summary_trans.pl脚本路径（默认: $default_SummaryScript_path）"
    echo "  --JuiceboxScript <路径> hicpro2juicebox.sh脚本路径（默认: $default_JuiceboxScript_path）"
    echo "  --JuicerTools <路径>    Juicer_tools.jar路径（默认: $default_JuicerTools_path）"
    echo "  --GenomeSizes <路径>    hg19.sizes文件路径（默认: $default_GenomeSizes_path）"
    echo "  --GenomeBed <路径>      hg19mboi.bed文件路径（默认: $default_GenomeBed_path）"
    echo "  -h                      显示此帮助信息"
    echo
    exit 1
}

# 解析命令行选项
while getopts ":n:p:i:t:o:j:u:e:-:" opt; do
    case ${opt} in
        n )
            config_type="$OPTARG"
            if [[ "$config_type" -eq 1 ]]; then
                config_file="/home/maolp/mao/Codeman/Project/DIPC/scCARE.txt"
            elif [[ "$config_type" -eq 2 ]]; then
                config_file="/home/maolp/mao/Codeman/Project/DIPC/SCCARE_INlaIIl.txt"
            else
                echo "无效的选项值: -n $OPTARG. 请选择1或2." >&2
                usage
            fi
            ;;
        p )
            Project_name="$OPTARG"
            ;;
        i )
            input_dir="$OPTARG"
            ;;
        t )
            trim_dir="$OPTARG"
            ;;
        o )
            output_dir="$OPTARG"
            ;;
        j )
            log_dir="$OPTARG"
            ;;
        u )
            cpu="$OPTARG"
            ;;
        e )
            conda_env="$OPTARG"
            ;;
        - )
            case "${OPTARG}" in
                HiC-Pro)
                    HiC_Pro_path="${!OPTIND}"; OPTIND=$((OPTIND +1))
                    ;;
                SentEmail)
                    SentEmail_path="${!OPTIND}"; OPTIND=$((OPTIND +1))
                    ;;
                SummaryScript)
                    SummaryScript_path="${!OPTIND}"; OPTIND=$((OPTIND +1))
                    ;;
                JuiceboxScript)
                    JuiceboxScript_path="${!OPTIND}"; OPTIND=$((OPTIND +1))
                    ;;
                JuicerTools)
                    JuicerTools_path="${!OPTIND}"; OPTIND=$((OPTIND +1))
                    ;;
                GenomeSizes)
                    GenomeSizes_path="${!OPTIND}"; OPTIND=$((OPTIND +1))
                    ;;
                GenomeBed)
                    GenomeBed_path="${!OPTIND}"; OPTIND=$((OPTIND +1))
                    ;;
                *)
                    echo "无效的选项 --${OPTARG}" >&2
                    usage
                    ;;
            esac
            ;;
        h )
            usage
            ;;
        \? )
            echo "无效的选项: -$OPTARG" >&2
            usage
            ;;
        : )
            echo "选项 -$OPTARG 需要一个参数." >&2
            usage
            ;;
    esac
done
shift $((OPTIND -1))

# 设置配置文件基于选择
if [[ "$config_type" -eq 1 ]]; then
    config_file="/home/maolp/mao/Codeman/Project/DIPC/scCARE.txt"
elif [[ "$config_type" -eq 2 ]]; then
    config_file="/home/maolp/mao/Codeman/Project/DIPC/SCCARE_INlaIIl.txt"
else
    config_file="/home/maolp/mao/Codeman/Project/DIPC/scCARE.txt"
fi

# 检查配置文件是否存在
if [[ ! -f "$config_file" ]]; then
    echo "错误: 配置文件 '$config_file' 不存在。" >&2
    exit 1
fi

# 检查HiC-Pro可执行文件是否存在
if [[ ! -x "$HiC_Pro_path" ]]; then
    echo "错误: HiC-Pro可执行文件 '$HiC_Pro_path' 不存在或不可执行。" >&2
    exit 1
fi

# 检查SentEmail.py脚本是否存在
if [[ ! -f "$SentEmail_path" ]]; then
    echo "错误: SentEmail.py脚本 '$SentEmail_path' 不存在。" >&2
    exit 1
fi

# 检查SummaryScript.pl脚本是否存在
if [[ ! -f "$SummaryScript_path" ]]; then
    echo "错误: SummaryScript.pl脚本 '$SummaryScript_path' 不存在。" >&2
    exit 1
fi

# 检查JuiceboxScript.sh脚本是否存在
if [[ ! -x "$JuiceboxScript_path" ]]; then
    echo "错误: JuiceboxScript.sh脚本 '$JuiceboxScript_path' 不存在或不可执行。" >&2
    exit 1
fi

# 检查JuicerTools.jar文件是否存在
if [[ ! -f "$JuicerTools_path" ]]; then
    echo "错误: JuicerTools.jar文件 '$JuicerTools_path' 不存在。" >&2
    exit 1
fi

# 检查GenomeSizes文件是否存在
if [[ ! -f "$GenomeSizes_path" ]]; then
    echo "错误: GenomeSizes文件 '$GenomeSizes_path' 不存在。" >&2
    exit 1
fi

# 检查GenomeBed文件是否存在
if [[ ! -f "$GenomeBed_path" ]]; then
    echo "错误: GenomeBed文件 '$GenomeBed_path' 不存在。" >&2
    exit 1
fi

# 激活指定的Conda环境
echo "正在激活Conda环境: $conda_env"
if ! command -v conda &> /dev/null; then
    echo "错误: conda 未安装或未在PATH中。" >&2
    exit 1
fi

# 初始化conda
source "$(conda info --base)/etc/profile.d/conda.sh"

# 激活环境
if ! conda activate "$conda_env"; then
    echo "错误: 无法激活Conda环境 '$conda_env'" >&2
    exit 1
fi

# 获取当前时间
current_time=$(date +"%Y%m%d-%H%M%S")
logfile="${Project_name}_${current_time}_log.txt"

# 创建日志目录
mkdir -p "$log_dir"

# 开始记录日志
{
    echo "=== Pipeline 开始于 $(date) ==="
    echo "项目名称: $Project_name"
    echo "输入目录: $input_dir"
    echo "修剪目录: $trim_dir"
    echo "输出目录: $output_dir"
    echo "日志目录: $log_dir"
    echo "配置文件: $config_file"
    echo "并行CPU数量: $cpu"
    echo "Conda环境: $conda_env"
    echo "HiC-Pro路径: $HiC_Pro_path"
    echo "SentEmail.py路径: $SentEmail_path"
    echo "SummaryScript.pl路径: $SummaryScript_path"
    echo "JuiceboxScript.sh路径: $JuiceboxScript_path"
    echo "JuicerTools.jar路径: $JuicerTools_path"
    echo "GenomeSizes路径: $GenomeSizes_path"
    echo "GenomeBed路径: $GenomeBed_path"
    echo "===================================="

    # 创建修剪目录
    mkdir -p "$trim_dir"
    # 如果需要创建输出目录，可以取消注释
    # mkdir -p "$output_dir"

    # 进入输入目录并重命名文件
    cd "$input_dir" || { echo "无法进入目录 '$input_dir'"; exit 1; }
    echo "重命名文件..."
    rename _1 _R1 *
    rename _2 _R2 *
    rename .fastq.gz .fq.gz *
    cd ..

    # 生成trim_galore脚本
    trim_script="Run2_trim_script.sh"
    > "$trim_script" # 清空或创建trim脚本
    for sample in $(ls "${input_dir}"/*_R1.fq.gz | rev | cut -d "_" -f 2- | rev | sort | uniq); do
        echo "trim_galore -q 20 --phred33 --stringency 3 --length 20 -e 0.1 --paired ${sample}_R1.fq.gz ${sample}_R2.fq.gz --gzip -o ${trim_dir}" >> "$trim_script"
    done
    chmod +x "$trim_script"
    echo "生成trim_galore脚本: $trim_script"

    # 使用ParaFly并行执行trim_galore
    echo "开始运行trim_galore..."
    ParaFly -c "$trim_script" -CPU "$cpu" || { echo "错误: trim_galore 运行失败"; exit 1; }

    # 进入修剪目录并重命名文件
    cd "$trim_dir" || { echo "无法进入目录 '$trim_dir'"; exit 1; }
    echo "重命名修剪后的文件..."
    rename _val_1 "" *
    rename _val_2 "" *

    # 将修剪后的文件移动到各自的子目录
    echo "整理修剪后的文件..."
    for sample in $(ls ../"${input_dir}"/*_R1.fq.gz | xargs -n 1 basename | rev | cut -d "_" -f 2- | rev | sort | uniq); do
        mkdir -p "${sample}"
        mv "${sample}"* "${sample}/" || { echo "警告: 移动文件到 '${sample}/' 失败"; }
    done

    cd ..

    # 运行HiC-Pro
    echo "运行HiC-Pro..."
    "$HiC_Pro_path" -i "${trim_dir}" -o "${output_dir}" -c "${config_file}" || { echo "错误: HiC-Pro 运行失败"; exit 1; }

    # 生成摘要文件
    summary_file="${Project_name}_Summary.txt"
    echo "生成摘要文件..."
    perl "$SummaryScript_path" "${output_dir}" > "${summary_file}" || { echo "错误: 生成摘要文件失败"; exit 1; }

    # 发送摘要邮件
    echo "发送摘要邮件..."
    python "$SentEmail_path" "${Project_name}" "${summary_file}" || { echo "错误: 发送摘要邮件失败"; exit 1; }

    # 处理HiC-Pro结果并转换为Juicebox格式
    echo "处理HiC-Pro结果并转换为Juicebox格式..."
    cd "${output_dir}/hic_results/data" || { echo "无法进入目录 '${output_dir}/hic_results/data'"; exit 1; }
    for i in *; do
        echo "处理样本: $i"
        cd "${i}"* || { echo "无法进入样本目录 '${i}'"; continue; }
        mkdir -p "${i}"
        ls *all* || { echo "警告: 在样本 '${i}' 中找不到 *all* 文件"; }
        bash "$JuiceboxScript_path" \
            -i *.allValidPairs \
            -g "$GenomeSizes_path" \
            -j "$JuicerTools_path" \
            -r "$GenomeBed_path" \
            -o "${i}" || { echo "错误: Juicebox转换失败 for sample '${i}'"; }
        cd ..
    done

    # 返回项目根目录
    cd ../../../..

    # 发送完成邮件
    echo "发送完成邮件..."
    python "$SentEmail_path" "${Project_name}_trans" "end" || { echo "错误: 发送完成邮件失败"; exit 1; }

    echo "=== Pipeline 结束于 $(date) ==="
} | tee -a "${log_dir}/${logfile}"

# 退出Conda环境
conda deactivate

exit 0
