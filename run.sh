#!/bin/bash

serial_id=7
plat=$1
device="/dev/ttyUSB0"
baud_rate=9600
power_on=1
power_off=0
logfile="log.txt"
max_ostool_time=300
max_test_time=180

send_config() {
    # send .project.toml and .board.toml to ostool
    cp "config/$plat/.project.toml" ../
    cp "config/$plat/.board.toml" ../
    cd ../
    ./axvisor.sh clean
}

start_ostool() {
    if ! command -v ostool &> /dev/null; then
        cargo install ostool
    else
        echo "ostool already installed, skipping..."
    fi
    echo "[Info] Start ostool..."
    ostool board-test | tee $logfile &
    ostool_pid=$!
}

power_on() {
    if [[ "$plat" == "phytiumpi-arceos" ]]; then
        serial_id=6
    elif [[ "$plat" == "rk3568-arceos" ]]; then
        serial_id=5
    else
        echo "[Error] Unknown platform: $plat"
        exit 1
    fi

    mbpoll -m rtu -a 1 -r $serial_id -t 0 -b $baud_rate -P none -v $device $power_on
    echo "[Info] Powered on!"
}

power_off() {
    mbpoll -m rtu -a 1 -r $serial_id -t 0 -b $baud_rate -P none -v $device $power_off
    echo "[Info] Powered off!"
}

reset() {
    # 关闭ostool
    echo "[Info] Reset..."
    # deactivate 新版axvisor都需要venv环境，不关闭也行
    kill $ostool_pid
    rm -rf $logfile .project.toml .board.toml .hvconfig .axconfig.toml
    cd ./axboard_test
}

test_failed() {
    echo "[Info] Test failed: $plat"
    power_off
    reset
    exit 1
}

check_result() {
    echo "[Info] Checking test result..."
    # 检查log.txt中是否有"Test passed"字样
    if grep -q "Test passed" log.txt; then
        echo "[Info] Test passed: $plat"
    else
        test_failed
    fi
}

ostool_timeout_check() {
    ostool_elapsed=0
    while (( ostool_elapsed < max_ostool_time )); do
        sleep 1
        if grep -qF ""等待 U-Boot 启动"" "$logfile" 2>/dev/null; then
            echo "[Info] The keyword has been detected, Continue."
            break
        elif grep -Eiq 'panic|paniced' "$logfile" 2>/dev/null; then
            echo "[Error] 'panic' detected."
            test_failed
        fi
        ((ostool_elapsed++))
    done

    # 判断是否因超时跳出
    if (( ostool_elapsed >= max_ostool_time )); then
        echo "[Error] Run timeout and redirect to exit."
        reset
        exit 1
    fi
}

test_timeout_check() {
    test_elapsed=0
    while (( test_elapsed < max_test_time )); do
        sleep 1
        if grep -qF "Test passed" "$logfile" 2>/dev/null; then
            echo "[Info] Test passed, Prepare to close."
            break
        fi
        ((test_elapsed++))
    done

    # 判断是否因超时跳出
    if (( test_elapsed >= max_test_time )); then
        echo "[Error] Run timeout and redirect to test_failed."
        test_failed
    fi
}

main () {
    echo "[Info] Start testing..."

    echo "[Info] Start test : $plat"
    # 1. 把 |内核启动配置文件| 和 |平台配置文件| 发送给 ostool
    send_config

    # 2. 启动ostool，上电运行测例
    start_ostool
    ostool_timeout_check

    sleep 3
    power_on
    test_timeout_check

    # 3. 检查结果，检查是否超时
    check_result

    # 4.发送下电指令，重置
    power_off
    reset

    ((serial_id++))

    echo "[Info] Test passed: $plat"
    echo

    echo "[Info] All tests completed."
}

main
