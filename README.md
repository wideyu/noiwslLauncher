# NOIwsl

NOILinux in Windows WSL2.

2022年3月居家抗疫，完成了NOIwsl项目，方便OIer在Windows WSL2一分钟即可安装使用NOILinux GUI桌面。NOIwsl从官方[NOILinux](https://www.noi.cn/gynoi/jsgz/2021-07-16/732450.shtml)提取，安装到[Windows WSL2](https://docs.microsoft.com/windows/wsl/install)环境。可以从Terminal访问，或通过远程桌面访问NOILinux的图形桌面。
https://github.com/wideyu/noiwsl

## Download
~~[NOIwsl-20_0317.zip](https://pan.baidu.com/s/1cyiIclZP3kN94wPAYREa5w) 链接: https://pan.baidu.com/s/1cyiIclZP3kN94wPAYREa5w 提取码: 76he （可提供稳定下载的:)请联系我）~~
安装文件改为xz压缩到2G 从[Release](https://github.com/wideyu/noiwsl/releases)下载

## Install
* Windows需要安装好wsl2；
* 解压文件到自定文件夹，比如D:\wsl\noiwsl-20；
* 运行D:\wsl\noiwsl-20\NOIwsl.exe，按提示输入新建用户名、密码；
* Windows远程桌面连接Gnome desktop，mstsc.exe /v:localhost。

## Manual Usage
NOIwsl.exe - Install rootfs.tar.xz to NOIwsl distro.

Blabla.exe - New folder, copy&rename exe, install to Blabla distro.

NOIwsl.exe D:\install.tar.gz - Install D:\install.tar.gz to NOIwsl distro.

## FAQ
* Why NOIwsl?

在实体机、虚拟机、WSL2安装NOILinux各有各自的好处，NOIwsl在WSL2提供远程桌面方式使用NOILinux图形桌面。

* Why Pascal?

作者学的第一个编程语言是Pascal。有意思的是：NOIwsl Launcher（NOIwsl安装、启动）是在NOIwsl中，使用NOILinux官方的Lazarus/freepascal编写、编译。

* 如有多个WSL Distro 都启用了xrdp，只有第一个启动的可以正常连接远程桌面。
```bash
# terminate other distro
wsl -l -v
wsl -t distro
wsl -t noiwsl
wsl -d noiwsl
# mstsc.exe /v:localhost

# or just shutdown wsl
wsl --shutdown
wsl -d noiwsl
# mstsc.exe /v:localhost
```

* NOI Linux 2.0?

[NOI Linux 2.0版](https://www.noi.cn/gynoi/jsgz/2021-07-16/732450.shtml)（Ubuntu-NOI 2.0版）已经基于Ubuntu 20.04.1版定制完成，现正式对外发布。根据NOI科学委员会决议，该系统将自2021年9月1日起作为NOI系列比赛和CSP-J/S等活动的标准环境使用。
