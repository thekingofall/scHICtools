# setup.py

import os
from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

install_requires = []
if os.path.exists("requirements.txt"):
    with open("requirements.txt", "r", encoding="utf-8") as f:
        install_requires = f.read().splitlines()

setup(
    name="scHICtools",
    version="0.1.0",
    author="YourName",
    author_email="youremail@example.com",
    description="A pipeline for HiC-Pro scHIC data processing.",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/your-repo/scHICtools",
    packages=find_packages(),
    python_requires=">=3.6",
    install_requires=install_requires,
    include_package_data=True,  # 如果需要打包一些数据文件
    entry_points={
        "console_scripts": [
            "scHICtools = scHICprocess.hicpro_pipeline:main"
        ],
    },
)
