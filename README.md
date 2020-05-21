# Easy install v2ray and trojan (trojan-go) script

# Trojan (支持 trojan-go版本) 和 V2ray 一键安装脚本 

====================================
系统：centos7+/debian9+/ubuntu16.04+

网站：www.v2rayssr.com （已开启禁止国内访问）

脚本感谢 秋水逸冰、Atrandys、V2ray官方等 Youtube：波仔分享

支持 trojan 与 v2ray 共存
支持 trojan 和 trojan-go
默认会创建10个用户账号, trojan 还能创建指定的密码, 方便用户使用.

====================================

脚本安装命令

```bash
curl -O https://raw.githubusercontent.com/jinwyp/one_click_script/master/trojan_v2ray_install.sh && chmod +x trojan_v2ray_install.sh && ./trojan_v2ray_install.sh

```

或

```bash
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/trojan_v2ray_install.sh && chmod +x trojan_v2ray_install.sh && ./trojan_v2ray_install.sh

```




![功能说明](https://github.com/jinwyp/Trojan/blob/master/readme.png?raw=true)


## 使用说明 Usage 

####


1. 安装 BBR plus. 运行脚本 ```./trojan_v2ray_install.sh ``` 选择1 然后选择2 安装 BBRplus版内核, 注意安装过程中会弹出大框的英文提示(下面有示例图)"安装linux内核有风险是否终止", 要选择" NO" 不终止. 安装完毕会重启VPS
2. 使用BBRplus版加速. 重新登录VPS后, 重新运行脚本 ```./trojan_v2ray_install.sh ```  选择1 然后 选择7 使用BBRplus版加速. 
3. 该步骤可省略. 选择15, 安装 oh-my-zsh. 这样以后登录有命令提示, 方便新手操作. 安装完成后请退出VPS, 命令为```exit```.  重新登录VPS后继续下面操作. 
4. 安装 trojan 或 v2ray. 根据提示 重新运行脚本 ```./trojan_v2ray_install.sh ```  选2 安装trojan, 或选5 安装trojan-go, 或选11 安装v2ray, 或选13 同时安装trojan和v2ray.


5. 第一步安装 BBR plus 时出现的提示 "是否终止删除内核" 请选择 "NO". 就是要卸载掉目前的内核. 
![注意 安装BBR plus](https://github.com/jinwyp/Trojan/blob/master/debian.jpg?raw=true)
![注意 安装BBR plus](https://github.com/jinwyp/Trojan/blob/master/kernel.png?raw=true)
![注意 安装BBR plus](https://github.com/jinwyp/Trojan/blob/master/ubuntu.png?raw=true)


6. 如果是使用google cloud 谷歌云服务器，默认无法使用root账号登陆， 可以选择16 开启root用户登录



