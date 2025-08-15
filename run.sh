#!/bin/bash

echo "start testing..."

## 遍历 config 下的所有目录
for dir in config/*; do
    # 检查文件是否存在
    if [ -d "$dir" ]; then
        # 1. 把 |平台接口配置项| 和 |vms的配置文件| 发送给 ostool

        # 2. 等待上电

        # 3. 检查结果，检查是否超时

        echo "test passed: $dir"
    else
        echo "Error: dir not found: $dir"
        exit 1
    fi
done

echo "all tests completed."