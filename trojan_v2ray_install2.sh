#!/bin/bash


# fonts color
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
bold(){
    echo -e "\033[1m\033[01m$1\033[0m"
}




osRelease=""
osSystemPackage=""
osSystemMdPath=""

# 系统检测版本
function getLinuxOSVersion(){
    # copy from 秋水逸冰 ss scripts
    if [[ -f /etc/redhat-release ]]; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
    elif cat /etc/issue | grep -Eqi "debian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
    elif cat /proc/version | grep -Eqi "debian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
    fi
    echo "OS info: ${osRelease}, ${osSystemPackage}, ${osSystemMdPath}"
}


osPort80=""
osPort443=""
osSELINUXCheck=""
osSELINUXCheckIsRebootInput=""

function testLinuxPortUsage(){
    $osSystemPackage -y install net-tools socat

    osPort80=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 80`
    osPort443=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 443`

    if [ -n "$osPort80" ]; then
        process80=`netstat -tlpn | awk -F '[: ]+' '$5=="80"{print $9}'`
        red "==========================================================="
        red "检测到80端口被占用，占用进程为：${process80}，本次安装结束"
        red "==========================================================="
        exit 1
    fi

    if [ -n "$osPort443" ]; then
        process443=`netstat -tlpn | awk -F '[: ]+' '$5=="443"{print $9}'`
        red "============================================================="
        red "检测到443端口被占用，占用进程为：${process443}，本次安装结束"
        red "============================================================="
        exit 1
    fi

    osSELINUXCheck=$(grep SELINUX= /etc/selinux/config | grep -v "#")
    if [ "$osSELINUXCheck" == "SELINUX=enforcing" ]; then
        red "======================================================================="
        red "检测到SELinux为开启强制模式状态，为防止申请证书失败，请先重启VPS后，再执行本脚本"
        red "======================================================================="
        read -p "是否现在重启? 请输入 [Y/n] :" osSELINUXCheckIsRebootInput
        [ -z "${osSELINUXCheckIsRebootInput}" ] && osSELINUXCheckIsRebootInput="y"

        if [[ $osSELINUXCheckIsRebootInput == [Yy] ]]; then
            sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
            setenforce 0
            echo -e "VPS 重启中..."
            reboot
        fi
        exit
    fi

    if [ "$osSELINUXCheck" == "SELINUX=permissive" ]; then
        red "======================================================================="
        red "检测到SELinux为宽容模式状态，为防止申请证书失败，请先重启VPS后，再执行本脚本"
        red "======================================================================="
        read -p "是否现在重启? 请输入 [Y/n] :" osSELINUXCheckIsRebootInput
        [ -z "${osSELINUXCheckIsRebootInput}" ] && osSELINUXCheckIsRebootInput="y"

        if [[ $osSELINUXCheckIsRebootInput == [Yy] ]]; then
            sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
            setenforce 0
            echo -e "VPS 重启中..."
            reboot
        fi
        exit
    fi

    if [ "$osRelease" == "centos" ]; then
        if  [ -n "$(grep ' 6\.' /etc/redhat-release)" ] ; then
            red "==============="
            red "当前系统不受支持"
            red "==============="
            exit
        fi

        if  [ -n "$(grep ' 5\.' /etc/redhat-release)" ] ; then
            red "==============="
            red "当前系统不受支持"
            red "==============="
            exit
        fi

        sudo systemctl stop firewalld
        sudo systemctl disable firewalld
        rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
        $osSystemPackage update -y
        $osSystemPackage install curl wget git unzip zip tar -y
        $osSystemPackage install xz -y
        $osSystemPackage install iputils-ping -y

    elif [ "$osRelease" == "ubuntu" ]; then
        if  [ -n "$(grep ' 14\.' /etc/os-release)" ] ;then
            red "==============="
            red "当前系统不受支持"
            red "==============="
            exit
        fi
        if  [ -n "$(grep ' 12\.' /etc/os-release)" ] ;then
            red "==============="
            red "当前系统不受支持"
            red "==============="
            exit
        fi

        sudo systemctl stop ufw
        sudo systemctl disable ufw
        $osSystemPackage update -y
        $osSystemPackage install curl wget git unzip zip tar -y
        $osSystemPackage install xz-utils -y
        $osSystemPackage install iputils-ping -y

    elif [ "$osRelease" == "debian" ]; then
        $osSystemPackage update -y
        $osSystemPackage install curl wget git unzip zip tar -y
        $osSystemPackage install xz-utils -y
        $osSystemPackage install iputils-ping -y
    fi

}




# 设置SSH root 登录

function setLinuxRootLogin(){

    read -p "是否设置允许root登陆(ssh密钥方式 或 密码方式登陆 )? 请输入[Y/n]?" osIsRootLoginInput
    osIsRootLoginInput=${osIsRootLoginInput:-Y}

    if [[ $osIsRootLoginInput == [Yy] ]]; then

        if [ "$osRelease" == "centos" ] || [ "$osRelease" == "debian" ] ; then
            sudo sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
        fi
        if [ "$osRelease" == "ubuntu" ]; then
            sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
        fi

        green "设置允许root登陆成功!"
    fi


    read -p "是否设置允许root使用密码登陆(上一步请先设置允许root登陆才可以)? 请输入[Y/n]?" osIsRootLoginWithPasswordInput
    osIsRootLoginWithPasswordInput=${osIsRootLoginWithPasswordInput:-Y}

    if [[ $osIsRootLoginWithPasswordInput == [Yy] ]]; then
        sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
        green "设置允许root使用密码登陆成功!"
    fi


    if [ "$osRelease" == "centos" ] ; then
        sudo service sshd restart
        sudo systemctl restart sshd

        green "设置成功, 请用shell工具软件登陆vps服务器!"
    fi

    if [ "$osRelease" == "ubuntu" ] || [ "$osRelease" == "debian" ] ; then
        sudo service ssh restart
        sudo systemctl restart ssh

        green "设置成功, 请用shell工具软件登陆vps服务器!"
    fi

    # /etc/init.d/ssh restart

}

function changeLinuxSSHPort(){
    green "修改的SSH登陆的端口号, 不要使用常用的端口号. 例如 20|21|23|25|53|69|80|110|443|123!"
    read -p "请输入要修改的端口号(必须是纯数字并且在1024~65535之间或22):" osSSHLoginPortInput
    osSSHLoginPortInput=${osSSHLoginPortInput:-0}

    if [ $osSSHLoginPortInput -eq 22 -o $osSSHLoginPortInput -gt 1024 -a $osSSHLoginPortInput -lt 65535 ]; then
        sed -i "s/#\?Port [0-9]*/Port $osSSHLoginPortInput/g" /etc/ssh/sshd_config

        if [ "$osRelease" == "centos" ] ; then
            sudo service sshd restart
            sudo systemctl restart sshd
        fi

        if [ "$osRelease" == "ubuntu" ] || [ "$osRelease" == "debian" ] ; then
            sudo service ssh restart
            sudo systemctl restart ssh
        fi

        green "设置成功, 请记住设置的端口号 ${osSSHLoginPortInput}!"
        green "登陆服务器命令: ssh -p ${osSSHLoginPortInput} root@111.111.111.your ip !"
    else
        echo "输入的端口号错误! 范围: 22,1025~65534"
    fi
}

function setLinuxDateZone(){

    green " =================================================="
    yellow "当前时区为: $(date -R)"
    yellow "是否设置时区为北京时间 +0800区, 以便cron定时重启脚本按照北京时间运行."
    green " =================================================="
    # read 默认值 https://stackoverflow.com/questions/2642585/read-a-variable-in-bash-with-a-default-value

    read -p "是否设置为北京时间 +0800 时区? 请输入[Y/n]?" osTimezoneInput
    osTimezoneInput=${osTimezoneInput:-Y}

    if [[ $osTimezoneInput == [Yy] ]]; then
        if [[ -f /etc/localtime ]] && [[ -f /usr/share/zoneinfo/Asia/Shanghai ]];  then
            mv /etc/localtime /etc/localtime.bak
            cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

            yellow "设置成功! 当前时区已设置为 $(date -R)"
            green " =================================================="
        fi
    fi
}



# 软件安装

function installBBR(){
    $osSystemPackage install wget git -y
    wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
}

function installSoftEditor(){
    # 安装 micro 编辑器
    if [[ ! -f "${HOME}/bin/micro" ]] ;  then
        mkdir -p ${HOME}/bin
        cd ${HOME}/bin
        curl https://getmic.ro | bash

        cp ${HOME}/bin/micro /usr/local/bin

        green " =================================================="
        yellow " micro 编辑器 安装成功!"
        green " =================================================="
    fi

    # 设置vim 中文乱码
    if [[ ! -d "${HOME}/.vimrc" ]] ;  then
        cat > "${HOME}/.vimrc" <<-EOF
set fileencodings=utf-8,gb2312,gb18030,gbk,ucs-bom,cp936,latin1
set enc=utf8
set fencs=utf8,gbk,gb2312,gb18030

syntax on
set nu!

EOF
    fi
}

function installSoftOhMyZsh(){

    green " =================================================="
    yellow " 准备安装 ZSH"
    green " =================================================="

    if [ "$osRelease" == "centos" ]; then

        sudo $osSystemPackage install zsh -y
        $osSystemPackage install util-linux-user -y

    elif [ "$osRelease" == "ubuntu" ]; then

        sudo $osSystemPackage install zsh -y

    elif [ "$osRelease" == "debian" ]; then

        sudo $osSystemPackage install zsh -y
    fi

    green " =================================================="
    yellow " ZSH 安装成功, 准备安装 oh-my-zsh"
    green " =================================================="

    # 安装 oh-my-zsh
    if [[ ! -d "${HOME}/.oh-my-zsh" ]] ;  then
        curl -Lo ${HOME}/ohmyzsh_install.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
        chmod +x ${HOME}/ohmyzsh_install.sh
        sh ${HOME}/ohmyzsh_install.sh --unattended
    fi

    if [[ ! -d "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]] ;  then
        git clone "https://github.com/zsh-users/zsh-autosuggestions" "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"

        # 配置 zshrc 文件
        zshConfig=${HOME}/.zshrc
        zshTheme="maran"
        sed -i 's/ZSH_THEME=.*/ZSH_THEME="'${zshTheme}'"/' $zshConfig
        sed -i 's/plugins=(git)/plugins=(git cp history z rsync colorize zsh-autosuggestions)/' $zshConfig

        zshAutosuggestionsConfig=${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
        sed -i "s/ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'/ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=1'/" $zshAutosuggestionsConfig


        # Actually change the default shell to zsh
        zsh=$(which zsh)

        if ! chsh -s "$zsh"; then
            error "chsh command unsuccessful. Change your default shell manually."
        else
            export SHELL="$zsh"
            green "===== Shell successfully changed to '$zsh'."
        fi


        echo 'alias lla="ll -ah"' >> ${HOME}/.zshrc
        echo 'alias mi="micro"' >> ${HOME}/.zshrc

        green "oh-my-zsh 安装成功, 请exit命令退出服务器后重新登陆vps服务器即可启动 oh-my-zsh!"

    fi

}




# 网络测速

function vps_superspeed(){
	bash <(curl -Lso- https://git.io/superspeed)
	wget -N --no-check-certificate https://raw.githubusercontent.com/ernisn/superspeed/master/superspeed.sh && chmod +x superspeed.sh && ./superspeed.sh
}

function vps_zbench(){
	wget -N --no-check-certificate https://raw.githubusercontent.com/FunctionClub/ZBench/master/ZBench-CN.sh && chmod +x ZBench-CN.sh && ./ZBench-CN.sh
}

function vps_testrace(){
	wget -N --no-check-certificate https://raw.githubusercontent.com/nanqinlang-script/testrace/master/testrace.sh && chmod +x testrace.sh && ./testrace.sh
}

function vps_LemonBench(){
    wget -O LemonBench.sh -N --no-check-certificate https://ilemonra.in/LemonBenchIntl && chmod +x LemonBench.sh && ./LemonBench.sh fast
}



configNetworkRealIp=""
configNetworkLocalIp=""
configSSLDomain=""

configSSLCertPath="${HOME}/website/cert"
configWebsitePath="${HOME}/website/html"
configTrojanWindowsCliPrefixPath=$(cat /dev/urandom | head -1 | md5sum | head -c 20)
configWebsiteDownloadPath="${configWebsitePath}/download/${configTrojanWindowsCliPrefixPath}"
configDownloadTempPath="${HOME}/temp"

configTrojanPath="${HOME}/trojan"
configTrojanGoPath="${HOME}/trojan-go"

configTrojanBasePath=${configTrojanPath}



versionTrojan="1.16.0"
downloadFilenameTrojan="trojan-${versionTrojan}-linux-amd64.tar.xz"

versionTrojanGo="0.8.1"
downloadFilenameTrojanGo="trojan-go-linux-amd64.zip"

versionV2ray="4.27.5"
downloadFilenameV2ray="v2ray-linux-64.zip"


promptInfoTrojanName=""
isTrojanGo="no"
isTrojanGoSupportWebsocket="false"


nginxConfigPath="/etc/nginx/nginx.conf"
nginxAccessLogFilePath="${HOME}/nginx-access.log"
nginxErrorLogFilePath="${HOME}/nginx-error.log"



configV2rayWebSocketPath=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
configV2rayPort="$(($RANDOM + 10000))"



function downloadAndUnzip(){
    if [ -z $1 ]; then
        green " ================================================== "
        green "     下载文件地址为空!"
        green " ================================================== "
        exit
    fi
    if [ -z $2 ]; then
        green " ================================================== "
        green "     目标路径地址为空!"
        green " ================================================== "
        exit
    fi
    if [ -z $3 ]; then
        green " ================================================== "
        green "     下载文件的文件名为空!"
        green " ================================================== "
        exit
    fi

    wget -O ${configDownloadTempPath}/$3 $1
    unzip -d $2 ${configDownloadTempPath}/$3
}

function getGithubLatestReleaseVersion(){
    # https://github.com/p4gefau1t/trojan-go/issues/63
    # trojanVersion="0.5.1"
    wget --no-check-certificate -qO- https://api.github.com/repos/$1/tags | grep 'name' | cut -d\" -f4 | head -1 | cut -b 2-
}

function getTrojanAndV2rayVersion(){
    versionTrojan=$(getGithubLatestReleaseVersion "trojan-gfw/trojan")
    downloadFilenameTrojan="trojan-${versionTrojan}-linux-amd64.tar.xz"

    versionTrojanGo=$(getGithubLatestReleaseVersion "p4gefau1t/trojan-go")
    downloadFilenameTrojanGo="trojan-go-linux-amd64.zip"

    versionV2ray=$(getGithubLatestReleaseVersion "v2fly/v2ray-core")
    downloadFilenameV2ray="v2ray-linux-64.zip"

    echo "versionTrojan: ${versionTrojan}"
    echo "versionTrojanGo: ${versionTrojanGo}"
    echo "versionV2ray: ${versionV2ray}"
}

function stopServiceNginx(){
    serviceNginxStatus=`ps -aux | grep "nginx: worker" | grep -v "grep"`
    if [[ -n "$serviceNginxStatus" ]]; then
        sudo systemctl stop nginx.service
    fi
}

function stopServiceV2ray(){
    if [[ -f "${osSystemMdPath}v2ray.service" ]] || [[ -f "/etc/systemd/system/v2ray.service" ]] || [[ -f "/lib/systemd/system/v2ray.service" ]] ; then
        sudo systemctl stop v2ray.service
    fi
}

function isTrojanGoInstall(){
    if [ "$isTrojanGo" = "yes" ] ; then
        configTrojanBasePath="$configTrojanGoPath"
        promptInfoTrojanName="-go"
    fi
}


function compareRealIpWithLocalIp(){

    if [ -n $1 ]; then
        configNetworkRealIp=`ping $1 -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
        configNetworkLocalIp=`curl ipv4.icanhazip.com`

        if [[ ${configNetworkRealIp} == ${configNetworkLocalIp} ]] ; then
            green "=========================================="
            green " 域名解析地址为 ${configNetworkRealIp}, 本VPS的IP为 ${configNetworkLocalIp}. 域名解析正常!"
            green "=========================================="
            true
        else
            red "================================"
            red "域名解析地址与本VPS IP地址不一致"
            red "本次安装失败，请确保域名解析正常"
            red "================================"
            false
        fi
    else
        false
    fi
}

function getHTTPSCertificate(){

    # 申请https证书
	mkdir -p ${configSSLCertPath}
	curl https://get.acme.sh | sh

    green "=========================================="

	if [[ $1 == "standalone" ]] ; then
	    green "  开始重新申请证书 acme.sh standalone mode !"
	    ~/.acme.sh/acme.sh  --issue  -d ${configSSLDomain}  --standalone
	else
	    green "  开始第一次申请证书 acme.sh nginx mode !"
        ~/.acme.sh/acme.sh  --issue  -d ${configSSLDomain}  --webroot ${configWebsitePath}/
    fi

    ~/.acme.sh/acme.sh  --installcert  -d ${configSSLDomain}   \
        --key-file   ${configSSLCertPath}/private.key \
        --fullchain-file ${configSSLCertPath}/fullchain.cer \
        --reloadcmd  "systemctl force-reload  nginx.service"
}



function installWebServerNginx(){

    green " ================================================== "
    yellow "     开始安装 Web服务器 nginx !"
    green " ================================================== "

    sleep 1s

    stopServiceV2ray

    if test -s ${nginxConfigPath}; then
        green " ================================================== "
        green "     Nginx 已存在, 退出安装!"
        green " ================================================== "
        exit
    fi

    ${osSystemPackage} install nginx -y
    sudo systemctl enable nginx.service
    sudo systemctl stop nginx.service

    cat > "${nginxConfigPath}" <<-EOF
user  root;
worker_processes  1;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  $nginxAccessLogFilePath  main;
    error_log $nginxErrorLogFilePath;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  120;
    client_max_body_size 20m;
    #gzip  on;

    server {
        listen       80;
        server_name  $configSSLDomain;
        root $configWebsitePath;
        index index.php index.html index.htm;

        location /$configV2rayWebSocketPath {
            proxy_redirect off;
            proxy_pass http://127.0.0.1:$configV2rayPort;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$http_host;
        }
    }
}
EOF

    # 下载伪装站点 并设置伪装网站
    rm -rf ${configWebsitePath}/*
    mkdir -p ${configWebsiteDownloadPath}

    downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/website.zip" "${configWebsitePath}" "website.zip"
    downloadAndUnzip "https://github.com/jinwyp/Trojan/raw/master/trojan_client_all.zip" "${configWebsiteDownloadPath}" "trojan_client_all.zip"

    sudo systemctl start nginx.service

    green " ================================================== "
    green "       Web服务器 nginx 安装成功!!"
    green " ================================================== "
}

function installTrojanWholeProcess(){

    stopServiceNginx
    testLinuxPortUsage

    isTrojanGoInstall

    green "=============================================="
    yellow "请输入绑定到本VPS的域名 安装时请关闭CDN后安装！"
    if [[ $1 == "repair" ]] ; then
        blue "务必与之前安装失败时使用的域名一致"
    fi
    green "=============================================="

    read configSSLDomain
    if compareRealIpWithLocalIp "${configSSLDomain}" ; then

        if [[ -z $1 ]] ; then
            installWebServerNginx
            getHTTPSCertificate
        else
            getHTTPSCertificate "standalone"
        fi

        if test -s ${configSSLCertPath}/fullchain.cer; then
            green "=========================================="
            green "       证书获取成功!!"
            green "=========================================="
            # install_trojan_server
        else
            red "==================================="
            red " https证书没有申请成功，安装失败!"
            red " 请检查域名和DNS是否生效, 同一域名请不要一天内多次申请!"
            red " 请检查80和443端口是否开启, VPS服务商可能需要添加额外防火墙规则，例如阿里云、谷歌云等!"
            red " 重启VPS, 重新执行脚本, 可重新选择修复证书选项再次申请证书 ! "
            red " 可参考 https://www.v2rayssr.com/trojan-2.html "
            red "==================================="
            exit
        fi
    else
        exit
    fi

}




function start_menu(){
    clear

    if [[ $1 == "first" ]] ; then
        getLinuxOSVersion
        ${osSystemPackage} -y install wget curl
    fi

    green " =================================================="
    green " Trojan Trojan-go V2ray 一键安装脚本 2020-9-2 更新  "
    green " 系统支持：centos7+ / debian9+ / ubuntu16.04+"
    red " *请不要在任何生产环境使用此脚本"
    red " *请不要有其他程序占用80和443端口"
    red " *若是已安装trojan或第二次使用脚本，请先执行卸载trojan"
    green " =================================================="
    echo
    green " 1. 安装 BBR-PLUS 加速4合一脚本"
    echo
    green " 2. 安装 trojan 和 nginx 不支持CDN"
    green " 3. 修复证书 并继续安装 trojan"
    green " 4. 升级 trojan 到最新版本"
    red " 5. 卸载 trojan 与 nginx"
    echo
    green " 6. 安装 trojan-go 和 nginx 不支持CDN, 不开启websocket "
    green " 7. 修复证书 并继续安装 trojan-go 不支持CDN, 不开启websocket"
    green " 8. 安装 trojan-go 和 nginx 支持CDN, 开启websocket "
    green " 9. 修复证书 并继续安装 trojan-go 支持CDN, 开启websocket "
    green " 10. 升级 trojan-go 到最新版本"
    red " 11. 卸载 trojan-go 与 nginx"
    echo
    green " 12. 安装 v2ray 和 nginx, 支持 websocket tls1.3, 支持CDN"
    green " 13. 升级 v2ray 到最新版本"
    red " 14. 卸载v2ray 和 nginx"
    echo
    green " 15. 同时安装 trojan + v2ray 和 nginx, 不支持CDN"
    green " 16. 升级 v2ray 和 trojan 到最新版本"
    red " 17. 卸载 trojan + v2ray 和 nginx"
    echo
    green " =================================================="
    green " 21. 安装OhMyZsh与插件zsh-autosuggestions, Micro编辑器 等软件"
    green " 22. 设置可以使用root登陆"
    green " 23. 修改SSH 登陆端口号"
    green " =================================================="
    green " 以下是 VPS 测网速工具"
    red " 脚本测速会大量消耗 VPS 流量，请悉知！"
    green " 31. superspeed 三网纯测速 （全国各地三大运营商部分节点全面测速）"
    green " 32. ZBench 综合网速测试  （包含节点测速, Ping 以及 路由测试）"
	green " 33. testrace 回程路由  （四网路由测试）"
	green " 34. LemonBench 快速全方位测试 （包含CPU内存性能、回程、速度）"
    echo
    green " 0. 退出脚本"
    echo
    read -p "请输入数字:" menuNumberInput
    case "$menuNumberInput" in
        1 )
            installBBR
        ;;
        2 )
            installTrojanWholeProcess
        ;;
        3 )
            installTrojanWholeProcess "repair"
        ;;
        4 )
            upgrade_trojan "trojan"
        ;;
        5 )
            remove_trojan
        ;;
        6 )
            isTrojanGo="yes"
            installTrojanWholeProcess
        ;;
        7 )
            isTrojanGo="yes"
            installTrojanWholeProcess "repair"
        ;;
        8 )
            isTrojanGo="yes"
            isTrojanGoSupportWebsocket="true"
            installTrojanWholeProcess
        ;;
        9 )
            isTrojanGo="yes"
            isTrojanGoSupportWebsocket="true"
            installTrojanWholeProcess "repair"
        ;;
        9 )
            isTrojanGo="yes"
            upgrade_trojan "trojan-go"
        ;;
        10 )
            isTrojanGo="yes"
            remove_trojan
        ;;
        12 )
            install_caddy
            install_v2ray
        ;;
        13 )
            upgrade_v2ray
        ;;
        14 )
            remove_caddy
        ;;
        15 )
            installTrojanWholeProcess
            install_v2ray
        ;;
        16 )
            upgrade_trojan "trojan"
            upgrade_v2ray
        ;;
        17 )
            remove_trojan
            remove_v2ray
        ;;
        21 )
            setLinuxDateZone
            testLinuxPortUsage
            installSoftEditor
            installSoftOhMyZsh
        ;;
        22 )
            setLinuxRootLogin
            sleep 5s
            start_menu
        ;;
        23 )
            changeLinuxSSHPort
            sleep 10s
            start_menu
        ;;
        99 )
            getTrojanAndV2rayVersion
        ;;
        31 )
            vps_superspeed
        ;;
        32 )
            vps_zbench
        ;;
        33 )
            vps_testrace
        ;;
        34 )
            vps_LemonBench
        ;;
        0 )
            exit 1
        ;;
        * )
            clear
            red "请输入正确数字 !"
            sleep 2s
            start_menu
        ;;
    esac
}



start_menu "first"

