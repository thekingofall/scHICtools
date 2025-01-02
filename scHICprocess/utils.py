# scHICprocess/utils.py

import os
import sys
import subprocess
import shutil
from datetime import datetime

def run_pipeline(args):
    """
    传入的 args 可以是 argparse.Namespace 或类似字典的对象，
    包含所有需要用到的参数，比如:
      - config_type
      - project_name, input_dir, trim_dir, output_dir, log_dir
      - cpu, conda_env
      - HiC_Pro, SentEmail, SummaryScript, JuiceboxScript, JuicerTools, GenomeSizes, GenomeBed
    这里执行原先 Shell/Python 中的完整逻辑。
    """
    # ===== 1. 根据 config_type 选择配置文件 =====
    if args.config_type == 1:
        config_file = "/home/maolp/mao/Codeman/Project/DIPC/scCARE.txt"
    else:
        config_file = "/home/maolp/mao/Codeman/Project/DIPC/SCCARE_INlaIIl.txt"

    # ===== 2. 进一步检查 =====
    if not os.path.isfile(config_file):
        print(f"错误: 配置文件 '{config_file}' 不存在。", file=sys.stderr)
        sys.exit(1)
    if not os.access(args.HiC_Pro, os.X_OK):
        print(f"错误: HiC-Pro可执行文件 '{args.HiC_Pro}' 不存在或不可执行。", file=sys.stderr)
        sys.exit(1)

    # ===== 3. 激活conda环境 =====
    # 注: 在非交互式 shell 中执行 'conda activate' 可能有问题，需要确保 conda 在 PATH 中
    if not shutil.which("conda"):
        print("错误: conda 未安装或不在 PATH 中。", file=sys.stderr)
        sys.exit(1)
    subprocess.run(
        f'source "$(conda info --base)/etc/profile.d/conda.sh" && conda activate {args.conda_env}',
        shell=True,
        executable="/bin/bash"
    )

    # ===== 4. 生成日志文件 =====
    current_time = datetime.now().strftime("%Y%m%d-%H%M%S")
    logfile = f"{args.project_name}_{current_time}_log.txt"
    os.makedirs(args.log_dir, exist_ok=True)
    log_path = os.path.join(args.log_dir, logfile)

    # 写入初始日志
    with open(log_path, "w") as lf:
        lf.write(f"=== Pipeline 开始于 {datetime.now()} ===\n")
        lf.write(f"项目名称: {args.project_name}\n")
        lf.write(f"输入目录: {args.input_dir}\n")
        lf.write(f"修剪目录: {args.trim_dir}\n")
        lf.write(f"输出目录: {args.output_dir}\n")
        lf.write(f"日志目录: {args.log_dir}\n")
        lf.write(f"配置文件: {config_file}\n")
        lf.write(f"并行CPU数量: {args.cpu}\n")
        lf.write(f"Conda环境: {args.conda_env}\n")
        lf.write(f"HiC-Pro路径: {args.HiC_Pro}\n")
        lf.write(f"SentEmail.py路径: {args.SentEmail}\n")
        lf.write(f"SummaryScript.pl路径: {args.SummaryScript}\n")
        lf.write(f"JuiceboxScript.sh路径: {args.JuiceboxScript}\n")
        lf.write(f"JuicerTools.jar路径: {args.JuicerTools}\n")
        lf.write(f"GenomeSizes路径: {args.GenomeSizes}\n")
        lf.write(f"GenomeBed路径: {args.GenomeBed}\n")
        lf.write("====================================\n")

    # ===== 5. 创建修剪/输出目录 =====
    os.makedirs(args.trim_dir, exist_ok=True)
    # os.makedirs(args.output_dir, exist_ok=True)  # 如果需要预先建好

    # ===== 6. 进入输入目录并重命名文件 =====
    if not os.path.isdir(args.input_dir):
        print(f"无法进入输入目录 '{args.input_dir}'，请检查!", file=sys.stderr)
        sys.exit(1)
    try:
        subprocess.run(f'cd {args.input_dir} && rename _1 _R1 *', shell=True, check=True)
        subprocess.run(f'cd {args.input_dir} && rename _2 _R2 *', shell=True, check=True)
        subprocess.run(f'cd {args.input_dir} && rename .fastq.gz .fq.gz *', shell=True, check=True)
    except subprocess.CalledProcessError as e:
        print("重命名文件时出现错误:", e, file=sys.stderr)
        sys.exit(1)

    # ===== 7. 生成trim_galore脚本并行执行 =====
    trim_script = "Run2_trim_script.sh"
    with open(trim_script, "w") as ts:
        for fn in os.listdir(args.input_dir):
            if fn.endswith("_R1.fq.gz"):
                sample_prefix = fn.rsplit("_R1.fq.gz", 1)[0]
                cmd = (
                    f"trim_galore -q 20 --phred33 --stringency 3 --length 20 -e 0.1 "
                    f"--paired {os.path.join(args.input_dir, sample_prefix)}_R1.fq.gz "
                    f"{os.path.join(args.input_dir, sample_prefix)}_R2.fq.gz "
                    f"--gzip -o {args.trim_dir}"
                )
                ts.write(cmd + "\n")

    subprocess.run(f"chmod +x {trim_script}", shell=True)
    try:
        subprocess.run(f"ParaFly -c {trim_script} -CPU {args.cpu}", shell=True, check=True)
    except subprocess.CalledProcessError as e:
        print("错误: trim_galore 并行执行失败:", e, file=sys.stderr)
        sys.exit(1)

    # ===== 8. 重命名修剪后文件 =====
    if not os.path.isdir(args.trim_dir):
        print(f"修剪目录 '{args.trim_dir}' 不存在!", file=sys.stderr)
        sys.exit(1)
    try:
        subprocess.run(f'cd {args.trim_dir} && rename _val_1 "" *', shell=True, check=True)
        subprocess.run(f'cd {args.trim_dir} && rename _val_2 "" *', shell=True, check=True)
    except subprocess.CalledProcessError as e:
        print("重命名修剪文件时出现错误:", e, file=sys.stderr)
        sys.exit(1)

    # ===== 9. 将修剪后的文件移动到各自子目录 =====
    for fn in os.listdir(args.input_dir):
        if fn.endswith("_R1.fq.gz"):
            sample_prefix = fn.rsplit("_R1.fq.gz", 1)[0]
            sample_dir = os.path.join(args.trim_dir, sample_prefix)
            os.makedirs(sample_dir, exist_ok=True)
            for f in os.listdir(args.trim_dir):
                if f.startswith(sample_prefix):
                    old_path = os.path.join(args.trim_dir, f)
                    new_path = os.path.join(sample_dir, f)
                    try:
                        os.rename(old_path, new_path)
                    except OSError as ee:
                        print(f"警告: 移动文件 '{f}' 到 '{sample_dir}' 失败: {ee}")

    # ===== 10. 运行HiC-Pro =====
    try:
        subprocess.run(
            [args.HiC_Pro, "-i", args.trim_dir, "-o", args.output_dir, "-c", config_file],
            check=True
        )
    except subprocess.CalledProcessError as e:
        print("错误: HiC-Pro 运行失败:", e, file=sys.stderr)
        sys.exit(1)

    # ===== 11. 生成摘要文件 =====
    summary_file = f"{args.project_name}_Summary.txt"
    try:
        with open(summary_file, "w") as sf:
            cmd = f"perl {args.SummaryScript} {args.output_dir}"
            result = subprocess.run(cmd, shell=True, check=True, capture_output=True, text=True)
            sf.write(result.stdout)
    except subprocess.CalledProcessError as e:
        print("错误: 生成摘要文件失败:", e, file=sys.stderr)
        sys.exit(1)

    # ===== 12. 发送摘要邮件 =====
    try:
        subprocess.run(["python", args.SentEmail, args.project_name, summary_file], check=True)
    except subprocess.CalledProcessError as e:
        print("错误: 发送摘要邮件失败:", e, file=sys.stderr)
        sys.exit(1)

    # ===== 13. 转换到Juicebox格式 =====
    hic_data_dir = os.path.join(args.output_dir, "hic_results", "data")
    if not os.path.isdir(hic_data_dir):
        print(f"无法进入目录 '{hic_data_dir}'，HiC-Pro 可能未成功。", file=sys.stderr)
        sys.exit(1)

    for sample_dir in os.listdir(hic_data_dir):
        sample_abs = os.path.join(hic_data_dir, sample_dir)
        if not os.path.isdir(sample_abs):
            continue
        subdirs = [d for d in os.listdir(sample_abs) if os.path.isdir(os.path.join(sample_abs, d))]
        for subd in subdirs:
            subd_path = os.path.join(sample_abs, subd)
            outdir = os.path.join(subd_path, subd)
            os.makedirs(outdir, exist_ok=True)
            cmd = (
                f"bash {args.JuiceboxScript} "
                f"-i {os.path.join(subd_path, '*.allValidPairs')} "
                f"-g {args.GenomeSizes} "
                f"-j {args.JuicerTools} "
                f"-r {args.GenomeBed} "
                f"-o {os.path.join(subd_path, subd)}"
            )
            try:
                subprocess.run(cmd, shell=True, check=True)
            except subprocess.CalledProcessError as e:
                print(f"错误: Juicebox转换失败 for sample '{subd}':", e, file=sys.stderr)

    # ===== 14. 发送完成邮件 =====
    try:
        subprocess.run(["python", args.SentEmail, f"{args.project_name}_trans", "end"], check=True)
    except subprocess.CalledProcessError as e:
        print("错误: 发送完成邮件失败:", e, file=sys.stderr)

    # ===== 15. 收尾 =====
    print(f"=== Pipeline 结束于 {datetime.now()} ===")
    print(f"日志保存在: {log_path}")

    # conda deactivate (可选)
    subprocess.run("conda deactivate", shell=True)
