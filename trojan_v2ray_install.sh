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
osSystemShell="bash"

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

    [[ -z $(echo $SHELL|grep zsh) ]] && osSystemShell="bash" || osSystemShell="zsh"

    echo "OS info: ${osRelease}, ${osSystemPackage}, ${osSystemMdPath}， ${osSystemShell}"
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

    tempCurrentDateZone=$(date +'%z')

    if [[ ${tempCurrentDateZone} == "+0800" ]]; then
        yellow "当前时区已经为北京时间  $tempCurrentDateZone | $(date -R) "
    else 
        green " =================================================="
        yellow "当前时区为: $tempCurrentDateZone | $(date -R) "
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

    fi
}



# 软件安装

function installBBR(){
    wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
}

function installBBR2(){
    wget -N --no-check-certificate "https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
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

        green " =================================================="
        yellow " oh-my-zsh 安装成功, 请用exit命令退出服务器后重新登陆即可!"
        green " =================================================="

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



versionTrojan="1.16.0"
downloadFilenameTrojan="trojan-${versionTrojan}-linux-amd64.tar.xz"

versionTrojanGo="0.8.2"
downloadFilenameTrojanGo="trojan-go-linux-amd64.zip"

versionV2ray="4.27.5"
downloadFilenameV2ray="v2ray-linux-64.zip"

versionTrojanWeb="2.8.7"
downloadFilenameTrojanWeb="trojan"

promptInfoTrojanName=""
isTrojanGo="no"
isTrojanGoSupportWebsocket="false"
configTrojanGoWebSocketPath=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
configTrojanPasswordPrefixInput="jin"

configTrojanPath="${HOME}/trojan"
configTrojanGoPath="${HOME}/trojan-go"
configTrojanWebPath="${HOME}/trojan-web"
configTrojanLogFile="${HOME}/trojan-access.log"
configTrojanGoLogFile="${HOME}/trojan-go-access.log"

configTrojanBasePath=${configTrojanPath}
configTrojanBaseVersion=${versionTrojan}

configTrojanWebNginxPath=$(cat /dev/urandom | head -1 | md5sum | head -c 5)
configTrojanWebPort="$(($RANDOM + 10000))"

isNginxWithSSL="no"
nginxConfigPath="/etc/nginx/nginx.conf"
nginxAccessLogFilePath="${HOME}/nginx-access.log"
nginxErrorLogFilePath="${HOME}/nginx-error.log"



configV2rayWebSocketPath=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
configV2rayPort="$(($RANDOM + 10000))"

configV2rayPath="${HOME}/v2ray"
configV2rayAccessLogFilePath="${HOME}/v2ray-access.log"
configV2rayErrorLogFilePath="${HOME}/v2ray-error.log"
configV2rayProtocol="vmess"



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

    mkdir -p ${configDownloadTempPath}

    if [[ $3 == *"tar.xz"* ]]; then
        green "===== 下载并解压tar文件: $3 "
        wget -O ${configDownloadTempPath}/$3 $1
        tar xf ${configDownloadTempPath}/$3 -C ${configDownloadTempPath}
        mv ${configDownloadTempPath}/trojan/* $2
        rm -rf ${configDownloadTempPath}/trojan
    else
        green "===== 下载并解压zip文件:  $3 "
        wget -O ${configDownloadTempPath}/$3 $1
        unzip -d $2 ${configDownloadTempPath}/$3
    fi

}

function getGithubLatestReleaseVersion(){
    # https://github.com/p4gefau1t/trojan-go/issues/63
    wget --no-check-certificate -qO- https://api.github.com/repos/$1/tags | grep 'name' | cut -d\" -f4 | head -1 | cut -b 2-
}

function getTrojanAndV2rayVersion(){
    # https://github.com/trojan-gfw/trojan/releases/download/v1.16.0/trojan-1.16.0-linux-amd64.tar.xz
    # https://github.com/p4gefau1t/trojan-go/releases/download/v0.8.1/trojan-go-linux-amd64.zip

    if [[ $1 == "trojan" ]] ; then
        versionTrojan=$(getGithubLatestReleaseVersion "trojan-gfw/trojan")
        downloadFilenameTrojan="trojan-${versionTrojan}-linux-amd64.tar.xz"
        echo "versionTrojan: ${versionTrojan}"
    fi

    if [[ $1 == "trojan-go" ]] ; then
        versionTrojanGo=$(getGithubLatestReleaseVersion "p4gefau1t/trojan-go")
        downloadFilenameTrojanGo="trojan-go-linux-amd64.zip"
        echo "versionTrojanGo: ${versionTrojanGo}"
    fi

    if [[ $1 == "v2ray" ]] ; then
        versionV2ray=$(getGithubLatestReleaseVersion "v2fly/v2ray-core")
        downloadFilenameV2ray="v2ray-linux-64.zip"
        echo "versionV2ray: ${versionV2ray}"
    fi

    if [[ $1 == "trojan-web" ]] ; then
        versionTrojanWeb=$(getGithubLatestReleaseVersion "Jrohy/trojan")
        downloadFilenameTrojanWeb="trojan"
        echo "versionTrojanWeb: ${versionTrojanWeb}"
    fi

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
        getTrojanAndV2rayVersion "trojan-go"
        configTrojanBaseVersion=${versionTrojanGo}
        configTrojanBasePath="${configTrojanGoPath}"
        promptInfoTrojanName="-go"
    else
        getTrojanAndV2rayVersion "trojan"
        configTrojanBaseVersion=${versionTrojan}
        configTrojanBasePath="${configTrojanPath}"
        promptInfoTrojanName=""
    fi
}


function compareRealIpWithLocalIp(){

    if [ -n $1 ]; then
        configNetworkRealIp=`ping $1 -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
        configNetworkLocalIp=`curl ipv4.icanhazip.com`

        if [[ ${configNetworkRealIp} == ${configNetworkLocalIp} ]] ; then
            green " ================================================== "
            green "     域名解析地址为 ${configNetworkRealIp}, 本VPS的IP为 ${configNetworkLocalIp}. 域名解析正常!"
            green " ================================================== "
            true
        else
            green " ================================================== "
            red "     域名解析地址与本VPS IP地址不一致!"
            red "     本次安装失败，请确保域名解析正常!"
            green " ================================================== "
            false
        fi
    else
        false
    fi
}

function getHTTPSCertificate(){

    # 申请https证书
	mkdir -p ${configSSLCertPath}
	mkdir -p ${configWebsitePath}
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

    if test -s ${nginxConfigPath}; then
        green " ================================================== "
        red "     Nginx 已存在, 退出安装!"
        green " ================================================== "
        exit
    fi

    stopServiceV2ray

    ${osSystemPackage} install nginx -y
    sudo systemctl enable nginx.service
    sudo systemctl stop nginx.service

    if [[ -z $1 ]] ; then
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
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] '
                      '"\$request" \$status \$body_bytes_sent  '
                      '"\$http_referer" "\$http_user_agent" "\$http_x_forwarded_for"';
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
            proxy_pass http://127.0.0.1:$configV2rayPort;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$http_host;

            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }
    }
}
EOF

    elif [[ $1 == "trojan-web" ]] ; then

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
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] '
                      '"\$request" \$status \$body_bytes_sent  '
                      '"\$http_referer" "\$http_user_agent" "\$http_x_forwarded_for"';
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
            proxy_pass http://127.0.0.1:$configV2rayPort;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$http_host;
        }

        location /$configTrojanWebNginxPath {
            proxy_pass http://127.0.0.1:$configTrojanWebPort/;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Host \$http_host;
        }

        location ~* ^/(js|css|vendor|common|auth|trojan)/ {
            proxy_pass  http://127.0.0.1:$configTrojanWebPort;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$http_host;
        }

        # http redirect to https
        if ( \$remote_addr != 127.0.0.1 ){
            rewrite ^/(.*)$ https://$configSSLDomain/\$1 redirect;
        }
    }
}
EOF
    else
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
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] '
                      '"\$request" \$status \$body_bytes_sent  '
                      '"\$http_referer" "\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  $nginxAccessLogFilePath  main;
    error_log $nginxErrorLogFilePath;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  120;
    client_max_body_size 20m;
    #gzip  on;

    server {
        listen 443 ssl http2;
        listen [::]:443 http2;
        server_name  $configSSLDomain;

        ssl_certificate       ${configSSLCertPath}/fullchain.cer;
        ssl_certificate_key   ${configSSLCertPath}/private.key;
        ssl_protocols         TLSv1.2;
        ssl_ciphers           TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5;

        # Config for 0-RTT in TLSv1.3
        ssl_early_data on;
        ssl_stapling on;
        ssl_stapling_verify on;
        add_header Strict-Transport-Security "max-age=31536000";

        root $configWebsitePath;
        index index.php index.html index.htm;

        location /$configV2rayWebSocketPath {
            proxy_pass http://127.0.0.1:$configV2rayPort;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$http_host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }
    }

    server {
        listen 80;
        listen [::]:80;
        server_name  $configSSLDomain;
        return 301 https://$configSSLDomain\$request_uri;
    }
}
EOF
    fi



    # 下载伪装站点 并设置伪装网站
    rm -rf ${configWebsitePath}/*
    mkdir -p ${configWebsiteDownloadPath}

    downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/website.zip" "${configWebsitePath}" "website.zip"
    downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/trojan_client_all.zip" "${configWebsiteDownloadPath}" "trojan_client_all.zip"
    downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/trojan-qt5.zip" "${configWebsiteDownloadPath}" "trojan-qt5.zip"
    
    downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/v2ray_client_all.zip" "${configWebsiteDownloadPath}" "v2ray_client_all.zip"
    wget -P "${configWebsiteDownloadPath}" "https://github.com/jinwyp/one_click_script/raw/master/download/v2ray-android.zip"

    sudo systemctl start nginx.service

    green " ================================================== "
    green "       Web服务器 nginx 安装成功!!"
    green "    伪装站点为 http://${configSSLDomain}"

	if [[ $1 == "trojan-web" ]] ; then
	    yellow "    Trojan-web ${versionTrojanWeb} 可视化管理面板地址  http://${configSSLDomain}/${configTrojanWebNginxPath} "
	    green "    Trojan-web 可视化管理面板 可执行文件路径 ${configTrojanWebPath}/trojan-web"
	    green "    Trojan 服务器端可执行文件路径 /usr/bin/trojan/trojan"
	    green "    Trojan 服务器端配置路径 /usr/local/etc/trojan/config.json "
	    green "    Trojan-web 停止命令: systemctl stop trojan-web.service  启动命令: systemctl start trojan-web.service  重启命令: systemctl restart trojan-web.service"
	    green "    Trojan 停止命令: systemctl stop trojan.service  启动命令: systemctl start trojan.service  重启命令: systemctl restart trojan.service"
	fi

    green "    伪装站点的静态html内容放置在目录 ${configWebsitePath}, 可自行更换网站内容!"
	green "    nginx 配置路径 ${nginxConfigPath} "
	green "    nginx 访问日志 ${nginxAccessLogFilePath} "
	green "    nginx 错误日志 ${nginxErrorLogFilePath} "
	green "    nginx 停止命令: systemctl stop nginx.service  启动命令: systemctl start nginx.service  重启命令: systemctl restart nginx.service"
    green " ================================================== "
}

function removeNginx(){

    sudo systemctl stop nginx.service

    green " ================================================== "
    red " 准备卸载已安装的nginx"
    green " ================================================== "

    if [ "$osRelease" == "centos" ]; then
        yum remove -y nginx
    else
        apt autoremove -y --purge nginx nginx-common nginx-core
        apt-get remove --purge nginx nginx-full nginx-common
    fi

    rm -rf ${configSSLCertPath}
    rm -rf ${configWebsitePath}
    rm -f ${nginxAccessLogFilePath}
    rm -f ${nginxErrorLogFilePath}

    rm -rf "/etc/nginx"
    rm -rf /root/.acme.sh/
    rm -rf ${configDownloadTempPath}

    green " ================================================== "
    green "  Nginx 卸载完毕 !"
    green " ================================================== "
}


function installTrojanWholeProcess(){

    stopServiceNginx
    testLinuxPortUsage

    green " ================================================== "
    yellow " 请输入绑定到本VPS的域名 例如www.xxx.com: (此步骤请关闭CDN后安装)"
    if [[ $1 == "repair" ]] ; then
        blue " 务必与之前安装失败时使用的域名一致"
    fi
    green " ================================================== "

    read configSSLDomain
    if compareRealIpWithLocalIp "${configSSLDomain}" ; then

        if [[ -z $1 ]] ; then
            if [ "$isNginxWithSSL" = "no" ] ; then
                installWebServerNginx
                getHTTPSCertificate
            else
                getHTTPSCertificate "standalone"
                installWebServerNginx "v2ray"
            fi

        else
            getHTTPSCertificate "standalone"
        fi

        if test -s ${configSSLCertPath}/fullchain.cer; then
            green " ================================================== "
            green "     SSL证书获取成功!"
            green " ================================================== "

            if [ "$isNginxWithSSL" = "no" ] ; then
                installTrojanServer
            else
                installV2ray
            fi
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




function installTrojanServer(){

    trojanPassword1=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
    trojanPassword2=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
    trojanPassword3=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
    trojanPassword4=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
    trojanPassword5=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
    trojanPassword6=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
    trojanPassword7=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
    trojanPassword8=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
    trojanPassword9=$(cat /dev/urandom | head -1 | md5sum | head -c 10)
    trojanPassword10=$(cat /dev/urandom | head -1 | md5sum | head -c 10)

    isTrojanGoInstall

    if [[ -f "${configTrojanBasePath}/trojan${promptInfoTrojanName}" ]]; then
        green " =================================================="
        green "  已安装过 Trojan${promptInfoTrojanName} , 退出安装 !"
        green " =================================================="
        exit
    fi


    green " =================================================="
    green " 开始安装 Trojan${promptInfoTrojanName} Version: ${configTrojanBaseVersion} !"
    yellow " 请输入trojan密码的前缀? (会生成若干随机密码和带有该前缀的密码)"
    green " =================================================="

    read configTrojanPasswordPrefixInput
    configTrojanPasswordPrefixInput=${configTrojanPasswordPrefixInput:-jin}

    mkdir -p ${configTrojanBasePath}
    cd ${configTrojanBasePath}
    rm -rf ${configTrojanBasePath}/*

    if [ "$isTrojanGo" = "no" ] ; then
        # https://github.com/trojan-gfw/trojan/releases/download/v1.16.0/trojan-1.16.0-linux-amd64.tar.xz
        downloadAndUnzip "https://github.com/trojan-gfw/trojan/releases/download/v${versionTrojan}/${downloadFilenameTrojan}" "${configTrojanPath}" "${downloadFilenameTrojan}"
    else
        # https://github.com/p4gefau1t/trojan-go/releases/download/v0.8.1/trojan-go-linux-amd64.zip
        downloadAndUnzip "https://github.com/p4gefau1t/trojan-go/releases/download/v${versionTrojanGo}/${downloadFilenameTrojanGo}" "${configTrojanGoPath}" "${downloadFilenameTrojanGo}"
    fi




    if [ "$isTrojanGo" = "no" ] ; then

        # 增加trojan 服务器端配置
	    cat > ${configTrojanBasePath}/server.json <<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "${trojanPassword1}",
        "${trojanPassword2}",
        "${trojanPassword3}",
        "${trojanPassword4}",
        "${trojanPassword5}",
        "${trojanPassword6}",
        "${trojanPassword7}",
        "${trojanPassword8}",
        "${trojanPassword9}",
        "${trojanPassword10}",
        "${configTrojanPasswordPrefixInput}202000",
        "${configTrojanPasswordPrefixInput}202010",
        "${configTrojanPasswordPrefixInput}202011",
        "${configTrojanPasswordPrefixInput}202012",
        "${configTrojanPasswordPrefixInput}202013",
        "${configTrojanPasswordPrefixInput}202014",
        "${configTrojanPasswordPrefixInput}202015",
        "${configTrojanPasswordPrefixInput}202016",
        "${configTrojanPasswordPrefixInput}202017",
        "${configTrojanPasswordPrefixInput}202018",
        "${configTrojanPasswordPrefixInput}202019",
        "${configTrojanPasswordPrefixInput}202020",
        "${configTrojanPasswordPrefixInput}202021",
        "${configTrojanPasswordPrefixInput}202022",
        "${configTrojanPasswordPrefixInput}202023",
        "${configTrojanPasswordPrefixInput}202024",
        "${configTrojanPasswordPrefixInput}202025",
        "${configTrojanPasswordPrefixInput}202026",
        "${configTrojanPasswordPrefixInput}202027",
        "${configTrojanPasswordPrefixInput}202028",
        "${configTrojanPasswordPrefixInput}202029",
        "${configTrojanPasswordPrefixInput}202030",
        "${configTrojanPasswordPrefixInput}202031",
        "${configTrojanPasswordPrefixInput}202032",
        "${configTrojanPasswordPrefixInput}202033",
        "${configTrojanPasswordPrefixInput}202034",
        "${configTrojanPasswordPrefixInput}202035",
        "${configTrojanPasswordPrefixInput}202036",
        "${configTrojanPasswordPrefixInput}202037",
        "${configTrojanPasswordPrefixInput}202038",
        "${configTrojanPasswordPrefixInput}202039",
        "${configTrojanPasswordPrefixInput}202040",
        "${configTrojanPasswordPrefixInput}202041",
        "${configTrojanPasswordPrefixInput}202042",
        "${configTrojanPasswordPrefixInput}202043",
        "${configTrojanPasswordPrefixInput}202044",
        "${configTrojanPasswordPrefixInput}202045",
        "${configTrojanPasswordPrefixInput}202046",
        "${configTrojanPasswordPrefixInput}202047",
        "${configTrojanPasswordPrefixInput}202048",
        "${configTrojanPasswordPrefixInput}202049",
        "${configTrojanPasswordPrefixInput}202050",
        "${configTrojanPasswordPrefixInput}202051",
        "${configTrojanPasswordPrefixInput}202052",
        "${configTrojanPasswordPrefixInput}202053",
        "${configTrojanPasswordPrefixInput}202054",
        "${configTrojanPasswordPrefixInput}202055",
        "${configTrojanPasswordPrefixInput}202056",
        "${configTrojanPasswordPrefixInput}202057",
        "${configTrojanPasswordPrefixInput}202058",
        "${configTrojanPasswordPrefixInput}202059",
        "${configTrojanPasswordPrefixInput}202060",
        "${configTrojanPasswordPrefixInput}202061",
        "${configTrojanPasswordPrefixInput}202062",
        "${configTrojanPasswordPrefixInput}202063",
        "${configTrojanPasswordPrefixInput}202064",
        "${configTrojanPasswordPrefixInput}202065",
        "${configTrojanPasswordPrefixInput}202066",
        "${configTrojanPasswordPrefixInput}202067",
        "${configTrojanPasswordPrefixInput}202068",
        "${configTrojanPasswordPrefixInput}202069",
        "${configTrojanPasswordPrefixInput}202070",
        "${configTrojanPasswordPrefixInput}202071",
        "${configTrojanPasswordPrefixInput}202072",
        "${configTrojanPasswordPrefixInput}202073",
        "${configTrojanPasswordPrefixInput}202074",
        "${configTrojanPasswordPrefixInput}202075",
        "${configTrojanPasswordPrefixInput}202076",
        "${configTrojanPasswordPrefixInput}202077",
        "${configTrojanPasswordPrefixInput}202078",
        "${configTrojanPasswordPrefixInput}202079",
        "${configTrojanPasswordPrefixInput}202080",
        "${configTrojanPasswordPrefixInput}202081",
        "${configTrojanPasswordPrefixInput}202082",
        "${configTrojanPasswordPrefixInput}202083",
        "${configTrojanPasswordPrefixInput}202084",
        "${configTrojanPasswordPrefixInput}202085",
        "${configTrojanPasswordPrefixInput}202086",
        "${configTrojanPasswordPrefixInput}202087",
        "${configTrojanPasswordPrefixInput}202088",
        "${configTrojanPasswordPrefixInput}202089",
        "${configTrojanPasswordPrefixInput}202090",
        "${configTrojanPasswordPrefixInput}202091",
        "${configTrojanPasswordPrefixInput}202092",
        "${configTrojanPasswordPrefixInput}202093",
        "${configTrojanPasswordPrefixInput}202094",
        "${configTrojanPasswordPrefixInput}202095",
        "${configTrojanPasswordPrefixInput}202096",
        "${configTrojanPasswordPrefixInput}202097",
        "${configTrojanPasswordPrefixInput}202098",
        "${configTrojanPasswordPrefixInput}202099"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "${configSSLCertPath}/fullchain.cer",
        "key": "${configSSLCertPath}/private.key",
        "key_password": "",
        "cipher_tls13":"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
	    "prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": ""
    }
}
EOF


        # 增加启动脚本
        cat > ${osSystemMdPath}trojan.service <<-EOF
[Unit]
Description=trojan
After=network.target

[Service]
Type=simple
PIDFile=${configTrojanPath}/trojan.pid
ExecStart=${configTrojanPath}/trojan -l ${configTrojanLogFile} -c "${configTrojanPath}/server.json"
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
RestartPreventExitStatus=23
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    fi


    if [ "$isTrojanGo" = "yes" ] ; then

        # 增加trojan 服务器端配置
	    cat > ${configTrojanBasePath}/server.json <<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "${trojanPassword1}",
        "${trojanPassword2}",
        "${trojanPassword3}",
        "${trojanPassword4}",
        "${trojanPassword5}",
        "${trojanPassword6}",
        "${trojanPassword7}",
        "${trojanPassword8}",
        "${trojanPassword9}",
        "${trojanPassword10}",
        "${configTrojanPasswordPrefixInput}202000",
        "${configTrojanPasswordPrefixInput}202010",
        "${configTrojanPasswordPrefixInput}202011",
        "${configTrojanPasswordPrefixInput}202012",
        "${configTrojanPasswordPrefixInput}202013",
        "${configTrojanPasswordPrefixInput}202014",
        "${configTrojanPasswordPrefixInput}202015",
        "${configTrojanPasswordPrefixInput}202016",
        "${configTrojanPasswordPrefixInput}202017",
        "${configTrojanPasswordPrefixInput}202018",
        "${configTrojanPasswordPrefixInput}202019",
        "${configTrojanPasswordPrefixInput}202020",
        "${configTrojanPasswordPrefixInput}202021",
        "${configTrojanPasswordPrefixInput}202022",
        "${configTrojanPasswordPrefixInput}202023",
        "${configTrojanPasswordPrefixInput}202024",
        "${configTrojanPasswordPrefixInput}202025",
        "${configTrojanPasswordPrefixInput}202026",
        "${configTrojanPasswordPrefixInput}202027",
        "${configTrojanPasswordPrefixInput}202028",
        "${configTrojanPasswordPrefixInput}202029",
        "${configTrojanPasswordPrefixInput}202030",
        "${configTrojanPasswordPrefixInput}202031",
        "${configTrojanPasswordPrefixInput}202032",
        "${configTrojanPasswordPrefixInput}202033",
        "${configTrojanPasswordPrefixInput}202034",
        "${configTrojanPasswordPrefixInput}202035",
        "${configTrojanPasswordPrefixInput}202036",
        "${configTrojanPasswordPrefixInput}202037",
        "${configTrojanPasswordPrefixInput}202038",
        "${configTrojanPasswordPrefixInput}202039",
        "${configTrojanPasswordPrefixInput}202040",
        "${configTrojanPasswordPrefixInput}202041",
        "${configTrojanPasswordPrefixInput}202042",
        "${configTrojanPasswordPrefixInput}202043",
        "${configTrojanPasswordPrefixInput}202044",
        "${configTrojanPasswordPrefixInput}202045",
        "${configTrojanPasswordPrefixInput}202046",
        "${configTrojanPasswordPrefixInput}202047",
        "${configTrojanPasswordPrefixInput}202048",
        "${configTrojanPasswordPrefixInput}202049",
        "${configTrojanPasswordPrefixInput}202050",
        "${configTrojanPasswordPrefixInput}202051",
        "${configTrojanPasswordPrefixInput}202052",
        "${configTrojanPasswordPrefixInput}202053",
        "${configTrojanPasswordPrefixInput}202054",
        "${configTrojanPasswordPrefixInput}202055",
        "${configTrojanPasswordPrefixInput}202056",
        "${configTrojanPasswordPrefixInput}202057",
        "${configTrojanPasswordPrefixInput}202058",
        "${configTrojanPasswordPrefixInput}202059",
        "${configTrojanPasswordPrefixInput}202060",
        "${configTrojanPasswordPrefixInput}202061",
        "${configTrojanPasswordPrefixInput}202062",
        "${configTrojanPasswordPrefixInput}202063",
        "${configTrojanPasswordPrefixInput}202064",
        "${configTrojanPasswordPrefixInput}202065",
        "${configTrojanPasswordPrefixInput}202066",
        "${configTrojanPasswordPrefixInput}202067",
        "${configTrojanPasswordPrefixInput}202068",
        "${configTrojanPasswordPrefixInput}202069",
        "${configTrojanPasswordPrefixInput}202070",
        "${configTrojanPasswordPrefixInput}202071",
        "${configTrojanPasswordPrefixInput}202072",
        "${configTrojanPasswordPrefixInput}202073",
        "${configTrojanPasswordPrefixInput}202074",
        "${configTrojanPasswordPrefixInput}202075",
        "${configTrojanPasswordPrefixInput}202076",
        "${configTrojanPasswordPrefixInput}202077",
        "${configTrojanPasswordPrefixInput}202078",
        "${configTrojanPasswordPrefixInput}202079",
        "${configTrojanPasswordPrefixInput}202080",
        "${configTrojanPasswordPrefixInput}202081",
        "${configTrojanPasswordPrefixInput}202082",
        "${configTrojanPasswordPrefixInput}202083",
        "${configTrojanPasswordPrefixInput}202084",
        "${configTrojanPasswordPrefixInput}202085",
        "${configTrojanPasswordPrefixInput}202086",
        "${configTrojanPasswordPrefixInput}202087",
        "${configTrojanPasswordPrefixInput}202088",
        "${configTrojanPasswordPrefixInput}202089",
        "${configTrojanPasswordPrefixInput}202090",
        "${configTrojanPasswordPrefixInput}202091",
        "${configTrojanPasswordPrefixInput}202092",
        "${configTrojanPasswordPrefixInput}202093",
        "${configTrojanPasswordPrefixInput}202094",
        "${configTrojanPasswordPrefixInput}202095",
        "${configTrojanPasswordPrefixInput}202096",
        "${configTrojanPasswordPrefixInput}202097",
        "${configTrojanPasswordPrefixInput}202098",
        "${configTrojanPasswordPrefixInput}202099"
    ],
    "log_level": 1,
    "log_file": "${configTrojanGoLogFile}",
    "ssl": {
        "verify": true,
        "verify_hostname": true,
        "cert": "${configSSLCertPath}/fullchain.cer",
        "key": "${configSSLCertPath}/private.key",
        "key_password": "",
	    "prefer_server_cipher": false,
        "alpn": [
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": "",
        "sni": "${configSSLDomain}",
        "fingerprint": "firefox"
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true
    },
    "websocket": {
        "enabled": ${isTrojanGoSupportWebsocket},
        "path": "/${configTrojanGoWebSocketPath}",
        "host": "${configSSLDomain}"
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": ""
    }
}
EOF

        # 增加启动脚本
        cat > ${osSystemMdPath}trojan-go.service <<-EOF
[Unit]
Description=trojan-go
After=network.target

[Service]
Type=simple
PIDFile=${configTrojanGoPath}/trojan-go.pid
ExecStart=${configTrojanGoPath}/trojan-go -config "${configTrojanGoPath}/server.json"
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
    fi

    chmod +x ${osSystemMdPath}trojan${promptInfoTrojanName}.service
    sudo systemctl daemon-reload
    sudo systemctl start trojan${promptInfoTrojanName}.service
    sudo systemctl enable trojan${promptInfoTrojanName}.service



    # 下载并制作 trojan windows 客户端的命令行启动文件
    rm -rf ${configTrojanBasePath}/trojan-win-cli
    rm -rf ${configTrojanBasePath}/trojan-win-cli-temp
    mkdir -p ${configTrojanBasePath}/trojan-win-cli-temp

    downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/trojan-win-cli.zip" "${configTrojanBasePath}" "trojan-win-cli.zip"

    if [ "$isTrojanGo" = "no" ] ; then
        downloadAndUnzip "https://github.com/trojan-gfw/trojan/releases/download/v${versionTrojan}/trojan-${versionTrojan}-win.zip" "${configTrojanBasePath}/trojan-win-cli-temp" "trojan-${versionTrojan}-win.zip"
        mv -f ${configTrojanBasePath}/trojan-win-cli-temp/trojan/trojan.exe ${configTrojanBasePath}/trojan-win-cli/
        mv -f ${configTrojanBasePath}/trojan-win-cli-temp/trojan/VC_redist.x64.exe ${configTrojanBasePath}/trojan-win-cli/
    fi

    if [ "$isTrojanGo" = "yes" ] ; then
        downloadAndUnzip "https://github.com/p4gefau1t/trojan-go/releases/download/v${versionTrojanGo}/trojan-go-windows-amd64.zip" "${configTrojanBasePath}/trojan-win-cli-temp" "trojan-go-windows-amd64.zip"
        mv -f ${configTrojanBasePath}/trojan-win-cli-temp/* ${configTrojanBasePath}/trojan-win-cli/
    fi

    rm -rf ${configTrojanBasePath}/trojan-win-cli-temp
    cp ${configSSLCertPath}/fullchain.cer ${configTrojanBasePath}/trojan-win-cli/fullchain.cer

    cat > ${configTrojanBasePath}/trojan-win-cli/config.json <<-EOF
{
    "run_type": "client",
    "local_addr": "127.0.0.1",
    "local_port": 1080,
    "remote_addr": "${configSSLDomain}",
    "remote_port": 443,
    "password": [
        "${trojanPassword1}"
    ],
    "log_level": 1,
    "ssl": {
        "verify": true,
        "verify_hostname": true,
        "cert": "fullchain.cer",
        "cipher_tls13":"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
	    "sni": "",
        "alpn": [
            "h2",
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "curves": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": false,
        "fast_open_qlen": 20
    }
}
EOF

    zip -r ${configWebsiteDownloadPath}/trojan-win-cli.zip ${configTrojanBasePath}/trojan-win-cli/




    # 设置 cron 定时任务
    # https://stackoverflow.com/questions/610839/how-can-i-programmatically-create-a-new-cron-job

    # (crontab -l 2>/dev/null | grep -v '^[a-zA-Z]'; echo "15 4 * * 0,1,2,3,4,5,6 systemctl restart trojan.service") | sort - | uniq - | crontab -
    (crontab -l ; echo "10 4 * * 0,1,2,3,4,5,6 systemctl restart trojan${promptInfoTrojanName}.service") | sort - | uniq - | crontab -


	green "======================================================================"
	green "    Trojan${promptInfoTrojanName} Version: ${configTrojanBaseVersion} 安装成功 !"
	green "    伪装站点为 http://${configSSLDomain}"
	green "    伪装站点的静态html内容放置在目录 ${configWebsitePath}, 可自行更换网站内容!"
	red "    Trojan 服务器端配置路径 ${configTrojanBasePath}/server.json "
	red "    Trojan 访问日志 ${configTrojanLogFile} 或运行 journalctl -u trojan${promptInfoTrojanName}.service 查看 !"
	green "    Trojan 停止命令: systemctl stop trojan${promptInfoTrojanName}.service  启动命令: systemctl start trojan${promptInfoTrojanName}.service  重启命令: systemctl restart trojan${promptInfoTrojanName}.service"
	green "    Trojan 服务器 每天会自动重启,防止内存泄漏. 运行 crontab -l 命令 查看定时重启命令 !"
	green "======================================================================"
	blue  "----------------------------------------"
	yellow "Trojan${promptInfoTrojanName} 配置信息如下, 请自行复制保存, 密码任选其一 !"
	yellow "服务器地址: ${configSSLDomain}  端口: 443"
	yellow "密码1: ${trojanPassword1}"
	yellow "密码2: ${trojanPassword2}"
	yellow "密码3: ${trojanPassword3}"
	yellow "密码4: ${trojanPassword4}"
	yellow "密码5: ${trojanPassword5}"
	yellow "密码6: ${trojanPassword6}"
	yellow "密码7: ${trojanPassword7}"
	yellow "密码8: ${trojanPassword8}"
	yellow "密码9: ${trojanPassword9}"
	yellow "密码10: ${trojanPassword10}"
	yellow "您指定前缀的密码若干: 从 ${configTrojanPasswordPrefixInput}202010 到 ${configTrojanPasswordPrefixInput}202099 都可以使用"

    if [[ ${isTrojanGoSupportWebsocket} == "true" ]]; then
        yellow "Websocket path 路径为: /${configTrojanGoWebSocketPath}"
        # yellow "Websocket obfuscation_password 混淆密码为: ${trojanPasswordWS}"
        yellow "Websocket 双重TLS为: true 开启"
    fi

	blue  "----------------------------------------"
	green "======================================================================"
	green "请下载相应的trojan客户端:"
	yellow "1 Windows 客户端下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/trojan-windows.zip"
	yellow "  Windows 客户端另一个版本下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/trojan-Qt5-windows.zip"
	yellow "  Windows 客户端命令行版本下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/trojan-win-cli.zip"
	yellow "  Windows 客户端命令行版本需要搭配浏览器插件使用，例如switchyomega等! "
    yellow "2 MacOS 客户端下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/trojan-mac.zip"
    yellow "  MacOS 客户端Trojan-Qt5下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/trojan-Qt5-mac.zip"
    yellow "3 Android 客户端下载 https://github.com/trojan-gfw/igniter/releases "
    yellow "4 iOS 客户端 请安装小火箭 https://shadowsockshelp.github.io/ios/ "
    yellow "  iOS 请安装小火箭另一个地址 https://lueyingpro.github.io/shadowrocket/index.html "
    yellow "  iOS 安装小火箭遇到问题 教程 https://github.com/shadowrocketHelp/help/ "
    green "======================================================================"
	green "教程与其他资源:"
	green "访问 https://www.v2rayssr.com/trojan-1.html ‎ 下载 浏览器插件 客户端 及教程"
	green "访问 https://westworldss.com/portal/page/download ‎ 下载 客户端 及教程"
	green "======================================================================"
	green "其他 Windows 客户端:"
	green "https://github.com/TheWanderingCoel/Trojan-Qt5/releases (exe为Win客户端, dmg为Mac客户端)"
	green "https://github.com/Qv2ray/Qv2ray/releases (exe为Win客户端, dmg为Mac客户端)"
	green "https://github.com/Dr-Incognito/V2Ray-Desktop/releases (exe为Win客户端, dmg为Mac客户端)"
	green "https://github.com/Fndroid/clash_for_windows_pkg/releases"
	green "======================================================================"
	green "其他 Mac 客户端:"
	green "https://github.com/TheWanderingCoel/Trojan-Qt5/releases (exe为Win客户端, dmg为Mac客户端)"
	green "https://github.com/Qv2ray/Qv2ray/releases (exe为Win客户端, dmg为Mac客户端)"
	green "https://github.com/Dr-Incognito/V2Ray-Desktop/releases (exe为Win客户端, dmg为Mac客户端)"
	green "https://github.com/JimLee1996/TrojanX/releases (exe为Win客户端, dmg为Mac客户端)"
	green "https://github.com/yichengchen/clashX/releases "
	green "======================================================================"
	green "其他 Android 客户端:"
	green "https://github.com/trojan-gfw/igniter/releases "
	green "https://github.com/Kr328/ClashForAndroid/releases "
	green "======================================================================"
}


function removeTrojan(){

    isTrojanGoInstall

    sudo systemctl stop trojan${promptInfoTrojanName}.service
    sudo systemctl disable trojan${promptInfoTrojanName}.service

    green " ================================================== "
    red " 准备卸载已安装的trojan${promptInfoTrojanName}"
    green " ================================================== "

    rm -rf ${configTrojanBasePath}
    rm -f ${osSystemMdPath}trojan${promptInfoTrojanName}.service
    rm -f ${configTrojanLogFile}
    rm -f ${configTrojanGoLogFile}

    crontab -r

    green " ================================================== "
    green "  trojan${promptInfoTrojanName} 和 nginx 卸载完毕 !"
    green "  crontab 定时任务 删除完毕 !"
    green " ================================================== "
}


function upgradeTrojan(){

    isTrojanGoInstall

    green " ================================================== "
    green "     开始升级 Trojan${promptInfoTrojanName} Version: ${configTrojanBaseVersion}"
    green " ================================================== "

    sudo systemctl stop trojan${promptInfoTrojanName}.service

    mkdir -p ${configDownloadTempPath}/upgrade/trojan${promptInfoTrojanName}

    if [ "$isTrojanGo" = "no" ] ; then
        # https://github.com/trojan-gfw/trojan/releases/download/v1.16.0/trojan-1.16.0-linux-amd64.tar.xz
        downloadAndUnzip "https://github.com/trojan-gfw/trojan/releases/download/v${versionTrojan}/${downloadFilenameTrojan}" "${configDownloadTempPath}/upgrade/trojan" "${downloadFilenameTrojan}"
        mv -f ${configDownloadTempPath}/upgrade/trojan/trojan ${configTrojanPath}
    else
        # https://github.com/p4gefau1t/trojan-go/releases/download/v0.8.1/trojan-go-linux-amd64.zip
        downloadAndUnzip "https://github.com/p4gefau1t/trojan-go/releases/download/v${versionTrojanGo}/${downloadFilenameTrojanGo}" "${configDownloadTempPath}/upgrade/trojan-go" "${downloadFilenameTrojanGo}"
        mv -f ${configDownloadTempPath}/upgrade/trojan-go/trojan-go ${configTrojanGoPath}
    fi

    sudo systemctl start trojan${promptInfoTrojanName}.service

    green " ================================================== "
    green "     升级成功 Trojan${promptInfoTrojanName} Version: ${configTrojanBaseVersion} !"
    green " ================================================== "

}






function installV2ray(){

    v2rayPassword1=$(cat /proc/sys/kernel/random/uuid)
    v2rayPassword2=$(cat /proc/sys/kernel/random/uuid)
    v2rayPassword3=$(cat /proc/sys/kernel/random/uuid)
    v2rayPassword4=$(cat /proc/sys/kernel/random/uuid)
    v2rayPassword5=$(cat /proc/sys/kernel/random/uuid)
    v2rayPassword6=$(cat /proc/sys/kernel/random/uuid)
    v2rayPassword7=$(cat /proc/sys/kernel/random/uuid)
    v2rayPassword8=$(cat /proc/sys/kernel/random/uuid)
    v2rayPassword9=$(cat /proc/sys/kernel/random/uuid)
    v2rayPassword10=$(cat /proc/sys/kernel/random/uuid)

    if [ -f "${configV2rayPath}/v2ray" ] || [ -f "/usr/local/bin/v2ray" ] || [ -f "/usr/bin/v2ray" ]; then
        green " =================================================="
        green "  已安装过 V2ray, 退出安装 !"
        green " =================================================="
        exit
    fi

    getTrojanAndV2rayVersion "v2ray"
    green " =================================================="
    green "    开始安装 V2ray Version: ${versionV2ray} !"
    green " =================================================="

    read -p "是否使用VLESS协议(默认为VMess协议 )? 请输入[Y/n]?" isV2rayUseVLessInput
    isV2rayUseVLessInput=${isV2rayUseVLessInput:-Y}

    if [[ $isV2rayUseVLessInput == [Yy] ]]; then
        configV2rayProtocol="vless"
    else
        configV2rayProtocol="vmess"
    fi

    mkdir -p ${configV2rayPath}
    cd ${configV2rayPath}
    rm -rf ${configV2rayPath}/*

    # https://github.com/v2fly/v2ray-core/releases/download/v4.27.5/v2ray-linux-64.zip
    downloadAndUnzip "https://github.com/v2fly/v2ray-core/releases/download/v${versionV2ray}/${downloadFilenameV2ray}" "${configV2rayPath}" "${downloadFilenameV2ray}"

    # 增加 v2ray 服务器端配置
    cat > ${configV2rayPath}/config.json <<-EOF
{
  "log" : {
    "access": "${configV2rayAccessLogFilePath}",
    "error": "${configV2rayErrorLogFilePath}",
    "loglevel": "warning"
  },
  "inbound": {
    "port": ${configV2rayPort},
    "listen":"127.0.0.1",
    "protocol": "${configV2rayProtocol}",
    "settings": {
      "clients": [
        {
          "id": "${v2rayPassword1}",
          "level": 1,
          "alterId": 64,
          "email": "password11@gmail.com"
        },
        {
          "id": "${v2rayPassword2}",
          "level": 1,
          "alterId": 64,
          "email": "password12@gmail.com"
        },
        {
          "id": "${v2rayPassword3}",
          "level": 1,
          "alterId": 64,
          "email": "password13@gmail.com"
        },
        {
          "id": "${v2rayPassword4}",
          "level": 1,
          "alterId": 64,
          "email": "password14@gmail.com"
        },
        {
          "id": "${v2rayPassword5}",
          "level": 1,
          "alterId": 64,
          "email": "password15@gmail.com"
        },
        {
          "id": "${v2rayPassword6}",
          "level": 1,
          "alterId": 64,
          "email": "password16@gmail.com"
        },
        {
          "id": "${v2rayPassword7}",
          "level": 1,
          "alterId": 64,
          "email": "password17@gmail.com"
        },
        {
          "id": "${v2rayPassword8}",
          "level": 1,
          "alterId": 64,
          "email": "password18@gmail.com"
        },
        {
          "id": "${v2rayPassword9}",
          "level": 1,
          "alterId": 64,
          "email": "password19@gmail.com"
        },
        {
          "id": "${v2rayPassword10}",
          "level": 1,
          "alterId": 64,
          "email": "password20@gmail.com"
        }
      ]
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {
        "path": "/${configV2rayWebSocketPath}"
      }
    }
  },
  "outbound": {
    "protocol": "freedom",
    "settings": {}
  }
}
EOF


    # 增加启动脚本
    cat > ${osSystemMdPath}v2ray.service <<-EOF
[Unit]
Description=V2Ray
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
Type=simple
# This service runs as root. You may consider to run it as another user for security concerns.
# By uncommenting User=nobody and commenting out User=root, the service will run as user nobody.
# More discussion at https://github.com/v2ray/v2ray-core/issues/1011
User=root
#User=nobody
#CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=${configV2rayPath}/v2ray -config ${configV2rayPath}/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF


    # 增加客户端配置说明
    cat > ${configV2rayPath}/clientConfig.json <<-EOF
===========客户端配置参数=============
{
协议:${configV2rayProtocol},
地址:${configSSLDomain},
端口:443,
uuid:${v2rayPassword1},
额外id:64, // 如果是Vless协议则不需要该项
加密方式:aes-128-gcm,
传输协议:ws,
别名:自己起个任意名称,
路径:/${configV2rayWebSocketPath},
底层传输:tls
}
EOF

    sudo systemctl daemon-reload
    sudo systemctl restart v2ray.service

    # 设置 cron 定时任务
    # https://stackoverflow.com/questions/610839/how-can-i-programmatically-create-a-new-cron-job

    (crontab -l ; echo "20 4 * * 0,1,2,3,4,5,6 systemctl restart v2ray.service") | sort - | uniq - | crontab -


    green "======================================================================"
	green "    V2ray Version: ${versionV2ray} 安装成功 !!"
	green "    伪装站点为 https://${configSSLDomain}!"
	# red "    caddy 配置路径 ${caddyConfigFile} !"
	# red "    caddy 访问日志 ${caddyAccessLogFile} !"
	# red "    caddy 错误日志 ${caddyErrorLogFile} !"
	red "    V2ray 服务器端配置路径 ${configV2rayPath}/config.json !"
	red "    V2ray 访问日志 ${configV2rayAccessLogFilePath} !"
	red "    V2ray 错误日志 ${configV2rayErrorLogFilePath} !"
	green "    V2ray 停止命令: systemctl stop v2ray.service  启动命令: systemctl start v2ray.service  重启命令: systemctl restart v2ray.service"
	# green "    caddy 停止命令: systemctl stop caddy.service  启动命令: systemctl start caddy.service  重启命令: systemctl restart caddy.service"
	green "    V2ray 服务器 每天会自动重启,防止内存泄漏. 运行 crontab -l 命令 查看定时重启命令 !"
	green "======================================================================"
	blue  "----------------------------------------"
	yellow "V2ray 配置信息如下, 请自行复制保存, 密码任选其一 (密码即用户ID或UUID) !!"
	yellow "服务器地址: ${configSSLDomain}  端口: 443"
	yellow "用户ID或密码1: ${v2rayPassword1}"
	yellow "用户ID或密码2: ${v2rayPassword2}"
	yellow "用户ID或密码3: ${v2rayPassword3}"
	yellow "用户ID或密码4: ${v2rayPassword4}"
	yellow "用户ID或密码5: ${v2rayPassword5}"
	yellow "用户ID或密码6: ${v2rayPassword6}"
	yellow "用户ID或密码7: ${v2rayPassword7}"
	yellow "用户ID或密码8: ${v2rayPassword8}"
	yellow "用户ID或密码9: ${v2rayPassword9}"
	yellow "用户ID或密码10: ${v2rayPassword10}"

	cat "${configV2rayPath}/clientConfig.json"
	blue  "----------------------------------------"
    green "======================================================================"
    green "请下载相应的 v2ray 客户端:"
    yellow "1 Windows 客户端V2rayN下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/v2ray-windows.zip"
    yellow "2 MacOS 客户端下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/v2ray-mac.zip"
    yellow "3 Android 客户端下载 http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/v2ray-android.zip"
    yellow "4 iOS 客户端 请安装小火箭 https://shadowsockshelp.github.io/ios/ "
    yellow "  iOS 请安装小火箭另一个地址 https://lueyingpro.github.io/shadowrocket/index.html "
    yellow "  iOS 安装小火箭遇到问题 教程 https://github.com/shadowrocketHelp/help/ "
    yellow "其他客户端程序请看 https://www.v2fly.org/awesome/tools.html "
    green "======================================================================"

}


function removeV2ray(){
    green " ================================================== "
    red " 准备卸载已安装 v2ray "
    green " ================================================== "

    sudo systemctl stop v2ray.service
    sudo systemctl disable v2ray.service

    rm -rf ${configV2rayPath}
    rm -f ${osSystemMdPath}v2ray.service
    rm -f ${configV2rayAccessLogFilePath}
    rm -f ${configV2rayErrorLogFilePath}

    green " ================================================== "
    green "  v2ray 卸载完毕 !"
    green " ================================================== "
}


function upgradeV2ray(){
    getTrojanAndV2rayVersion "v2ray"

    green " =================================================="
    green "       开始升级 V2ray Version: ${versionV2ray} !"
    green " =================================================="

    sudo systemctl stop v2ray.service

    mkdir -p ${configDownloadTempPath}/upgrade/v2ray

    downloadAndUnzip "https://github.com/v2fly/v2ray-core/releases/download/v${versionV2ray}/${downloadFilenameV2ray}" "${configDownloadTempPath}/upgrade/v2ray" "${downloadFilenameV2ray}"

    mv -f ${configDownloadTempPath}/upgrade/v2ray/v2ray ${configV2rayPath}
    mv -f ${configDownloadTempPath}/upgrade/v2ray/v2ctl ${configV2rayPath}
    mv -f ${configDownloadTempPath}/upgrade/v2ray/geoip.dat ${configV2rayPath}
    mv -f ${configDownloadTempPath}/upgrade/v2ray/geosite.dat ${configV2rayPath}

    sudo systemctl start v2ray.service

    green " ================================================== "
    green "     升级成功 V2ray Version: ${versionV2ray} !"
    green " ================================================== "
}







function installTrojanWeb(){
    # wget -O trojan-web_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/Jrohy/trojan/master/install.sh" && chmod +x trojan-web_install.sh && ./trojan-web_install.sh


    if [ -f "${configTrojanWebPath}/trojan-web" ] ; then
        green " =================================================="
        green "  已安装过 Trojan-web 可视化管理面板, 退出安装 !"
        green " =================================================="
        exit
    fi

    stopServiceNginx
    testLinuxPortUsage

    green " ================================================== "
    yellow " 请输入绑定到本VPS的域名 例如www.xxx.com: (此步骤请关闭CDN后安装)"
    green " ================================================== "

    read configSSLDomain
    if compareRealIpWithLocalIp "${configSSLDomain}" ; then

        getTrojanAndV2rayVersion "trojan-web"
        green " =================================================="
        green "    开始安装 Trojan-web 可视化管理面板: ${versionTrojanWeb} !"
        green " =================================================="

        mkdir -p ${configTrojanWebPath}
        wget -O ${configTrojanWebPath}/trojan-web --no-check-certificate "https://github.com/Jrohy/trojan/releases/download/v${versionTrojanWeb}/${downloadFilenameTrojanWeb}"
        chmod +x ${configTrojanWebPath}/trojan-web

        # 增加启动脚本
        cat > ${osSystemMdPath}trojan-web.service <<-EOF
[Unit]
Description=trojan-web
Documentation=https://github.com/Jrohy/trojan
After=network.target network-online.target nss-lookup.target mysql.service mariadb.service mysqld.service docker.service

[Service]
Type=simple
StandardError=journal
ExecStart=${configTrojanWebPath}/trojan-web web -p ${configTrojanWebPort}
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl daemon-reload
        sudo systemctl restart trojan-web.service
        sudo systemctl enable trojan-web.service

        green " =================================================="
        green " Trojan-web 可视化管理面板: ${versionTrojanWeb} 安装成功!"
        green " Trojan可视化管理面板地址 https://${configSSLDomain}/${configTrojanWebNginxPath}"
        green " 开始运行命令 ${configTrojanWebPath}/trojan-web 进行初始化设置."
        green " =================================================="



        ${configTrojanWebPath}/trojan-web

        installWebServerNginx "trojan-web"

        # 命令补全环境变量
        echo "export PATH=$PATH:${configTrojanWebPath}" >> ${HOME}/.${osSystemShell}rc

        # (crontab -l ; echo '25 0 * * * "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" > /dev/null') | sort - | uniq - | crontab -
        (crontab -l ; echo "30 4 * * 0,1,2,3,4,5,6 systemctl restart trojan-web.service") | sort - | uniq - | crontab -

    else
        exit
    fi
}

function removeTrojanWeb(){
    # wget -O trojan-web_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/Jrohy/trojan/master/install.sh" && chmod +x trojan-web_install.sh && ./trojan-web_install.sh --remove

    green " ================================================== "
    red " 准备卸载已安装 Trojan-web "
    green " ================================================== "

    sudo systemctl stop trojan.service
    sudo systemctl stop trojan-web.service
    sudo systemctl disable trojan-web.service

    # 移除trojan web 管理程序  和数据库 leveldb文件
    # rm -f /usr/local/bin/trojan
    rm -rf ${configTrojanWebPath}
    rm -f ${osSystemMdPath}trojan-web.service
    rm -rf /var/lib/trojan-manager

    # 移除trojan
    rm -rf /usr/bin/trojan
    rm -rf /usr/local/etc/trojan
    rm -f ${osSystemMdPath}trojan.service

    # 移除trojan的专用数据库
    docker rm -f trojan-mysql
    docker rm -f trojan-mariadb
    rm -rf /home/mysql
    rm -rf /home/mariadb


    # 移除环境变量
    sed -i '/trojan/d' ${HOME}/.${osSystemShell}rc

    crontab -r

    green " ================================================== "
    green "  Trojan-web 卸载完毕 !"
    green " ================================================== "
}

function upgradeTrojanWeb(){
    getTrojanAndV2rayVersion "trojan-web"
    green " =================================================="
    green "    开始升级 Trojan-web 可视化管理面板: ${versionTrojanWeb} !"
    green " =================================================="

    sudo systemctl stop trojan-web.service

    mkdir -p ${configDownloadTempPath}/upgrade/trojan-web

    wget -O ${configDownloadTempPath}/upgrade/trojan-web/trojan-web "https://github.com/Jrohy/trojan/releases/download/v${versionTrojanWeb}/${downloadFilenameTrojanWeb}"
    mv -f ${configDownloadTempPath}/upgrade/trojan-web/trojan-web ${configTrojanWebPath}
    chmod +x ${configTrojanWebPath}/trojan-web

    sudo systemctl start trojan-web.service
    sudo systemctl restart trojan.service


    green " ================================================== "
    green "     升级成功 Trojan-web 可视化管理面板: ${versionTrojanWeb} !"
    green " ================================================== "
}
function runTrojanWebSSL(){
    sudo systemctl stop trojan-web.service
    sudo systemctl stop nginx.service
    sudo systemctl stop trojan.service
    ${configTrojanWebPath}/trojan-web tls
    sudo systemctl start trojan-web.service
    sudo systemctl start nginx.service
    sudo systemctl restart trojan.service
}
function runTrojanWebLog(){
    ${configTrojanWebPath}/trojan-web
}


function installV2rayUI(){

    stopServiceNginx
    testLinuxPortUsage

    green " ================================================== "
    yellow " 请输入绑定到本VPS的域名 例如www.xxx.com: (此步骤请关闭CDN后安装)"
    green " ================================================== "

    read configSSLDomain
    if compareRealIpWithLocalIp "${configSSLDomain}" ; then

        green " =================================================="
        green "    开始安装 V2ray-UI 可视化管理面板 !"
        green " =================================================="

        wget -O v2_ui_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/sprov065/v2-ui/master/install.sh" && chmod +x v2_ui_install.sh && ./v2_ui_install.sh

        green " V2ray-UI 可视化管理面板地址 http://${configSSLDomain}:65432"
        green " V2ray-UI 可视化管理面板 默认管理员用户 admin 密码 admin "
    else
        exit
    fi
}
function removeV2rayUI(){
    green " =================================================="
    /usr/bin/v2-ui
}
function upgradeV2rayUI(){
    green " =================================================="
    /usr/bin/v2-ui
}










function startMenuOther(){
    clear
    green " =================================================="
    green " 1. 安装 trojan-web (trojan 和 trojan-go 可视化管理面板) 和 nginx 伪装网站"
    green " 2. 升级 trojan-web 到最新版本"
    green " 3. 重新申请证书"
    green " 4. 查看日志, 管理用户, 查看配置等功能"
    red " 5. 卸载 trojan-web 和 nginx "
    echo
    green " 6. 安装 v2ray 可视化管理面板V2ray UI"
    green " 7. 升级 v2ray UI 到最新版本"
    red " 8. 卸载 v2ray UI"
    echo
    red " 安装上述2款可视化管理面板 之前不能用本脚本安装过trojan或v2ray 安装过请先用本脚本卸载!"
    red " 安装上述2款可视化管理面板 之前不能用其他脚本安装过trojan或v2ray 安装过请先用其他脚本卸载!"
    red " 上述2款可视化管理面板 无法同时安装!"
    echo
    green " =================================================="
    echo
    green " 以下是 VPS 测网速工具"
    red " 脚本测速会大量消耗 VPS 流量，请悉知！"
    green " 11. superspeed 三网纯测速 （全国各地三大运营商部分节点全面测速）"
    green " 12. ZBench 综合网速测试  （包含节点测速, Ping 以及 路由测试）"
	green " 13. testrace 回程路由  （四网路由测试）"
	green " 14. LemonBench 快速全方位测试 （包含CPU内存性能、回程、速度）"
    echo
    green " 9. 返回上级菜单"
    green " 0. 退出脚本"
    echo
    read -p "请输入数字:" menuNumberInput
    case "$menuNumberInput" in
        1 )
            setLinuxDateZone
            installTrojanWeb
        ;;
        2 )
            upgradeTrojanWeb
        ;;
        3 )
            runTrojanWebSSL
        ;;
        4 )
            runTrojanWebLog
        ;;
        5 )
            removeNginx
            removeTrojanWeb
        ;;
        6 )
            setLinuxDateZone
            installV2rayUI
        ;;
        7 )
            upgradeV2rayUI
        ;;
        8 )
            # removeNginx
            removeV2rayUI
        ;;
        11 )
            vps_superspeed
        ;;
        12 )
            vps_zbench
        ;;
        13 )
            vps_testrace
        ;;
        14 )
            vps_LemonBench
        ;;
        9)
            start_menu
        ;;
        0 )
            exit 1
        ;;
        * )
            clear
            red "请输入正确数字 !"
            sleep 2s
            startMenuOther
        ;;
    esac
}







function start_menu(){
    clear

    if [[ $1 == "first" ]] ; then
        getLinuxOSVersion
        ${osSystemPackage} -y install wget curl git
    fi

    green " =================================================="
    green " Trojan Trojan-go V2ray 一键安装脚本 2020-9-10 更新.  系统支持：centos7+ / debian9+ / ubuntu16.04+"
    red " *请不要在任何生产环境使用此脚本 请不要有其他程序占用80和443端口"
    red " *若是已安装trojan 或第二次使用脚本，请先执行卸载trojan"
    green " =================================================="
    green " 1. 安装 BBR-PLUS 加速4合一脚本"
    echo
    green " 2. 安装 trojan 和 nginx 不支持CDN"
    green " 3. 修复证书 并继续安装 trojan"
    green " 4. 升级 trojan 到最新版本"
    red " 5. 卸载 trojan 与 nginx"
    echo
    green " 6. 安装 trojan-go 和 nginx 不支持CDN, 不开启websocket (兼容trojan客户端)"
    green " 7. 修复证书 并继续安装 trojan-go 不支持CDN, 不开启websocket"
    green " 8. 安装 trojan-go 和 nginx 支持CDN, 开启websocket (不兼容trojan客户端)"
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
    red " 17. 卸载 trojan, v2ray 和 nginx"
    green " 18. 同时安装 trojan-go + v2ray 和 nginx, 不支持CDN"
    green " 19. 同时安装 trojan-go + v2ray 和 nginx, trojan-go 和 v2ray 都支持CDN"
    green " 20. 升级 v2ray 和 trojan-go 到最新版本"
    red " 21. 卸载 trojan-go, v2ray 和 nginx"

    echo
    green " 29. 安装 trojan 和 v2ray 可视化管理面板"
    green " =================================================="
    green " 31. 安装OhMyZsh与插件zsh-autosuggestions, Micro编辑器 等软件"
    green " 32. 设置可以使用root登陆"
    green " 33. 修改SSH 登陆端口号"
    green " 34. 设置时区为北京时间"
    green " =================================================="
    green " 41 VPS 测网速工具"
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
            upgradeTrojan
        ;;
        5 )
            removeNginx
            removeTrojan
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
        10 )
            isTrojanGo="yes"
            upgradeTrojan
        ;;
        11 )
            isTrojanGo="yes"
            removeNginx
            removeTrojan
        ;;
        12 )
            isNginxWithSSL="yes"
            installTrojanWholeProcess
        ;;
        13 )
            upgradeV2ray
        ;;
        14 )
            removeNginx
            removeV2ray
        ;;
        15 )
            installTrojanWholeProcess
            installV2ray
        ;;
        16 )
            upgradeTrojan
            upgradeV2ray
        ;;
        17 )
            removeNginx
            removeTrojan
            removeV2ray
        ;;
        18 )
            isTrojanGo="yes"
            installTrojanWholeProcess
            installV2ray
        ;;
        19 )
            isTrojanGo="yes"
            isTrojanGoSupportWebsocket="true"
            installTrojanWholeProcess
            installV2ray
        ;;
        20 )
            isTrojanGo="yes"
            upgradeTrojan
            upgradeV2ray
        ;;
        21 )
            isTrojanGo="yes"
            removeNginx
            removeTrojan
            removeV2ray
        ;;
        31 )
            setLinuxDateZone
            testLinuxPortUsage
            installSoftEditor
            installSoftOhMyZsh
        ;;
        32 )
            setLinuxRootLogin
            sleep 4s
            start_menu
        ;;
        33 )
            changeLinuxSSHPort
            sleep 10s
            start_menu
        ;;
        34 )
            setLinuxDateZone
            sleep 4s
            start_menu
        ;;
        29 )
            startMenuOther
        ;;
        41 )
            startMenuOther
        ;;
        98 )
            installBBR2
        ;;
        99 )
            getTrojanAndV2rayVersion "trojan"
            getTrojanAndV2rayVersion "trojan-go"
            getTrojanAndV2rayVersion "trojan-web"
            getTrojanAndV2rayVersion "v2ray"
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

