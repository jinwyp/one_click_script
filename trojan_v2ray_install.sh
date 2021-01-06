#!/bin/bash

export LC_ALL=C
#export LANG=C
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCmd="sudo"
else
  sudoCmd=""
fi

uninstall() {
  ${sudoCmd} $(which rm) -rf $1
  printf "Removed: %s\n" $1
}


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

        ${sudoCmd} systemctl stop firewalld
        ${sudoCmd} systemctl disable firewalld
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

        ${sudoCmd} systemctl stop ufw
        ${sudoCmd} systemctl disable ufw
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


# 编辑 SSH 公钥 文件用于 免密码登录
function editLinuxLoginWithPublicKey(){
    if [ ! -d "${HOME}/ssh" ]; then
        mkdir -p ${HOME}/.ssh
    fi

    vi ${HOME}/.ssh/authorized_keys
}



# 设置SSH root 登录

function setLinuxRootLogin(){

    read -p "是否设置允许root登陆(ssh密钥方式 或 密码方式登陆 )? 请输入[Y/n]?" osIsRootLoginInput
    osIsRootLoginInput=${osIsRootLoginInput:-Y}

    if [[ $osIsRootLoginInput == [Yy] ]]; then

        if [ "$osRelease" == "centos" ] || [ "$osRelease" == "debian" ] ; then
            ${sudoCmd} sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
        fi
        if [ "$osRelease" == "ubuntu" ]; then
            ${sudoCmd} sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
        fi

        green "设置允许root登陆成功!"
    fi


    read -p "是否设置允许root使用密码登陆(上一步请先设置允许root登陆才可以)? 请输入[Y/n]?" osIsRootLoginWithPasswordInput
    osIsRootLoginWithPasswordInput=${osIsRootLoginWithPasswordInput:-Y}

    if [[ $osIsRootLoginWithPasswordInput == [Yy] ]]; then
        sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
        green "设置允许root使用密码登陆成功!"
    fi


    ${sudoCmd} sed -i 's/#TCPKeepAlive yes/TCPKeepAlive yes/g' /etc/ssh/sshd_config
    ${sudoCmd} sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 300/g' /etc/ssh/sshd_config

    if [ "$osRelease" == "centos" ] ; then

        ${sudoCmd} sed -i 's/ClientAliveInterval 420/ClientAliveInterval 120/g' /etc/ssh/sshd_config
        ${sudoCmd} sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 120/g' /etc/ssh/sshd_config
        
        ${sudoCmd} service sshd restart
        ${sudoCmd} systemctl restart sshd

        green "设置成功, 请用shell工具软件登陆vps服务器!"
    fi

    if [ "$osRelease" == "ubuntu" ] || [ "$osRelease" == "debian" ] ; then

        ${sudoCmd} sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 120/g' /etc/ssh/sshd_config
        
        ${sudoCmd} service ssh restart
        ${sudoCmd} systemctl restart ssh

        green "设置成功, 请用shell工具软件登陆vps服务器!"
    fi

    # /etc/init.d/ssh restart

}

# 修改SSH 端口号
function changeLinuxSSHPort(){
    green "修改的SSH登陆的端口号, 不要使用常用的端口号. 例如 20|21|23|25|53|69|80|110|443|123!"
    read -p "请输入要修改的端口号(必须是纯数字并且在1024~65535之间或22):" osSSHLoginPortInput
    osSSHLoginPortInput=${osSSHLoginPortInput:-0}

    if [ $osSSHLoginPortInput -eq 22 -o $osSSHLoginPortInput -gt 1024 -a $osSSHLoginPortInput -lt 65535 ]; then
        sed -i "s/#\?Port [0-9]*/Port $osSSHLoginPortInput/g" /etc/ssh/sshd_config

        if [ "$osRelease" == "centos" ] ; then
            yum -y install policycoreutils-python

            semanage port -a -t ssh_port_t -p tcp $osSSHLoginPortInput
            firewall-cmd --add-port=$osSSHLoginPortInput/tcp --permanent
            firewall-cmd --reload
            ${sudoCmd} service sshd restart
            ${sudoCmd} systemctl restart sshd
        fi

        if [ "$osRelease" == "ubuntu" ] || [ "$osRelease" == "debian" ] ; then
            ${sudoCmd} service ssh restart
            ${sudoCmd} systemctl restart ssh
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
    wget -O tcp_old.sh -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp_old.sh && ./tcp_old.sh
}

function installBBR2(){
    
    if [[ -f ./tcp.sh ]];  then
        mv ./tcp.sh ./tcp_old.sh
    fi    
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

    if [ "$osRelease" == "centos" ]; then   
        $osSystemPackage install -y xz 
    else
        $osSystemPackage install -y vim-gui-common vim-runtime vim 
    fi

    # 设置vim 中文乱码
    if [[ ! -d "${HOME}/.vimrc" ]] ;  then
        cat > "${HOME}/.vimrc" <<-EOF
set fileencodings=utf-8,gb2312,gb18030,gbk,ucs-bom,cp936,latin1
set enc=utf8
set fencs=utf8,gbk,gb2312,gb18030

syntax on
set nu!
colorscheme elflord

EOF
    fi
}

function installSoftOhMyZsh(){

    green " =================================================="
    yellow " 准备安装 ZSH"
    green " =================================================="

    if [ "$osRelease" == "centos" ]; then

        ${sudoCmd} $osSystemPackage install zsh -y
        $osSystemPackage install util-linux-user -y

    elif [ "$osRelease" == "ubuntu" ]; then

        ${sudoCmd} $osSystemPackage install zsh -y

    elif [ "$osRelease" == "debian" ]; then

        ${sudoCmd} $osSystemPackage install zsh -y
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
        sed -i 's/plugins=(git)/plugins=(git cp history z rsync colorize nvm zsh-autosuggestions)/' $zshConfig

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

function vps_bench(){
	wget -N --no-check-certificate https://raw.githubusercontent.com/teddysun/across/master/bench.sh && chmod +x bench.sh && bash bench.sh
}

function vps_zbench(){
	wget -N --no-check-certificate https://raw.githubusercontent.com/FunctionClub/ZBench/master/ZBench-CN.sh && chmod +x ZBench-CN.sh && bash ZBench-CN.sh
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

versionV2ray="4.33.0"
downloadFilenameV2ray="v2ray-linux-64.zip"

versionXray="1.1.1"
downloadFilenameXray="Xray-linux-64.zip"

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


isInstallNginx="true"
isNginxWithSSL="no"
nginxConfigPath="/etc/nginx/nginx.conf"
nginxAccessLogFilePath="${HOME}/nginx-access.log"
nginxErrorLogFilePath="${HOME}/nginx-error.log"


promptInfoXrayName="v2ray"
isXray="no"

configV2rayWebSocketPath=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
configV2rayPort="$(($RANDOM + 10000))"
configV2rayVmessTCPPort="$(($RANDOM + 10000))"
configV2rayPortShowInfo=$configV2rayPort
configV2rayIsTlsShowInfo="none"
configV2rayTrojanPort="$(($RANDOM + 10000))"

configV2rayPath="${HOME}/v2ray"
configV2rayAccessLogFilePath="${HOME}/v2ray-access.log"
configV2rayErrorLogFilePath="${HOME}/v2ray-error.log"
configV2rayProtocol="vmess"
configV2rayVlessMode=""
configV2rayInstallXrayOnly=""
configReadme=${HOME}/trojan_v2ray_readme.txt


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

    echo ""

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
        echo "versionV2ray: ${versionV2ray}"
    fi

    if [[ $1 == "xray" ]] ; then
        versionXray=$(getGithubLatestReleaseVersion "XTLS/Xray-core")
        echo "versionXray: ${versionXray}"
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
        ${sudoCmd} systemctl stop nginx.service
    fi
}

function stopServiceV2ray(){
    if [[ -f "${osSystemMdPath}v2ray.service" ]] || [[ -f "/etc/systemd/system/v2ray.service" ]] || [[ -f "/lib/systemd/system/v2ray.service" ]] ; then
        ${sudoCmd} systemctl stop v2ray.service
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

    yellow " 是否检测域名指向的IP正确 (默认检测，如果域名指向的IP不是本机器IP则无法继续. 如果已开启CDN不方便关闭可以选择否)"
    read -p "是否检测域名指向的IP正确? 请输入[Y/n]?" isDomainValidInput
    isDomainValidInput=${isDomainValidInput:-Y}

    if [[ $isDomainValidInput == [Yy] ]]; then
        if [ -n $1 ]; then
            configNetworkRealIp=`ping $1 -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
            # configNetworkLocalIp=`curl ipv4.icanhazip.com`
            configNetworkLocalIp=`curl v4.ident.me`

            green " ================================================== "
            green "     域名解析地址为 ${configNetworkRealIp}, 本VPS的IP为 ${configNetworkLocalIp}. "
            green " ================================================== "

            if [[ ${configNetworkRealIp} == ${configNetworkLocalIp} ]] ; then
                green " ================================================== "
                green "     域名解析的IP正常!"
                green " ================================================== "
                true
            else
                green " ================================================== "
                red "     域名解析地址与本VPS IP地址不一致!"
                red "     本次安装失败，请确保域名解析正常, 请检查域名和DNS是否生效!"
                green " ================================================== "
                false
            fi
        else
            green " ================================================== "        
            red "     域名输入错误!"
            green " ================================================== "        
            false
        fi
        
    else
        green " ================================================== "
        green "     不检测域名解析是否正确!"
        green " ================================================== "
        true
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

        ~/.acme.sh/acme.sh  --installcert  -d ${configSSLDomain}   \
        --key-file   ${configSSLCertPath}/private.key \
        --fullchain-file ${configSSLCertPath}/fullchain.cer

	else
	    green "  开始第一次申请证书 acme.sh nginx mode !"
        ~/.acme.sh/acme.sh  --issue  -d ${configSSLDomain}  --webroot ${configWebsitePath}/

        ~/.acme.sh/acme.sh  --installcert  -d ${configSSLDomain}   \
        --key-file   ${configSSLCertPath}/private.key \
        --fullchain-file ${configSSLCertPath}/fullchain.cer \
        --reloadcmd  "systemctl force-reload  nginx.service"
    fi
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
    ${sudoCmd} systemctl enable nginx.service
    ${sudoCmd} systemctl stop nginx.service

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
    #downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/trojan-qt5.zip" "${configWebsiteDownloadPath}" "trojan-qt5.zip"
    
    downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/v2ray_client_all.zip" "${configWebsiteDownloadPath}" "v2ray_client_all.zip"
    #wget -P "${configWebsiteDownloadPath}" "https://github.com/jinwyp/one_click_script/raw/master/download/v2ray-android.zip"

    ${sudoCmd} systemctl start nginx.service

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

    cat >> ${configReadme} <<-EOF

Web服务器 nginx 安装成功! 伪装站点为 ${configSSLDomain}   
伪装站点的静态html内容放置在目录 ${configWebsitePath}, 可自行更换网站内容.
nginx 配置路径 ${nginxConfigPath}, nginx 访问日志 ${nginxAccessLogFilePath}, nginx 错误日志 ${nginxErrorLogFilePath}
nginx 停止命令: systemctl stop nginx.service  启动命令: systemctl start nginx.service  重启命令: systemctl restart nginx.service

如果安装了Trojan-web ${versionTrojanWeb} 可视化管理面板,访问地址  ${configSSLDomain}/${configTrojanWebNginxPath}
Trojan-web 停止命令: systemctl stop trojan-web.service  启动命令: systemctl start trojan-web.service  重启命令: systemctl restart trojan-web.service


EOF
}

function removeNginx(){

    ${sudoCmd} systemctl stop nginx.service

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

    rm -f ${configReadme}

    rm -rf "/etc/nginx"
    ${sudoCmd} bash /root/.acme.sh/acme.sh --uninstall
    uninstall /root/.acme.sh
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
            green "     SSL证书已检测到获取成功!"
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


    if [ "$configV2rayVlessMode" != "trojan" ] ; then
        configV2rayTrojanPort=443
    fi


    if [ "$isTrojanGo" = "no" ] ; then

        # 增加trojan 服务器端配置
	    cat > ${configTrojanBasePath}/server.json <<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": $configV2rayTrojanPort,
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

        rm /etc/systemd/system/trojan.service   
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
    "local_port": $configV2rayTrojanPort,
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
    ${sudoCmd} systemctl daemon-reload
    ${sudoCmd} systemctl start trojan${promptInfoTrojanName}.service
    ${sudoCmd} systemctl enable trojan${promptInfoTrojanName}.service



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

    if [[ ${isInstallNginx} == "true" ]]; then
        green "    伪装站点为 http://${configSSLDomain}"
	    green "    伪装站点的静态html内容放置在目录 ${configWebsitePath}, 可自行更换网站内容!"
    fi

	red "    Trojan 服务器端配置路径 ${configTrojanBasePath}/server.json "
	red "    Trojan 访问日志 ${configTrojanLogFile} 或运行 journalctl -u trojan${promptInfoTrojanName}.service 查看 !"
	green "    Trojan 停止命令: systemctl stop trojan${promptInfoTrojanName}.service  启动命令: systemctl start trojan${promptInfoTrojanName}.service  重启命令: systemctl restart trojan${promptInfoTrojanName}.service"
	green "    Trojan 服务器 每天会自动重启,防止内存泄漏. 运行 crontab -l 命令 查看定时重启命令 !"
	green "======================================================================"
	blue  "----------------------------------------"
	yellow "Trojan${promptInfoTrojanName} 配置信息如下, 请自行复制保存, 密码任选其一 !"
	yellow "服务器地址: ${configSSLDomain}  端口: $configV2rayTrojanPort"
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
	yellow "1 Windows 客户端下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/v2ray-windows.zip"
	#yellow "  Windows 客户端另一个版本下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/trojan-Qt5-windows.zip"
	yellow "  Windows 客户端命令行版本下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/trojan-win-cli.zip"
	yellow "  Windows 客户端命令行版本需要搭配浏览器插件使用，例如switchyomega等! "
    yellow "2 MacOS 客户端下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/trojan-mac.zip"
    #yellow "  MacOS 客户端Trojan-Qt5下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/trojan-Qt5-mac.zip"
    yellow "3 Android 客户端下载 https://github.com/trojan-gfw/igniter/releases "
    yellow "  Android 另一个客户端下载 https://github.com/2dust/v2rayNG/releases "
    yellow "  Android 客户端Clash下载 https://github.com/Kr328/ClashForAndroid/releases "
    yellow "4 iOS 客户端 请安装小火箭 https://shadowsockshelp.github.io/ios/ "
    yellow "  iOS 请安装小火箭另一个地址 https://lueyingpro.github.io/shadowrocket/index.html "
    yellow "  iOS 安装小火箭遇到问题 教程 https://github.com/shadowrocketHelp/help/ "
    green "======================================================================"
	green "教程与其他资源:"
	green "访问 https://www.v2rayssr.com/trojan-1.html ‎ 下载 浏览器插件 客户端 及教程"
	green "客户端汇总 https://tlanyan.me/trojan-clients-download ‎ 下载 trojan客户端"
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


    cat >> ${configReadme} <<-EOF

Trojan${promptInfoTrojanName} Version: ${configTrojanBaseVersion} 安装成功 !
Trojan${promptInfoTrojanName} 服务器端配置路径 ${configTrojanBasePath}/server.json
Trojan${promptInfoTrojanName} 停止命令: systemctl stop trojan${promptInfoTrojanName}.service  启动命令: systemctl start trojan${promptInfoTrojanName}.service  重启命令: systemctl restart trojan${promptInfoTrojanName}.service

Trojan${promptInfoTrojanName}服务器地址: ${configSSLDomain}  端口: $configV2rayTrojanPort

密码1: ${trojanPassword1}
密码2: ${trojanPassword2}
密码3: ${trojanPassword3}
密码4: ${trojanPassword4}
密码5: ${trojanPassword5}
密码6: ${trojanPassword6}
密码7: ${trojanPassword7}
密码8: ${trojanPassword8}
密码9: ${trojanPassword9}
密码10: ${trojanPassword10}
您指定前缀的密码若干: 从 ${configTrojanPasswordPrefixInput}202010 到 ${configTrojanPasswordPrefixInput}202099 都可以使用

如果是trojan-go开启了Websocket，那么Websocket path 路径为: /${configTrojanGoWebSocketPath}


EOF
}


function removeTrojan(){

    isTrojanGoInstall

    ${sudoCmd} systemctl stop trojan${promptInfoTrojanName}.service
    ${sudoCmd} systemctl disable trojan${promptInfoTrojanName}.service

    green " ================================================== "
    red " 准备卸载已安装的trojan${promptInfoTrojanName}"
    green " ================================================== "

    rm -rf ${configTrojanBasePath}
    rm -f ${osSystemMdPath}trojan${promptInfoTrojanName}.service
    rm -f ${configTrojanLogFile}
    rm -f ${configTrojanGoLogFile}

    rm -f ${configReadme}

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

    ${sudoCmd} systemctl stop trojan${promptInfoTrojanName}.service

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

    ${sudoCmd} systemctl start trojan${promptInfoTrojanName}.service

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
        green "  已安装过 V2ray 或 Xray, 退出安装 !"
        green " =================================================="
        exit
    fi


    if [[ $configV2rayVlessMode == "trojan" ]] ; then
        promptInfoXrayName="xray"
        isXray="yes"
    else
        read -p "是否使用Xray内核(默认为V2ray内核 )? 请输入[y/N]?" isV2rayOrXrayInput
        isV2rayOrXrayInput=${isV2rayOrXrayInput:-n}

        if [[ $isV2rayOrXrayInput == [Yy] ]]; then
            promptInfoXrayName="xray"
            isXray="yes"
        fi
    fi


    if [[ -n "$configV2rayVlessMode" ]]; then
         configV2rayProtocol="vless"
    else 

        read -p "是否使用VLESS协议(默认为VMess协议 )? 请输入[y/N]?" isV2rayUseVLessInput
        isV2rayUseVLessInput=${isV2rayUseVLessInput:-n}

        if [[ $isV2rayUseVLessInput == [Yy] ]]; then
            configV2rayProtocol="vless"
        else
            configV2rayProtocol="vmess"
        fi

    fi


    if [ "$isXray" = "no" ] ; then
        getTrojanAndV2rayVersion "v2ray"
        green " =================================================="
        green "    开始安装 V2ray Version: ${versionV2ray} !"
        green " =================================================="
    else
        getTrojanAndV2rayVersion "xray"
        green " =================================================="
        green "    开始安装 Xray Version: ${versionXray} !"
        green " =================================================="
    fi



    mkdir -p ${configV2rayPath}
    cd ${configV2rayPath}
    rm -rf ${configV2rayPath}/*


    if [ "$isXray" = "no" ] ; then
        # https://github.com/v2fly/v2ray-core/releases/download/v4.27.5/v2ray-linux-64.zip
        downloadAndUnzip "https://github.com/v2fly/v2ray-core/releases/download/v${versionV2ray}/${downloadFilenameV2ray}" "${configV2rayPath}" "${downloadFilenameV2ray}"

    else
        downloadAndUnzip "https://github.com/XTLS/Xray-core/releases/download/v${versionXray}/${downloadFilenameXray}" "${configV2rayPath}" "${downloadFilenameXray}"
    fi


    # 增加 v2ray 服务器端配置

    read -r -d '' userpasswordInput << EOM
                        {
                            "id": "${v2rayPassword1}",
                            "level": 0,
                            "email": "password11@gmail.com"
                        },
                        {
                            "id": "${v2rayPassword2}",
                            "level": 0,
                            "email": "password12@gmail.com"
                        },
                        {
                            "id": "${v2rayPassword3}",
                            "level": 0,
                            "email": "password13@gmail.com"
                        },
                        {
                            "id": "${v2rayPassword4}",
                            "level": 0,
                            "email": "password14@gmail.com"
                        },
                        {
                            "id": "${v2rayPassword5}",
                            "level": 0,
                            "email": "password15@gmail.com"
                        },
                        {
                            "id": "${v2rayPassword6}",
                            "level": 0,
                            "email": "password16@gmail.com"
                        },
                        {
                            "id": "${v2rayPassword7}",
                            "level": 0,
                            "email": "password17@gmail.com"
                        },
                        {
                            "id": "${v2rayPassword8}",
                            "level": 0,
                            "email": "password18@gmail.com"
                        },
                        {
                            "id": "${v2rayPassword9}",
                            "level": 0,
                            "email": "password19@gmail.com"
                        },
                        {
                            "id": "${v2rayPassword10}",
                            "level": 0,
                            "email": "password20@gmail.com"
                        }
EOM

    if [[ -z "$configV2rayVlessMode" ]]; then
        cat > ${configV2rayPath}/config.json <<-EOF
{
    "log" : {
        "access": "${configV2rayAccessLogFilePath}",
        "error": "${configV2rayErrorLogFilePath}",
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${userpasswordInput}
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/${configV2rayWebSocketPath}"
                }
            }
        }
    ],
    "outbounds": [
        {
            "tag": "direct",
            "protocol": "freedom",
            "settings": {}
        },
        {
            "tag": "blocked",
            "protocol": "blackhole",
            "settings": {}
        }
    ]
}
EOF
    fi


    if [[ "$configV2rayVlessMode" == "vlessws" ]]; then
        cat > ${configV2rayPath}/config.json <<-EOF
{
    "log" : {
        "access": "${configV2rayAccessLogFilePath}",
        "error": "${configV2rayErrorLogFilePath}",
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": 443,
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${userpasswordInput}
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": 80
                    },
                    {
                        "path": "/${configV2rayWebSocketPath}",
                        "dest": ${configV2rayPort},
                        "xver": 1
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "tls",
                "tlsSettings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "${configSSLCertPath}/fullchain.cer",
                            "keyFile": "${configSSLCertPath}/private.key"
                        }
                    ]
                }
            }
        },
        {
            "port": ${configV2rayPort},
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    ${userpasswordInput}
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "acceptProxyProtocol": true,
                    "path": "/${configV2rayWebSocketPath}" 
                }
            }
        }
    ],
    "outbounds": [
        {
            "tag": "direct",
            "protocol": "freedom",
            "settings": {}
        },
        {
            "tag": "blocked",
            "protocol": "blackhole",
            "settings": {}
        }
    ]
}
EOF
    fi


    if [[ "$configV2rayVlessMode" == "vmessws" ]]; then
        cat > ${configV2rayPath}/config.json <<-EOF
{
    "log" : {
        "access": "${configV2rayAccessLogFilePath}",
        "error": "${configV2rayErrorLogFilePath}",
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": 443,
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${userpasswordInput}
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": 80
                    },
                    {
                        "path": "/${configV2rayWebSocketPath}",
                        "dest": ${configV2rayPort},
                        "xver": 1
                    },
                    {
                        "path": "/tcp${configV2rayWebSocketPath}",
                        "dest": ${configV2rayVmessTCPPort},
                        "xver": 1
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "tls",
                "tlsSettings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "${configSSLCertPath}/fullchain.cer",
                            "keyFile": "${configSSLCertPath}/private.key"
                        }
                    ]
                }
            }
        },
        {
            "port": ${configV2rayPort},
            "listen": "127.0.0.1",
            "protocol": "vmess",
            "settings": {
                "clients": [
                    ${userpasswordInput}
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "/${configV2rayWebSocketPath}" 
                }
            }
        },
        {
            "port": ${configV2rayVmessTCPPort},
            "listen": "127.0.0.1",
            "protocol": "vmess",
            "settings": {
                "clients": [
                    ${userpasswordInput}
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "none",
                "tcpSettings": {
                    "acceptProxyProtocol": true,
                    "header": {
                        "type": "http",
                        "request": {
                            "path": [
                                "/tcp${configV2rayWebSocketPath}"
                            ]
                        }
                    }
                }
            }
        }
    ],
    "outbounds": [
        {
            "tag": "direct",
            "protocol": "freedom",
            "settings": {}
        },
        {
            "tag": "blocked",
            "protocol": "blackhole",
            "settings": {}
        }
    ]
}
EOF
    fi






    if [[ "$configV2rayVlessMode" == "trojan" ]]; then

            cat > ${configV2rayPath}/config.json <<-EOF
{
    "log" : {
        "access": "${configV2rayAccessLogFilePath}",
        "error": "${configV2rayErrorLogFilePath}",
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": 443,
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    {
                        "id": "${v2rayPassword1}",
                        "flow": "xtls-rprx-direct",
                        "level": 0,
                        "email": "password11@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword2}",
                        "flow": "xtls-rprx-direct",
                        "level": 0,
                        "email": "password12@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword3}",
                        "flow": "xtls-rprx-direct",
                        "level": 0,
                        "email": "password13@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword4}",
                        "flow": "xtls-rprx-direct",
                        "level": 0,
                        "email": "password14@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword5}",
                        "flow": "xtls-rprx-direct",
                        "level": 0,
                        "email": "password15@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword6}",
                        "flow": "xtls-rprx-direct",
                        "level": 0,
                        "email": "password16@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword7}",
                        "flow": "xtls-rprx-direct",
                        "level": 0,
                        "email": "password17@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword8}",
                        "flow": "xtls-rprx-direct",
                        "level": 0,
                        "email": "password18@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword9}",
                        "flow": "xtls-rprx-direct",
                        "level": 0,
                        "email": "password19@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword10}",
                        "flow": "xtls-rprx-direct",
                        "level": 0,
                        "email": "password20@gmail.com"
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": ${configV2rayTrojanPort}
                    },
                    {
                        "path": "/${configTrojanGoWebSocketPath}",
                        "dest": ${configV2rayTrojanPort}
                    },
                    {
                        "path": "/${configV2rayWebSocketPath}",
                        "dest": ${configV2rayPort},
                        "xver": 1
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "xtls",
                "xtlsSettings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "${configSSLCertPath}/fullchain.cer",
                            "keyFile": "${configSSLCertPath}/private.key"
                        }
                    ]
                }
            }
        },
        {
            "port": ${configV2rayPort},
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${v2rayPassword1}",
                        "level": 0,
                        "email": "password11@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword2}",
                        "level": 0,
                        "email": "password12@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword3}",
                        "level": 0,
                        "email": "password13@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword4}",
                        "level": 0,
                        "email": "password14@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword5}",
                        "level": 0,
                        "email": "password15@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword6}",
                        "level": 0,
                        "email": "password16@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword7}",
                        "level": 0,
                        "email": "password17@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword8}",
                        "level": 0,
                        "email": "password18@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword9}",
                        "level": 0,
                        "email": "password19@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword10}",
                        "level": 0,
                        "email": "password20@gmail.com"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "acceptProxyProtocol": true,
                    "path": "/${configV2rayWebSocketPath}" 
                }
            }
        }
    ],
    "outbounds": [
        {
            "tag": "direct",
            "protocol": "freedom",
            "settings": {}
        },
        {
            "tag": "blocked",
            "protocol": "blackhole",
            "settings": {}
        }
    ]
}
EOF

    fi





    # 增加 V2ray启动脚本
    if [ "$isXray" = "no" ] ; then
    
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
NoNewPrivileges=true
ExecStart=${configV2rayPath}/v2ray -config ${configV2rayPath}/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
    else
        cat > ${osSystemMdPath}xray.service <<-EOF
[Unit]
Description=Xray
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
NoNewPrivileges=true
ExecStart=${configV2rayPath}/xray run -config ${configV2rayPath}/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
    fi

    ${sudoCmd} chmod +x ${configV2rayPath}/${promptInfoXrayName}
    ${sudoCmd} chmod +x ${osSystemMdPath}${promptInfoXrayName}.service
    ${sudoCmd} systemctl daemon-reload
    ${sudoCmd} systemctl restart ${promptInfoXrayName}.service
    ${sudoCmd} systemctl enable ${promptInfoXrayName}.service




    # 增加客户端配置说明
    if [[ ${isInstallNginx} == "true" ]]; then
        configV2rayPortShowInfo=443
        configV2rayIsTlsShowInfo="tls"
    else
        configV2rayIsTlsShowInfo="none"
    fi

    if [[ -n "$configV2rayVlessMode" ]]; then
        configV2rayPortShowInfo=443
        configV2rayIsTlsShowInfo="tls"
    fi




    cat > ${configV2rayPath}/clientConfig.json <<-EOF
===========V2ray客户端配置参数=============
{
    协议: ${configV2rayProtocol},
    地址: ${configSSLDomain},
    端口: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    加密方式: aes-128-gcm,  // 如果是Vless协议则为none
    传输协议: ws,
    WS路径:/${configV2rayWebSocketPath},
    底层传输协议:${configV2rayIsTlsShowInfo},
    别名:自己起个任意名称
}
EOF


if [[ "$configV2rayVlessMode" == "vlessws" ]] || [[ "$configV2rayVlessMode" == "trojan" ]]; then
    cat > ${configV2rayPath}/clientConfig.json <<-EOF
当选择了16. 只安装v2ray VLess运行在443端口 (VLess-TCP-TLS) + (VLess-WS-TLS) 支持CDN, 不安装nginx
当选择了20. 只安装Xray VLess运行在443端口 (VLess-TCP-XTLS direct ) + (VLess-WS-TLS), 不安装nginx" 
当选择了21. 只安装Xray VLess运行在443端口 (VLess-TCP-XTLS direct ) + (VLess-WS-TLS) + trojan 支持VLess的CDN, 不安装nginx
当选择了22. 只安装Xray VLess运行在443端口 (VLess-TCP-XTLS direct) + (VLess-WS-TLS) + trojan-go 支持VLess的CDN, 不安装nginx
当选择了23. 只安装Xray VLess运行在443端口 (VLess-TCP-XTLS direct) + (VLess-WS-TLS) + trojan-go 支持VLess的CDN和trojan-go的CDN, 不安装nginx

===========V2ray客户端 VLess-TCP-TLS 配置参数=============
{
    协议: VLess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    流控flow:  // 选择了16 为空, 选择了20-23 为 xtls-rprx-direct
    加密方式: none,  // 如果是Vless协议则为none
    传输协议: tcp ,
    WS路径:无,
    底层传输协议:tls,    // 选择了16 为tls, 选择了20-23 为xtls
    别名:自己起个任意名称
}

===========V2ray客户端 VLess-WS-TLS 配置参数 支持CDN =============
{
    协议: VLess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    流控flow:  // 选择了16 为空, 选择了20-23 为 xtls-rprx-direct
    加密方式: none,  // 如果是Vless协议则为none
    传输协议: ws,
    WS路径:/${configV2rayWebSocketPath},
    底层传输:tls,     
    别名:自己起个任意名称
}
EOF
fi



if [[ "$configV2rayVlessMode" == "vmessws" ]]; then
    cat > ${configV2rayPath}/clientConfig.json <<-EOF
当选择了17. 只安装v2ray VLess运行在443端口 (VLess-TCP-TLS) + (VMess-TCP-TLS) + (VMess-WS-TLS)  支持CDN, 不安装nginx
===========V2ray客户端 VLess-TCP-TLS 配置参数=============
{
    协议: VLess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    加密方式: none,  // 如果是Vless协议则为none
    传输协议: tcp ,
    WS路径:无,
    底层传输:tls,
    别名:自己起个任意名称
}

===========V2ray客户端 VMess-WS-TLS 配置参数 支持CDN =============
{
    协议: VMess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    加密方式: none,  // 如果是Vless协议则为none
    传输协议: ws,
    WS路径:/${configV2rayWebSocketPath},
    底层传输:tls,
    别名:自己起个任意名称
}

===========V2ray客户端 VMess-TCP-TLS 配置参数 支持CDN =============
{
    协议: VMess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    加密方式: none,  // 如果是Vless协议则为none
    传输协议: tcp,
    路径:/tcp${configV2rayWebSocketPath},
    底层传输:tls,
    别名:自己起个任意名称
}
EOF
fi




    # 设置 cron 定时任务
    # https://stackoverflow.com/questions/610839/how-can-i-programmatically-create-a-new-cron-job

    (crontab -l ; echo "20 4 * * 0,1,2,3,4,5,6 systemctl restart ${promptInfoXrayName}.service") | sort - | uniq - | crontab -


    green "======================================================================"

    if [ "$isXray" = "no" ] ; then
        green "    V2ray Version: ${versionV2ray} 安装成功 !!"
    else
        green "    Xray Version: ${versionXray} 安装成功 !!"
    fi

    if [[ ${isInstallNginx} == "true" ]]; then
        green "    伪装站点为 https://${configSSLDomain}!"
    fi
	
	red "    ${promptInfoXrayName} 服务器端配置路径 ${configV2rayPath}/config.json !"
	red "    ${promptInfoXrayName} 访问日志 ${configV2rayAccessLogFilePath} !"
	red "    ${promptInfoXrayName} 错误日志 ${configV2rayErrorLogFilePath} !"
	green "    ${promptInfoXrayName} 停止命令: systemctl stop ${promptInfoXrayName}.service  启动命令: systemctl start ${promptInfoXrayName}.service  重启命令: systemctl restart ${promptInfoXrayName}.service"
	# green "    caddy 停止命令: systemctl stop caddy.service  启动命令: systemctl start caddy.service  重启命令: systemctl restart caddy.service"
	green "    ${promptInfoXrayName} 服务器 每天会自动重启,防止内存泄漏. 运行 crontab -l 命令 查看定时重启命令 !"
	green "======================================================================"
	echo ""
	yellow "${promptInfoXrayName} 配置信息如下, 请自行复制保存, 密码任选其一 (密码即用户ID或UUID) !!"
	yellow "服务器地址: ${configSSLDomain}  端口: ${configV2rayPortShowInfo}"
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
    echo ""
	cat "${configV2rayPath}/clientConfig.json"
	echo ""
    green "======================================================================"
    green "请下载相应的 ${promptInfoXrayName} 客户端:"
    yellow "1 Windows 客户端V2rayN下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/v2ray-windows.zip"
    yellow "2 MacOS 客户端下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/v2ray-mac.zip"
    yellow "3 Android 客户端下载 https://github.com/2dust/v2rayNG/releases"
    #yellow "3 Android 客户端下载 http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/v2ray-android.zip"
    yellow "4 iOS 客户端 请安装小火箭 https://shadowsockshelp.github.io/ios/ "
    yellow "  iOS 请安装小火箭另一个地址 https://lueyingpro.github.io/shadowrocket/index.html "
    yellow "  iOS 安装小火箭遇到问题 教程 https://github.com/shadowrocketHelp/help/ "
    yellow "其他客户端程序请看 https://www.v2fly.org/awesome/tools.html "
    green "======================================================================"

    cat >> ${configReadme} <<-EOF

V2ray Version: ${versionV2ray} 安装成功 ! 
V2ray 服务器端配置路径 ${configV2rayPath}/config.json 
V2ray 访问日志 ${configV2rayAccessLogFilePath} , V2ray 错误日志 ${configV2rayErrorLogFilePath}
V2ray 停止命令: systemctl stop v2ray.service  启动命令: systemctl start v2ray.service  重启命令: systemctl restart v2ray.service

V2ray 服务器地址: ${configSSLDomain}  端口: ${configV2rayPortShowInfo}"
用户ID或密码1: ${v2rayPassword1}"
用户ID或密码2: ${v2rayPassword2}"
用户ID或密码3: ${v2rayPassword3}"
用户ID或密码4: ${v2rayPassword4}"
用户ID或密码5: ${v2rayPassword5}"
用户ID或密码6: ${v2rayPassword6}"
用户ID或密码7: ${v2rayPassword7}"
用户ID或密码8: ${v2rayPassword8}"
用户ID或密码9: ${v2rayPassword9}"
用户ID或密码10: ${v2rayPassword10}"

===========V2ray客户端配置参数=============
{
    协议: ${configV2rayProtocol},
    地址: ${configSSLDomain},
    端口: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    加密方式: aes-128-gcm,  // 如果是Vless协议则为none
    传输协议: ws,
    WS路径:/${configV2rayWebSocketPath},
    底层传输:${configV2rayIsTlsShowInfo},
    别名:自己起个任意名称
}


EOF

}


function removeV2ray(){
    if [ -f "${configV2rayPath}/xray" ]; then
        promptInfoXrayName="xray"
        isXray="yes"
    fi

    green " ================================================== "
    red " 准备卸载已安装 ${promptInfoXrayName} "
    green " ================================================== "

    ${sudoCmd} systemctl stop ${promptInfoXrayName}.service
    ${sudoCmd} systemctl disable ${promptInfoXrayName}.service


    rm -rf ${configV2rayPath}
    rm -f ${osSystemMdPath}${promptInfoXrayName}.service
    rm -f ${configV2rayAccessLogFilePath}
    rm -f ${configV2rayErrorLogFilePath}

    green " ================================================== "
    green "  ${promptInfoXrayName} 卸载完毕 !"
    green " ================================================== "
}


function upgradeV2ray(){
    if [ -f "${configV2rayPath}/xray" ]; then
        promptInfoXrayName="xray"
        isXray="yes"
    fi

    if [ "$isXray" = "no" ] ; then
        getTrojanAndV2rayVersion "v2ray"
        green " =================================================="
        green "       开始升级 V2ray Version: ${versionV2ray} !"
        green " =================================================="
    else
        getTrojanAndV2rayVersion "xray"
        green " =================================================="
        green "       开始升级 Xray Version: ${versionXray} !"
        green " =================================================="
    fi



    ${sudoCmd} systemctl stop ${promptInfoXrayName}.service

    mkdir -p ${configDownloadTempPath}/upgrade/${promptInfoXrayName}

    if [ "$isXray" = "no" ] ; then
        downloadAndUnzip "https://github.com/v2fly/v2ray-core/releases/download/v${versionV2ray}/${downloadFilenameV2ray}" "${configDownloadTempPath}/upgrade/${promptInfoXrayName}" "${downloadFilenameV2ray}"
        mv -f ${configDownloadTempPath}/upgrade/${promptInfoXrayName}/v2ctl ${configV2rayPath}
    else
        downloadAndUnzip "https://github.com/XTLS/Xray-core/releases/download/v${versionXray}/${downloadFilenameXray}" "${configDownloadTempPath}/upgrade/${promptInfoXrayName}" "${downloadFilenameXray}"
    fi

    mv -f ${configDownloadTempPath}/upgrade/${promptInfoXrayName}/${promptInfoXrayName} ${configV2rayPath}
    mv -f ${configDownloadTempPath}/upgrade/${promptInfoXrayName}/geoip.dat ${configV2rayPath}
    mv -f ${configDownloadTempPath}/upgrade/${promptInfoXrayName}/geosite.dat ${configV2rayPath}

    ${sudoCmd} systemctl start ${promptInfoXrayName}.service


    if [ "$isXray" = "no" ] ; then
        green " ================================================== "
        green "     升级成功 V2ray Version: ${versionV2ray} !"
        green " ================================================== "
    else
        getTrojanAndV2rayVersion "xray"
        green " =================================================="
        green "     升级成功 Xray Version: ${versionXray} !"
        green " =================================================="
    fi
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

        ${sudoCmd} systemctl daemon-reload
        ${sudoCmd} systemctl restart trojan-web.service
        ${sudoCmd} systemctl enable trojan-web.service

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

    ${sudoCmd} systemctl stop trojan.service
    ${sudoCmd} systemctl stop trojan-web.service
    ${sudoCmd} systemctl disable trojan-web.service

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

    ${sudoCmd} systemctl stop trojan-web.service

    mkdir -p ${configDownloadTempPath}/upgrade/trojan-web

    wget -O ${configDownloadTempPath}/upgrade/trojan-web/trojan-web "https://github.com/Jrohy/trojan/releases/download/v${versionTrojanWeb}/${downloadFilenameTrojanWeb}"
    mv -f ${configDownloadTempPath}/upgrade/trojan-web/trojan-web ${configTrojanWebPath}
    chmod +x ${configTrojanWebPath}/trojan-web

    ${sudoCmd} systemctl start trojan-web.service
    ${sudoCmd} systemctl restart trojan.service


    green " ================================================== "
    green "     升级成功 Trojan-web 可视化管理面板: ${versionTrojanWeb} !"
    green " ================================================== "
}
function runTrojanWebSSL(){
    ${sudoCmd} systemctl stop trojan-web.service
    ${sudoCmd} systemctl stop nginx.service
    ${sudoCmd} systemctl stop trojan.service
    ${configTrojanWebPath}/trojan-web tls
    ${sudoCmd} systemctl start trojan-web.service
    ${sudoCmd} systemctl start nginx.service
    ${sudoCmd} systemctl restart trojan.service
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
        green " 请确保 65432 端口已经放行, 例如检查linux防火墙或VPS防火墙 65432 端口是否开启"
        green " V2ray-UI 可视化管理面板 默认管理员用户 admin 密码 admin, 为保证安全,请登陆后尽快修改默认密码 "
        green " =================================================="

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


function getHTTPSNoNgix(){
    #stopServiceNginx
    #testLinuxPortUsage


    green " ================================================== "
    yellow " 请输入绑定到本VPS的域名 例如www.xxx.com: (此步骤请关闭CDN后和nginx后安装 避免80端口占用导致申请证书失败)"
    green " ================================================== "

    read configSSLDomain

    read -p "是否申请证书? 默认为自动申请证书,如果二次安装或已有证书可以选否 请输入[Y/n]?" isDomainSSLRequestInput
    isDomainSSLRequestInput=${isDomainSSLRequestInput:-Y}

    isInstallNginx="false"

    if compareRealIpWithLocalIp "${configSSLDomain}" ; then
        if [[ $isDomainSSLRequestInput == [Yy] ]]; then

            getHTTPSCertificate "standalone"

            if test -s ${configSSLCertPath}/fullchain.cer; then
                green " =================================================="
                green "   域名SSL证书申请成功 !"
                green " ${configSSLDomain} 域名证书内容文件路径 ${configSSLCertPath}/fullchain.cer "
                green " ${configSSLDomain} 域名证书私钥文件路径 ${configSSLCertPath}/private.key "
                green " =================================================="

            else
                red "==================================="
                red " https证书没有申请成功，安装失败!"
                red " 请检查域名和DNS是否生效, 同一域名请不要一天内多次申请!"
                red " 请检查80和443端口是否开启, VPS服务商可能需要添加额外防火墙规则，例如阿里云、谷歌云等!"
                red " 重启VPS, 重新执行脚本, 可重新选择修复证书选项再次申请证书 ! "
                red "==================================="
                exit
            fi

        else
            green " =================================================="
            green "   不申请域名的证书, 请把证书放到如下目录, 或自行修改trojan或v2ray配置!"
            green " ${configSSLDomain} 域名证书内容文件路径 ${configSSLCertPath}/fullchain.cer "
            green " ${configSSLDomain} 域名证书私钥文件路径 ${configSSLCertPath}/private.key "
            green " =================================================="
        fi
    else
        exit
    fi



    if [[ $1 == "trojan" ]] ; then
        installTrojanServer
    fi

    if [[ $1 == "v2ray" ]] ; then
        installV2ray

        if [[ $configV2rayVlessMode == "trojan" && $configV2rayInstallXrayOnly=="" ]]; then
            installTrojanServer
        fi
    fi
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
    green " 6. 安装 v2ray 可视化管理面板V2ray UI 可以同时支持trojan"
    green " 7. 升级 v2ray UI 到最新版本"
    red " 8. 卸载 v2ray UI"
    echo
    red " 安装上述2款可视化管理面板 之前不能用本脚本安装过trojan或v2ray 安装过请先用本脚本卸载!"
    red " 安装上述2款可视化管理面板 之前不能用其他脚本安装过trojan或v2ray 安装过请先用其他脚本卸载!"
    red " 上述2款可视化管理面板 无法同时安装!"

    green " =================================================="

    green " 11. 单独申请域名SSL证书"
    green " 12. 只安装trojan 运行在443端口, 不安装nginx, 请确保443端口没有被nginx占用"
    green " 13. 只安装trojan-go 运行在443端口, 不支持CDN, 不开启websocket, 不安装nginx. 请确保80端口有监听,否则trojan-go无法启动"
    green " 14. 只安装trojan-go 运行在443端口, 支持CDN, 开启websocket, 不安装nginx. 请确保80端口有监听,否则trojan-go无法启动"    
    green " 15. 只安装V2Ray或Xray (VLess或VMess协议) 开启websocket, 支持CDN, (VLess/VMess+WS) 不安装nginx,无TLS加密,方便与现有网站或宝塔面板集成"
    green " 16. 只安装V2Ray VLess运行在443端口 (VLess-TCP-TLS) + (VLess-WS-TLS) 支持CDN, 不安装nginx"
    green " 17. 只安装V2Ray VLess运行在443端口 (VLess-TCP-TLS) + (VMess-TCP-TLS) + (VMess-WS-TLS) 支持CDN, 不安装nginx"
    green " 20. 只安装Xray VLess运行在443端口 (VLess-TCP-XTLS direct) + (VLess-WS-TLS), 不安装nginx" 
    green " 21. 只安装Xray VLess运行在443端口 (VLess-TCP-XTLS direct) + (VLess-WS-TLS) + trojan 支持VLess的CDN, 不安装nginx"    
    green " 22. 只安装Xray VLess运行在443端口 (VLess-TCP-XTLS direct) + (VLess-WS-TLS) + trojan-go 支持VLess的CDN, 不安装nginx"   
    green " 23. 只安装Xray VLess运行在443端口 (VLess-TCP-XTLS direct) + (VLess-WS-TLS) + trojan-go 支持VLess的CDN和trojan-go的CDN, 不安装nginx"   

    red " 27. 卸载 trojan"    
    red " 28. 卸载 trojan-go"   
    red " 29. 卸载 v2ray或Xray"   

    green " =================================================="
    echo
    green " 以下是 VPS 测网速工具"
    red " 脚本测速会大量消耗 VPS 流量，请悉知！"
    green " 31. superspeed 三网纯测速 （全国各地三大运营商部分节点全面测速）"
    green " 32. 由teddysun 编写的Bench 综合测试 （包含系统信息 IO 测试 多处数据中心的节点测试 ）"
	green " 33. testrace 回程路由测试 （四网路由测试）"
	green " 34. LemonBench 快速全方位测试 （包含CPU内存性能、回程、速度）"
    green " 35. ZBench 综合网速测试 （包含节点测速, Ping 以及 路由测试）"
    echo
    green " 41. 安装新版本 BBR-PLUS 加速6合一脚本"
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
            getHTTPSNoNgix
        ;;
        12 )
            getHTTPSNoNgix "trojan"
        ;;
        13 )
            isTrojanGo="yes"
            getHTTPSNoNgix "trojan"
        ;;
        14 )
            isTrojanGo="yes"
            isTrojanGoSupportWebsocket="true"
            getHTTPSNoNgix "trojan"
        ;;          
        15 )
            getHTTPSNoNgix "v2ray"
        ;;     
        16 )
            configV2rayVlessMode="vlessws"
            getHTTPSNoNgix "v2ray"
        ;; 
        17 )
            configV2rayVlessMode="vmessws"
            getHTTPSNoNgix "v2ray"
        ;;    
        20 )
            configV2rayVlessMode="trojan"
            configV2rayInstallXrayOnly="yes"
            getHTTPSNoNgix "v2ray"
        ;; 
        21 )
            configV2rayVlessMode="trojan"
            getHTTPSNoNgix "v2ray"
        ;;
        22 )
            configV2rayVlessMode="trojan"
            isTrojanGo="yes"
            getHTTPSNoNgix "v2ray"
        ;;    
        23 )
            configV2rayVlessMode="trojan"
            isTrojanGo="yes"
            isTrojanGoSupportWebsocket="true"
            getHTTPSNoNgix "v2ray"
        ;;     
        27 )
            removeTrojan
        ;;    
        28 )
            isTrojanGo="yes"
            removeTrojan
        ;;
        29 )
            removeV2ray
        ;;                                                   
        31 )
            vps_superspeed
        ;;
        32 )
            vps_bench
        ;;        
        33 )
            vps_testrace
        ;;
        34 )
            vps_LemonBench
        ;;
        35 )
            vps_zbench
        ;;        
        41 )
            installBBR2
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
    green " Trojan Trojan-go V2ray 一键安装脚本 2020-12-6 更新.  系统支持：centos7+ / debian9+ / ubuntu16.04+"
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
    green " 8. 安装 trojan-go 和 nginx 支持CDN 开启websocket (兼容trojan客户端但不兼容websocket)"
    green " 9. 修复证书 并继续安装 trojan-go 支持CDN, 开启websocket"
    green " 10. 升级 trojan-go 到最新版本"
    red " 11. 卸载 trojan-go 与 nginx"
    echo
    green " 12. 安装 v2ray或xray 和 nginx, 支持 websocket tls1.3, 支持CDN"
    green " 13. 升级 v2ray或xray 到最新版本"
    red " 14. 卸载v2ray或xray 和 nginx"
    echo
    green " 15. 同时安装 trojan + v2ray或xray 和 nginx, 不支持CDN"
    green " 16. 升级 v2ray或xray 和 trojan 到最新版本"
    red " 17. 卸载 trojan, v2ray或xray 和 nginx"
    green " 18. 同时安装 trojan-go + v2ray或xray 和 nginx, 不支持CDN"
    green " 19. 同时安装 trojan-go + v2ray或xray 和 nginx, trojan-go 和 v2ray 都支持CDN"
    green " 20. 升级 v2ray或xray 和 trojan-go 到最新版本"
    red " 21. 卸载 trojan-go, v2ray或xray 和 nginx"
    echo
    green " 28. 查看已安装的配置和用户密码等信息"
    green " 29. 安装 trojan 和 v2ray 可视化管理面板"
    green " 30. 不安装nginx,只安装trojan或v2ray,可选择是否安装SSL证书"
    green " =================================================="
    green " 31. 安装OhMyZsh与插件zsh-autosuggestions, Micro编辑器 等软件"
    green " 32. 设置可以使用root登陆"
    green " 33. 修改SSH 登陆端口号"
    green " 34. 设置时区为北京时间"
    green " 41. VPS 测网速工具"
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
        28 )
            cat "${configReadme}"
            cat "${configV2rayPath}/clientConfig.json"
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
        30 )
            startMenuOther
        ;;        
        41 )
            startMenuOther
        ;;
        77 )
            editLinuxLoginWithPublicKey
        ;;
        88 )
            installBBR2
        ;;
        99 )
            getTrojanAndV2rayVersion "trojan"
            getTrojanAndV2rayVersion "trojan-go"
            getTrojanAndV2rayVersion "trojan-web"
            getTrojanAndV2rayVersion "v2ray"
            getTrojanAndV2rayVersion "xray"
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

