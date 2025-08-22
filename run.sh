#!/bin/bash

echo "start testing..."
serial_id=1

## 遍历 config 下的所有目录
for dir in config/*; do
    # 检查文件是否存在
    if [ -d "$dir" ]; then
        echo "start test : $dir"
        # 1. 把 |内核启动配置文件| 和 |平台配置文件| 发送给 ostool
        # send .project.toml and .project.toml to ostool
        # 把 .project.toml 放在axvisor根目录下
        cp "$dir/.project.toml" ../
        cp "$dir/.board.toml" ../
        # 2. 等待上电，执行测例
        cd ../
        ostool board-test
        sleep 5

        # 发送对应门路的上电指令 A0(起始标识) 01(第一路) 01(上电) A2(校验码)
        check_code=$((0xA0 + serial_id + 0x01))
        power_on_cmd=$(printf "A0%02X01%X" "$serial_id" "$check_code")
        echo "power on command: $power_on_cmd"

        serial_port="/dev/ttyUSB$((serial_id-1))"
        echo -n -e "$power_on_cmd" > $serial_port

        # 3. 检查结果，检查是否超时
        timeout=300
        # todo: check result

        # 4.发送下电指令，重置
        # 发送对应门路的下电指令 A0(起始标识) 01(第一路) 00(下电) A1(校验码)
        check_code=$((0xA0 + serial_id))
        power_off_cmd=$(printf "A0%02X00%X" "$serial_id" "$check_code")
        echo "power off command: $power_off_cmd"

        echo -n -e "$power_off_cmd" > $serial_port

        ((serial_id++))
        cd ./axboard_test

        echo "test passed: $dir"
        echo
    else
        echo "Error: dir not found: $dir"
        exit 1
    fi
done

echo "all tests completed."
