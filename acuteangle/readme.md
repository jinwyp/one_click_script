# 锐角云安装PVE 最简单教程

### 准备工作
1. 下载 PVE镜像 proxmox.img.gz  地址 https://n3450.cloud/proxmox.img.gz
2. 下载 SystemRescue Linux 启动盘  地址 https://osdn.net/projects/systemrescuecd/storage/releases/7.01/systemrescue-7.01-amd64.iso 或  https://n3450.cloud/systemrescue-7.01-amd64.iso

3. 下载autorun脚本 https://rt1.jinss2.cf/autorun


### 开始制作启动盘和安装PVE：

1. 用 rufus U盘写入工具 将 systemrescue-7.01-amd64.iso 写入U盘 
2. U盘写入完成后, 复制 autorun 脚本 和 proxmox.img.gz 到U盘根目录
3. 插入U盘到 锐角云 HDMI口旁边的USB, 开机按F7选择U盘引导后 (一般U盘为第二项 UEFI：你的U盘名称 例如 SanDisk, Partition 1)。
4. 进入SystemRescue 菜单后 选择第二个项 Boot SystemRescue and Copy system to Ram (Copytoram) 进入, 然后 根据提示选择Y 安装PVE或n 退出。 随后耐心等待直至屏幕变化，设备重启。
5. 进入PVE的命令行环境后，使用用户名和密码为“root/password”进行登陆。  首次进入要执行一下 bash /reset.sh 来初始化一下。此时可以插入网线。
6. 修复bios没有电池导致时间丢失问题 和 同时设置网卡静态IP. 运行以下命令. 脚本每天会保存当前时间到文件, 断电重启后会通过crontab重启脚本读取文件设置系统时间,同时会提示设置IP。以后可以通过其他电脑在浏览器通过 PVE网页登陆方式：https://你设置的IP:8006，用户名/密码分别是“root/password”进行登陆。
```bash
wget --no-check-certificate https://rt1.jinss2.cf/date.sh && chmod +x ./date.sh && ./date.sh firstrun 
```
或
```bash
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/acuteangle/date.sh && chmod +x ./date.sh && ./date.sh firstrun 
```
