# 锐角云安装PVE 最简单教程

## Table of Contents

* [方法1 自动DD方法)](#autodd)
* [方法2 修改代码方法 让PVE 安装到EMMC 硬盘上](#pveemmc)
* [在 PVE中 安装Openwrt](#openwrt)



## AutoDD
## 方法1 自动DD方法
### 准备工作
1. 下载 PVE 6.2 镜像 proxmox.img.gz(该镜像已经被修改 可以支持emmc并且删除了无用lvm分区)  地址 https://n3450.cloud/proxmox.img.gz 
2. 下载 SystemRescue Linux 启动盘  地址 https://nchc.dl.sourceforge.net/project/systemrescuecd/sysresccd-x86/9.04/systemrescue-9.04-amd64.iso
3. 下载 autorun 脚本 https://raw.githubusercontent.com/jinwyp/one_click_script/master/acuteangle/autorun , 页面打开后另存为autorun. 注意不要有扩展名 (autorun.txt 这种是错误的)
4. 下载初始化脚本 https://raw.githubusercontent.com/jinwyp/one_click_script/master/acuteangle/date.sh, 页面打开后另存为date.sh 扩展名是.sh



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





## pveemmc
## 方法2 修改代码方法让PVE 安装到EMMC 硬盘上

### 准备工作
1. 下载 PVE 7.1 https://n3450.cloud/proxmox-ve_7.1-2-emmc.iso (已经修改好可以从EMMC安装PVE的镜像, 后面不再需要修改代码) 
2. 或从 官方下载 [PVE 7.2-1](https://www.proxmox.com/en/downloads?task=callelement&format=raw&item_id=654&element=f85c494b-2b32-4109-b8c1-083cca2b7db6&method=download&args[0]=71d0b7259765b2c03267418eb4d7889e) 

### 开始制作启动盘和安装PVE
1. 用 balenaEtcher(推荐) U盘写入工具 将 proxmox-ve_7.1-2-emmc.iso 或 官方PVE的 proxmox-ve_7.2-1.iso 写入U盘 
2. 插入U盘到 锐角云 HDMI口旁边的USB, 开机按F7选择U盘引导后 (一般U盘为第二项 UEFI：你的U盘名称 例如 SanDisk, Partition 1)。
3. 启动 PVE 安装程序后 进入安装初始界面后 先选 Advanced Options, 然后点击 Install Proxmox VE (Debug mode), 在第一次提示你可以输入命令的时候输入 Ctrl-D ，
![pve1](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/pve1.jpg?raw=true)


4. 继续安装过程, 在第二次提示你可以输入命令的时候输入命令 vi /usr/bin/proxinstall. 编辑文件（或者使用其他文字编辑器如 nano）. 
![pve2](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/pve2.jpg?raw=true)

5. 输入 /unable to get device 回车后 定位到对应位置, 输入i进入编辑模式 , 找到如下代码: (这里对VIM编辑器不熟悉的建议去学一下VIM的基本操作. VIM默认有两种模式 打开文件后默认是普通模式 可以控制光标移动,搜索但不能编辑, 输入i 进入编辑模式 可以编辑文件但无法保存, 按ESC键返回到普通模式. 普通模式输入/是搜索, 输入:wq是保存退出)
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

具体操作如下: 在普通模式移动到/dev/nvme那行输入2yy 就是复制2行的意思, 然后移动光标到else行 键入p 就是粘贴, 然后输入i 进入编辑模式 编辑成/dev/mmcblk\d+$, 然后按ESC返回到普通模式, 输入:wq, 保存退出后. 然后输入 Ctrl-D ，继续安装过程. 此时应该进入了正常的安装程序，

![pve3](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/pve3.jpg?raw=true)



6. 硬盘选择的时候选择 /dev/mmcblk1 (没有 bootX 后缀). 点击下图 options (建议关闭 swap, swapsize设置为0, 延长EMMC寿命. maxvz 也推荐设置为0, 毕竟只有64G, 不需要分太多卷). 最后安装完成后输入 Ctrl-D ，重启系统. 完成后访问 http://IP:8006 进入后台
![pve9](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/pve9.jpg?raw=true)

7. 后续操作 运行以下脚本, 更新软件源, 删除逻辑卷 /pve/data 合并磁盘等操作 (安装完/dev/pve/root 只有14G).

```bash
wget --no-check-certificate -P /root https://raw.githubusercontent.com/jinwyp/one_click_script/master/dsm/pve.sh && chmod 700 /root/pve.sh && /root/pve.sh

```

#### 注意 解决 Proxmox VE 无法安装到 eMMC 上的问题

1. 如果使用PVE官方6.4的iso安装 默认无法安装到EMMC存储上 需要 修改代码 可以参考这篇文章 https://lookas2001.com/%E8%A7%A3%E5%86%B3-proxmox-ve-%E6%97%A0%E6%B3%95%E5%AE%89%E8%A3%85%E5%88%B0-emmc-%E4%B8%8A%E7%9A%84%E9%97%AE%E9%A2%98/



## 其他工作

1. 如果不能联网, 因为PVE是基于 Debian系统的, 对linux 熟悉的可以直接 修改 /etc/network/interfaces 文件. 同时也要想要修改/etc/issue 和 /etc/hosts. 不熟悉linux的可以用上面的date.sh 脚本修改.

2. PVE的硬盘盘符. 因为锐角云只有一个64G的EMMC硬盘 物理设备为 /dev/mmcblk1. 安装完PVE后会建立3个物理分区 /dev/mmcblk1p1 /dev/mmcblk1p2 /dev/mmcblk1p3, 其中前2个为系统引导分区 不要修改, PVE的主要文件都在 /dev/mmcblk1p3 分区上. 可以运行命令 lsblk 或 blkid 查看
![local1](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/local1.jpg?raw=true)

3. PVE的LVM LVM逻辑卷. 首先科普一下 [linix的 LVM 磁盘管理](https://www.yisu.com/zixun/3865.html) [LVM 科普文章2](https://zhuanlan.zhihu.com/p/62597195). 简单来讲就是物理卷PV(就是/dev/mmcblk1p3分区), 逻辑卷组VG 和 逻辑卷LV. PVE正常通过官方ISO安装 就是用上面的第二种方法安装, 默认会有3个LV: /dev/pve/root /dev/pve/data /dev/pve/swap . 如果安装过成功中swap设置为0 就不没有第三个 /dev/pve/swap 了. 通过运行 命令 lvdisplay 可以查看这3个LV的信息. 在PVE的概念里面 通过 数据中心-> 存储 里面可以看到有local (对应 /dev/pve/root) 和 local-lvm (对应 /dev/pve/data) 两个储存盘. 

![local2](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/local2.jpg?raw=true)


由于锐角云只有64G, 建议合并成只有一个LV 都是/dev/pve/root. 运行下面脚本选择3 合并逻辑卷. 合并完成后就只有一个 local (对应 /dev/pve/root) 储存盘了 如上图


```bash
wget --no-check-certificate -P /root https://raw.githubusercontent.com/jinwyp/one_click_script/master/dsm/pve.sh && chmod 700 /root/pve.sh && /root/pve.sh

```

4. 通过再次运行上面脚本 选择1 更新软件源


## Openwrt 
## 在 PVE中 安装Openwrt 

### 准备工作
1. 下载 openwrt X86的 镜像 可以使用esir的版本 Stable v21.02.3 0818 [官方下载地址](https://drive.google.com/drive/folders/1amWhdhq0XhQR4tNyFcouB49-Uf4VsUrL).  这里选择的是 sirpdboy 编译的版本,比esir速度快不少[sirpdboy官方下载地址](https://www.123pan.com/s/dS5A-Hoxqd?pwd=MwhD#MwhD)

2. 一般 openwrt X86 镜像有2种 uefi 引导和 传统的legacy引导. 如果不使用PVE直接把openwrt安装到锐角云上必须使用UEFI版本,  由于锐角云只支持UEFI引导, 使用legacy版本直接安装会导致锐角云变砖.   而这里如果用PVE创建虚拟机安装openwrt, 虚拟机的bios是支持legacy的, 所以2种引导都可以,这里选择legacy版本. esir版本的固件下载文件 openwrt-21.02.3-x86-64-generic-squashfs-legacy.img.gz . sirpdboy版本的固件下载文件为 20220919-Ipv6-Super-5.15-x86-64-generic-squashfs-rootfs.img.gz

3. 开始创建虚拟机. 点击右上角 "创建虚拟机" 按钮 输入名称 例如OpenWRTX86. 点击勾选 下面的高级选项, 勾选开机自启动.  点击 下一步.  选择不使用任何介质, 因为.img.gz的格式PVE无法直接使用需要转换. 客户机操作系统不用改动,点击下一步. 然后系统菜单直接点击下一步. 然后磁盘菜单 删除已有的磁盘 不需要任何磁盘. 因为稍后会导入img.gz镜像. 点击下一步进入CPU菜单

![vm1](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/vm1.jpg?raw=true)

![vm2](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/vm2.jpg?raw=true)

4. CPU菜单 可以选择2核, 也可以根据情况添加更多的核. 锐角云是4核8G内存. 如果需要在openwrt里面安装docker 可以增加CPU核数或内容, 但不建议, 如果要使用docker建议在创建另外的linux虚拟机. 类别选host. 点击勾选 下面的高级选项, 开启 aes.  点击下一步 内存设置为1024 除非要在openwrt里面跑docker, 否则1024(1G) 已经够用了. 点击下一步进入网络, 一切都默认后继续点击直到完成.

![vm3](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/vm3.jpg?raw=true)

5. 把之前下载的 20220919-Ipv6-Super-5.15-x86-64-generic-squashfs-rootfs.img.gz 解压出来并改名为 openwrt.img (原文件名太长了,改名后方便以后打字输入). 点击 PVE 节点 -> local (PVE) 储存盘 -> ISO镜像 点击上传按钮 在弹出选择文件框 选择 openwrt.img文件上传.  上传成功后会弹出信息提示 记住上传的文件路径 例如  target file: /var/lib/vz/template/iso/openwrt.img

![img1](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/img1.jpg?raw=true)

![img2](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/img2.jpg?raw=true)

6. 把镜像转成虚拟磁盘并导入到虚拟机. 选择“pve”节点 > shell > 输入以下命令并回车：qm importdisk 100 /var/lib/vz/template/iso/openwrt.img local-lvm 
这里注意 100 是相应的虚拟机的ID 需要修改成对应的ID. local-lvm 是PVE储存盘, 也有可能是local. 如果弄不明白命令, 直接用我下面的脚本 选择14 使用 qm importdisk 命令导入. 运行下面的脚本选择14后 根据提示输入文件名 openwrt.img 和 虚拟机ID 100 然后回车 完成导入。

```bash
wget --no-check-certificate -O /root/pve.sh https://raw.githubusercontent.com/jinwyp/one_click_script/master/dsm/pve.sh && chmod 700 /root/pve.sh && /root/pve.sh

```

7. 导入成功后在 Openwrt 虚拟机的“硬件”选项卡就能看到一个“未使用的磁盘0”，选中它 双击弹出配置窗口，总线/设备类型选“sata”，最后点击添加。然后继续给磁盘扩容. 由于openwrt制作的镜像可能体积较小,导致以后虚拟机磁盘空间不足, 需要进行一下扩容 一般增加1G空间足够给openwrt用了

![img3](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/img3.jpg?raw=true)

![img32](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/img32.jpg?raw=true)

![img33](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/img33.jpg?raw=true)

8. 切换到虚拟机的“选项”选项卡，双击“引导顺序”，第一引导项拖拽选‘sata0’ 勾选 已启用 点击 OK
![img4](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/img4.jpg?raw=true)


9. 启动虚拟机, 点击 openwrt 虚拟机 “控制台”查看启动状态. 按一下回车 显示 Openwrt 的图标表明启动正常. esir固件默认后台地址：192.168.5.1 密码：空 . sirpdboy 固件默认后台地址：192.168.8.1 密码无
![boot1](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/boot1.jpg?raw=true)

10. 不知道openwrt IP地址的也可以 输入命令 ip addr 查看. 
![boot2](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/boot2.jpg?raw=true)


11. 下一步就是改电脑的IP为192.168.5.2,让电脑和openwrt 在同一个网段. 或者觉得改电脑IP麻烦可以修改openwrt的IP.  在虚拟机的 “控制台” 输入命令 vi /etc/config/network 找到 config interface 'lan' 下面的IP.  编辑openwrt的IP 192.168.5.1 或 192.168.8.1 那行, 改为你想要的IP  输入:wq 保存后 重启openwrt虚拟机. 输入 reboot 命令即可重启. 
![boot3](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/boot3.jpg?raw=true) 

12. 重启后就可以在电脑浏览器上打开你设定的 ip 例如 http://192.168.1.6/ 密码：空 进入管理openwrt了.

13. 后续操作: 由于锐角云只有一个网卡, 可以在 网络 -> 接口 里面删除WAN. sirpdboy 固件里面还可以通过向导模式设置旁路由. 具体单臂网关服务器如何设置可以参考 [DNS设置方法](https://github.com/jinwyp/one_click_script/blob/master/DNS.md#mosdns). 建议使用锐角云做DHCP服务器 (锐角云的DHCP优先级高, 在DHCP勾选 强制), 并保留原路由器的DHCP功能. 使主路由的DHCP和锐角云的DHCP同时工作, 这样即使锐角云挂了也可以正常上网. 
![setup1](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/setup1.jpg?raw=true) 
![setup2](https://github.com/jinwyp/one_click_script/blob/master/acuteangle/setup2.jpg?raw=true) 

