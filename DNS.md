# DNS, DOT(DNS over TLS) and DOH(DNS over HTTPS) 

## 目录 Table of Contents

* [DNS DOT DOH 介绍](#dns)
* [Chrome 如何开启DOH 解决DNS污染](#chrome)
* [Firefox 如何开启DOH](#firefox)
* [Edge 如何开启DOH](#edge)
* [安装 AdGuard Home  搭建 DNS 服务器](#adguardhome)
* [使用 Mosdns 分流国内与国外域名DNS解析请求](#mosdns)

### DNS

1. 面试程序员经常会问的一道面试题: 当在浏览器输入一个网址回车后,后面发生了什么. 例如下图 输入了网址foobar.com后, 首先从DNS服务器查询 foobar.com对应的IP地址 156.x.x.x. 浏览器得到IP后继续访问156.x.x.x 这个服务器地址返回网页. 用户就可以正常浏览网页了.
![DNS1](https://github.com/jinwyp/one_click_script/blob/master/docs/dns1.png?raw=true)

2. 早些年网页采用http方式传输, 网页没有加密. 后来基于TLS加密技术的https方式传送,网页就被加密无法看到传送的内容了. 如下图
![DNS2](https://github.com/jinwyp/one_click_script/blob/master/docs/dns2.png?raw=true)

3. 网页传输 http未加密 与 https加密 对比图. 可以看到内容已被加密
![HTTPS1](https://github.com/jinwyp/one_click_script/blob/master/docs/https1.png?raw=true)

4. 通过DNS解析后得到IP后虽然网页传输是加密的https,其他人无法知道浏览的内容是什么,但第一步查询DNS时是未加密的, GFW防火墙就可以获取到域名信息并污染DNS,返回一个错误的IP地址,这样就无法正常打开网页了. 所以DNS也要加密, DOT(DNS over TLS) 与 DOH(DNS over HTTPS)就诞生了. 开启DOT或DOH后就如下图, 查询DNS后返回的IP地址信息也是加密的. GFW就无法截取信息并污染DNS了. 如何开启DOT和DOH 请看[Chrome开启方法](#chrome) 和 [Firefox开启方法](#firefox)
![DNS3](https://github.com/jinwyp/one_click_script/blob/master/docs/dns3.png?raw=true)

5. 根据上图仔细看还会发现,第一步输入网址查询DNS的时候还是未加密的, 这样网址的名称还会被其他人获取, 为了解决这个问题又提出了ESNI(Encrypted server name indication), 这样从所有链路都加密了. 由于从第一步输入网址信息就是加密的, 那么DNS服务器如何知道输入的什么网址呢, 所以该技术需要浏览器和DNS提供商配合, 目前新版firefox和CDN服务商Cloudflare已支持开启ESNI. [如何开启Firefox的ESNI方法](#firefoxesni).

6. 更多DOH DOT ESNI 资料请看[什么是加密的 SNI](https://www.cloudflare.com/zh-cn/learning/ssl/what-is-encrypted-sni/). [使用 ESNI、DoH 和 DoT](https://www.toptal.com/web/encrypted-safe-with-esni-doh-dot). [搭建全协议DNS服务器](https://blog.dnomd343.top/dns-server/)


### Chrome

1. 需要先下载新版本Chrome 100 [下载地址1](https://pan.baidu.com/s/1PPRPggOHvBhcuZoQL7ZRQQ?pwd=9xuu).  [下载地址2](https://wws.lanzout.com/ihbbt040y4oh) 
2. 打开 Chrome, 在网址栏输入 chrome://settings/security 回车后, 进入"安全"设置页面. 或者点击Chrome地址栏右边菜单栏的三个点 打开菜单，然后点击 "设置" , 然后点击左边菜单的 "隐私设置和安全性", 然后在右边找到的 "安全"点击进入"安全"设置页面

![Chrome1](https://github.com/jinwyp/one_click_script/blob/master/docs/chrome1.png?raw=true)
![Chrome2](https://github.com/jinwyp/one_click_script/blob/master/docs/chrome2.png?raw=true)

3. 在打开的 "安全" 设置页面中, 选中 "使用安全 DNS" 后面的滑块, 再选择下拉框中的Cloudflare 1.1.1.1 或 Google Public DNS，也可以选择下拉框里选择自定义, 然后在下面文本框中输入自己找到的 DoH 服务器. [DNS服务器列表](https://dns.icoa.cn/)  [如何验证是否开启DOT和ESNI](#测试是否开启DOT和ESNI ).

![Chrome3](https://github.com/jinwyp/one_click_script/blob/master/docs/chrome3.png?raw=true)

4. 有时候选择Cloudflare 1.1.1.1 或  Google Public DNS 会出现打不开网站的情况, 这是因为GFW防火墙除了会污染DNS, 还会直接屏蔽掉IP, 导致Cloudflare 1.1.1.1 或 Google Public DNS 8.8.8.8 无法访问, 也就无法解析DNS域名. 解决办法就是自己找到其他海外支持DOT或DOH的DNS服务器, 或者自己在海外架设DNS服务器. 可以使用[
AdGuardHome](https://github.com/AdguardTeam/AdGuardHome). 具体方法请看[搭建自己的DNS服务器](#搭建自己的DNS服务器).

5. 使用了国外的DOT或DOH后, 也会发现访问国内网站慢, 或者访问国内网站变成海外版本的问题. 这就需要区分国内和国外网站走不同的DNS进行分流, [具体请看DNS分流](#分流国内和国外的DNS服务解析)

### Firefox

1. 需要下载新版本的Firefox.  [下载地址1](https://pan.baidu.com/s/19u-Ayy-rKvgYDmg_TNDIzA?pwd=827m). [下载地址2](https://wws.lanzout.com/ipGdD040ylbg) 

2. 点击右边的菜单栏, 然后在下拉菜单点击 "设置". 然后选择左边菜单点击"常规", 然后在右边最下面"网络设置" 点击"设置" 
![Firefox1](https://github.com/jinwyp/one_click_script/blob/master/docs/firefox1.png?raw=true)
![Firefox2](https://github.com/jinwyp/one_click_script/blob/master/docs/firefox2.png?raw=true)

3. 在打开的对话框中，在最下面, 选中 "启用基于 HTTPS 的 DNS", 然后在下拉框可以选择Cloudflare 默认值或自定义的DOT服务器 .  [如何验证是否开启DOT和ESNI](#测试是否开启DOT和ESNI ).
![Firefox3](https://github.com/jinwyp/one_click_script/blob/master/docs/firefox3.png?raw=true)

4. 其他网上教程 [在Firefox中启用 DNS-over-HTTPS(DoH)](https://zhuanlan.zhihu.com/p/75845767)

### FirefoxESNI

1. 需要下载最新版的Firefox  [下载地址1](https://pan.baidu.com/s/19u-Ayy-rKvgYDmg_TNDIzA?pwd=827m). [下载地址2](https://wws.lanzout.com/ipGdD040ylbg) 
2. 在地址栏输入 ``` about:config ``` , 然后点击 "接受风险并继续", 然后搜索 ``` network.security.esni.enabled ``` , 
![Firefox1](https://github.com/jinwyp/one_click_script/blob/master/docs/firefoxesni1.png?raw=true)
![Firefox2](https://github.com/jinwyp/one_click_script/blob/master/docs/firefoxesni2.png?raw=true)

3. 然后选择 "布尔" 类型, 点击右边 + 号, 然后点击右边按钮 将值设为true, 完成.  [如何验证是否开启DOT和ESNI](#测试是否开启DOT和ESNI ).
![Firefox3](https://github.com/jinwyp/one_click_script/blob/master/docs/firefoxesni3.png?raw=true)

4. 开启 Encrypted Client Hello (ECH) (ESNI的进化版本). 同样在 ``` about:config ``` 搜索条目 ```network.dns.echconfig.enabled``` 和 ```network.dns.use_https_rr_as_altsvc```，将它们的值设定改为 true 即可。

5. 更多问题请查看 [在 Firefox 上设置 DoH 和 ESNI/ECH](https://blog.outv.im/2020/firefox-doh-ech-esni/)


### Edge

1. Edge 浏览器 [设置DoH加密DNS的方法] (https://www.icoa.cn/a/953.html)

### 测试是否开启DOT和ESNI 

1. 使用浏览器打开 https://www.cloudflare.com/zh-cn/ssl/encrypted-sni/ 点击 "Check My Browser" 按钮. 测试之前浏览器设置DNS的服务器请选择Cloudflare的DOH的服务器.

![CF1](https://github.com/jinwyp/one_click_script/blob/master/docs/cfcheck1.png?raw=true)

2. 查看结果. 目前Chrome 还不支持ESNI,估计很快就会支持.
![CF2](https://github.com/jinwyp/one_click_script/blob/master/docs/cfcheck2.png?raw=true)


3. 常见问题: Cloudflare 提醒我 ESNI 未启用！可能是你的 DNS over HTTPS 并没有生效，Firefox 还在使用普通的 DNS 请求方式。这种情况下 ECH 无法工作。

你可以尝试按照 Mozilla Wiki 的指示，在 about:config 中将 network.trr.mode设置为 3，即只使用 TRR（也就是我们的 DNS over HTTPS），强制 Firefox 使用 DoH，这样就能确保使用 ESNI 了。

![CF3](https://github.com/jinwyp/one_click_script/blob/master/docs/cfcheck3.png?raw=true)

### AdGuardHome
### 搭建的DNS服务器

1. 通过本脚本, ``` bash <(curl -Lso- https://git.io/oneclick) ``` 运行本脚本, 选择28 安装 AdGuard Home 架设DNS服务器, 同时还可以去广告. 建议在国外的服务器上安装 
2. 安装完成后, 再次运行本脚本 选择29 申请域名证书. 这样就可以开启DOH和DOT 加密DNS解析. 

3. 具体设置请参考 [AdGuardHome 官方网站](https://github.com/AdguardTeam/AdGuardHome). 本脚本已经自动添加了针对中国网站的广告屏蔽规则.
4. [AdGuard Home 的整理的DNS服务器列表](https://kb.adguard.com/en/general/dns-providers)

### Mosdns
### 分流国内和国外的DNS服务解析

1. 建议有条件的请先按照上面教程搭建AdGuardHome DNS服务器. 然后再安装mosdns 进行DNS分流. 没有条件搭建DNS服务器也不用担心, 本脚本已经内置多个DNS服务器地址 
2. 通过使用mosdns 或 mosdns-cn 可以让国内的网址走国内的DNS解析, 国外的网址走国外的DNS解析. 同时也不用在浏览器里面设置DOH了 (上面教程里浏览器设置部分不需要了).  安装mosdns 分为 [Openwrt X86版本](#openwrt), [linux 版本](#linux) 或 [windows 版本](#windows). 建议有软路由的直接在软路由安装Openwrt X86版本.

#### openwrt
3. 如果使用x86 openwrt 软路由, 可以直接使用 SSH登录到软路由上 使用如下脚本安装mosdns. 如果已经安装过mosdns 可以在OpenWRT中先删除mosdns. 在openwrt管理菜单 系统 -> 软件包 -> 过滤器  里面 搜索 mosdns 有两个结果 一个是mosdns 一个是 luci-app-mosdns  2个都点击移除 然后再用下面脚本重新安装就可以了
```bash 
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/dsm/openwrt.sh && chmod +x ./openwrt.sh && ./openwrt.sh
```


4. 使用上面脚本在软路由安装 luci-app-mosdns 完毕后, 请进入OpenWRT管理菜单: 服务-> MosDNS -> MosDNS 配置文件选择 下拉框选择 自定义配置. 然后勾选 启用 复选框后, 点击 保存&应用 按钮 就可以启动 MosDNS. 注意:如果mosdns启动失败, 请先关闭ssr 或 passwall 插件, 因为这些插件内置的PDNSD也运行在5335端口导致冲突. 或者更换mosdns的启动端口.

![mosdns1](https://github.com/jinwyp/one_click_script/blob/master/docs/mosdns1.png?raw=true)

5. 然后在 OpenWRT管理菜单: 网络-> DHCP/DNS -> DNS 转发 填入 127.0.0.1#5335, 因为mosdns运行在软路由的5335端口, 如果mosdns不是运行在软路由而是用下面的脚本运行在其他linux上,则填入对应IP和端口即可. 然后在第二个tab "HOSTS 和解析文件" 勾选 忽略解析文件. 最后点击右下角 保存&应用 按钮完成设置.  注意: 如果没有正确填写转发就勾选了 "忽略解析文件" 会导致无法上网, 忽略解析文件的意思就是在dnsmasq 添加 no-reslov 指令不再使用原有的上游DNS解析. 最后在 ShadowSocksR Plus+ 设置 -> DNS解析方式 -> 使用本机端口为5335的DNS服务. 注意: 默认使用PDNSD TCP查询并缓存, 该项的PDNSD的也运行在5335端口, 所以会导致冲突, 如果mosdns启动失败, 请先关闭ssr 然后选择"使用本机端口为5335的DNS服务"后再启动ssr , 或者更换mosdns的启动端口.
![mosdns2](https://github.com/jinwyp/one_click_script/blob/master/docs/mosdns2.png?raw=true)
![mosdns3](https://github.com/jinwyp/one_click_script/blob/master/docs/mosdns3.png?raw=true)
![mosdns4](https://github.com/jinwyp/one_click_script/blob/master/docs/mosdns4.png?raw=true)

#### linux
6. 如果 linux系统 可以使用如下脚本在linux 系统上安装 mosdns 或 mosdns-cn. 安装完成后按照上面的步骤在路由器中设置DNS即可. 
```bash 
wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/trojan_v2ray_install.sh && chmod +x ./trojan_v2ray_install.sh && ./trojan_v2ray_install.sh
```


#### windows
7. 如果是 windows 系统, 可以从 [mosdns-cn 官方网站](https://github.com/IrineSistiana/mosdns-cn/releases/download/v1.2.3/mosdns-cn-windows-amd64.zip) 下载 mosdns-cn 压缩包直接解压后放到一个目录中. 再下载 [geosite文件](https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat) [geoip文件](https://raw.githubusercontent.com/Loyalsoldier/geoip/release/geoip.dat)  [cnip文件](https://raw.githubusercontent.com/Loyalsoldier/geoip/release/cn.dat)  放到mosdns-cn解压的同一个目录中. 最后运行 ``` mosdns-cn -s :53 --blacklist-domain "geosite.dat:category-ads-all" --local-upstream https://223.5.5.5/dns-query --local-domain "geosite.dat:cn" --local-ip "geoip.dat:cn" --remote-upstream https://8.8.8.8/dns-query --remote-domain "geosite.dat:geolocation-!cn" ``` 即可.


8. 如果是 windows 系统, 也可以直接下载打包好的 [mosdns-cn](https://wws.lanzout.com/i7pYR05e80eh) 解压后运行 run.bat 或运行命令 ``` mosdns-cn --config ./config_mosdns_cn.yaml ```

9. 在 OpenWRT中可以在DHCP给客户端分配IP时, 直接给客户端赋予与路由器IP不同的DNS服务器, 这样无论通过上面方法架设好mosdns后, 把mosdns机器的IP填入下图.客户端就不用手动设置DNS了. OpenWRT管理菜单: 网络 -> 接口 -> LAN 点击"修改" 按钮 进入页面下部 "DHCP 服务器" 部分, 点击第二个tab "高级设置" -> DHCP 选项 填入6,192.168.1.5, 其中192.168.1.5改为mosdns的机器IP就可以了.  这样所有客户端会默认使用mosdns作为DNS服务器, 同时也不需要上面的设置 DHCP/DNS -> DNS 转发 的修改方法了.
![mosdns5](https://github.com/jinwyp/one_click_script/blob/master/docs/mosdns5.png?raw=true)

10. 具体参数可以参考官方网站 https://github.com/IrineSistiana/mosdns-cn 和 https://github.com/IrineSistiana/mosdns

### DNS服务器列表大全

1. [AdGuard 官方DNS服务器列表1](https://kb.adguard.com/en/general/dns-providers)

2. [DNS服务器列表2](https://dns.icoa.cn/), [https://dns.icoa.cn/](https://dns.icoa.cn/)

