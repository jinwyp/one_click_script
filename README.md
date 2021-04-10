# Easy install v2ray (xray) and trojan (trojan-go) script (ultimate script for all condition)


## 目录 Table of Contents

* [Trojan 和 V2ray xray 一键安装脚本](#installation-安装方法)
* [安装 最新版和LTS Linux 内核, BBR 和 BBR Plus 内核](#installation-linux-kernel-wireguard)
* [一键安装 wireguard, 解决google 验证码和 Netflix 限制问题](#installation-linux-kernel-wireguard)
* [V2board 服务器端 V2Ray-Poseidon 或 soga 一键安装脚本](#installation-soga)
* [PVE Proxmox VE虚拟机 群晖NAS 安装工具脚本](/dsm/readme.md)
* [FRP 内网穿透工具 一键安装脚本](/dsm/readme.md)
* [锐角云 自动安装PVE 工具脚本](/acuteangle/readme.md)


## 功能说明 Features 

1. 支持 trojan，trojan-go 和 v2ray, xray 的安装 升级 卸载. 卸载后不留任何痕迹, 方便重复安装.
2. 支持 trojan 或 trojan-go 与 v2ray 共存, nginx全面支持TLS1.3 保证安全性, 支持SNI分流
3. 可以仅安装 trojan 或 v2ray, 可以不安装nginx. 方便与宝塔面板或现有网站共存.
4. 支持 v2ray 和 xray 新的vless协议, 支持v2ray作为前端 监听443端口 同时转发trojan 和 websocket 
5. 支持 trojan-go websocket 模式, 可以选择是否支持CDN (websocket)
6. 默认会创建10个以上用户账号, 还能创建指定前缀的密码, 方便用户使用.
7. trojan 和 v2ray 可视化管理面板安装. 
8. 一键安装wireguard, 解决google 验证码和 Netflix 限制问题
9. 支持 一键安装 v2board 面板的服务器端 V2Ray-Poseidon 或 soga 
12. 本脚本没有偷跑服务器流量的网页或其他屏蔽bt流量的等限制. 默认网页仅为bootstarp最简单的模板
13. 本脚本所使用端口除443和80外都是随机生成, 保证安全性, 而其他脚本写死固定端口容易被检测
14. 本脚本不推荐安装多种v2ray的多种协议共存, 协议越多安全性越低, 而且也不会提高速度, 没有必要使用多合一的脚本同时安装多个协议

## Features English 
1. Install V2Ray or Xray using VLESS or VMess, support all condition: VLESS+TCP+TLS / VLESS+Websocket+TLS(CDN) / VMess+TCP+TLS / VMess+Websocket+TLS(CDN)  
2. Using Trojan or Nginx or v2ray-core / Xray-core as frontend listening port 443
3. Install trojan or trojan-go and V2Ray or Xray on the same server to support all protocol.
4. Support Debian9+, Ubuntu 16+ and CentOS 7+ operation systems
5. install wireguard and wgcf to solve google CAPTCHA and netflix ip unlock

## Installation 安装方法  

#### 通过 wget 命令安装 via wget to install script

```bash
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/trojan_v2ray_install.sh && chmod +x ./trojan_v2ray_install.sh && ./trojan_v2ray_install.sh

```


![功能列表](https://github.com/jinwyp/one_click_script/blob/master/docs/readme.png?raw=true)

![功能列表2](https://github.com/jinwyp/one_click_script/blob/master/docs/readme2.png?raw=true)

![功能列表3](https://github.com/jinwyp/one_click_script/blob/master/docs/readme3.png?raw=true)



## Installation Linux kernel Wireguard 

#### 通过 wget 命令安装 Linux 内核 和 Wireguard 

```bash
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/install_kernel.sh && chmod +x ./install_kernel.sh && ./install_kernel.sh

```


## 使用说明 Usage 

### 安装命令行方式 启动 trojan 或 v2ray

1. 该步骤可省略. 如果是使用google cloud 谷歌云服务器，默认无法使用root账号登陆， 可以选择32 开启root用户登录. 建议使用root用户运行该脚本. 安装bbr plus 需要root权限, 默认认为使用root执行, 非root用户请手动添加sudo执行 ```sudo ./tcp.sh ```和 ```sudo ./trojan_v2ray_install.sh ``` 脚本. （注意 证书申请也需要用root用户而不建议用sudo  [acme.sh文档说明](https://github.com/acmesh-official/acme.sh/wiki/sudo)  ).
2. 安装 BBR plus. 运行脚本 ```./trojan_v2ray_install.sh ``` 选择1 然后选择31 安装 BBRplus 4.14,129 版内核 或 选择37 安装 BBRplus 5.10 版内核, 注意安装过程中会弹出大框的英文提示(下面有示例图)"安装linux内核有风险是否终止", 要选择" NO" 不终止. 安装完毕会重启VPS
3. 使用BBRplus版加速. 重新登录VPS后, 重新运行脚本 ```./trojan_v2ray_install.sh ```  选择1 然后 选择3 使用BBRplus版加速. 
4. 该步骤可省略. 选择31, 安装 oh-my-zsh. 这样以后登录有命令提示, 方便新手操作. 安装完成后请退出VPS, 命令为```exit```.  重新登录VPS后继续下面操作. 
5. 安装 trojan 或 v2ray. 根据提示 重新运行脚本 ```./trojan_v2ray_install.sh ```  选2 安装trojan, 或选6 安装trojan-go, 或选12 安装v2ray, 或选15 同时安装trojan和v2ray， 或选18 或19 同时安装trojan-go和v2ray.  强烈建议：如果VPS线路速度可以保证，不需要CDN，强烈建议选2 只安装trojan或只安装6 trojan-go (trojan-go速度已经很快了). 需要CDN可以选12只安装V2ray.  协议安装的越多安全性越低,而且也不会提高速度,适合自己的软件装一种最好. 完全没有必要使用多合一的脚本同时安装多个协议

6. 第一步安装 BBR plus 时出现的提示 "是否终止删除内核" 请选择 "NO". 就是要卸载掉目前的内核. 
![注意 安装BBR plus](https://github.com/jinwyp/one_click_script/blob/master/docs/debian.jpg?raw=true)
![注意 安装BBR plus](https://github.com/jinwyp/one_click_script/blob/master/docs/kernel.png?raw=true)
![注意 安装BBR plus](https://github.com/jinwyp/one_click_script/blob/master/docs/ubuntu.png?raw=true)


### 安装管理面板 Install web admin panel

1. 在没有安装任何 trojan 和 v2ray 的新机器上(即没有执行过第5步, 执行过可以选择卸载), 选择29 进入子菜单安装 trojan 或 v2ray 可视化管理面板。(如果之前通过其他脚本安装过,再安装可视化管理面板则极易产生问题)
2. 选择29后 然后再选择1 安装trojan-web可视化管理面板(建议使用centos7系统).根据提示输入域名后, 继续根据提示再选择1.Let's Encrypt 证书, 申请证书成功后. 继续根据提示再选择1.安装docker版mysql(mariadb). ariadb启动成功后,继续根据提示输入第一个trojan用户的账号密码,回车后出现"欢迎使用trojan管理程序" 需要不输入数字直接按回车,这样继续安装nginx直到完成. nginx安装成功会显示可视化管理面板网址,请保存下来. 如果没有显示管理面板网址则表明安装失败. 
3. 选择29后 然后再选择6 安装v2ray-ui可视化管理面板. 安装成功后可以再次运行本脚本选择29后在选择11申请域名SSL证书. 然后再可视化管理面板新建添加vless账号或trojan账号, 填入证书文件路径 即可同时支持trojan和v2ray.

### 高级用法 Advanced Usage 与现有网站共存

1. 如果机器上已经有nginx或已有网站服务, 或是与宝塔面板共同使用, 可以运行脚本后选择30, 然后单独安装不带有nginx的版本。 选择30后再选15, 则V2ray运行在其他端口没有加密, 然后在宝塔面板或nginx自行修改配置, 让nginx服务于443 https端口, 根据指定的url路径转发到V2ray 端口, 起到加密作用。
2. 选择30后 再选择12-14 安装trojan或trojan-go, 这样让trojan或trojan-go服务于443 https端口, 与现有的nginx或网站共存, nginx需要修改配置只监听80端口即可。https ssl加密由trojan或trojan-go提供。
3. 选择30后, 再选择13或14后仅安装trojan-go. 必须保证本机80端口有监听, 否则trojan-go无法启动. 这是trojan-go的一个fallback功能, 非trojan协议的流量会转发到remote_addr和remote_port指定这个HTTP服务器的地址. Trojan-Go将会测试这个HTTP服务器是否工作正常，如果不正常，Trojan-Go会拒绝启动. [参考trojan-go官方文档](https://p4gefau1t.github.io/trojan-go/basic/config/) 
4. 选择30后 再选择16-24 安装V2ray或Xray, 这样让V2ray或Xray 的 Vless协议服务于443 https端口, 与现有的nginx或网站共存, nginx需要修改配置只监听80端口即可。https ssl加密由V2ray或Xray 的 Vless协议提供。 推荐选择20的 Xray的Xtls-direct 模式速度最快
5. 以上安装都可以选择是否申请证书, 如果已有证书可以不在安装过程中申请, 或多次安装本脚本也可以不需要再次申请。证书位置在 /root/website/cert/fullchain.cer 和 /root/website/cert/private.key, 可以手动放置


## 注意事项与常见问题 FAQ 

1. 免费域名可以使用 [freenom](https://www.freenom.com/zh/index.html?lang=zh). 注册freenom时需要使用美国IP,否则无法通过注册邮件验证. 请自行搜索教程.
2. 使用脚本安装时请先关闭CDN, cloudflare.com 中DNS设置页面, 二级域名设置为DNS only 为关闭CDN. 安装v2ray或trojan-go完毕后 可以开启CDN 设置为Proxied 即可. trojan目前不支持CDN, trojan-go 默认安装设置为不支持CDN,可以在安装过程中选择支持CDN.

![注意 cloudflare CDN](https://github.com/jinwyp/one_click_script/blob/master/docs/cloudflare1.jpg?raw=true)

3. 以下是Cloudflare CDN 的worker 加速脚本, 请把域名替换成自己的vps的域名. 然后在Cloudflare新建worker 添加即可. 可以通过下面3个工具任选其一, [better-cloudflare-ip], [CloudflareScanner], [CloudflareSpeedTest],  在你自己的客户端机器上运行, 找出距离你最快的 cloudflare 的CDN IP, 在v2ray或trojan-go支持CDN的配置中填入该IP即可.
```
addEventListener(
    "fetch", event => {
        let url = new URL(event.request.url);
        url.hostname = "yourdomain.xxx.xx";
        url.protocol = "https";
        let request = new Request(url, event.request);
        event.respondWith(
            fetch(request)
        )
    }
)
```

## 关于Let's Encrypt证书
本脚本使用的acme.sh来申请的Let's Encrypt免费证书。三个月需要续期，本脚本通过cron自动完成续期的，无需用户操作。但Let's Encrypt 申请证书有一些限制，如下：

Let's Encrypt证书申请频率的限制

1. 同一个主域名一周之内只能申请50个证书
2. 每个账号下每个域名每小时申请验证失败的次数为5次
3. 每周只能创建5个重复的证书，即使是通过不同的账号进行创建
4. 每个账号同一个IP地址每3小时最多可以创建10个证书
5. 每个多域名（SAN） SSL证书（不是通配符域名证书）最多只能包含100个子域
6. 更新证书没有次数的限制，但是更新证书会受到上述重复证书的限制
7. 如果提示证书申请失败，可以尝试更换域名再试（添加或换不同的二级域名，也算是新域名）
8. 同一IP地址，在短时间内过于频繁的申请证书，也会被限制，此时更换域名也无法申请成功，只能等待一段时间，或者更换Ip.


## 特别感谢 Special Thanks

1. 脚本感谢 https://github.com/sprov065/v2-ui 
2. 脚本感谢 https://github.com/Jrohy/trojan 
3. 脚本感谢 https://github.com/v2fly/v2ray-core
4. 脚本感谢 https://github.com/XTLS/Xray-core
5. 脚本感谢 https://github.com/trojan-gfw/trojan
6. 脚本感谢 https://github.com/p4gefau1t/trojan-go
7. 脚本感谢 https://github.com/ylx2016/Linux-NetSpeed
8. 脚本感谢 秋水逸冰、Atrandys、V2ray官方 和 波仔分享 等 
9. 脚本感谢 JCNF的博客 https://ybfl.xyz/111.html



## Installation Soga 
## 安装其他 Linux 软件 和 V2board 服务器端 V2Ray-Poseidon 或 soga 

#### via curl 安装命令 

```bash
curl -O https://raw.githubusercontent.com/jinwyp/one_click_script/master/linux_install_software.sh && chmod +x ./linux_install_software.sh && ./linux_install_software.sh

```

#### via wget 安装命令 

```bash
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/linux_install_software.sh && chmod +x ./linux_install_software.sh && ./linux_install_software.sh

```




## Stargazers over time
[![Stargazers over time](https://starchart.cc/jinwyp/one_click_script.svg)](https://starchart.cc/jinwyp/one_click_script)



[better-cloudflare-ip]: https://github.com/badafans/better-cloudflare-ip/releases
[CloudflareScanner]: https://github.com/Spedoske/CloudflareScanner/releases/tag/1.1.2
[CloudflareSpeedTest]: https://github.com/XIU2/CloudflareSpeedTest/releases/tag/v1.4.9