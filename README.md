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


## How to use

`temple.toml` 是平台相关的配置文件模板，在config的各平台中，根据实际环境配置平台相关的信息，并更名为 `.board.toml`

在 test.yml 调用 run.sh 脚本，脚本中遍历各个测试设备，执行测试，并将结果同步到 Github Action 中。

## 文件介绍

```
.
├── config
│   ├── rk3568-arceos
│   │   ├── .project.toml				            # ostool配置项
│   │   ├── .board.toml				                # 硬件平台配置项 (根据 temple.toml 新建)
│   │   ├── arceos.bin								# 客户机镜像文件
│   │   ├── arceos-rk3568.dtb					    # 客户机设备树文件
│   │   ├── vm-rk3568-arceos.toml				    # 客户机配置文件
│   |   └── rk3568.dtb							    # axvisor设备树文件
│   └── phytiumpi-arceos (todo)
│       ├── .project.toml
│       ├── .board.toml
│       ├── arceos.bin
│       ├── arceos-phytiumpi.dtb
│       ├── vm-phytiumpi-arceos.toml
│       └── phytiumpi.dtb
├── img
│   └── board_test.png
├── README.md
├── run.sh											# 启动脚本
└── temple.toml										# 硬件平台配置模板
```

## 注意
1. `vm-rk3568-arceos.toml` 是客户机配置文件，其中 `kernel_path` 和 `dtb_path` 配置绝对路径
2. 启动脚本run.sh, `device` 为继电器的端口，若更改测试环境，将 `device` 修改为继电器实际对应的端口

## More
https://github.com/orgs/arceos-hypervisor/discussions/217
