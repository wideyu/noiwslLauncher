# NOIwsl

NOILinux in Windows WSL2.

从官方NOILinux提取，安装到Windows WSL2环境。可以从Terminal访问，或通过远程桌面访问NOILinux的图形桌面。

## Download
链接: https://pan.baidu.com/s/1oC_-u-55CNUGvKZBeiGIrA 提取码: ngt5

https://github.com/wideyu/noiwsl

## Install
* 解压文件到自定文件夹，比如D:\wsl\noiwsl-20；
* 运行D:\wsl\noiwsl-20\NOIwsl.exe，按提示输入新建用户名、密码；
* Windows远程桌面连接Gnome desktop，mstsc.exe /v:localhost。

## Manual Usage
NOIwsl.exe ~ Install intall.tar.gz to NOIwsl distro.

Blabla.exe ~ New folder, copy&rename exe, install to Blabla distro.

NOIwsl.exe D:\rootfs.tar.gz ~ Install D:\rootfs.tar.gz to NOIwsl distro.

## FAQ
* Why NOIwsl?

在实体机、虚拟机、WSL2安装NOILinux各有各自的好处，NOIwsl在WSL2提供远程桌面方式使用NOILinux图形桌面。

* Why Pascal?

作者学的第一个编程语言是Pascal，NOIwsl Launcher是在NOIwsl中使用NOILinux官方的Lazarus/freepascal编写、编译。

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
