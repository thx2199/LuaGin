#!/bin/bash

# 定义要处理的文件后缀
file_extension=".lua"

# 定义输出文件名
output_file="combined.lua"

# 遍历目录，将所有后缀为$file_extension的文件的路径和内容输出到$output_file
for file in **/*$file_extension; do
    echo "-- $file" >> $output_file
    cat $file >> $output_file
    echo "" >> $output_file
done

echo "All files combined into $output_file"
