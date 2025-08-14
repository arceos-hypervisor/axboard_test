## 遍历 config/board 目录下的所有 toml 文件
echo "start testing..."

for file in config/board/*.toml; do
    # 检查文件是否存在
    if [ -f "$file" ]; then
        # 1. 解析 board 配置文件

        # 2. 把 |ostool的配置项| 和 |vms的配置文件| 发送给 ostool

        # 3. 等待上电

        # 4. 检查结果，检查是否超时

        echo "test passed: $file"
    else
        echo "Error: file not found: $file"
        exit 1
    fi
done

echo "all tests completed."