# Easy install v2ray (xray) and trojan (trojan-go) script (ultimate script for all condition)

### [中文文档](/README2_CN.md) 

[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fjinwyp%2Fone_click_script&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)

## Sponsors
Thanks for support this project. Check on [patreon](https://www.patreon.com/linuxkernel)

## Table of Contents

* [Install Trojan/Trojan-go and V2ray/Xray shell script](#installation)
* [Easy get SSL certificate for domains](#acme)
* [Linux Kernel switcher, including all LTS kernel and latest kernel, enable BBR or BBR Plus to speed up network](/KERNEL.md)
* [Install wireguard and Cloudflare WARP, unlock Netflix restriction and avoid Google reCAPTCHA](/KERNEL.md)
* [Netflix available region testing shell script, support for testing through IPv6 and WARP Sock5 proxy](#netflix-check)
* [PVE Proxmox VE and Synology DiskStation Manager NAS Toolkit](/dsm/readme.md)
* [Install FRP shell script (expose local server behind a NAT or firewall to the Internet tool)](/dsm/readme.md)
* [How to enable DOH for DNS](/DNS.md)
* [Install DNS server AdGuard Home and Mosdns to divert domestic and foreign dns traffic](/DNS.md)



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

#### via bash
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



![功能列表](https://github.com/jinwyp/one_click_script/blob/master/docs/readme_en.png?raw=true)

![功能列表2](https://github.com/jinwyp/one_click_script/blob/master/docs/readme2_en.png?raw=true)

![功能列表3](https://github.com/jinwyp/one_click_script/blob/master/docs/readme3_en.png?raw=true)




## Netflix-Check
### Netflix non-self-produced drama and region testing shell script

#### via wget to install script

```bash
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/netflix_check.sh && chmod +x ./netflix_check.sh && ./netflix_check.sh
```


## acme
### Get SSL certificate for domain

1. Run script then choose 26 to request SSL certificate for any domains. It's better to disable CDN of your domain duiring the SSL certificate application process. Make sure the domain is resolved to the real VPS ip.
2. Duiring the SSL certificate application process, if you can't disable CDN or the VPS only have IPv6, you can skip the IP check process to continue your following SSL certificate request.
3. The script is using acme.sh to get SSL certificate. There are 4 providers: Let's Encrypt, BuyPass.com, ZeroSSL.com, Google. When you request too many times in one day and reach the limit of Let's Encrypt, you can switch other providers such as BuyPass.com.
4. Normally SSL certificate need renew in three month，The script will autorenew the certificate with Cronjob by acme.sh .

![功能列表4](https://github.com/jinwyp/one_click_script/blob/master/docs/readme4.png?raw=true)


#####  [The Rate Limits rule of Let's Encrypt](https://letsencrypt.org/docs/rate-limits/)

1. The main limit is Certificates per Registered Domain (50 per week)
2. You can create a maximum of 300 New Orders per account per 3 hours
3. You can create a maximum of 10 Accounts per IP Address per 3 hours. You can create a maximum of 500 Accounts per IP Range within an IPv6 /48 per 3 hours
4. You can combine multiple hostnames into a single certificate, up to a limit of 100 Names per Certificate
5. You can have a maximum of 300 Pending Authorizations on your account



## How to use


### Preparatory work for setting up a new VPS

1. There are several work to do to secure your VPS when you set up a new VPS. It's optional but recommended. 
2. Configuring an SSH login without password. Run script then choose 26. Input your public key and save the authorized_keys file
3. Change the SSH Default Port. Run script then choose 33. Customize your SSH login port. The default SSH port is 22, Modify the port number you want.
5. Enable root accout login. Some VPS can't login with root as default. Run script then choose 32 to enable root accout login.
6. Run script then choose 31 to install sofrware including Oh-my-zsh, zsh-autosuggestions, Micro editors. After finish installation, exit VPS and relogin SSH to use ZSH. 

### Install latest or LTS Linux kernel and enable BBR or BBR plus 
1. To install latest or LTS Linux kernel. Run script then choose 1. And enter the sub menu to install Linux kernel and enable BBR+Cake. Check out more details for [LTS Linux kernel switcher script](/KERNEL.md)



### Install command line trojan or trojan-go

1. Firstly, prefer run this script with root user. Because linux kernel installation need root privileges. And to get SSL with acme.sh also need root privileges. [acme.sh instruction](https://github.com/acmesh-official/acme.sh/wiki/sudo).

2. How to install trojan. Run script ```./trojan_v2ray_install.sh ```. Choose 2 to install trojan or trojan-go with websocket support CDN. 



### Install command line xray or v2ray

1. Firstly, prefer run this script with root user. Because linux kernel installation need root privileges. And to get SSL with acme.sh also need root privileges. [acme.sh instruction](https://github.com/acmesh-official/acme.sh/wiki/sudo).

2. How to install V2ray or Xray. Run script ```./trojan_v2ray_install.sh ```. Choose 11 to install V2ray or Xray with Nginx. Nginx listen 443 port and serve TLS service. During the installation, you can choose websocket or gRPC to support CDN.  Choose TCP or HTTP2 or QUIC protocal will not supprot CDN. 

3. How to install V2ray or Xray using Vless. Run script ```./trojan_v2ray_install.sh ```. Choose 13-16 to install V2ray or Xray. Vless listen 443 port and serve TLS service. Nginx is optional during the installation for fake website service. Also you can choose XTLS instead of TLS to improve network speed.

4. Run script ```./trojan_v2ray_install.sh ```. Choose 21 to install both V2ray and trojan on same VPS. Vless listen 443 port and serve TLS service.

5. Run script ```./trojan_v2ray_install.sh ```. Choose 22 to install both V2ray and trojan/trojan-go on same VPS. trojan/trojan-go listen 443 port and serve TLS service.

6. Run script ```./trojan_v2ray_install.sh ```. Choose 23 to install both V2ray and trojan/trojan-go on same VPS. Nginx SNI listen 443 port. You need at least 2 domain for trojan and v2ray. Nginx SNI distinguishes v2ray or trojan traffic by different domain name.

### Install command line xray  vision or Reality 

1. How to install Xray using XTLS Vision. Run script ```./trojan_v2ray_install.sh ```. Choose 17 to install Xray XTLS Vision protocol. Use Vless protocol to provide tls service on port 443.  Fallback to nginx on port 80 to provide web camouflage. During installation, please select Xray version 1.7.5 or above, as older versions prior to 1.6 do not support XTLS Vision protocol. This protocol does not support CDN relay. To use XTLS Vision on the client side, please use latest V2rayN and choose Xray version 1.7.5 or higher.

2. How to install Xray using Reality protocol. Run script ```./trojan_v2ray_install.sh ```. Choose 18 to install Xray Reality protocol. Domain name is not required for this installation, making the process more convenient. Vless Reality protocol provides forwarding service on port 443, and fallbacks to a specific foreign enterprise website that was filled by you during installation. During the installation, please choose Xray version 1.8.0 or above, as older versions of Xray prior to 1.7 do not support Reality protocol. This protocol does not support CDN relay. To use Xray Reality on the client side, it is necessary to use latest V2rayN 6.xx and choose Xray version 1.8.0 or above.




### Advanced Tutorials - Work with existing website or web server

1. If you already have a website or other web server, you can choose 12 to install V2ray or Xray only running at non 80 and 443 port with no TLS. You need modify nginx config manually to serve TLS and redirect v2ray traffic by url or path for V2ray websocket.

2. If you already have a website or other web server, you can choose 13-17 to install V2ray or Xray. Duiring the installation, you can choose not to install nginx. Vless serve 443 port with TLS. You need modify nginx config manually to serve the website at 80 port. V2ray or Xray will fallback non V2ray traffic to 80 port.

3. If you already have a website or other web server, you can choose 4 to install trojan or trojan-go only running at non 443 port with TLS. You need modify nginx config manually to serve the website at 80 port. trojan or trojan-go will fallback non trojan traffic to 80 port. Pay attention that if you choose to install trojan-go, nginx must already serve at 80 port which is trojan-go fallback port. Otherwise trojan-go will stop and not running if 80 port is not served by web HTTP server.   [trojan-go document](https://p4gefau1t.github.io/trojan-go/basic/config/) 




### Install Web UI admin panel for trojan and v2ray

1. On a new VPS without v2ray or trojan installed. Run script ```./trojan_v2ray_install.sh ```. Choose 30 to enter sub menu. Then choose 1 to install trojan UI admin panel. 

2. On a new VPS without v2ray or trojan installed. Run script ```./trojan_v2ray_install.sh ```. Choose 30 to enter sub menu. Then choose 6 or 9 to install V2ray or Xray UI admin panel.  After sinish the installation. Run script and choose 26 to request SSL certificate. Then input the certificate file path on the UI admin panel config.



### Unlock Region restriction for Netflix or Disney+ or other video streaming site 
### Avoid showing Google CAPTCHA Human verification

1. Run script ```./trojan_v2ray_install.sh ```. Choose 1 to enter sub menu to install linux kernel. Prefer to install linux kernel 5.10 LTS. [More Details](/KERNEL.md)
2. Run script ```./trojan_v2ray_install.sh ```. Choose 1 to enter sub menu. Then choose 2 to enable BBR and Cake. This will import VPS network speed. 
3. After reboot, rerun script ```./trojan_v2ray_install.sh ```. Choose 1 to enter sub menu. Then choose 11 or 12 to Wireguard or cloudflare WARP linux client sock5 proxy. 
4. After finish Wireguard installation, rerun script ```./trojan_v2ray_install.sh ```. Choose 11-17 to v2ray or xray。 During the installation, you can follow the instruction to unlock netflix region restriction and avoid showing Google CAPTCHA Human verification.




## FAQ 

1. You can use [freenom](https://www.freenom.com/zh/index.html?lang=zh) for free domain name.

2. Please disable your CDN acceleration duiring the installation. Such as cloudflare.com. After finish v2ray or trojan-go installation. you can enable CDN acceleration. trojan not support CDN acceleration. 

![注意 cloudflare CDN](https://github.com/jinwyp/one_click_script/blob/master/docs/cloudflare1.jpg?raw=true)

3. Using v2ray or xray gRPC protocal for CDN acceleration, you need do some settings at cloudflare.com.  Click the "Network" on the leftside menu. Then enable gRPC on the right page. "Network => gRPC" 

![注意 cloudflare CDN gRPC](https://github.com/jinwyp/one_click_script/blob/master/docs/grpc.png?raw=true)

4. The Cloudflare CDN worker script, Please replace the domain name with your own domain name. 
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

1. https://github.com/sprov065/v2-ui 
2. https://github.com/Jrohy/trojan 
3. https://github.com/v2fly/v2ray-core
4. https://github.com/XTLS/Xray-core
5. https://github.com/trojan-gfw/trojan
6. https://github.com/p4gefau1t/trojan-go
7. https://github.com/ylx2016/Linux-NetSpeed




## Stargazers over time
[![Stargazers over time](https://starchart.cc/jinwyp/one_click_script.svg)](https://starchart.cc/jinwyp/one_click_script)



[better-cloudflare-ip]: https://github.com/badafans/better-cloudflare-ip/releases
[CFIP]: https://github.com/BlueSkyXN/CFIP/releases
[CloudflareScanner]: https://github.com/Spedoske/CloudflareScanner/releases/tag/1.1.2
[CloudflareSpeedTest]: https://github.com/XIU2/CloudflareSpeedTest/releases/tag/v1.4.9
