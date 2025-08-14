## 简介

axboard_test 是在本地服务器搭建的测试环境，本地服务器与 Github Action 以及各个测试设备连接，执行 Action 中的一系列测试步骤，然后结果分析测试结果，并将结果同步到 Github Action 中。

## 流程图

<img src="./img/board_test.png" width="70%" height="70%">


## 硬件平台

### aarch64

- [ ] Phytium-pi
- [ ] Raspi
- [ ] Rockchip RK3568 

### riscv64

- [ ] A
- [ ] B

### loongarch64

- [ ] A
- [ ] B

## How to use

在 test.yml 调用 run.sh 脚本，脚本中遍历各个测试设备，执行测试，并将结果同步到 Github Action 中。

## More
https://github.com/orgs/arceos-hypervisor/discussions/217
