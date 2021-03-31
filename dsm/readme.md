# PVE 和 群晖DSM NAS 安装工具, FRP 内网穿透工具 一键安装管理脚本

### 运行方法 Installation 

#### linux系统下 通过 wget 命令安装 via wget to install script

```bash
wget --no-check-certificate -P /root https://raw.githubusercontent.com/jinwyp/one_click_script/master/dsm/pve.sh && chmod 700 /root/pve.sh && /root/pve.sh

```

#### DSM 群晖系统下 通过 wget 命令安装 via wget to install script

```bash
wget --no-check-certificate -P /tmp https://raw.githubusercontent.com/jinwyp/one_click_script/master/dsm/pve.sh && chmod 700 /tmp/pve.sh && /tmp/pve.sh

```


### 注意事项与常见问题 FAQ 

1. 群晖补丁需要用 ssh 工具登录到群晖的系统后运行使用. 请先在群晖系统 "控制面板->终端机和SNMP" 开启SSH, 然后用admin用户登录ssh后, 运行上面命令. 由于第一次使用admin登陆后, 默认admin没有写入当前的文件夹的权限,所以第一次运行的命令把脚本放到了/tmp目录下.  以后开启root登陆后,可以直接用上面linux的运行方法把脚放到/root目录下即可.

 

### 功能介绍 Feature 

![功能列表](https://github.com/jinwyp/one_click_script/blob/master/docs/pve1.png?raw=true)

![功能列表](https://github.com/jinwyp/one_click_script/blob/master/docs/pve2.png?raw=true)


