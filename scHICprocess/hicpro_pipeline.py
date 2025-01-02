# scHICprocess/hicpro_pipeline.py

import os
import sys
import argparse
import configparser
import shutil
from datetime import datetime

# 从 utils.py 引入 run_pipeline 函数
from .utils import run_pipeline


def load_defaults():
    """
    读取 scHICprocess/config/default_config.ini 中的默认值，返回字典。
    """
    # 找到 config/default_config.ini 的绝对路径
    config_path = os.path.join(
        os.path.dirname(__file__), 
        "config", 
        "default_config.ini"
    )
    if not os.path.isfile(config_path):
        print(f"警告: 找不到默认配置文件: {config_path}")
        return {}

    parser = configparser.ConfigParser()
    parser.read(config_path)
    defaults = dict(parser["DEFAULT"])

    # configparser 读取到的值均是 str，需要手动转换某些字段
    if "cpu" in defaults:
        defaults["cpu"] = int(defaults["cpu"])
    if "config_type" in defaults:
        defaults["config_type"] = int(defaults["config_type"])

    return defaults


def parse_cli(defaults):
    """
    解析命令行参数；若用户没传参，就使用 defaults 中的值。
    """
    parser = argparse.ArgumentParser(
        description="Run HiC-Pro pipeline with optional parameters."
    )

    parser.add_argument("-n", "--config_type",
                        type=int,
                        choices=[1, 2],
                        default=defaults.get("config_type", 1),
                        help="Choose config file type (1: scCARE.txt, 2: SCCARE_INlaIIl.txt).")

    parser.add_argument("-p", "--project_name",
                        default=defaults.get("project_name", "scC-HiCMOBI"),
                        help="Project name.")

    parser.add_argument("-i", "--input_dir",
                        default=defaults.get("input_dir", "Run1_fastq"),
                        help="Input directory.")

    parser.add_argument("-t", "--trim_dir",
                        default=defaults.get("trim_dir", "Run2_trim"),
                        help="Trim directory.")

    parser.add_argument("-o", "--output_dir",
                        default=defaults.get("output_dir", "Run3_hic"),
                        help="Output directory.")

    parser.add_argument("-j", "--log_dir",
                        default=defaults.get("log_dir", "Run0_log"),
                        help="Log directory.")

    parser.add_argument("-u", "--cpu",
                        type=int,
                        default=defaults.get("cpu", 10),
                        help="Number of CPU threads.")

    parser.add_argument("-e", "--conda_env",
                        default=defaults.get("conda_env", "hicpro3"),
                        help="Conda env name to activate.")

    # Software paths
    parser.add_argument("--HiC_Pro", 
                        default=defaults.get("HiC_Pro", "/home/maolp/mao/Biosoft/HiC-Pro-3.1.0/bin/HiC-Pro"),
                        help="Path to HiC-Pro executable.")

    parser.add_argument("--SentEmail", 
                        default=defaults.get("SentEmail", "/home/maolp/mao/Codeman/All_Archived_Project/SentEmail.py"),
                        help="Path to SentEmail.py script.")

    parser.add_argument("--SummaryScript", 
                        default=defaults.get("SummaryScript", "/home/maolp/mao/Codeman/Project/DIPC/scCARE-seq/Processing_Hi-C/hicpro_summary_trans.pl"),
                        help="Path to hicpro_summary_trans.pl script.")

    parser.add_argument("--JuiceboxScript", 
                        default=defaults.get("JuiceboxScript", "/home/maolp/mao/Biosoft/HiC-Pro-3.1.0/bin/utils/hicpro2juicebox.sh"),
                        help="Path to hicpro2juicebox.sh script.")

    parser.add_argument("--JuicerTools", 
                        default=defaults.get("JuicerTools", "/home/maolp/mao/Biosoft/juicer_tools_1.22.01.jar"),
                        help="Path to juicer_tools.jar.")

    parser.add_argument("--GenomeSizes", 
                        default=defaults.get("GenomeSizes", "/home/maolp/mao/Ref/AllnewstarRef/Homo/HG19/hg19.sizes"),
                        help="Path to hg19.sizes.")

    parser.add_argument("--GenomeBed", 
                        default=defaults.get("GenomeBed", "/home/maolp/mao/Ref/AllnewstarRef/Homo/HG19/HG19mboi.bed"),
                        help="Path to hg19mboi.bed.")

    return parser.parse_args()


def main():
    # 1. 从 default_config.ini 读取默认值
    defaults = load_defaults()

    # 2. 解析命令行，优先覆盖 defaults
    args = parse_cli(defaults)

    # 3. 调用 utils.run_pipeline() 执行整个流程
    run_pipeline(args)


if __name__ == "__main__":
    main()
