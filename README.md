# scHICprocess

A Python package for processing single-cell Hi-C data using HiC-Pro pipeline.

## Installation

```
pip install scHICprocess
```

## Usage

```
scHICprocess -c custom_config.ini -p my_project -i input_dir -o output_dir
```

## Configuration

The package comes with a default configuration file (`default_config.ini`). You can create a custom configuration file to override the default settings.

Example custom_config.ini:
```
[DEFAULT]
project_name = my_project
input_dir = my_input_dir
cpu = 20

[paths]
HiC_Pro = /custom/path/to/HiC-Pro
```
