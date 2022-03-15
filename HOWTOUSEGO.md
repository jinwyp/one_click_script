# How to use software by go language



## 如何使用go语言开发的软件

### 区分服务器端还是客户端使用的软件, 区分命令行客户端软件不同操作系统平台


1. 很多软件首先要区分是用在服务器端还是客户端. 服务器端(即运行在linux操作系统下服务器端软件,而且是命令行软件,没有图形界面). 客户端(即平常使用的 windows/Mac/iOS/Android 系统)

#### 例子1 例如内网穿透软件FRP

1. 例子1 例如内网穿透软件FRP https://github.com/fatedier/frp
打开github官方网页后首先找到右边 Releases 处, 可以看到当前最新版本是0.39.0
![软件使用11](https://github.com/jinwyp/one_click_script/blob/master/docs/go1.png?raw=true)


2. 点击 Releases 进入已编译打包好的程序下载页面 https://github.com/fatedier/frp/releases

![软件使用12](https://github.com/jinwyp/one_click_script/blob/master/docs/go2.png?raw=true)

3. 这里就要下载服务器端还是客户端软件. 如果要下载服务器端, 正常情况一般linux服务器都是x86架构的64位CPU, 需要下载 frp_0.39.0_linux_amd64.tar.gz. 就是要下载"amd64"字样的服务器端程序. 如果服务器是很老的32位CPU 需要下载 frp_0.39.0_linux_386.tar.gz. 就是要下载"386"字样的服务器端. 如果服务器是使用ARM的CPU,同样需要区分是64位的ARM还是32位的ARM CPU. 64位的ARM对应下载frp_0.39.0_linux_arm64.tar.gz, 32位的ARM CPU 对应下载frp_0.39.0_linux_arm.tar.gz.

4. 下载完成后解压出来 frps是用于服务器端, frpc是用于客户端.

5. 一般用户用的都是客户端 并且都是 windows/Mac/iOS/Android 系统. 就要下载 windows 客户端 frp_0.39.0_windows_amd64.zip. 或下载 Mac 客户端 frp_0.39.0_darwin_amd64.tar.gz. Mac就是要下载"darwin"字样的程序. 而新出的M1芯片的Mac由于是ARM架构, 就需要下载frp_0.39.0_darwin_arm64.tar.gz.  下载完成后解压出来 frpc是用于客户端. 通常需要先修改配置文件然后运行frpc就可以了.

#### 例子2 V2ray 

1. 例子2 V2ray https://github.com/v2fly/v2ray-core
打开github官方网页后首先找到右边 Releases 处, 可以看到当前最新版本是4.44.0
![软件使用11](https://github.com/jinwyp/one_click_script/blob/master/docs/gov1.png?raw=true)


2. 点击 Releases 进入已编译打包好的程序下载页面 https://github.com/v2fly/v2ray-core/releases 由于目前v2ray 5.0版本是开发者预览版本还不稳定, 把页面向下翻找到4.44.0版本

![软件使用12](https://github.com/jinwyp/one_click_script/blob/master/docs/gov2.png?raw=true)

![软件使用13](https://github.com/jinwyp/one_click_script/blob/master/docs/gov3.png?raw=true)


3. 这里就要下载服务器端还是客户端软件. 如果要下载服务器端, 正常情况一般linux服务器都是x86架构的64位CPU, 需要下载 v2ray-linux-64.zip. 就是要下载"64"字样的服务器端程序. 如果服务器是很老的32位CPU 需要下载 v2ray-linux-32.zip. 就是要下载"32"字样的服务器端. 如果服务器是使用ARM的CPU,同样需要区分是64位的ARM还是32位的ARM CPU. 64位的ARM对应下载v2ray-linux-arm64-v8a.zip, 32位的ARM CPU 对应下载v2ray-linux-arm32-v7a.zip 或 v2ray-linux-arm32-v6.zip.

4. 下载完成后解压出来 与frp不同, v2ray服务器端与客户端是同一个文件, 都是v2ray, 是通过v2ray 配置文件来区分启动的是服务器端还是客户端

5. 一般用户用的都是客户端 并且都是 windows/Mac/iOS/Android 系统. 就要下载 windows 客户端 v2ray-windows-64.zip. 或下载 Mac 客户端 v2ray-macos-64.zip. 而新出的M1芯片的Mac由于是ARM架构, 就需要下载v2ray-macos-arm64-v8a.zip. Android 客户端就下载v2ray-android-arm64-v8a.zip 下载完成后解压出来, 通常需要先修改配置文件然后运行v2ray就可以了.




### 区分是命令行程序还是带有UI的GUI界面软件

1. 上面是命令行方式运行的程序核心文件. 对于普通用户来说命令行方式需要手动修改配置文件很不方便. 所以对普通用户来说肯定需要找对应的UI带界面的程序,这样使用起来才方便. UI带界面的程序与原来的命令行程序都是不同项目不同人开发的. 所以有的界面集成了核心命令程序, 有的没有集成核心命令行程序只是一个界面需要自己手动下载命令行与UI界面程序放到一起.

2. 同样用v2ray举例, 不同平台的v2ray UI界面程序五花八门, 名字叫什么的都有, 所以要区分仅仅是v2ray的界面程序还是 根本就不是v2ray的UI界面程序而是可以支持v2ray的协议的程序例如Clash

3. 这里先说仅仅是v2ray的UI界面程序. 例如 windows平台 v2rayN 根据上面介绍进入v2rayN项目的下载Releases 页面 https://github.com/2dust/v2rayN/releases 当前版本4.29

![软件使用15](https://github.com/jinwyp/one_click_script/blob/master/docs/gov5.png?raw=true)

4. 由于 v2rayN只针对 windows 平台 所以不需要区分平台版本, 下载 v2rayN-Core.zip 带v2ray命令行核心文件. 或下载 v2rayN.zip 只有界面程序需要手动下载 [v2ray命令行程序](https://github.com/v2fly/v2ray-core/releases)

5. 这种界面程序与核心程序分开的好处就是 如果核心命令行有新功能升级了, 可以单独升级命令行核心程序. 在v2rayN可以点击 检查更新 升级v2ray-core或xray-core. 这里简单说明一下 v2ray-core和xray-core的区别. xray-core基本与v2ray-core相同, 但xray-core 多支持一种XTLS加密方式, XTLS速度快,但需要服务器端开启. 具体详细请看[xray官方文档](https://xtls.github.io/). 如果需要使用XTLS加密, 需要在v2rayN中参数设置-> v2rayN 设置 -> Core类型设置 使用xray-core.


![软件使用15](https://github.com/jinwyp/one_click_script/blob/master/docs/gov6.png?raw=true)

6. windows 平台下的v2ray的UI界面程序 还有WinXray  [官方地址](https://github.com/TheMRLL/WinXray/releases)

7. [Qv2ray](https://github.com/Qv2ray/Qv2ray/releases)也是一个v2ray的UI界面程序, 而且支持windows和Mac, 还可以通过插件支持trojan等其他协议.

8. 不同平台下都有不同的UI界面程序, 有的集成了核心命令行程序有的没有集成, 所以要学会到官方github网站上下载最新版程序. Windows 平台: v2rayN / Qv2ray / WinXray.  Android 平台: v2rayNG / Kitsunebi.  iOS 平台(只能通过apple store 购买获得): Shadowrocket / Quantumult / Quantumult X. OpenWrt 路由器平台: PassWall / Hello World / ShadowSocksR Plus+

### 本身不是某个软件的UI界面程序 例如 Clash 与  Quantumult X

1. [Clash](https://github.com/Dreamacro/clash) 本身并不是v2ray的UI界面程序. Clash本身自己是个独立的代理平台软件,主要用来提供SOCKS5/HTTP代理. 而随后支持V2ray的Vmess协议, 同时还支持 Shadowsocks, Snell, Trojan等其他协议.

2. 同样 Clash也是go语言开发的命令行软件, 用户要方便使用还需要找对应平台的UI客户端. 例如 windows 平台下UI界面客户端 [clash_for_windows](https://github.com/Fndroid/clash_for_windows_pkg/releases) 注意 clash_for_windows 没有开源, 安全性未知.  Mac平台下Clash的UI界面客户端 [clashX](https://github.com/yichengchen/clashX).  Android平台下Clash的UI界面客户端 [ClashForAndroid](https://github.com/Kr328/ClashForAndroid).



### 关于 TLS 加密与各种协议的介绍和具体使用方法 敬请期待

