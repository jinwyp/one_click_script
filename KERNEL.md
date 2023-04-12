# Easy install latest or LTS linux kernel and enable BBR or BBR plus

### [中文文档](/KERNEL_CN.md)
### [xray v2ray trojan 一键安装脚本](/README2.md)

## Sponsors
Thanks for support this project. Check on [patreon](https://www.patreon.com/linuxkernel)


## Table of Contents

* [Easy install v2ray (xray) and trojan (trojan-go) script (ultimate script for all condition)](/README2.md)
* [Install linux latest and LTS kernel. Install BBR Plus kernel](#kernel)
* [Enable BBR or BBR plus or BBR2 congestion control algorithm with FQ or CAKE](#kernel)
* [Install wireguard and Cloudflare WARP. Unlock Netflix ip geo-restriction. Avoid Google reCAPTCHA human verification](#Wireguard)


## Features 
1. Easily switch Linux kernel for all versions, including latest kernel, 5.16, 5.10 LTS, 5.4 LTS, 4.19 LTS, 4.14 LTS  
2. Easily enable BBR or BBR plus congestion control algorithm with FQ / FQ-Codel / FQ-PIE / CAKE. 
3. Support Debian9+, Ubuntu 16+ and CentOS 7+ operation systems
4. Install wireguard and Cloudflare WARP client to avoid Google reCAPTCHA and unlock Netflix ip geo-restriction
 



## Installation

#### via bash
```bash
bash <(curl -Lso- https://git.io/kernel.sh)
```
#### via curl to install script

```bash
curl -O https://raw.githubusercontent.com/jinwyp/one_click_script/master/install_kernel.sh && chmod +x ./install_kernel.sh && ./install_kernel.sh
```


#### via wget to install script

```bash
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/install_kernel.sh && chmod +x ./install_kernel.sh && ./install_kernel.sh
```



![功能列表3](https://github.com/jinwyp/one_click_script/blob/master/docs/readme3_en.png?raw=true)




## Usage 

### kernel
### Install latest or LTS linux kernel and enable BBR or BBR Plus

1. On CentOS / AlmaLinux / Rocky Linux, run script then choose 31 to install latest 5.16 kernel or choose 35 to install LTS 5.10 kernel (recommended). It will reboot twice duiring the whole installation.
2. On Debian run script then choose 41 to install LTS 5.10 kernel, on Ubuntu please choose 45 to install LTS 5.10 kernel. It will reboot twice duiring the whole installation.
3. After finished new kernel installation, rerun the script and choose 2 to enable BBR congestion control algorithm with Cake(recommended) or FQ. 
4. To enable BBR Plus. run script then choose 61 to install BBR Plus 4.14.129 kernel , or choose 66 to install BBR Plus 5.10 LTS kernel. It will reboot twice duiring the whole installation.  After finished new kernel installation, rerun the script then choose 3 to enable BBR Plus. 
5. Duiring the the whole installation when show the big warning screen(see below pics), please choose "NO" to continue installation. Do not abort kernel removal. 

![注意 安装BBR plus](https://github.com/jinwyp/one_click_script/blob/master/docs/debian.jpg?raw=true)
![注意 安装BBR plus](https://github.com/jinwyp/one_click_script/blob/master/docs/kernel.png?raw=true)
![注意 安装BBR plus](https://github.com/jinwyp/one_click_script/blob/master/docs/ubuntu.png?raw=true)

6. To install XanMod kernel and enable BBR2 on Debian or Ubuntu. Run script then choose 51 to install XanMod LTS 5.10 kernel, after reboot and finish kernel installation, rerun the script then choose 2 to enable BBR2 congestion control algorithm.


### Wireguard
### Unlock Netflix(Youtube/Hulu/HBO Now/Disney+) region restriction and avoid Google reCAPTCHA human verification

1. Unlock with Cloudflare WARP sock5 proxy. Run script then choose 11 to install Cloudflare WARP linux client sock5 proxy, After finish installation, rerun script then choose 21 to test whether Netflix is unlock or not through the WARP sock5 proxy.
2. Unlock with Cloudflare WARP IPv6. Run script then choose 12 to install Wireguard and Cloudflare WARP.  After finish installation, The VPS will enable IPv6. As default the VPS is to use IPv4 to access the network. Rerun script then choose 21 to test whether Netflix is unlock or not through the IPv6.
3. To unlock Netflix and other stream website. Using the [script](/README.md) in the same repo to install v2ray. During the v2ray installation follow the instruction and select different v2ray routing rules (IPv6 or WARP sock5 or DNS or other unlocked v2ray server) to unlock netflix. 
4. To avoid Google reCAPTCHA human verification. Using the [script](/README.md) in the same repo to install v2ray. During the v2ray installation follow the instruction and select different v2ray routing rules (IPv6 or WARP sock5 or other unlocked v2ray server) to avoid Google reCAPTCHA. Recommended to use IPv6 to avoid Google reCAPTCHA.




## Netflix-Check
### Netflix non-self produced drama test script for regions. Support test with IPv6 and Cloudflare WARP Sock5 proxy

#### via wget to install script

```bash
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/netflix_check.sh && chmod +x ./netflix_check.sh && ./netflix_check.sh
```


####  via curl to install script

```bash
curl -O https://raw.githubusercontent.com/jinwyp/one_click_script/master/netflix_check.sh && chmod +x ./netflix_check.sh && ./netflix_check.sh
```



## FAQ 

1. Netflix non-self produced drama test script can't test through v2ray routing rule. The VPS is already unlocked but the result of the test could not show the right unlocked answer. You can use the test script on the V2ray client computer which connected the unlocked netflix V2ray server to get the right unlocked result.  The Netflix non-self produced drama test shell script can be running on Mac and linux. On Windows you can use Ubuntu (windows linux sub-system) to run the test script.



