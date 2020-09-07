# Easy install v2ray and trojan (trojan-go) script

# Trojan (支持 trojan-go版本) 和 V2ray 一键安装脚本 


## 功能说明 Feature 
====================================

1. 系统要求：centos7+/debian9+/ubuntu16.04+
2. 支持 trojan， trojan-go 和v2ray 的 安装 升级 完全卸载
3. 支持 trojan 或 trojan-go 与 v2ray 共存
4. 支持v2ray 新的vless协议  
5. 支持 trojan-go websocket 模式, 可以选择是否支持CDN (websocket)
6. 默认会创建10个以上用户账号, 还能创建指定前缀的密码, 方便用户使用.
7. trojan 和 v2ray 可视化管理面板安装. 
8. 卸载后不留任何痕迹, 方便重复安装

9. 脚本感谢 秋水逸冰、Atrandys、V2ray官方 和 波仔分享 等 

====================================

## 安装方法 Installation 

#### via curl 安装命令 

```bash
curl -O https://raw.githubusercontent.com/jinwyp/one_click_script/master/trojan_v2ray_install.sh && chmod +x trojan_v2ray_install.sh && ./trojan_v2ray_install.sh

```

#### via wget 安装命令 

```bash
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/trojan_v2ray_install.sh && chmod +x trojan_v2ray_install.sh && ./trojan_v2ray_install.sh

```



![功能列表](https://github.com/jinwyp/one_click_script/blob/master/docs/readme.png?raw=true)


## 使用说明 Usage 


1. 该步骤可省略. 如果是使用google cloud 谷歌云服务器，默认无法使用root账号登陆， 可以选择32 开启root用户登录. 建议使用root用户运行该脚本. 安装bbr plus 需要root权限, 默认认为使用root执行, 非root用户请手动添加sudo执行 ```sudo ./tcp.sh ```和 ```sudo ./trojan_v2ray_install.sh ``` 脚本. （注意 证书申请也需要用root用户而不建议用sudo  [acme.sh文档说明](https://github.com/acmesh-official/acme.sh/wiki/sudo)  ).
2. 安装 BBR plus. 运行脚本 ```./trojan_v2ray_install.sh ``` 选择1 然后选择2 安装 BBRplus版内核, 注意安装过程中会弹出大框的英文提示(下面有示例图)"安装linux内核有风险是否终止", 要选择" NO" 不终止. 安装完毕会重启VPS
3. 使用BBRplus版加速. 重新登录VPS后, 重新运行脚本 ```./trojan_v2ray_install.sh ```  选择1 然后 选择7 使用BBRplus版加速. 
4. 该步骤可省略. 选择31, 安装 oh-my-zsh. 这样以后登录有命令提示, 方便新手操作. 安装完成后请退出VPS, 命令为```exit```.  重新登录VPS后继续下面操作. 
5. 安装 trojan 或 v2ray. 根据提示 重新运行脚本 ```./trojan_v2ray_install.sh ```  选2 安装trojan, 或选6 安装trojan-go, 或选12 安装v2ray, 或选15 同时安装trojan和v2ray， 或选18 同时安装trojan-go和v2ray.
6. 在没有安装任何 trojan 和 v2ray 的新机器上(即没有执行过第5步, 执行过可以选择卸载), 选择29 进入子菜单安装 trojan 或 v2ray 可视化管理面板。(如果之前通过其他脚本安装过,再安装可视化管理面板则极易产生问题)

7. 第一步安装 BBR plus 时出现的提示 "是否终止删除内核" 请选择 "NO". 就是要卸载掉目前的内核. 
![注意 安装BBR plus](https://github.com/jinwyp/one_click_script/blob/master/docs/debian.jpg?raw=true)
![注意 安装BBR plus](https://github.com/jinwyp/one_click_script/blob/master/docs/kernel.png?raw=true)
![注意 安装BBR plus](https://github.com/jinwyp/one_click_script/blob/master/docs/ubuntu.png?raw=true)


## 注意事项与常见问题 FAQ 

1. 免费域名可以使用 [freenom](https://www.freenom.com/zh/index.html?lang=zh). 注册freenom时需要使用美国IP,否则无法通过注册邮件验证. 请自行搜索教程.
2. 使用脚本安装时请先关闭CDN, cloudflare.com 中DNS设置页面, 二级域名设置为DNS only 为关闭CDN. 安装v2ray或trojan-go完毕后 可以开启CDN 设置为Proxied 即可. trojan目前不支持CDN, trojan-go 默认安装设置为不支持CDN,可以在安装过程中选择支持CDN.

![注意 cloudflare CDN](https://github.com/jinwyp/one_click_script/blob/master/docs/cloudflare1.jpg?raw=true)

