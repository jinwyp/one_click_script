---
name: Bug report 问题报告
about: 用来解决BUG和新功能需求
title: ''
labels: ''
assignees: jinwyp

---

**Describe the bug** A clear and concise description of what the bug is.
在提出问题前请先自行排除服务器端问题和升级到最新客户端，同时也请通过搜索确认是否有人提出过相同问题。


!!! 请务必提供安装的选择的第几项 !!!
!!! 请务必提供什么操作系统 和用的什么终端 !!!
!!! 请务必提供是否开启了Cloudflare 的 CDN !!!
!!! 请用 ping.pe 或 ping.ceo 网站 输入IP:端口号 查看是否被GFW屏蔽 !!!


** Steps to reproduce the behavior: **  请提供使用脚本安装的选择第几项: 

1. 例如选择的第2项 安装trojan. 安装过程中选择了 2 原版trojan-go 
2. 例如选择的第11项 安装v2ray 或 xray . 安装过程中选择了 websocket 选项  并 选择了解锁流媒体

** OS and Terminal: **  系统环境 信息 请务必提供什么操作系统 和用的什么终端 ，还有VPS主机商

- OS: [e.g. Centos]
- Version [e.g. 7]
- Terminal :  例如 Mac的teminal 或 linux ssh 或 zsh 或 Windows putty 或 VPS自带的在线ssh
- VPS  [e.g.  Google Cloud]


** To Reproduce ** 复现方法  

Log Info 日志信息： 请提供安装时出错的信息
例如 xxx

安装完成后 通过以下命令 检查服务是否启动成功  并提供输出日志

1. 检查 trojan 是否启动成功  ``` systemctl status trojan ```
2. 检查 trojan-go 是否启动成功  ``` systemctl status trojan-go ```
3. 检查 v2ray 是否启动成功  ``` systemctl status v2ray ```
4. 检查 xray 是否启动成功  ``` systemctl status xray ```
4. 检查 shadowsocks (xray内核) 是否启动成功  ``` systemctl status shadowsocksxray ```
5. 检查 nginx 是否启动成功  ``` systemctl nginx xray ``` 


安装完成如选择了安装nginx, 请检查 nginx 是否启动成功，域名网站是否能在浏览器正常打开， 是https 还是 http. 正常安装应该是https. 如果打不开说明nginx安装有问题，请给出nginx安装时输出日志

