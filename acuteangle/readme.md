# 锐角云安装PVE 最简单教程

## 方法1 自动DD方法
### 准备工作
1. 下载 PVE 6.2 镜像 proxmox.img.gz  地址 https://n3450.cloud/proxmox.img.gz 
2. 下载 SystemRescue Linux 启动盘  地址 https://nchc.dl.sourceforge.net/project/systemrescuecd/sysresccd-x86/9.04/systemrescue-9.04-amd64.iso
3. 下载 autorun 脚本 https://raw.githubusercontent.com/jinwyp/one_click_script/master/acuteangle/autorun , 页面打开后另存为autorun. 注意不要有扩展名 (autorun.txt 这种是错误的)
4. 下载初始化脚本 https://raw.githubusercontent.com/jinwyp/one_click_script/master/acuteangle/date.sh, 页面打开后另存为date.sh 扩展名是.sh

![zip1](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/zip1.png?raw=true)



### 开始制作启动盘和安装PVE

1. 用 rufus 或 balenaEtcher(推荐 https://www.balena.io/) U盘写入工具 将 systemrescue-9.04-amd64.iso 写入U盘 
2. U盘写入完成后, 复制 autorun 脚本 和 proxmox.img.gz 到U盘根目录
3. 插入U盘到 锐角云 HDMI口旁边的USB, 开机按F7选择U盘引导后 (一般U盘为第二项 UEFI：你的U盘名称 例如 SanDisk, Partition 1)。
4. 进入SystemRescue 菜单后 选择第二项 Boot SystemRescue and Copy system to Ram (Copytoram) 进入, 然后会自动运行autorun脚本, 根据提示选择Y 安装PVE或n 退出。 随后耐心等待直至屏幕变化，设备会自动重启。此时可以插入网线连接好路由器.

5. 插入网线会通过dhcp获取ip的。进入PVE的命令行环境后，使用用户名和密码为"root/password"进行登陆。 首次进入要执行下面初始化脚本, 需要已经正常联网. 然后根据提示可以选择DHCP获取IP或手动指定IP地址。
```bash
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/acuteangle/date.sh && chmod +x ./date.sh && ./date.sh reset
```

如果没有联网,可以执行 bash /reset.sh 来初始化系统, 但会导致重启后获取不到IP连不上网, 请慎重使用。 所以没有联网推荐插入网线重启后运行上一条命令。


6. 如果第5步没有联网，重启后获取不到IP连不上网 解决方法. 下载脚本date.sh, 放到U盘, 插入到 HDMI口旁边的USB, 输入下面的命令. 加载U盘运行脚本，根据提示可以选择DHCP获取IP或手动指定IP地址。
```bash
mkdir -p /mnt/usb1/ 
mount /dev/sda1 /mnt/usb1
chmod +x ./mnt/usb1/date.sh && /mnt/usb1/date.sh firstrun
```
7. 一切完成后访问 http://IP:8006 进入后台

### date.sh 脚本 说明
1. date.sh 脚本会保存到/root/下，还修复了bios没有电池导致时间丢失问题  脚本每天会保存当前时间到文件, 断电重启后会通过crontab重启脚本读取文件设置系统时间,
```bash
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/acuteangle/date.sh && chmod +x ./date.sh && ./date.sh firstrun 
```

2. 以后使用其他电脑在浏览器就可以管理PVE,登陆方式：https://你设置的IP:8006，用户名/密码分别是"root/password"进行登陆。

3. 如果已经给机器加上了bios电池, 不需要再修复系统时间问题, 运行 ```crontab -r ```  清除自动运行修复时间的脚本, 注意 ```crontab -r ``` 会清除所有定时任务, 如果还有其他定时任务 请运行```crontab -e ```手动修改 删除或注释掉 包含 date.sh 的两行脚本即可  



## 方法2 修改代码方法让PVE 安装到EMMC 硬盘上

### 准备工作
1. 下载 PVE 7.1 https://n3450.cloud/proxmox-ve_7.1-2-emmc.iso (已经修改好可以从EMMC安装PVE的镜像, 后面不再需要修改代码) 
2. 或从 官方下载 [PVE 7.2](https://www.proxmox.com/en/downloads?task=callelement&format=raw&item_id=654&element=f85c494b-2b32-4109-b8c1-083cca2b7db6&method=download&args[0]=3fe6f5552df740d7a85a879ffe42dc14) 

### 开始制作启动盘和安装PVE
1. 用 balenaEtcher(推荐) U盘写入工具 将 proxmox-ve_7.1-2-emmc.iso 或 官方PVE的 proxmox-ve_7.2-1.iso 写入U盘 
2. 插入U盘到 锐角云 HDMI口旁边的USB, 开机按F7选择U盘引导后 (一般U盘为第二项 UEFI：你的U盘名称 例如 SanDisk, Partition 1)。
3. 启动 PVE 安装程序后 进入安装初始界面后 点击 Install Proxmox VE (Debug mode), 在第一次提示你可以输入命令的时候输入 Ctrl-D ，
![pve1](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/pve1.jpg?raw=true)


4. 继续安装过程, 在第二次提示你可以输入命令的时候输入命令 vi /usr/bin/proxinstall. 编辑文件（或者使用其他文字编辑器如 nano）. 输入 /unable to get device 定位到对应位置 , 找到如下代码:
```

    } elsif ($dev =~ m|^/dev/[^/]+/hd[a-z]$|) {
        return "${dev}$partnum";
    } elsif ($dev =~ m|^/dev/nvme\d+n\d+$|) {
        return "${dev}p$partnum";
    } else {
        die "unable to get device for partition $partnum on device $dev\n";
    }

```

修改为下面代码 (增加  elsif ($dev =~ m|^/dev/mmcblk\d+$|)  部分代码 )

```
    } elsif ($dev =~ m|^/dev/[^/]+/hd[a-z]$|) {
        return "${dev}$partnum";
    } elsif ($dev =~ m|^/dev/nvme\d+n\d+$|) {
        return "${dev}p$partnum";

    } elsif ($dev =~ m|^/dev/mmcblk\d+$|) {
        return "${dev}p$partnum";

    } else {
        die "unable to get device for partition $partnum on device $dev\n";
    }

```

输入:wq, 保存退出后, 然后输入 Ctrl-D ，继续安装过程. 此时应该进入了正常的安装程序，

![pve2](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/pve2.jpg?raw=true)

![pve3](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/pve3.jpg?raw=true)



4. 硬盘选择的时候选择 /dev/mmcblk1 (没有 bootX 后缀). 点击下图 options (建议关闭 swap, swapsize设置为0, 延长EMMC寿命. maxvz 也推荐设置为0, 毕竟只有64G, 不需要分太多卷). 最后安装完成后输入 Ctrl-D ，重启系统.
![pve9](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/pve9.jpg?raw=true)


#### 注意 解决 Proxmox VE 无法安装到 eMMC 上的问题

1. 如果使用PVE官方6.4的iso安装 默认无法安装到EMMC存储上 需要 修改代码 可以参考这篇文章 https://lookas2001.com/%E8%A7%A3%E5%86%B3-proxmox-ve-%E6%97%A0%E6%B3%95%E5%AE%89%E8%A3%85%E5%88%B0-emmc-%E4%B8%8A%E7%9A%84%E9%97%AE%E9%A2%98/



