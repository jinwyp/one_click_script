# 锐角云安装PVE 最简单教程


### 准备工作
1 下载 PVE镜像 proxmox.img.gz  地址 https://n3450.cloud/proxmox.img.gz
2 下载 SystemRescue Linux 启动盘  地址 https://osdn.net/projects/systemrescuecd/storage/releases/7.01/systemrescue-7.01-amd64.iso 或  https://n3450.cloud/systemrescue-7.01-amd64.iso

3 下载autorun脚本 和 date.sh 脚本


### 开始制作启动盘和安装PVE：

1. 用 rufus U盘写入工具 将 systemrescue-7.01-amd64.iso 写入U盘 
2. 复制 autorun 脚本, date.sh 脚本 和 proxmox.img.gz 到U盘根目录
3. 开机按F7选择U盘引导后 (一般U盘为第二项 UEFI：你的U盘名称 例如 SanDisk, Partition 1)。
4. 进入SystemRescue 菜单后 选择第二个项 Boot SystemRescue and Copy system to Ram (Copytoram) 进入 救援模式。
5. 根据提示选择Y 安装PVE或n 退出。 随后耐心等待直至屏幕变化，设备重启。

6. 进入PVE的命令行环境后，使用用户名和密码为“root/password”进行登陆。 
7. 首次进入要执行一下 bash /reset.sh 来初始化一下。此时可以插入网线。
8. 10.100.99.1并不是机器的ip地址，装好后默认是通过dhcp获取ip的。可通过主路由器的IP DHCP分配地址进行查询。
9. PVE网页登陆方式：“https://192.168.1.xxx:8006”，用户名/密码分别是“root/password”进行登陆。
10. 修复bios时间丢失问题 和 设置网卡静态IP 运行以下命令. 脚本每天都会保存当前时间到文件, 断电重启后会通过crontab重启脚本读取文件设置系统时间,同时会提示设置IP。
```bash
wget --no-check-certificate https://rt1.jinss2.cf/date.sh && chmod +x ./date.sh && ./date.sh firstrun 
```

```bash
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/acuteangle/date.sh && chmod +x ./date.sh && ./date.sh firstrun 
```