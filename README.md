# NOIwsl

NOILinux in Windows WSL2.

从官方NOILinux提取，安装到Windows WSL2环境。可以从Terminal访问，或通过远程桌面访问GUI Desktop。

## Download
链接: https://pan.baidu.com/s/1KIStGGAiAy-9p78NHGxPfA 提取码: v77w

## Install
* 解压文件到自定文件夹，比如D:\wsl\noiwsl-20；
* 运行D:\wsl\noiwsl-20\NOIwsl.exe，按提示输入新建用户名、密码；
* Windows远程桌面连接Gnome desktop，mstsc.exe /v:localhost。

## Manual Usage
NOIwsl.exe ~ Install intall.tar.gz to NOIwsl distro.

Blabla.exe ~ New folder, copy&rename exe, install to Blabla distro.

NOIwsl.exe D:\rootfs.tar.gz ~ Install D:\rootfs.tar.gz to NOIwsl distro.

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
