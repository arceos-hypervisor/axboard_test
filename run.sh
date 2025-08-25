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
        ostool board-test &
        ostool_pid=$!
        sleep 20

        # 发送对应门路的上电指令 A0(起始标识) 01(第一路) 01(上电) A2(校验码)
        serial_hex=$(printf "%02X" "$serial_id")
        device="/dev/ttyACM$((serial_id-1))"
        stty -F "$device" 115200 cs8 -cstopb -parenb raw -echo -echoe -echok

        up_check_code=$(printf '%02X' $((0xA0 + $serial_hex + 0x01)))
        up_data="A0 $serial_hex 01 $up_check_code"
        echo "power on command: $up_data"
        echo -n $up_data | xxd -r -p > $device

        sleep 30
        # 3. 检查结果，检查是否超时
        # todo: check result

        # 4.发送下电指令，重置
        # 发送对应门路的下电指令 A0(起始标识) 01(第一路) 00(下电) A1(校验码)
        down_check_code=$(printf '%02X' $((0xA0 + $serial_hex + 0x00)))
        down_data="A0 $serial_hex 00 $down_check_code"
        echo "power off command: $power_off_cmd"
        echo -n $down_data | xxd -r -p > $device
        # 关闭ostool
        kill $ostool_pid

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
