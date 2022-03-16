# NOIwsl

NOILinux in Windows WSL2

## Usage
NOIwsl.exe ~ Install intall.tar.gz to NOIwsl distro.

Blabla.exe ~ New folder, copy&rename exe, install to Blabla distro.

NOIwsl.exe D:\rootfs.tar.gz ~ Install D:\rootfs.tar.gz to NOIwsl distro.

## Download

## Install
* 解压文件到D:\wsl\noiwsl-20，或自定文件夹；
* 运行D:\wsl\noiwsl-20\NOIwsl.exe，按提示输入新建用户名、密码。

## Faq
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
