# 锐角云安装PVE 最简单教程

### 准备工作
1. 下载 PVE镜像 proxmox.img.gz  地址 https://n3450.cloud/proxmox.img.gz
2. 下载 SystemRescue Linux 启动盘  地址 https://osdn.net/projects/systemrescuecd/storage/releases/7.01/systemrescue-7.01-amd64.iso 或  https://n3450.cloud/systemrescue-7.01-amd64.iso

3. 下载autorun脚本 https://rt1.jinss2.cf/autorun, 可选下载初始化脚本 https://rt1.jinss2.cf/date.sh 


### 开始制作启动盘和安装PVE：

1. 用 rufus U盘写入工具 将 systemrescue-7.01-amd64.iso 写入U盘 
2. U盘写入完成后, 复制 autorun 脚本 和 proxmox.img.gz 到U盘根目录
3. 插入U盘到 锐角云 HDMI口旁边的USB, 开机按F7选择U盘引导后 (一般U盘为第二项 UEFI：你的U盘名称 例如 SanDisk, Partition 1)。
4. 进入SystemRescue 菜单后 选择第二项 Boot SystemRescue and Copy system to Ram (Copytoram) 进入, 然后 根据提示选择Y 安装PVE或n 退出。 随后耐心等待直至屏幕变化，设备会自动重启。此时可以插入网线连接好路由器

5. 插入网线会通过dhcp获取ip的。进入PVE的命令行环境后，使用用户名和密码为"root/password"进行登陆。 首次进入要执行下面初始化脚本, 需要已经正常联网. 然后根据提示可以选择DHCP获取IP或手动指定IP地址。
```bash
wget --no-check-certificate https://rt1.jinss2.cf/date.sh && chmod +x ./date.sh && ./date.sh reset
```

如果没有联网,可以执行 bash /reset.sh 来初始化系统, 但会导致重启后获取不到IP连不上网, 请慎重使用。 所以没有联网推荐插入网线重启后运行上一条命令。

6. 如果第5步没有联网，重启后获取不到IP连不上网 解决方法. 下载脚本date.sh, 放到U盘, 插入到 HDMI口旁边的USB, 输入下面的命令. 加载U盘运行脚本，根据提示可以选择DHCP获取IP或手动指定IP地址。
```bash
mkdir -p /mnt/usb1/ 
mount /dev/sda1 /mnt/usb1
chmod +x ./mnt/usb1/date.sh && /mnt/usb1/date.sh firstrun
```

### date.sh 脚本 说明
1. date.sh 脚本会保存到/root/下，还修复了bios没有电池导致时间丢失问题  脚本每天会保存当前时间到文件, 断电重启后会通过crontab重启脚本读取文件设置系统时间,
```bash
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/acuteangle/date.sh && chmod +x ./date.sh && ./date.sh firstrun 
```

2. 以后使用其他电脑在浏览器就可以管理PVE,登陆方式：https://你设置的IP:8006，用户名/密码分别是"root/password"进行登陆。

3. 如果已经给机器加上了bios电池, 不需要再修复系统时间问题, 运行 ```crontab -r ```  清除自动运行修复时间的脚本, 注意 ```crontab -r ``` 会清除所有定时任务, 如果还有其他定时任务 请运行```crontab -e ```手动修改 删除或注释掉 包含 date.sh 的两行脚本即可  