#!/bin/bash
serial_id=1
device="/dev/ttyACM0"
logfile="log.txt"
max_ostool_time=120
max_test_time=300

send_config() {
    # send .project.toml and .board.toml to ostool
    cp "$dir/.project.toml" ../
    cp "$dir/.board.toml" ../
}

start_ostool() {
    cd ../
    source ./activate.sh
    ostool board-test | tee $logfile &
    ostool_pid=$!
}

power_on() {
    # 发送对应门路的上电指令 A0(起始标识) 01(第一路) 01(上电) A2(校验码)
    serial_hex=$(printf "%02X" "$serial_id")
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
    echo "reset..."
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

ostool_timeout_check() {
    elapsed=0
    while (( elapsed < max_ostool_time )); do
        sleep 1
        if grep -qF ""等待 U-Boot 启动"" "$logfile"; then
            echo "The keyword has been detected, Continue."
            break
        fi
        ((elapsed++))
    done

    # 判断是否因超时跳出
    if (( elapsed >= max_ostool_time )); then
        echo "The keyword was not detected during the timeout and was redirected to reset."
        reset
        exit 1
    fi
}

test_timeout_check() {
    elapsed=0
    while (( elapsed < max_test_time )); do
        sleep 1
        if grep -qF "Test passed" "$logfile"; then
            echo "Test passed, Prepare to close."
            break
        fi
        ((elapsed++))
    done

    # 判断是否因超时跳出
    if (( elapsed >= max_test_time )); then
        echo "The keyword was not detected during the timeout and was redirected to test_failed."
        test_failed
    fi
}

echo "start testing..."
## 遍历 config 下的所有目录
for dir in config/*; do
    # 检查文件是否存在
    if [ -d "$dir" ]; then
        echo "start test : $dir"
        # 1. 把 |内核启动配置文件| 和 |平台配置文件| 发送给 ostool
        send_config

        # 2. 启动ostool，上电运行测例
        start_ostool
        ostool_timeout_check

        power_on
        test_timeout_check

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
