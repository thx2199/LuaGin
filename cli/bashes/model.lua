local bash_cmd = [===[
#!/bin/bash
# 该脚本用于依据migration sql文件批量生成或删除模型文件
# 但不删除特殊的模型文件，如：user等
# 用法：bash cli/bash/model.sh [-d]
# 设置工作目录为脚本所在目录的父目录
cd "$(dirname "$0")/.."

# 检查参数是否为 -d
if [ "$1" == "-d" ]; then
    command="del"
else
    command="g"
fi

# 遍历 db/migrations 目录中的文件
for file in db/migrations/*.lua; do
  # 从文件名中提取模型名称
    model_name=$(basename "$file" | sed -E 's/^[0-9]+_([^.]*)\.lua$/\1/')
    # 如果模型名称为 users，则跳过
    if [ "$model_name" == "users" ]; then
        continue
    fi
    # 根据参数执行相应的命令
    gin "$command" model "$model_name"
done
]===]
return bash_cmd
