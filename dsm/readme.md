# PVE 和 群晖 安装工具


![功能列表](https://github.com/jinwyp/one_click_script/blob/master/docs/pve1.png?raw=true)


## 运行方法 Installation 


####  通过 curl 命令安装  via curl to install script

```bash
curl -o /tmp/pve.sh https://raw.githubusercontent.com/jinwyp/one_click_script/master/dsm/pve.sh && chmod +x /tmp/pve.sh && /tmp/pve.sh

```

或

#### 通过 wget 命令安装 via wget to install script

```bash
wget --no-check-certificate -P /tmp https://raw.githubusercontent.com/jinwyp/one_click_script/master/dsm/pve.sh && chmod +x /tmp/pve.sh && /tmp/pve.sh

```


## 注意事项与常见问题 FAQ 

1. 群晖补丁需要用 ssh 工具登录到群晖的系统后运行使用. 请先在群晖系统 "控制面板->终端机和SNMP" 开启SSH, 然后用admin用户登录ssh后运行上面命令
 


