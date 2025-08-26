#!/bin/bash

echo "start testing..."
serial_id=1

send_config() {
    # send .project.toml and .board.toml to ostool
    cp "$dir/.project.toml" ../
    cp "$dir/.board.toml" ../
}

start_ostool() {
    cd ../
    source ./activate.sh
    ostool board-test | tee log.txt &
    ostool_pid=$!
}

power_on() {
    # 发送对应门路的上电指令 A0(起始标识) 01(第一路) 01(上电) A2(校验码)
    serial_hex=$(printf "%02X" "$serial_id")
    device="/dev/ttyACM$((serial_id-1))"
    stty -F "$device" 115200 cs8 -cstopb -parenb raw -echo -echoe -echok

    up_check_code=$(printf '%02X' $((0xA0 + $serial_hex + 0x01)))
    up_data="A0 $serial_hex 01 $up_check_code"
    echo "send power on command: $up_data"
    echo -n $up_data | xxd -r -p > $device
    echo "Powered on!"
}

power_off() {
    # 发送对应门路的下电指令 A0(起始标识) 01(第一路) 00(下电) A1(校验码)
    down_check_code=$(printf '%02X' $((0xA0 + $serial_hex + 0x00)))
    down_data="A0 $serial_hex 00 $down_check_code"
    echo "send power off command: $down_data"
    echo -n $down_data | xxd -r -p > $device
    echo "Powered off!"
}

reset() {
    # 关闭ostool
    kill $ostool_pid
    deactivate
    cargo clean
    cd ./axboard_test
}

test_failed() {
    echo "Test failed: $dir"
    power_off
    reset
    exit 1
}

check_result() {
    # 检查log.txt中是否有"Test passed"字样
    if grep -q "Test passed" log.txt; then
        echo "Test passed: $dir"
    else
        test_failed
    fi
}

timeout_handler() {
    echo "Test timed out."
    reset
    exit 1
}

## 遍历 config 下的所有目录
for dir in config/*; do
    # 检查文件是否存在
    if [ -d "$dir" ]; then
        echo "start test : $dir"
        # 1. 把 |内核启动配置文件| 和 |平台配置文件| 发送给 ostool
        send_config

        # 2. 启动ostool，上电运行测例
        start_ostool
        sleep 30
        power_on
        sleep 30

        # 3. 检查结果，检查是否超时
        check_result

        # 4.发送下电指令，重置
        power_off
        reset
        ((serial_id++))

        echo "Test passed: $dir"
        echo
    else
        echo "Error: dir not found: $dir"
        exit 1
    fi
done

echo "all tests completed."
