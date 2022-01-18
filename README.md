# Easy install v2ray (xray) and trojan (trojan-go) script (ultimate script for all condition)

## [中文文档](/README_CN.md)
## Table of Contents

* [Install Trojan/Trojan-go and V2ray/Xray shell script](#installation)
* [Easy get SSL certificate for domains](#acme)
* [Linux Kernel switcher, including all LTS kernel and latest kernel, enable BBR or BBR Plus to speed up network](/KERNEL.md)
* [Install wireguard and Cloudflare WARP, unlock Netflix restriction and avoid Google reCAPTCHA](/KERNEL.md)
* [Netflix available region testing shell script, support for testing through IPv6 and WARP Sock5 proxy](#netflix-check)
* [Install V2Ray-Poseidon, Soga, XrayR, Air-Universe shell script for V2board panel](/TOOL.md)
* [PVE Proxmox VE and Synology DiskStation Manager NAS Toolkit](/dsm/readme.md)
* [Install FRP shell script (expose local server behind a NAT or firewall to the Internet tool)](/dsm/readme.md)




## Features 

1. Install and upgrade trojan/trojan-go/v2ray/xray and fully remove.
2. Support to running trojan-go and v2ray at the same server.
3. Support various mode, using trojan or v2ray or nginx to serve 443 port   
4. Support multi https domains with Nginx SNI on one VPS server.
5. Support install trojan or v2ray only in order to work with exist website on one VPS.
6. Customize trojan or v2ray working port, password and Websocket path. 
7. Support v2ray or xray vless protocol. Support Xray XTLS. 
8. Script create 10 password as default, can set prefix for these passwords.
9. Install trojan and v2ray UI panel to easily manage users. 
10. Easily set v2ray route rules with wireguard IPv6 and Cloudflare WARP to unlock  Netflix restriction and Google reCAPTCHA.
11. Using bootstarp official template for default website content serve by nginx
12. All working port are random generated to ensure high security.



## Installation

#### Usage
```bash
bash <(curl -Lso- https://git.io/oneclick)
```


####  via curl to install script

```bash
curl -O https://raw.githubusercontent.com/jinwyp/one_click_script/master/trojan_v2ray_install.sh && chmod +x ./trojan_v2ray_install.sh && ./trojan_v2ray_install.sh
```

#### via wget to install script

```bash
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/trojan_v2ray_install.sh && chmod +x ./trojan_v2ray_install.sh && ./trojan_v2ray_install.sh
```



![功能列表](https://github.com/jinwyp/one_click_script/blob/master/docs/readme.png?raw=true)

![功能列表2](https://github.com/jinwyp/one_click_script/blob/master/docs/readme2.png?raw=true)

![功能列表3](https://github.com/jinwyp/one_click_script/blob/master/docs/readme3.png?raw=true)




## Netflix-Check
### Netflix non-self-produced drama and region testing shell script

#### via wget to install script

```bash
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/netflix_check.sh && chmod +x ./netflix_check.sh && ./netflix_check.sh
```


## acme
### Get a SSL certificate for website

1. 本脚本可以用来单独给网站申请免费的SSL证书, 选择26 即可. 申请SSL证书过程中请关闭域名的CDN功能, 保证域名已经成功解析到VPS真实IP.
2. 申请SSL证书过程中如果不方便关闭CDN, 或者纯IPv6主机 可以选择不检测IP解析是否正确, 从而跳过检测IP继续申请证书.
3. 本脚本使用的 acme.sh 来申请的免费证书. 可以选择 Let's Encrypt, BuyPass.com, ZeroSSL.com 提供商.  Let's Encrypt 申请证书有一些限制, 如果频繁申请证书出现无法申请的情况请选择其他证书提供商如 BuyPass.com
4. 三个月之后需要续期，本脚本通过cron任务自动完成续期，无需用户操作.

#####  Let's Encrypt 申请证书有一些限制, 具体限制如下：

1. 同一个主域名一周之内只能申请50个证书
2. 每个账号下每个域名每小时申请验证失败的次数为5次
3. 每周只能创建5个重复的证书，即使是通过不同的账号进行创建
4. 每个账号同一个IP地址每3小时最多可以创建10个证书
5. 每个多域名（SAN） SSL证书（不是通配符域名证书）最多只能包含100个子域
6. 更新证书没有次数的限制，但是更新证书会受到上述重复证书的限制
7. 如果提示证书申请失败，可以尝试更换域名再试（添加或换不同的二级域名，也算是新域名）
8. 同一IP地址，在短时间内过于频繁的申请证书，也会被限制，此时更换域名也无法申请成功，只能等待一段时间，或者在安装过程中选择使用 BuyPass.com 来申请.




## How to use


### Prepare work of new VPS

1. 一台新的VPS开通后,建议做以下事情(非必须)
2. 运行脚本后 选择35 填入你自己的公钥, 这样就可以不需要每次输入SSH密码登录VPS, 提高安全性. 还可以继续手动修改配置文件 /etc/ssh/sshd_config 关闭SSH使用密码登录,使其只能使用密钥登录VPS
3. 运行脚本后 选择33 修改SSH端口号, 一般默认SSH端口号是22, 强烈建议改成其他的端口号, 提高安全性. 默认22端口极易被扫描和攻击.
4. 运行脚本后 选择34 修改时区为北京时间, 因为V2ray的Vmess的协议需要对服务器和客户端时间一致, 建议把VPS服务器改成北京时间.
5. 有一些VPS例如Google Cloud 默认没有开启root账号登录, 运行脚本后 选择31 可以开启root账号登录. 建议使用root用户运行该脚本.
6. 运行脚本后 选择31 安装 Oh-my-zsh 等软件, 这些软件会简化你的后续操作, 并带有提示. 安装完成后请退出VPS, 命令为```exit```. 重新登录VPS后继续后续操作. 

### Install latest or LTS Linux kernel and enable BBR or BBR plus 
1. 运行脚本后 选择1 安装 Linux 内核和开启BBR+Cake, 具体请参考[Linux 内核一键安装脚本](/KERNEL_CN.md)
2. 运行脚本后 选择1 安装 BBR plus (或 BBR) 网络加速. 运行脚本 ```./trojan_v2ray_install.sh ``` 选择1 然后 再选择36 安装5.10内核 或 选择61或其他 安装原版 BBRplus 4.14,129 版内核 , 注意安装过程中会弹出大框的英文提示(下面有示例图)"安装linux内核有风险是否终止", 要选择" NO" 不终止. 安装完毕会重启VPS
3. 使用 BBR 或 BBRplus版 网络加速. 重新登录VPS后, 重新运行脚本 ```./trojan_v2ray_install.sh ```  选择1 然后 选择2 使用BBR 或选择2 使用BBRplus 加速. 

6. 第一步安装 BBR plus 时出现的提示 "是否终止删除内核" 请选择 "NO". 就是要卸载掉目前的内核. 
![注意 安装BBR plus](https://github.com/jinwyp/one_click_script/blob/master/docs/debian.jpg?raw=true)
![注意 安装BBR plus](https://github.com/jinwyp/one_click_script/blob/master/docs/kernel.png?raw=true)
![注意 安装BBR plus](https://github.com/jinwyp/one_click_script/blob/master/docs/ubuntu.png?raw=true)




### Install commandline trojan or v2ray

1. 建议使用root用户运行该脚本. 安装bbr plus 内核 需要root权限, 默认认为使用root执行本脚本, 非root用户请手动添加sudo执行 ```sudo ./trojan_v2ray_install.sh ``` 脚本. 注意 证书申请也需要用root用户而不建议用sudo运行 [acme.sh文档说明](https://github.com/acmesh-official/acme.sh/wiki/sudo).

2. 安装 trojan 重新运行脚本 命令为 ```./trojan_v2ray_install.sh ```  选2 安装trojan 或 安装trojan-go 支持原版trojan客户端, 或3 安装 trojan-go 支持Websocket, 注意原版trojan客户端不支持websocket, 使用原版trojan客户端只能连接 trojan-go的原版tcp协议, 无法支持websocket 使用CDN. 需要使用trojan-go的客户端才可以支持websocket 支持CDN.

3. 安装 v2ray 重新运行脚本 选择11 安装 v2ray或xray 并且nginx 提供443端口的tls服务, 推荐使用本模式. 然后安装v2ray协议可以选择websocket或gRPC 等协议 通过设置 path来区分v2ray流量, 并且支持CDN. 如果选择TCP或HTTP2或QUIC 协议则无法使用CDN中转流量. Cloudflare 虽然支持HTTP2或QUIC协议, 但却无法使用其CDN中转, [具体信息可以看](https://github.com/v2ray/v2ray-core/issues/1769). QUIC(HTTP3)协议由于使用了UDP, 在某些运营商会被禁止或被限制端口或QoS降速, 所以使用QUIC可能无法达到提速的预期目的. 选择KCP协议降低延迟,如果打游戏可以尝试该协议.

4. 安装 v2ray 重新运行脚本 选择13-17 安装 v2ray或xray 使用Vless协议提供443端口的tls服务, 而且安装过程中如果选XTLS代替TLS加密 将会明显提高速度. 安装完毕后会提供多种协议可以同时使用. 使用WS-TLS 或 gRPC+TLS协议可以使用CDN中转加速. 使用TCP-XTLS则为直连速度最快协议. 安装V2ray或Xray, 都可以自定义端口, 密码和websocket 的path 路径, 默认为随机密码和随机路径. 同时还可以增加一个额外的监听端口与主端口同时使用, 方便用于不支持443端口的中转机中转给目标主机.

5. 同时安装 trojan 和 v2ray 选择21 使用Vless提供443端口的tls服务, 而trojan或trojan-go运行在非443的其他端口上.

6. 同时安装 trojan 和 v2ray 选择22 使用trojan或trojan-go 提供443端口的tls服务, trojan把非trojan流量转发到nginx, nginx在通过path路径转发流量到v2ray.

7. 同时安装 trojan 和 v2ray 选择23 通过nginx SNI 提供443端口服务, 最少需要提供2个域名分别给trojan, v2ray单独使用, 并且可以与现有网站共存(需要再提供第3个域名给网站使用), 通过不同域名区分不同的HTTPS加密流量. 

8. 建议: 如果VPS线路速度可以保证，不需要CDN，建议17 安装xray + XTLS 速度最快, 或选2或3 安装 trojan-go. 如果需要CDN 可以选11 安装V2ray和Nginx. 不建议使用本脚本或其他脚本同时安装多个协议, 协议安装的越多安全性越低, 而且也不会提高速度, 适合自己的协议装一种最好. 

9. 以上安装都可以选择是否申请证书, 如果已有证书可以不在安装过程中申请, 或多次安装本脚本也可以不需要再次申请。证书位置在 /root/website/cert/fullchain.cer 和 /root/website/cert/private.key, 可以手动放置.


### Advanced Usage Working with exist website or web server

1. 如果机器上已经有nginx或已有其他Web网站服务, 或是与宝塔面板共同使用, 可以运行脚本后 选择12  只安装V2ray或Xray, 运行在非80和443端口(端口可自定义), 注意: 选择12 安装V2ray或Xray 此时没有加密, 需要在宝塔面板或nginx自行修改配置, 让nginx服务于443 https端口, 根据指定的url路径path 转发到V2ray 端口, 起到tls加密作用.

2. 如果机器上已经有nginx或已有其他Web网站服务, 或是与宝塔面板共同使用, 可以运行脚本后 选择4 只安装trojan或trojan-go, 这样让trojan或trojan-go服务于443 https端口, 与现有的nginx或网站共存, nginx需要修改配置只监听80端口即可。Https的TLS加密由 trojan或trojan-go提供服务.

3. 注意 运行脚本后选择4 并选择安装trojan-go. 必须保证本机80端口有监听, 否则trojan-go无法启动. 这是trojan-go的一个fallback功能, 非trojan协议的流量会转发到remote_addr和remote_port指定这个HTTP服务器的地址. Trojan-Go将会测试这个HTTP服务器是否工作正常，如果不正常，Trojan-Go会拒绝启动. [参考trojan-go官方文档](https://p4gefau1t.github.io/trojan-go/basic/config/) 

4. 运行脚本 选择13-17 安装V2ray或Xray, 过程中可以选择不安装nginx, 这样让V2ray或Xray的 Vless协议服务于443 https端口(端口可自定义), 可与现有的nginx或网站共存, nginx需要修改配置只监听80端口即可。Https的TLS加密由V2ray或Xray的 Vless协议提供.




### Install Web UI panel for trojan and v2ray

1. 在没有安装任何 trojan 和 v2ray 的新机器上(如使用本脚本安装过可执行卸载操作), 选择30 进入子菜单安装 trojan 或 v2ray 可视化管理面板。(如果之前通过其他脚本安装过,再安装可视化管理面板则极易产生问题, 请先卸载其他脚本程序在安装)

2. 选择30后 然后再选择1 安装trojan-web可视化管理面板 和 nginx. 根据提示输入域名后, 继续根据提示再选择1.Let's Encrypt 证书, 申请证书成功后. 继续根据提示再选择1.安装docker版mysql(mariadb). ariadb启动成功后,继续根据提示输入第一个trojan用户的账号密码,回车后出现"欢迎使用trojan管理程序" 需要不输入数字直接按回车,这样继续安装nginx直到完成. nginx安装成功会显示可视化管理面板网址,请保存下来. 如果没有显示管理面板网址则表明安装失败. 

3. 选择30后 然后再选择6或9 安装v2ray-ui可视化管理面板. 安装成功后可以再次运行本脚本, 选择26申请域名SSL证书. 然后再可视化管理面板新建添加vless账号或trojan账号, 填入证书文件路径 即可同时支持trojan和v2ray.


### Netflix Unlock 解锁Netflix 等其他流媒体网站的区域限制 和 避免弹出Google人机验证

1. 运行脚本后选择1 进入Linux 内核安装菜单, 根据提示安装 linux 内核 5.10或5.14 都可以.
2. 更换内核重启后, 选择1 进入linux 内核安装菜单, 选择2 使用BBR加速 和 Cake算法 优化VPS参数后 重启
3. 重启后, 选择1, 再选择6 安装 Wireguard 和 cloudflare WARP. 
4. 确认 Wireguard 启动成功后, 运行脚本后 安装v2ray或xray, 安装过程中根据提示 选择netflix 和 google 人机验证 解锁即可, 也可以选择解锁更多的视频网站.
5. 本脚本集合了所有解锁 Netflix 网站的方法, 目前有 1 使用DNS解锁, 2 使用IPv6解锁, 3 使用WARP sock5 代理解锁, 4 使用转发到可解锁的V2ray或Xray服务器解锁, 5 神秘方法解锁
6. 目前网上搭建解锁反代服务器是使用 sniproxy + dns的方式, 本脚本稍后推出 nginx stream + dns, nginx + xray, nginx + v2ray, nginx + sock5, 非常灵活的各种方式搭建解锁反代服务器, 以便达到一台VPS可以同时做网站+提供解锁+v2ray+trojan的目的



## FAQ 

1. 免费域名可以使用 [freenom](https://www.freenom.com/zh/index.html?lang=zh). 注册freenom时需要使用美国IP,否则无法通过注册邮件验证. 请自行搜索教程.
2. 使用脚本安装时请先关闭CDN, cloudflare.com 中DNS设置页面, 二级域名设置为DNS only 为关闭CDN. 安装v2ray或trojan-go完毕后 可以开启CDN 设置为Proxied 即可. trojan目前不支持CDN, trojan-go 默认安装设置为不支持CDN,可以在安装过程中选择支持CDN.

![注意 cloudflare CDN](https://github.com/jinwyp/one_click_script/blob/master/docs/cloudflare1.jpg?raw=true)

3. 如果使用v2ray 或 xray的 gRPC 通过cloudflare 转发, 需要在cloudflare 域名 "设置"中 => "网络" 菜单里面 允许gRPC，cloudflare Network => gRPC 

![注意 cloudflare CDN gRPC](https://github.com/jinwyp/one_click_script/blob/master/docs/grpc.png?raw=true)

4. 以下是Cloudflare CDN 的worker 加速脚本, 请把域名替换成自己的vps的域名. 然后在Cloudflare新建worker 添加即可. 可以通过下面3个工具任选其一, [CFIP][better-cloudflare-ip], [CloudflareScanner], [CloudflareSpeedTest],  在你自己的客户端机器上运行, 找出距离你最快的 cloudflare 的CDN IP, 在v2ray或trojan-go支持CDN的配置中填入该IP即可.
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

## Special Thanks

1. 脚本感谢 https://github.com/sprov065/v2-ui 
2. 脚本感谢 https://github.com/Jrohy/trojan 
3. 脚本感谢 https://github.com/v2fly/v2ray-core
4. 脚本感谢 https://github.com/XTLS/Xray-core
5. 脚本感谢 https://github.com/trojan-gfw/trojan
6. 脚本感谢 https://github.com/p4gefau1t/trojan-go
7. 脚本感谢 https://github.com/ylx2016/Linux-NetSpeed
8. 脚本感谢 秋水逸冰、Atrandys、V2ray官方 和 波仔分享 等 
9. 脚本感谢 JCNF的博客 https://ybfl.xyz/111.html



## Stargazers over time
[![Stargazers over time](https://starchart.cc/jinwyp/one_click_script.svg)](https://starchart.cc/jinwyp/one_click_script)



[better-cloudflare-ip]: https://github.com/badafans/better-cloudflare-ip/releases
[CFIP]: https://github.com/BlueSkyXN/CFIP/releases
[CloudflareScanner]: https://github.com/Spedoske/CloudflareScanner/releases/tag/1.1.2
[CloudflareSpeedTest]: https://github.com/XIU2/CloudflareSpeedTest/releases/tag/v1.4.9


