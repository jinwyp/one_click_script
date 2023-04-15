# Easy install latest or LTS linux kernel and enable BBR or BBR plus

### [xray v2ray trojan 一键安装脚本](/README2.md)

## 目录 Table of Contents

* [Trojan 或 Trojan-go 和 V2ray 或 xray 一键安装脚本](/README2_CN.md)
* [安装 Linux 最新版内核或 LTS 内核, 安装支持 BBR Plus 内核](#kernel)
* [开启BBR 或 BBR plus 网络加速](#kernel)
* [安装 wireguard 和 Cloudflare WARP, 解锁 Netflix 区域限制 和 避免弹出Google人机验证](#Wireguard)
* [Netflix 非自制剧检测脚本 支持IPv6和 WARP Sock5 代理检测](#netflix-check)

## 功能说明 Features 
1. 安装各个版本的 Linux 内核 包括最新的5.16内核 和 所有LTS内核. 例如 5.10 LTS, 5.4 LTS, 4.19 LTS, 4.14 LTS  
2. 开启 BBR / BBR Plus / BBR2 网络加速, 切换 FQ / FQ-Codel / FQ-PIE / CAKE 队列调度算法. 
3. 支持 Debian9+, Ubuntu 16+, CentOS 7+ (AlmaLinux / Rocky Linux)
4. 安装 wireguard 和 Cloudflare WARP sock5 client 用于解锁 Netflix 和避免弹出Google人机验证


## Installation 安装方法  

#### Usage 脚本使用方法
```bash
bash <(curl -Lso- https://git.io/kernel.sh)
```
#### 通过 curl 命令安装  via curl to install script

```bash
curl -O https://raw.githubusercontent.com/jinwyp/one_click_script/master/install_kernel.sh && chmod +x ./install_kernel.sh && ./install_kernel.sh
```


#### 通过 wget 命令安装 Linux 内核 和 Wireguard  via wget to install script

```bash
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/install_kernel.sh && chmod +x ./install_kernel.sh && ./install_kernel.sh
```



![功能列表3](https://github.com/jinwyp/one_click_script/blob/master/docs/readme3.png?raw=true)




## 使用说明 Usage 

### kernel
### 安装 linux 新版内核 开启BBR 或 BBR Plus 加速


1. CentOS / AlmaLinux / Rocky Linux 系统安装新版 linux 内核. 运行脚本后 请选择31 安装官方源最新版5.16内核 或选择35 安装 LTS 5.10 内核 推荐安装 LTS 5.10. 根据提示需要重启2次 完成内核安装。
2. Debian / Ubuntu 系统安装新版 linux 内核. 运行脚本后 Debian 请选择41 安装 LTS 5.10 内核, Ubuntu 请选择45 安装 LTS 5.10 内核. 根据提示需要重启2次 完成内核安装。
3. 开启 BBR 网络加速. 完成上面更换新内核后, 重新运行脚本后 选择2 然后根据提示选择 BBR 加速, 推荐使用BBR + Cake 组合算法.
4. 安装BBR Plus 内核并开启 BBR Plus. 运行脚本后 选择61 安装原版4.14.129版本 BBR Plus 内核, 或选择66 安装5.10 LTS BBR Plus内核. 安装完成重启2次后, 重新运行脚本后 选择3 根据提示开始 BBR Plus. 
5. 注意安装过程中 如果弹出大框的英文提示(下面有示例图) "安装linux内核有风险是否终止", 要选择" NO" 不终止. 安装完毕会重启VPS.

![注意 安装BBR plus](https://github.com/jinwyp/one_click_script/blob/master/docs/debian.jpg?raw=true)
![注意 安装BBR plus](https://github.com/jinwyp/one_click_script/blob/master/docs/kernel.png?raw=true)
![注意 安装BBR plus](https://github.com/jinwyp/one_click_script/blob/master/docs/ubuntu.png?raw=true)

6. 安装 XanMod 内核并开启 BBR2. Debian / Ubuntu 系统 运行脚本后 请选择51 安装 XanMod 内核, 安装完成重启后, 重新运行脚本后 选择2 然后根据提示选择 BBR2 加速.


### Wireguard
### 解锁 Netflix 等流媒体网站的区域限制 和 避免弹出 Google reCAPTCHA 人机验证

1. 使用Cloudflare WARP sock5 方式解锁. 运行脚本后 选择11 安装 Cloudflare WARP 官方 linux client sock5 代理, 安装完成后系统已经启动 WARP的sock5 代理. 重新运行脚本 选择21 测试一下 WARP sock5 是否已经解锁Netflix.
2. 使用Cloudflare WARP IPv6 方式解锁. 运行脚本后 选择12 安装 Wireguard 和 Cloudflare WARP. 安装成功后系统会启用IPv6, 但默认还是优先使用IPv4 访问网络. 重新运行脚本 选择21 测试一下 IPv6 是否已经解锁Netflix.
3. 解锁 Netflix 等流媒体网站. 通过本项目内的[另一脚本](/README_CN.md) 安装V2ray, 安装过成功中根据提示设置域名分流规则, 让流媒体网站使用IPv6 或 WARP sock5解锁即可. 
4. 解锁 Google reCAPTCHA 人机验证. 通过本项目内的[另一脚本](/README_CN.md) 安装V2ray, 安装过成功中根据提示设置域名分流规则, 让Google网站使用IPv6 或 WARP sock5解锁即可. 推荐使用 IPv6 来避免 Google reCAPTCHA 人机验证.




## Netflix-Check
### Netflix 非自制剧解锁 检测脚本 支持IPv6 和 Cloudflare WARP Sock5 代理检测

#### 通过 wget 命令安装 via wget to install script

```bash
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/netflix_check.sh && chmod +x ./netflix_check.sh && ./netflix_check.sh
```


####  通过 curl 命令安装 via curl to install script

```bash
curl -O https://raw.githubusercontent.com/jinwyp/one_click_script/master/netflix_check.sh && chmod +x ./netflix_check.sh && ./netflix_check.sh
```



## 注意事项与常见问题 FAQ 

1. Netflix 检测解锁脚本无法测试 使用V2ray路由规则的解锁. 就是说使用本脚本安装过v2ray已经解锁了Netflix, 但用检测解锁脚本检测的结果还是会显示没有解锁, 就是无法测出已解锁Netflix. 可以把检测脚本运行在 V2ray客户端机器上, 则能检测成功解锁. Netflix 检测解锁脚本只能运行在Mac或linux 平台. Windows平台可以使用linux ubuntu 子系统来运行 Netflix 检测解锁脚本.

