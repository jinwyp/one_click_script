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


function getGithubLatestReleaseVersion() {
    curl --silent "https://api.github.com/repos/$1/releases/latest" | grep -Po '"tag_name": "v\K.*?(?=")'
}

function getGithubLatestReleaseVersion2() {
    # https://github.com/p4gefau1t/trojan-go/issues/63
    # trojanVersion="0.5.1"
    wget --no-check-certificate -qO- https://api.github.com/repos/$1/tags | grep 'name' | cut -d\" -f4 | head -1 | cut -b 2-
}


function setDateZone(){

    green "=================================================="
    yellow "当前时区为: $(date -R)"
    yellow "是否设置时区为北京时间 +0800区, 以便cron定时重启脚本按照北京时间运行."
    green "=================================================="
    # read 默认值 https://stackoverflow.com/questions/2642585/read-a-variable-in-bash-with-a-default-value

    read -p "是否设置为北京时间 +0800 时区? 请输入[Y/n]?" osTimezone
    osTimezone=${osTimezone:-Y}

    if [[ $osTimezone == [Yy] ]]; then
        if [[ -f /etc/localtime ]] && [[ -f /usr/share/zoneinfo/Asia/Shanghai ]];  then
            mv /etc/localtime /etc/localtime.bak
            cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

            yellow "设置成功! 当前时区已设置为 $(date -R)"
            green "=================================================="
        fi
    fi
}

function setRootLogin() {
    
    read -p "是否设置允许root登陆(ssh密钥方式 或 密码方式登陆 )? 请输入[Y/n]?" osIsRootLogin
    osIsRootLogin=${osIsRootLogin:-Y}

    if [[ $osIsRootLogin == [Yy] ]]; then

        if [ "$osRelease" == "centos" ] || [ "$osRelease" == "debian" ] ; then
            sudo sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
        fi
        if [ "$osRelease" == "ubuntu" ]; then
            sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
        fi  

        green "设置允许root登陆成功!"

    fi


    read -p "是否设置允许root使用密码登陆(上一步请先设置允许root登陆才可以)? 请输入[Y/n]?" osIsRootLoginWithPassword
    osIsRootLoginWithPassword=${osIsRootLoginWithPassword:-Y}

    if [[ $osIsRootLoginWithPassword == [Yy] ]]; then
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

function changeSSHPort() {
    green "修改的SSH登陆的端口号, 不要使用常用的端口号. 例如 20|21|23|25|53|69|80|110|443|123!"
    read -p "请输入要修改的端口号(必须是纯数字并且在1024~65535之间或22):" osSSHPort
    osSSHPort=${osSSHPort:-0}

    if [ $osSSHPort -eq 22 -o $osSSHPort -gt 1024 -a $osSSHPort -lt 65535 ]; then
        sed -i "s/#\?Port [0-9]*/Port $osSSHPort/g" /etc/ssh/sshd_config

        if [ "$osRelease" == "centos" ] ; then
            sudo service sshd restart
            sudo systemctl restart sshd
        fi

        if [ "$osRelease" == "ubuntu" ] || [ "$osRelease" == "debian" ] ; then
            sudo service ssh restart
            sudo systemctl restart ssh
        fi   

        green "设置成功, 请记住设置的端口号 ${osSSHPort}!"
        green "登陆服务器命令: ssh -p ${osSSHPort} root@111.111.111.your ip !"
    else
        echo "输入的端口号错误! 范围: 22,1025~65534"
    fi
}


function installOnMyZsh(){
    setDateZone
    testPortUsage

    # 安装 micro 编辑器
    if [[ ! -f "${HOME}/bin/micro" ]] ;  then
        mkdir -p ${HOME}/bin
        cd ${HOME}/bin
        curl https://getmic.ro | bash

        cp ${HOME}/bin/micro /usr/local/bin
    fi


    green "=============================="
    yellow "准备安装 ZSH"
    green "=============================="

    if [ "$osRelease" == "centos" ]; then

        sudo $osSystemPackage install zsh -y
        $osSystemPackage install util-linux-user -y

    elif [ "$osRelease" == "ubuntu" ]; then

        sudo $osSystemPackage install zsh -y

    elif [ "$osRelease" == "debian" ]; then

        sudo $osSystemPackage install zsh -y
    fi

    green "=============================="
    yellow " ZSH 安装成功, 准备安装 oh-my-zsh"
    green "=============================="

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




osRelease=""
osSystemPackage=""
osSystemmdPath=""

function getLinuxOSVersion(){
    # copy from 秋水逸冰 ss scripts
    if [[ -f /etc/redhat-release ]]; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemmdPath="/usr/lib/systemd/system/"
    elif cat /etc/issue | grep -Eqi "debian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemmdPath="/lib/systemd/system/"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemmdPath="/lib/systemd/system/"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemmdPath="/usr/lib/systemd/system/"
    elif cat /proc/version | grep -Eqi "debian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemmdPath="/lib/systemd/system/"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemmdPath="/lib/systemd/system/"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemmdPath="/usr/lib/systemd/system/"
    fi
    echo "OS info: ${osRelease}, ${osSystemPackage}, ${osSystemmdPath}"
}


osPort80=""
osPort443=""
osSELINUXCheck=""
osSELINUXCheckIsReboot=""

function testPortUsage() {
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
        read -p "是否现在重启? 请输入 [Y/n] :" osSELINUXCheckIsReboot
        [ -z "${osSELINUXCheckIsReboot}" ] && osSELINUXCheckIsReboot="y"

        if [[ $osSELINUXCheckIsReboot == [Yy] ]]; then
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
        read -p "是否现在重启? 请输入 [Y/n] :" osSELINUXCheckIsReboot
        [ -z "${osSELINUXCheckIsReboot}" ] && osSELINUXCheckIsReboot="y"

        if [[ $osSELINUXCheckIsReboot == [Yy] ]]; then
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


configRealIp=""
configLocalIp=""
configDomainTrojan=""

nginxConfigPath="/etc/nginx/nginx.conf"
nginxAccessLogFile="${HOME}/nginx-trojan-access.log"
nginxErrorLogFile="${HOME}/nginx-trojan-error.log"

showTrojanName=""
isTrojanGo="no"
isTrojanGoSupportWS="n"
isTrojanGoWebsocketConfig="false"
trojanVersion="1.15.1"
configTrojanGoWebSocketPath=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
configTrojanCli="trojan-${trojanVersion}-linux-amd64.tar.xz"
configTrojanOriginalCli="trojan-${trojanVersion}-linux-amd64.tar.xz"
configTrojanGoCli="trojan-go-linux-amd64.zip"
configTrojanPasswordPrefix="jin"
configTrojanPath="${HOME}/trojan"
configTrojanOriginalPath="${HOME}/trojan"
configTrojanGoPath="${HOME}/trojan-go"
configTrojanLogFile="${HOME}/trojan-access.log"
configTrojanCertPath="${HOME}/trojan/cert"
configTrojanWebsitePath="${configTrojanPath}/website/html"
configTrojanWindowsCliPath=$(cat /dev/urandom | head -1 | md5sum | head -c 20)
configTrojanWebsiteDownloadPath="${configTrojanWebsitePath}/download/${configTrojanWindowsCliPath}"




configDomainV2ray=""

caddyConfigPath="/etc/caddy/"
caddyConfigFile="/etc/caddy/Caddyfile"
caddyCertPath="${HOME}/caddy/cert"
caddyAccessLogFile="${HOME}/caddy-v2ray-access.log"
caddyErrorLogFile="${HOME}/caddy-v2ray-error.log"

configV2rayBinPath="/usr/bin/v2ray"
configV2rayDefaultConfigPath="/etc/v2ray"
configV2rayDefaultConfigFile="/etc/v2ray/config.json"

configV2rayPath="${HOME}/v2ray"
configV2rayAccessLogFile="${HOME}/v2ray-access.log"
configV2rayErrorLogFile="${HOME}/v2ray-error.log"
configV2rayWebsitePath="${HOME}/v2ray/website/html"
configV2rayWebsiteDownloadPath="${configV2rayWebsitePath}/download/${configTrojanWindowsCliPath}"

configV2rayWebSocketPath=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
configV2rayPort="$(($RANDOM + 10000))"

configV2raySystemdFile="/etc/systemd/system/v2ray.service"
configV2rayCliFileName="v2ray-linux-64.zip"
v2rayVersion="4.26.0"



function compareRealIpWithLocalIp(){

    if [ -n $1 ]; then
        configRealIp=`ping $1 -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
        configLocalIp=`curl ipv4.icanhazip.com`

        if [ $configRealIp == $configLocalIp ] ; then
            green "=========================================="
            green " 域名解析地址为 ${configRealIp}, 本VPS的IP为 ${configLocalIp}. 域名解析正常!"
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

function install_nginx(){


    green "=============================================="
    yellow "   开始安装 Web服务器 nginx !"
    green "=============================================="

    sleep 1s

    if [[ -f "${osSystemmdPath}caddy.service" ]] ; then
        sudo systemctl stop caddy.service
    fi

    if [[ -f "${osSystemmdPath}v2ray.service" ]] || [[ -f "/etc/systemd/system/v2ray.service" ]] || [[ -f "/lib/systemd/system/v2ray.service" ]] ; then
        sudo systemctl stop v2ray.service
    fi

    if test -s ${nginxConfigPath}; then
        green "==========================="
        green "      Nginx 已存在, 退出安装!"
        green "==========================="
        exit
    fi

    $osSystemPackage install nginx -y
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
    access_log  $nginxAccessLogFile  main;
    error_log $nginxErrorLogFile;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  120;
    client_max_body_size 20m;
    #gzip  on;

    server {
        listen       80;
        server_name  $configDomainTrojan;
        root $configTrojanWebsitePath;
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
    rm -rf ${configTrojanWebsitePath}/*
    mkdir -p ${configTrojanWebsiteDownloadPath}
    wget -O ${configTrojanPath}/website/trojan_website.zip https://github.com/jinwyp/Trojan/raw/master/web.zip
    unzip -d ${configTrojanWebsitePath} ${configTrojanPath}/website/trojan_website.zip

    wget -O ${configTrojanPath}/website/trojan_client_all.zip https://github.com/jinwyp/Trojan/raw/master/trojan_client_all.zip
    unzip -d ${configTrojanWebsiteDownloadPath} ${configTrojanPath}/website/trojan_client_all.zip

    sudo systemctl start nginx.service

    green "=========================================="
    green "       Web服务器 nginx 安装成功!!"
    green "=========================================="
}


function get_https_certificate(){

    # 申请https证书
	mkdir -p ${configTrojanCertPath}
	curl https://get.acme.sh | sh

    green "=========================================="

	if [[ $1 == "standalone" ]] ; then
	    green "  开始重新申请证书 acme.sh standalone mode !"
	    ~/.acme.sh/acme.sh  --issue  -d ${configDomainTrojan}  --standalone
	else
	    green "  开始第一次申请证书 acme.sh nginx mode !"
        ~/.acme.sh/acme.sh  --issue  -d ${configDomainTrojan}  --webroot ${configTrojanWebsitePath}/
    fi

    ~/.acme.sh/acme.sh  --installcert  -d ${configDomainTrojan}   \
        --key-file   ${configTrojanCertPath}/private.key \
        --fullchain-file ${configTrojanCertPath}/fullchain.cer \
        --reloadcmd  "systemctl force-reload  nginx.service"
}


function install_trojan_server(){

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
    trojanPasswordWS=$(cat /dev/urandom | head -1 | md5sum | head -c 10)

    #wget https://github.com/trojan-gfw/trojan/releases/download/v1.15.1/trojan-1.15.1-linux-amd64.tar.xz

    #trojanVersion=$(curl --silent "https://api.github.com/repos/trojan-gfw/trojan/releases/latest" | grep -Po '"tag_name": "v\K.*?(?=")')

    if [ "$isTrojanGo" = "no" ] ; then
      trojanVersion=$(getGithubLatestReleaseVersion "trojan-gfw/trojan")
      configTrojanCli="trojan-${trojanVersion}-linux-amd64.tar.xz"
    fi

    if [ "$isTrojanGo" = "yes" ] ; then
        trojanVersion=$(getGithubLatestReleaseVersion2 "p4gefau1t/trojan-go")
        # trojanVersion="0.6.0"
        configTrojanCli="${configTrojanGoCli}"
    fi

    if [[ -f "${configTrojanPath}/${configTrojanCli}" ]]; then
        green "=========================================="
        green "  已安装过 Trojan${showTrojanName} v${trojanVersion}, 退出安装 !"
        green "=========================================="
        exit
    fi

    green "=========================================="
    green "       开始安装 Trojan${showTrojanName} Version: ${trojanVersion} !"
    green "=========================================="
    read -p "请输入trojan密码的前缀? (会生成若干随机密码和带有指定该前缀的密码)" configTrojanPasswordPrefix
    configTrojanPasswordPrefix=${configTrojanPasswordPrefix:-jin}

    cd ${configTrojanPath}
    rm -rf ${configTrojanPath}/src
    mkdir -p ${configTrojanPath}/src


    if [ "$isTrojanGo" = "no" ] ; then
        wget -O ${configTrojanPath}/${configTrojanCli}  https://github.com/trojan-gfw/trojan/releases/download/v${trojanVersion}/${configTrojanCli}
        tar xf ${configTrojanCli} -C ${configTrojanPath}
        mv ${configTrojanPath}/trojan/* ${configTrojanPath}/src
        rm -rf ${configTrojanPath}/trojan
    fi

    if [ "$isTrojanGo" = "yes" ] ; then
        # https://github.com/p4gefau1t/trojan-go/releases/download/v0.5.1/trojan-go-linux-amd64.zip
        wget -O ${configTrojanPath}/${configTrojanCli}  https://github.com/p4gefau1t/trojan-go/releases/download/v${trojanVersion}/${configTrojanCli}
        unzip -d ${configTrojanPath}/src ${configTrojanCli}
    fi




    if [ "$isTrojanGo" = "no" ] ; then

        # 增加trojan 服务器端配置
	    cat > ${configTrojanPath}/src/server.json <<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "$trojanPassword1",
        "$trojanPassword2",
        "$trojanPassword3",
        "$trojanPassword4",
        "$trojanPassword5",
        "$trojanPassword6",
        "$trojanPassword7",
        "$trojanPassword8",
        "$trojanPassword9",
        "$trojanPassword10",
        "${configTrojanPasswordPrefix}202000",
        "${configTrojanPasswordPrefix}202010",
        "${configTrojanPasswordPrefix}202011",
        "${configTrojanPasswordPrefix}202012",
        "${configTrojanPasswordPrefix}202013",
        "${configTrojanPasswordPrefix}202014",
        "${configTrojanPasswordPrefix}202015",
        "${configTrojanPasswordPrefix}202016",
        "${configTrojanPasswordPrefix}202017",
        "${configTrojanPasswordPrefix}202018",
        "${configTrojanPasswordPrefix}202019",
        "${configTrojanPasswordPrefix}202020",
        "${configTrojanPasswordPrefix}202021",
        "${configTrojanPasswordPrefix}202022",
        "${configTrojanPasswordPrefix}202023",
        "${configTrojanPasswordPrefix}202024",
        "${configTrojanPasswordPrefix}202025",
        "${configTrojanPasswordPrefix}202026",
        "${configTrojanPasswordPrefix}202027",
        "${configTrojanPasswordPrefix}202028",
        "${configTrojanPasswordPrefix}202029",
        "${configTrojanPasswordPrefix}202030",
        "${configTrojanPasswordPrefix}202031",
        "${configTrojanPasswordPrefix}202032",
        "${configTrojanPasswordPrefix}202033",
        "${configTrojanPasswordPrefix}202034",
        "${configTrojanPasswordPrefix}202035",
        "${configTrojanPasswordPrefix}202036",
        "${configTrojanPasswordPrefix}202037",
        "${configTrojanPasswordPrefix}202038",
        "${configTrojanPasswordPrefix}202039",
        "${configTrojanPasswordPrefix}202040",
        "${configTrojanPasswordPrefix}202030",
        "${configTrojanPasswordPrefix}202031",
        "${configTrojanPasswordPrefix}202032",
        "${configTrojanPasswordPrefix}202033",
        "${configTrojanPasswordPrefix}202034",
        "${configTrojanPasswordPrefix}202035",
        "${configTrojanPasswordPrefix}202036",
        "${configTrojanPasswordPrefix}202037",
        "${configTrojanPasswordPrefix}202038",
        "${configTrojanPasswordPrefix}202039",
        "${configTrojanPasswordPrefix}202040",
        "${configTrojanPasswordPrefix}202041",
        "${configTrojanPasswordPrefix}202042",
        "${configTrojanPasswordPrefix}202043",
        "${configTrojanPasswordPrefix}202044",
        "${configTrojanPasswordPrefix}202045",
        "${configTrojanPasswordPrefix}202046",
        "${configTrojanPasswordPrefix}202047",
        "${configTrojanPasswordPrefix}202048",
        "${configTrojanPasswordPrefix}202049",
        "${configTrojanPasswordPrefix}202050",
        "${configTrojanPasswordPrefix}202051",
        "${configTrojanPasswordPrefix}202052",
        "${configTrojanPasswordPrefix}202053",
        "${configTrojanPasswordPrefix}202054",
        "${configTrojanPasswordPrefix}202055",
        "${configTrojanPasswordPrefix}202056",
        "${configTrojanPasswordPrefix}202057",
        "${configTrojanPasswordPrefix}202058",
        "${configTrojanPasswordPrefix}202059",
        "${configTrojanPasswordPrefix}202060",
        "${configTrojanPasswordPrefix}202061",
        "${configTrojanPasswordPrefix}202062",
        "${configTrojanPasswordPrefix}202063",
        "${configTrojanPasswordPrefix}202064",
        "${configTrojanPasswordPrefix}202065",
        "${configTrojanPasswordPrefix}202066",
        "${configTrojanPasswordPrefix}202067",
        "${configTrojanPasswordPrefix}202068",
        "${configTrojanPasswordPrefix}202069",
        "${configTrojanPasswordPrefix}202070",
        "${configTrojanPasswordPrefix}202071",
        "${configTrojanPasswordPrefix}202072",
        "${configTrojanPasswordPrefix}202073",
        "${configTrojanPasswordPrefix}202074",
        "${configTrojanPasswordPrefix}202075",
        "${configTrojanPasswordPrefix}202076",
        "${configTrojanPasswordPrefix}202077",
        "${configTrojanPasswordPrefix}202078",
        "${configTrojanPasswordPrefix}202079",
        "${configTrojanPasswordPrefix}202080",
        "${configTrojanPasswordPrefix}202081",
        "${configTrojanPasswordPrefix}202082",
        "${configTrojanPasswordPrefix}202083",
        "${configTrojanPasswordPrefix}202084",
        "${configTrojanPasswordPrefix}202085",
        "${configTrojanPasswordPrefix}202086",
        "${configTrojanPasswordPrefix}202087",
        "${configTrojanPasswordPrefix}202088",
        "${configTrojanPasswordPrefix}202089",
        "${configTrojanPasswordPrefix}202090",
        "${configTrojanPasswordPrefix}202091",
        "${configTrojanPasswordPrefix}202092",
        "${configTrojanPasswordPrefix}202093",
        "${configTrojanPasswordPrefix}202094",
        "${configTrojanPasswordPrefix}202095",
        "${configTrojanPasswordPrefix}202096",
        "${configTrojanPasswordPrefix}202097",
        "${configTrojanPasswordPrefix}202098",
        "${configTrojanPasswordPrefix}202099"
    ],
    "log_level": 1,
    "log_file": "${configTrojanLogFile}",
    "ssl": {
        "cert": "$configTrojanCertPath/fullchain.cer",
        "key": "$configTrojanCertPath/private.key",
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
        cat > ${osSystemmdPath}trojan.service <<-EOF
[Unit]
Description=trojan${showTrojanName}
After=network.target

[Service]
Type=simple
PIDFile=${configTrojanPath}/src/trojan.pid
ExecStart=${configTrojanPath}/src/trojan${showTrojanName} -l $configTrojanLogFile -c "${configTrojanPath}/src/server.json"
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
	    cat > ${configTrojanPath}/src/server.json <<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "$trojanPassword1",
        "$trojanPassword2",
        "$trojanPassword3",
        "$trojanPassword4",
        "$trojanPassword5",
        "$trojanPassword6",
        "$trojanPassword7",
        "$trojanPassword8",
        "$trojanPassword9",
        "$trojanPassword10",
        "${configTrojanPasswordPrefix}202000",
        "${configTrojanPasswordPrefix}202010",
        "${configTrojanPasswordPrefix}202011",
        "${configTrojanPasswordPrefix}202012",
        "${configTrojanPasswordPrefix}202013",
        "${configTrojanPasswordPrefix}202014",
        "${configTrojanPasswordPrefix}202015",
        "${configTrojanPasswordPrefix}202016",
        "${configTrojanPasswordPrefix}202017",
        "${configTrojanPasswordPrefix}202018",
        "${configTrojanPasswordPrefix}202019",
        "${configTrojanPasswordPrefix}202020",
        "${configTrojanPasswordPrefix}202021",
        "${configTrojanPasswordPrefix}202022",
        "${configTrojanPasswordPrefix}202023",
        "${configTrojanPasswordPrefix}202024",
        "${configTrojanPasswordPrefix}202025",
        "${configTrojanPasswordPrefix}202026",
        "${configTrojanPasswordPrefix}202027",
        "${configTrojanPasswordPrefix}202028",
        "${configTrojanPasswordPrefix}202029",
        "${configTrojanPasswordPrefix}202030",
        "${configTrojanPasswordPrefix}202031",
        "${configTrojanPasswordPrefix}202032",
        "${configTrojanPasswordPrefix}202033",
        "${configTrojanPasswordPrefix}202034",
        "${configTrojanPasswordPrefix}202035",
        "${configTrojanPasswordPrefix}202036",
        "${configTrojanPasswordPrefix}202037",
        "${configTrojanPasswordPrefix}202038",
        "${configTrojanPasswordPrefix}202039",
        "${configTrojanPasswordPrefix}202040",
        "${configTrojanPasswordPrefix}202030",
        "${configTrojanPasswordPrefix}202031",
        "${configTrojanPasswordPrefix}202032",
        "${configTrojanPasswordPrefix}202033",
        "${configTrojanPasswordPrefix}202034",
        "${configTrojanPasswordPrefix}202035",
        "${configTrojanPasswordPrefix}202036",
        "${configTrojanPasswordPrefix}202037",
        "${configTrojanPasswordPrefix}202038",
        "${configTrojanPasswordPrefix}202039",
        "${configTrojanPasswordPrefix}202040",
        "${configTrojanPasswordPrefix}202041",
        "${configTrojanPasswordPrefix}202042",
        "${configTrojanPasswordPrefix}202043",
        "${configTrojanPasswordPrefix}202044",
        "${configTrojanPasswordPrefix}202045",
        "${configTrojanPasswordPrefix}202046",
        "${configTrojanPasswordPrefix}202047",
        "${configTrojanPasswordPrefix}202048",
        "${configTrojanPasswordPrefix}202049",
        "${configTrojanPasswordPrefix}202050",
        "${configTrojanPasswordPrefix}202051",
        "${configTrojanPasswordPrefix}202052",
        "${configTrojanPasswordPrefix}202053",
        "${configTrojanPasswordPrefix}202054",
        "${configTrojanPasswordPrefix}202055",
        "${configTrojanPasswordPrefix}202056",
        "${configTrojanPasswordPrefix}202057",
        "${configTrojanPasswordPrefix}202058",
        "${configTrojanPasswordPrefix}202059",
        "${configTrojanPasswordPrefix}202060",
        "${configTrojanPasswordPrefix}202061",
        "${configTrojanPasswordPrefix}202062",
        "${configTrojanPasswordPrefix}202063",
        "${configTrojanPasswordPrefix}202064",
        "${configTrojanPasswordPrefix}202065",
        "${configTrojanPasswordPrefix}202066",
        "${configTrojanPasswordPrefix}202067",
        "${configTrojanPasswordPrefix}202068",
        "${configTrojanPasswordPrefix}202069",
        "${configTrojanPasswordPrefix}202070",
        "${configTrojanPasswordPrefix}202071",
        "${configTrojanPasswordPrefix}202072",
        "${configTrojanPasswordPrefix}202073",
        "${configTrojanPasswordPrefix}202074",
        "${configTrojanPasswordPrefix}202075",
        "${configTrojanPasswordPrefix}202076",
        "${configTrojanPasswordPrefix}202077",
        "${configTrojanPasswordPrefix}202078",
        "${configTrojanPasswordPrefix}202079",
        "${configTrojanPasswordPrefix}202080",
        "${configTrojanPasswordPrefix}202081",
        "${configTrojanPasswordPrefix}202082",
        "${configTrojanPasswordPrefix}202083",
        "${configTrojanPasswordPrefix}202084",
        "${configTrojanPasswordPrefix}202085",
        "${configTrojanPasswordPrefix}202086",
        "${configTrojanPasswordPrefix}202087",
        "${configTrojanPasswordPrefix}202088",
        "${configTrojanPasswordPrefix}202089",
        "${configTrojanPasswordPrefix}202090",
        "${configTrojanPasswordPrefix}202091",
        "${configTrojanPasswordPrefix}202092",
        "${configTrojanPasswordPrefix}202093",
        "${configTrojanPasswordPrefix}202094",
        "${configTrojanPasswordPrefix}202095",
        "${configTrojanPasswordPrefix}202096",
        "${configTrojanPasswordPrefix}202097",
        "${configTrojanPasswordPrefix}202098",
        "${configTrojanPasswordPrefix}202099"
    ],
    "log_level": 1,
    "log_file": "${configTrojanLogFile}",
    "ssl": {
        "cert": "$configTrojanCertPath/fullchain.cer",
        "key": "$configTrojanCertPath/private.key",
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
        "dhparam": "",
        "sni": "$configDomainTrojan"
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "websocket": {
        "enabled": $isTrojanGoWebsocketConfig,
        "path": "/${configTrojanGoWebSocketPath}",
        "host": "$configDomainTrojan",
        "obfuscation_password": "$trojanPasswordWS"
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
        cat > ${osSystemmdPath}trojan.service <<-EOF
[Unit]
Description=trojan${showTrojanName}
After=network.target

[Service]
Type=simple
PIDFile=${configTrojanPath}/src/trojan-go.pid
ExecStart=${configTrojanPath}/src/trojan${showTrojanName} -config "${configTrojanPath}/src/server.json"
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
    fi

    chmod +x ${osSystemmdPath}trojan.service
    sudo systemctl daemon-reload
    sudo systemctl start trojan.service
    sudo systemctl enable trojan.service



    # 下载并制作 trojan windows 客户端的命令行启动文件
    rm -rf ${configTrojanPath}/trojan-win-cli
    rm -rf ${configTrojanPath}/trojan-win-cli-temp

    wget -O ${configTrojanPath}/trojan-win-cli.zip https://github.com/jinwyp/Trojan/raw/master/trojan-win-cli.zip
    unzip -d ${configTrojanPath} ${configTrojanPath}/trojan-win-cli.zip
    rm ${configTrojanPath}/trojan-win-cli.zip

    mkdir ${configTrojanPath}/trojan-win-cli-temp

    if [ "$isTrojanGo" = "no" ] ; then
      wget -P ${configTrojanPath}/trojan-win-cli-temp https://github.com/trojan-gfw/trojan/releases/download/v${trojanVersion}/trojan-${trojanVersion}-win.zip
      unzip -d ${configTrojanPath}/trojan-win-cli-temp ${configTrojanPath}/trojan-win-cli-temp/trojan-${trojanVersion}-win.zip
      mv -f ${configTrojanPath}/trojan-win-cli-temp/trojan/trojan.exe ${configTrojanPath}/trojan-win-cli/
    fi

    if [ "$isTrojanGo" = "yes" ] ; then
      wget -P ${configTrojanPath}/trojan-win-cli-temp https://github.com/p4gefau1t/trojan-go/releases/download/v${trojanVersion}/trojan-go-windows-amd64.zip
      unzip -d ${configTrojanPath}/trojan-win-cli-temp ${configTrojanPath}/trojan-win-cli-temp/trojan-go-windows-amd64.zip
      rm -f ${configTrojanPath}/trojan-win-cli-temp/trojan-go-windows-amd64.zip
      mv -f ${configTrojanPath}/trojan-win-cli-temp/* ${configTrojanPath}/trojan-win-cli/
    fi

    rm -rf ${configTrojanPath}/trojan-win-cli-temp
    cp ${configTrojanCertPath}/fullchain.cer ${configTrojanPath}/trojan-win-cli/fullchain.cer

    cat > ${configTrojanPath}/trojan-win-cli/config.json <<-EOF
{
    "run_type": "client",
    "local_addr": "127.0.0.1",
    "local_port": 1080,
    "remote_addr": "$configDomainTrojan",
    "remote_port": 443,
    "password": [
        "$trojanPassword1"
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
    cd ${configTrojanPath}/trojan-win-cli/
    zip -r trojan-win-cli.zip ${configTrojanPath}/trojan-win-cli/
    mv -f ${configTrojanPath}/trojan-win-cli/trojan-win-cli.zip ${configTrojanWebsiteDownloadPath}




    # 设置 cron 定时任务
    # https://stackoverflow.com/questions/610839/how-can-i-programmatically-create-a-new-cron-job

    # (crontab -l 2>/dev/null | grep -v '^[a-zA-Z]'; echo "15 4 * * 0,1,2,3,4,5,6 systemctl restart trojan.service") | sort - | uniq - | crontab -
    (crontab -l ; echo "15 4 * * 0,1,2,3,4,5,6 systemctl restart trojan.service") | sort - | uniq - | crontab -


	green "======================================================================"
	green "    Trojan${showTrojanName} Version: ${trojanVersion} 安装成功 !!"
	green "    伪装站点为 http://${configDomainTrojan}!"
	green "    伪装站点的静态html内容放置在目录 ${configTrojanWebsitePath}, 可自行更换网站内容!"
	red "    nginx 配置路径 ${nginxConfigPath} !"
	red "    nginx 访问日志 ${nginxAccessLogFile} !"
	red "    nginx 错误日志 ${nginxErrorLogFile} !"
	red "    Trojan 服务器端配置路径 ${configTrojanPath}/src/server.json !"
	red "    Trojan 访问日志 ${configTrojanLogFile} 或运行 journalctl -u trojan.service 查看 !"
	green "    trojan 停止命令: systemctl stop trojan.service  启动命令: systemctl start trojan.service  重启命令: systemctl restart trojan.service"
	green "    nginx 停止命令: systemctl stop nginx.service  启动命令: systemctl start nginx.service  重启命令: systemctl restart nginx.service"
	green "    Trojan 服务器 每天会自动重启,防止内存泄漏. 运行 crontab -l 命令 查看定时重启命令 !"
	green "======================================================================"
	blue  "----------------------------------------"
	yellow "Trojan${showTrojanName} 配置信息如下, 请自行复制保存, 密码任选其一 !!"
	yellow "服务器地址: ${configDomainTrojan}  端口: 443"
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
	yellow "您指定前缀的密码若干: 从 ${configTrojanPasswordPrefix}202010 到 ${configTrojanPasswordPrefix}202099 都可以使用"

    if [[ $isTrojanGoSupportWS == [Yy] ]]; then
        yellow "Websocket path 路径为: /${configTrojanGoWebSocketPath}"
        yellow "Websocket obfuscation_password 混淆密码为: ${trojanPasswordWS}"
        yellow "Websocket 双重TLS为: true 开启"
    fi

	blue  "----------------------------------------"
	green "======================================================================"
	green "请下载相应的trojan客户端:"
	yellow "1 Windows 客户端下载：http://${configDomainTrojan}/download/${configTrojanWindowsCliPath}/trojan-windows.zip"
	yellow "  Windows 客户端另一个版本下载：http://${configDomainTrojan}/download/${configTrojanWindowsCliPath}/trojan-Qt5-windows.zip"
	yellow "  Windows 客户端命令行版本下载：http://${configDomainTrojan}/download/${configTrojanWindowsCliPath}/trojan-win-cli.zip"
	yellow "  Windows 客户端命令行版本需要搭配浏览器插件使用，例如switchyomega等! 具体请看 https://www.atrandys.com/2019/1963.html"
    yellow "2 MacOS 客户端下载：http://${configDomainTrojan}/download/${configTrojanWindowsCliPath}/trojan-mac.zip"
    yellow "  MacOS 客户端另一个版本下载：https://github.com/Trojan-Qt5/Trojan-Qt5/releases"
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



function installTrojanWholeProcess(){
    nginx_status=`ps -aux | grep "nginx: worker" | grep -v "grep"`
    if [ -n "$nginx_status" ]; then
        sudo systemctl stop nginx.service
    fi

    testPortUsage

    if [ "$isTrojanGo" = "no" ] ; then
        configTrojanPath="$configTrojanOriginalPath"
    fi

    if [ "$isTrojanGo" = "yes" ] ; then
        configTrojanPath="$configTrojanGoPath"
        showTrojanName="-go"

        green "=============================================="
        read -p "是否开启Websocket 支持CDN? 请输入[y/n] (默认不开启):" isTrojanGoSupportWS
        isTrojanGoSupportWS=${isTrojanGoSupportWS:-n}

        if [[ $isTrojanGoSupportWS == [Yy] ]]; then
            isTrojanGoSupportWS="y"
            isTrojanGoWebsocketConfig="true"
        else
            isTrojanGoSupportWS="n"
            isTrojanGoWebsocketConfig="false"
        fi
    fi

    green "=============================================="
    yellow "请输入绑定到本VPS的域名 此步骤安装时不能使用CDN！"
    if [[ $1 == "repair" ]] ; then
        blue "务必与之前失败使用的域名一致"
    fi
    green "=============================================="


    configTrojanWebsitePath="${configTrojanPath}/website/html"
    configTrojanWebsiteDownloadPath="${configTrojanWebsitePath}/download/${configTrojanWindowsCliPath}"

    read configDomainTrojan
    if compareRealIpWithLocalIp "${configDomainTrojan}" ; then

        configDomainV2ray=${configDomainTrojan}

        if [[ -z $1 ]] ; then
            install_nginx
            get_https_certificate
        else
            get_https_certificate "standalone"
        fi

        if test -s ${configTrojanCertPath}/fullchain.cer; then
            green "=========================================="
            green "       证书获取成功!!"
            green "=========================================="
            install_trojan_server
        else
            red "==================================="
            red " https证书没有申请成功，安装失败!"
            red " 请检查域名和DNS是否生效, 同一域名请不要一天内多次申请!"
            red " 请检查80和443端口是否开启, VPS服务商可能需要添加额外防火墙规则，例如阿里云、谷歌云等!"
            red " 重启VPS, 重新执行脚本, 可选择重新申请证书选项再次申请证书 ! "
            red " 参考 https://www.atrandys.com/2020/2429.html "
            red " 参考 https://www.v2rayssr.com/trojan-2.html "
            red "==================================="
            exit
        fi
    else
        exit
    fi

}


function repair_cert(){
    installTrojanWholeProcess "repair"
}


function remove_trojan(){

    sudo systemctl stop nginx.service
    sudo systemctl stop trojan
    sudo systemctl disable trojan

    if [ "$isTrojanGo" = "no" ] ; then
      showTrojanName=""
      configTrojanPath="$configTrojanOriginalPath"
    fi

    if [ "$isTrojanGo" = "yes" ] ; then
      configTrojanPath="$configTrojanGoPath"
      showTrojanName="-go"
    fi

    green "================================"
    red "即将卸载trojan${showTrojanName}"
    red "同时卸载已安装的nginx"
    green "================================"

    if [ "$osRelease" == "centos" ]; then
        yum remove -y nginx
    else
        apt autoremove -y --purge nginx nginx-common nginx-core
        apt-get remove --purge nginx nginx-full nginx-common
    fi

    rm -f ${osSystemmdPath}trojan.service
    rm -rf ${configTrojanPath}
    rm -rf "/etc/nginx"
    rm -rf /root/.acme.sh/

    crontab -r

    green "================================"
    green "  trojan${showTrojanName} 和 nginx 卸载完毕 !"
    green "  crontab 定时任务 删除完毕 !"
    green "================================"
}

function upgrade_trojan(){

    if [ "$isTrojanGo" = "no" ] ; then
        showTrojanName=""
        configTrojanPath="$configTrojanOriginalPath"

        trojanVersion=$(getGithubLatestReleaseVersion "trojan-gfw/trojan")
        configTrojanCli="trojan-${trojanVersion}-linux-amd64.tar.xz"
    fi

    if [ "$isTrojanGo" = "yes" ] ; then
        configTrojanPath="$configTrojanGoPath"
        showTrojanName="-go"

        trojanVersion=$(getGithubLatestReleaseVersion2 "p4gefau1t/trojan-go")
        configTrojanCli="${configTrojanGoCli}"
    fi   

    green "=========================================="
    green "       开始升级 Trojan${showTrojanName} Version: ${trojanVersion} !"
    green "=========================================="

    sudo systemctl stop trojan

    mkdir -p ${configTrojanPath}/upgrade
    cd ${configTrojanPath}


    if [[ $1 == "trojan" ]] ; then
        wget -O ${configTrojanPath}/upgrade/${configTrojanCli}  https://github.com/trojan-gfw/trojan/releases/download/v${trojanVersion}/${configTrojanCli}
        tar xf ${configTrojanPath}/upgrade/${configTrojanCli} -C ${configTrojanPath}/upgrade
        mv -f ${configTrojanPath}/upgrade/trojan/trojan ${configTrojanPath}/src

        green "       升级成功!"
    fi


    if [[ $1 == "trojan-go" ]] ; then
        # https://github.com/p4gefau1t/trojan-go/releases/download/v0.5.1/trojan-go-linux-amd64.zip
        wget -O ${configTrojanPath}/upgrade/${configTrojanCli}  https://github.com/p4gefau1t/trojan-go/releases/download/v${trojanVersion}/${configTrojanCli}
        unzip -d ${configTrojanPath}/upgrade ${configTrojanPath}/upgrade/${configTrojanCli} 
        mv -f ${configTrojanPath}/upgrade/trojan-go ${configTrojanPath}/src
        
        green "       升级成功!"
    fi

    rm -rf ${configTrojanPath}/upgrade

    sudo systemctl start trojan
}








function install_caddy(){
    nginx_status=`ps -aux | grep "nginx: worker" | grep -v "grep"`
    if [ -n "$nginx_status" ]; then
        sudo systemctl stop nginx.service
    fi
    if [[ -f "${osSystemmdPath}trojan.service" ]] ; then
        sudo systemctl stop trojan.service
    fi

    testPortUsage

    green "=============================================="
    yellow "请输入绑定到本VPS的域名 请不要使用CDN !"
    yellow "全部安装完毕后可以开启CDN."
    green "=============================================="

    read configDomainV2ray
    if compareRealIpWithLocalIp "${configDomainV2ray}" ; then

        if [[ -f ${osSystemmdPath}caddy.service ]]; then
            green "=========================================="
            green "  已安装过 Caddy, 退出安装 !"
            green "=========================================="
            exit
        fi

        green "=========================================="
	    green "          开始安装 Caddy web服务器 !"
	    green "=========================================="


        curl https://getcaddy.com | bash -s personal

        mkdir "${caddyConfigPath}"
        mkdir -p "${caddyCertPath}"

        cat > "${caddyConfigFile}" <<-EOF
$configDomainV2ray
{
  root $configV2rayWebsitePath
  proxy /$configV2rayWebSocketPath localhost:$configV2rayPort {
    websocket
    header_upstream -Origin
  }
  log $caddyAccessLogFile
  errors $caddyErrorLogFile
}
EOF

        # 下载伪装站点 并设置伪装网站
        rm -rf ${configV2rayWebsitePath}/*
        mkdir -p ${configV2rayWebsiteDownloadPath}
        wget -O ${configV2rayPath}/website/v2ray_website.zip https://github.com/jinwyp/Trojan/raw/master/web.zip
        unzip -d ${configV2rayWebsitePath} ${configV2rayPath}/website/v2ray_website.zip

        wget -O ${configV2rayPath}/website/v2ray_client_all.zip https://github.com/jinwyp/Trojan/raw/master/v2ray_client_all.zip
        unzip -d ${configV2rayWebsiteDownloadPath} ${configV2rayPath}/website/v2ray_client_all.zip

        # 增加启动脚本
        # https://github.com/caddyserver/dist/blob/master/init/caddy.service

        cat > ${osSystemmdPath}caddy.service <<-EOF
[Unit]
Description=Caddy HTTP/2 web server
Documentation=https://caddyserver.com/docs/
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service


[Service]
Restart=on-abnormal

# User=root
# Group=root

Environment=CADDYPATH=${caddyCertPath}


ExecStart=/usr/local/bin/caddy -agree=true -conf=${caddyConfigFile}
ExecReload=/bin/kill -USR1 \$MAINPID

KillMode=mixed
KillSignal=SIGQUIT
TimeoutStopSec=5s

LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
PrivateDevices=false
ProtectSystem=full

ReadWritePaths=${HOME}
ReadWriteDirectories=${HOME}

#CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

        sudo chmod +x ${osSystemmdPath}caddy.service
        sudo systemctl daemon-reload
        sudo systemctl enable caddy.service
        sudo systemctl start caddy.service
        sudo systemctl status caddy.service

        green "=========================================="
        green "       Web服务器 Caddy 安装成功!!"
        green "=========================================="
    else
        exit
    fi

}



function install_v2ray(){

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

    if [[ -f ${osSystemmdPath}v2ray.service ]]; then
        green "=========================================="
        green "  已安装过 V2ray, 退出安装 !"
        green "=========================================="
        exit
    fi

    green "=========================================="
    green "      开始安装 V2ray !"
    green "=========================================="

    v2rayVersion=$(getGithubLatestReleaseVersion2 "v2ray/v2ray-core")
    bash <(curl -L -s https://install.direct/go.sh)

    mkdir -p ${configV2rayPath}/
    cd ${configV2rayPath}

    cat > ${configV2rayDefaultConfigFile} <<-EOF
{
  "log" : {
    "access": "$configV2rayAccessLogFile",
    "error": "$configV2rayErrorLogFile",
    "loglevel": "warning"
  },
  "inbound": {
    "port": $configV2rayPort,
    "listen":"127.0.0.1",
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "$v2rayPassword1",
          "level": 1,
          "alterId": 64,
          "email": "password11@gmail.com"
        },
        {
          "id": "$v2rayPassword2",
          "level": 1,
          "alterId": 64,
          "email": "password12@gmail.com"
        },
        {
          "id": "$v2rayPassword3",
          "level": 1,
          "alterId": 64,
          "email": "password13@gmail.com"
        },
        {
          "id": "$v2rayPassword4",
          "level": 1,
          "alterId": 64,
          "email": "password14@gmail.com"
        },
        {
          "id": "$v2rayPassword5",
          "level": 1,
          "alterId": 64,
          "email": "password15@gmail.com"
        },
        {
          "id": "$v2rayPassword6",
          "level": 1,
          "alterId": 64,
          "email": "password16@gmail.com"
        },
        {
          "id": "$v2rayPassword7",
          "level": 1,
          "alterId": 64,
          "email": "password17@gmail.com"
        },
        {
          "id": "$v2rayPassword8",
          "level": 1,
          "alterId": 64,
          "email": "password18@gmail.com"
        },
        {
          "id": "$v2rayPassword9",
          "level": 1,
          "alterId": 64,
          "email": "password19@gmail.com"
        },
        {
          "id": "$v2rayPassword10",
          "level": 1,
          "alterId": 64,
          "email": "password20@gmail.com"
        }
      ]
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {
        "path": "/$configV2rayWebSocketPath"
      }
    }
  },
  "outbound": {
    "protocol": "freedom",
    "settings": {}
  }
}
EOF



    cat > ${configV2rayPath}/clientConfig.json <<-EOF
===========客户端配置参数=============
{
地址：${configDomainV2ray}
端口：443
uuid：${v2rayPassword1}
额外id：64
加密方式：aes-128-gcm
传输协议：ws
别名：自己起个任意名称
路径：/${configV2rayWebSocketPath}
底层传输：tls
}
EOF
    sed -i 's/CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE/#CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE/g' ${configV2raySystemdFile}
    sudo systemctl daemon-reload
    sudo systemctl restart v2ray.service
    sudo systemctl restart caddy.service

    # 设置 cron 定时任务
    # https://stackoverflow.com/questions/610839/how-can-i-programmatically-create-a-new-cron-job

    (crontab -l ; echo "20 4 * * 0,1,2,3,4,5,6 systemctl restart v2ray.service") | sort - | uniq - | crontab -


    green "======================================================================"
	green "    V2ray Version: ${v2rayVersion} 安装成功  支持CDN !!"
	green "    伪装站点为 https://${configDomainV2ray}!"
	green "    伪装站点的静态html内容放置在目录 ${configV2rayWebsitePath}, 可自行更换网站内容!"
	red "    caddy 配置路径 ${caddyConfigFile} !"
	red "    caddy 访问日志 ${caddyAccessLogFile} !"
	red "    caddy 错误日志 ${caddyErrorLogFile} !"
	red "    V2ray 服务器端配置路径 ${configV2rayDefaultConfigFile} !"
	red "    V2ray 访问日志 ${configV2rayAccessLogFile} !"
	red "    V2ray 访问错误日志 ${configV2rayErrorFile} !"
	green "    V2ray 停止命令: systemctl stop v2ray.service  启动命令: systemctl start v2ray.service  重启命令: systemctl restart v2ray.service"
	green "    caddy 停止命令: systemctl stop caddy.service  启动命令: systemctl start caddy.service  重启命令: systemctl restart caddy.service"
	green "    V2ray 服务器 每天会自动重启,防止内存泄漏. 运行 crontab -l 命令 查看定时重启命令 !"
	green "======================================================================"
	blue  "----------------------------------------"
	yellow "V2ray 配置信息如下, 请自行复制保存, 密码任选其一 (密码即用户ID或UUID) !!"
	yellow "服务器地址: ${configDomainV2ray}  端口: 443"
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
    green "======================================================================"
    green "请下载相应的 v2ray 客户端:"
    yellow "1 Windows 客户端V2rayN下载：http://${configDomainV2ray}/download/${configTrojanWindowsCliPath}/v2ray-windows.zip"
    yellow "2 MacOS 客户端下载：http://${configDomainV2ray}/download/${configTrojanWindowsCliPath}/v2ray-mac.zip"
    yellow "3 Android 客户端下载 https://github.com/2dust/v2rayNG/releases "
    yellow "4 iOS 客户端 请安装小火箭 https://shadowsockshelp.github.io/ios/ "
    yellow "  iOS 请安装小火箭另一个地址 https://lueyingpro.github.io/shadowrocket/index.html "
    yellow "  iOS 安装小火箭遇到问题 教程 https://github.com/shadowrocketHelp/help/ "
    yellow "其他客户端程序请看 https://www.v2ray.com/awesome/tools.html "
    green "======================================================================"

}

function remove_caddy(){

    green "================================"
    red "  即将卸载已安装的 caddy"
    green "================================"

    sudo systemctl stop caddy.service
    sudo systemctl disable caddy.service

    rm -rf /usr/local/bin/caddy
    rm -rf ${caddyConfigPath}
    rm -rf ${caddyCertPath}

    rm -f ${osSystemmdPath}caddy.service

    green "================================"
    green "  caddy 卸载完毕 !"
    green "================================"

    remove_v2ray

}

function remove_v2ray(){

    rm -rf /usr/bin/v2ray /etc/v2ray

    green "================================"
    red " 即将卸载 v2ray "
    green "================================"


    sudo systemctl stop v2ray.service
    sudo systemctl disable v2ray.service

    rm -rf ${configV2rayBinPath}
    rm -rf ${configV2rayDefaultConfigPath}
    rm -rf ${configV2rayPath}

    rm -f ${osSystemmdPath}v2ray.service
    rm -f ${configV2raySystemdFile}
    rm -f /lib/systemd/system/v2ray.service

    crontab -r

    green "================================"
    green "  v2ray 卸载完毕 !"
    green "  crontab 定时任务 删除完毕 !"
    green "================================"

}


function upgrade_v2ray(){

    v2rayVersion=$(getGithubLatestReleaseVersion2 "v2ray/v2ray-core")

    # https://github.com/v2ray/v2ray-core/releases/download/v4.24.2/v2ray-linux-64.zip

    sleep 3s

    green "=========================================="
    green "       开始升级 V2ray Version: ${v2rayVersion} !"
    green "=========================================="

    sudo systemctl stop v2ray

    mkdir -p ${configV2rayPath}/upgrade
    mkdir -p ${configV2rayBinPath}
    cd ${configV2rayPath}


    wget -O ${configV2rayPath}/upgrade/${configV2rayCliFileName}  https://github.com/v2ray/v2ray-core/releases/download/v${v2rayVersion}/${configV2rayCliFileName}
    unzip -d ${configV2rayPath}/upgrade ${configV2rayPath}/upgrade/${configV2rayCliFileName} 
    mv -f ${configV2rayPath}/upgrade/v2ray ${configV2rayBinPath}
    mv -f ${configV2rayPath}/upgrade/v2ctl ${configV2rayBinPath}
        
    rm -rf ${configV2rayPath}/upgrade
    sudo systemctl start v2ray

    green "       升级成功!"
}







function bbr_boost_sh(){
    $osSystemPackage install wget git -y
    wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
}



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



function start_menu(){
    clear
    getLinuxOSVersion
    green " ======================================="
    green " Trojan V2ray 一键安装自动脚本 2020-6-10 更新  "
    green " 系统：centos7+/debian9+/ubuntu16.04+"
    green " 此脚本集成于 atrandys 和 波仔 "
    green " ======================================="
    blue " 声明："
    red " *请不要在任何生产环境使用此脚本"
    red " *请不要有其他程序占用80和443端口"
    red " *若是已安装trojan或第二次使用脚本，请先执行卸载trojan"
    green " ======================================="
    echo
    green " 1. 安装 BBR-PLUS 加速4合一脚本"
    echo
    green " 2. 安装 trojan 和 nginx 不支持CDN"
    green " 3. 修复证书 并继续安装 trojan"
    green " 4. 升级 trojan 到最新版本"
    red " 5. 卸载 trojan 与 nginx"
    echo
    green " 6. 安装 trojan-go 和 nginx 支持websocket, 支持CDN, "
    green " 7. 修复证书 并继续安装 trojan-go"
    green " 8. 升级 trojan-go 到最新版本"
    red " 9. 卸载 trojan-go 与 nginx"
    echo
    green " 11. 安装 v2ray 和 Caddy 1.0.5, 支持 websocket tls1.3, 支持CDN"
    green " 12. 升级 v2ray 到最新版本"
    red " 13. 卸载v2ray 和 Caddy 1.0.5"
    echo
    green " 14. 同时安装 trojan + v2ray 和 nginx, 不支持CDN"
    green " 15. 升级 v2ray 和 trojan 到最新版本"    
    red " 16. 卸载 trojan + v2ray 和 nginx"
    echo
    green " ======================================="
    echo
    green " 21. 安装OhMyZsh与插件zsh-autosuggestions, Micro编辑器 等软件"
    green " 22. 设置可以使用root登陆"
    green " 23. 修改SSH 登陆端口号"
    echo
    green " ======================================="
    echo
    green " 以下是 VPS 测网速工具"
    red " 脚本测速会大量消耗 VPS 流量，请悉知！"
    green " 31. superspeed 三网纯测速 （全国各地三大运营商部分节点全面测速）"
    green " 32. ZBench 综合网速测试  （包含节点测速, Ping 以及 路由测试）"
	green " 33. testrace 回程路由  （四网路由测试）"
	green " 34. LemonBench 快速全方位测试 （包含CPU内存性能、回程、速度）"
    echo    
    green " 0. 退出脚本"
    echo
    read -p "请输入数字:" menuInputNumber
    case "$menuInputNumber" in
        1 )
            bbr_boost_sh
        ;;
        2 )
            installTrojanWholeProcess
        ;;
        3 )
            repair_cert
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
            repair_cert
        ;;
        8 )
            isTrojanGo="yes"
            upgrade_trojan "trojan-go"
        ;;        
        9 )
            isTrojanGo="yes"
            remove_trojan
        ;;
        11 )
            install_caddy
            install_v2ray
        ;;
        12 )
            upgrade_v2ray
        ;;         
        13 )
            remove_caddy
        ;;
        14 )
            installTrojanWholeProcess
            install_v2ray
        ;;
        15 )
            upgrade_trojan "trojan"
            upgrade_v2ray
        ;;          
        16 )
            remove_trojan
            remove_v2ray
        ;;
        21 )
            installOnMyZsh
        ;;
        22 )
            setRootLogin
            sleep 5s
            start_menu
        ;;
        23 )
            changeSSHPort
            sleep 10s
            start_menu
        ;;
        31 )
            $osSystemPackage -y install wget curl
            vps_superspeed
        ;;
        32 )
            $osSystemPackage -y install wget curl
            vps_zbench
        ;;
        33 )
            $osSystemPackage -y install wget curl
            vps_testrace
        ;;
        34 )
            $osSystemPackage -y install wget curl
            vps_LemonBench
        ;;
        0 )
            exit 1
        ;;
        * )
            clear
            red "请输入正确数字"
            sleep 1s
            start_menu
        ;;
    esac
}


start_menu
