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
  printf "File or Folder Deleted: %s\n" $1
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


osCPU="intel"
osArchitecture="arm"
osInfo=""
osRelease=""
osReleaseVersion=""
osReleaseVersionNo=""
osReleaseVersionCodeName="CodeName"
osSystemPackage=""
osSystemMdPath=""
osSystemShell="bash"


function checkArchitecture(){
	# https://stackoverflow.com/questions/48678152/how-to-detect-386-amd64-arm-or-arm64-os-architecture-via-shell-bash

	case $(uname -m) in
		i386)   osArchitecture="386" ;;
		i686)   osArchitecture="386" ;;
		x86_64) osArchitecture="amd64" ;;
		arm)    dpkg --print-architecture | grep -q "arm64" && osArchitecture="arm64" || osArchitecture="arm" ;;
		* )     osArchitecture="arm" ;;
	esac
}

function checkCPU(){
	osCPUText=$(cat /proc/cpuinfo | grep vendor_id | uniq)
	if [[ $osCPUText =~ "GenuineIntel" ]]; then
		osCPU="intel"
    else
        osCPU="amd"
    fi

	# green " Status 状态显示--当前CPU是: $osCPU"
}

# 检测系统发行版代号
function getLinuxOSRelease(){
    if [[ -f /etc/redhat-release ]]; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
        osReleaseVersionCodeName=""
    elif cat /etc/issue | grep -Eqi "debian|raspbian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="buster"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="bionic"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
        osReleaseVersionCodeName=""
    elif cat /proc/version | grep -Eqi "debian|raspbian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="buster"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="bionic"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
        osReleaseVersionCodeName=""
    fi

    getLinuxOSVersion
    checkArchitecture
	checkCPU

    [[ -z $(echo $SHELL|grep zsh) ]] && osSystemShell="bash" || osSystemShell="zsh"

    green " 系统信息: ${osInfo}, ${osRelease}, ${osReleaseVersion}, ${osReleaseVersionNo}, ${osReleaseVersionCodeName}, ${osCPU} CPU ${osArchitecture}, ${osSystemShell}, ${osSystemPackage}, ${osSystemMdPath}"
}

# 检测系统版本号
getLinuxOSVersion(){
    if [[ -s /etc/redhat-release ]]; then
        osReleaseVersion=$(grep -oE '[0-9.]+' /etc/redhat-release)
    else
        osReleaseVersion=$(grep -oE '[0-9.]+' /etc/issue)
    fi

    # https://unix.stackexchange.com/questions/6345/how-can-i-get-distribution-name-and-version-number-in-a-simple-shell-script

    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        source /etc/os-release
        osInfo=$NAME
        osReleaseVersionNo=$VERSION_ID

        if [ -n $VERSION_CODENAME ]; then
            osReleaseVersionCodeName=$VERSION_CODENAME
        fi
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        osInfo=$(lsb_release -si)
        osReleaseVersionNo=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        osInfo=$DISTRIB_ID
        
        osReleaseVersionNo=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        osInfo=Debian
        osReleaseVersion=$(cat /etc/debian_version)
        osReleaseVersionNo=$(sed 's/\..*//' /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        osReleaseVersion=$(grep -oE '[0-9.]+' /etc/redhat-release)
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        osInfo=$(uname -s)
        osReleaseVersionNo=$(uname -r)
    fi
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
        if  [[ ${osReleaseVersionNo} == "6" || ${osReleaseVersionNo} == "5" ]]; then
            green " =================================================="
            red " 本脚本不支持 Centos 6 或 Centos 6 更早的版本"
            green " =================================================="
            exit
        fi

        red " 关闭防火墙 firewalld"
        ${sudoCmd} systemctl stop firewalld
        ${sudoCmd} systemctl disable firewalld

    elif [ "$osRelease" == "ubuntu" ]; then
        if  [[ ${osReleaseVersionNo} == "14" || ${osReleaseVersionNo} == "12" ]]; then
            green " =================================================="
            red " 本脚本不支持 Ubuntu 14 或 Ubuntu 14 更早的版本"
            green " =================================================="
            exit
        fi

        red " 关闭防火墙 ufw"
        ${sudoCmd} systemctl stop ufw
        ${sudoCmd} systemctl disable ufw
        
    elif [ "$osRelease" == "debian" ]; then
        $osSystemPackage update -y
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

    read -p "是否设置允许root登陆(ssh密钥方式 或 密码方式登陆 )? 请输入[Y/n]:" osIsRootLoginInput
    osIsRootLoginInput=${osIsRootLoginInput:-Y}

    if [[ $osIsRootLoginInput == [Yy] ]]; then

        if [ "$osRelease" == "centos" ] || [ "$osRelease" == "debian" ] ; then
            ${sudoCmd} sed -i 's/#\?PermitRootLogin \(yes\|no\|Yes\|No\|prohibit-password\)/PermitRootLogin yes/g' /etc/ssh/sshd_config
        fi
        if [ "$osRelease" == "ubuntu" ]; then
            ${sudoCmd} sed -i 's/#\?PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
        fi

        green "设置允许root登陆成功!"
    fi


    read -p "是否设置允许root使用密码登陆(上一步请先设置允许root登陆才可以)? 请输入[Y/n]:" osIsRootLoginWithPasswordInput
    osIsRootLoginWithPasswordInput=${osIsRootLoginWithPasswordInput:-Y}

    if [[ $osIsRootLoginWithPasswordInput == [Yy] ]]; then
        sed -i 's/#\?PasswordAuthentication \(yes\|no\)/PasswordAuthentication yes/g' /etc/ssh/sshd_config
        green "设置允许root使用密码登陆成功!"
    fi


    ${sudoCmd} sed -i 's/#\?TCPKeepAlive yes/TCPKeepAlive yes/g' /etc/ssh/sshd_config
    ${sudoCmd} sed -i 's/#\?ClientAliveCountMax 3/ClientAliveCountMax 30/g' /etc/ssh/sshd_config
    ${sudoCmd} sed -i 's/#\?ClientAliveInterval [0-9]*/ClientAliveInterval 40/g' /etc/ssh/sshd_config

    if [ "$osRelease" == "centos" ] ; then

        ${sudoCmd} service sshd restart
        ${sudoCmd} systemctl restart sshd

        green "设置成功, 请用shell工具软件登陆vps服务器!"
    fi

    if [ "$osRelease" == "ubuntu" ] || [ "$osRelease" == "debian" ] ; then
        
        ${sudoCmd} service ssh restart
        ${sudoCmd} systemctl restart ssh

        green "设置成功, 请用shell工具软件登陆vps服务器!"
    fi

    # /etc/init.d/ssh restart

}

# 修改SSH 端口号
function changeLinuxSSHPort(){
    green " 修改的SSH登陆的端口号, 不要使用常用的端口号. 例如 20|21|23|25|53|69|80|110|443|123!"
    read -p "请输入要修改的端口号(必须是纯数字并且在1024~65535之间或22):" osSSHLoginPortInput
    osSSHLoginPortInput=${osSSHLoginPortInput:-0}

    if [ $osSSHLoginPortInput -eq 22 -o $osSSHLoginPortInput -gt 1024 -a $osSSHLoginPortInput -lt 65535 ]; then
        sed -i "s/#\?Port [0-9]*/Port $osSSHLoginPortInput/g" /etc/ssh/sshd_config

        if [ "$osRelease" == "centos" ] ; then

            if  [[ ${osReleaseVersionNo} == "7" ]]; then
                yum -y install policycoreutils-python
            elif  [[ ${osReleaseVersionNo} == "8" ]]; then
                yum -y install policycoreutils-python-utils
            fi

            # semanage port -l
            semanage port -a -t ssh_port_t -p tcp $osSSHLoginPortInput
            firewall-cmd --permanent --zone=public --add-port=$osSSHLoginPortInput/tcp 
            firewall-cmd --reload
    
            ${sudoCmd} systemctl restart sshd.service

        fi

        if [ "$osRelease" == "ubuntu" ] || [ "$osRelease" == "debian" ] ; then
            semanage port -a -t ssh_port_t -p tcp $osSSHLoginPortInput
            sudo ufw allow $osSSHLoginPortInput/tcp

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
        yellow " 当前时区为: $tempCurrentDateZone | $(date -R) "
        yellow " 是否设置时区为北京时间 +0800区, 以便cron定时重启脚本按照北京时间运行."
        green " =================================================="
        # read 默认值 https://stackoverflow.com/questions/2642585/read-a-variable-in-bash-with-a-default-value

        read -p "是否设置为北京时间 +0800 时区? 请输入[Y/n]:" osTimezoneInput
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


function upgradeScript(){
    wget -Nq --no-check-certificate -O ./trojan_v2ray_install.sh "https://raw.githubusercontent.com/jinwyp/one_click_script/master/trojan_v2ray_install.sh"
    green " 本脚本升级成功! "
    chmod +x ./trojan_v2ray_install.sh
    sleep 2s
    exec "./trojan_v2ray_install.sh"
}

function installSoftDownload(){
	if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
		if ! dpkg -l | grep -qw wget; then
			${osSystemPackage} -y install wget curl git
			
			# https://stackoverflow.com/questions/11116704/check-if-vt-x-is-activated-without-having-to-reboot-in-linux
			${osSystemPackage} -y install cpu-checker
		fi

	elif [[ "${osRelease}" == "centos" ]]; then
		if ! rpm -qa | grep -qw wget; then
			${osSystemPackage} -y install wget curl git
		fi
	fi 
}

function installPackage(){
    if [ "$osRelease" == "centos" ]; then
       
        # rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm

        cat > "/etc/yum.repos.d/nginx.repo" <<-EOF
[nginx]
name=nginx repo
baseurl=https://nginx.org/packages/centos/$osReleaseVersionNo/\$basearch/
gpgcheck=0
enabled=1

EOF
        if ! rpm -qa | grep -qw iperf3; then
			${sudoCmd} ${osSystemPackage} install -y epel-release

            ${osSystemPackage} install -y curl wget git unzip zip tar
            ${osSystemPackage} install -y xz jq redhat-lsb-core 
            ${osSystemPackage} install -y iputils
            ${osSystemPackage} install -y iperf3
		fi

        ${osSystemPackage} update -y


        # https://www.cyberciti.biz/faq/how-to-install-and-use-nginx-on-centos-8/
        if  [[ ${osReleaseVersionNo} == "8" ]]; then
            ${sudoCmd} yum module -y reset nginx
            ${sudoCmd} yum module -y enable nginx:1.18
            ${sudoCmd} yum module list nginx
        fi

    elif [ "$osRelease" == "ubuntu" ]; then
        
        # https://joshtronic.com/2018/12/17/how-to-install-the-latest-nginx-on-debian-and-ubuntu/
        # https://www.nginx.com/resources/wiki/start/topics/tutorials/install/
        
        $osSystemPackage install -y gnupg2
        wget -O - https://nginx.org/keys/nginx_signing.key | ${sudoCmd} apt-key add -

        cat > "/etc/apt/sources.list.d/nginx.list" <<-EOF
deb https://nginx.org/packages/ubuntu/ $osReleaseVersionCodeName nginx
deb-src https://nginx.org/packages/ubuntu/ $osReleaseVersionCodeName nginx
EOF

        ${osSystemPackage} update -y

        if ! dpkg -l | grep -qw iperf3; then
            ${sudoCmd} ${osSystemPackage} install -y software-properties-common
            ${osSystemPackage} install -y curl wget git unzip zip tar
            ${osSystemPackage} install -y xz-utils jq lsb-core lsb-release
            ${osSystemPackage} install -y iputils-ping
            ${osSystemPackage} install -y iperf3
		fi    

    elif [ "$osRelease" == "debian" ]; then
        # ${sudoCmd} add-apt-repository ppa:nginx/stable -y

        ${osSystemPackage} install -y gnupg2
        wget -O - https://nginx.org/keys/nginx_signing.key | ${sudoCmd} apt-key add -
        # curl -L https://nginx.org/keys/nginx_signing.key | ${sudoCmd} apt-key add -

        cat > "/etc/apt/sources.list.d/nginx.list" <<-EOF 
deb http://nginx.org/packages/debian/ $osReleaseVersionCodeName nginx
deb-src http://nginx.org/packages/debian/ $osReleaseVersionCodeName nginx
EOF
        
        ${osSystemPackage} update -y

        if ! dpkg -l | grep -qw iperf3; then
            ${osSystemPackage} install -y curl wget git unzip zip tar
            ${osSystemPackage} install -y xz-utils jq lsb-core lsb-release
            ${osSystemPackage} install -y iputils-ping
            ${osSystemPackage} install -y iperf3
        fi        
    fi
}


function installSoftEditor(){
    # 安装 micro 编辑器
    if [[ ! -f "${HOME}/bin/micro" ]] ;  then
        mkdir -p ${HOME}/bin
        cd ${HOME}/bin
        curl https://getmic.ro | bash

        cp ${HOME}/bin/micro /usr/local/bin

        green " =================================================="
        green " micro 编辑器 安装成功!"
        green " =================================================="
    fi

    if [ "$osRelease" == "centos" ]; then   
        $osSystemPackage install -y xz  vim-minimal vim-enhanced vim-common
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
colorscheme elflord

if has('mouse')
  se mouse+=a
  set number
endif

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
    green " ZSH 安装成功"
    green " =================================================="

    # 安装 oh-my-zsh
    if [[ ! -d "${HOME}/.oh-my-zsh" ]] ;  then

        green " =================================================="
        yellow " 准备安装 oh-my-zsh"
        green " =================================================="
        curl -Lo ${HOME}/ohmyzsh_install.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
        chmod +x ${HOME}/ohmyzsh_install.sh
        sh ${HOME}/ohmyzsh_install.sh --unattended
    fi

    if [[ ! -d "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]] ;  then
        git clone "https://github.com/zsh-users/zsh-autosuggestions" "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"

        # 配置 zshrc 文件
        zshConfig=${HOME}/.zshrc
        zshTheme="maran"
        sed -i 's/ZSH_THEME=.*/ZSH_THEME="'"${zshTheme}"'"/' $zshConfig
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


        echo 'alias lla="ls -ahl"' >> ${HOME}/.zshrc
        echo 'alias mi="micro"' >> ${HOME}/.zshrc

        green " =================================================="
        yellow " oh-my-zsh 安装成功, 请用exit命令退出服务器后重新登陆即可!"
        green " =================================================="

    fi

}



# 网络测速

function vps_netflix(){
    # bash <(curl -sSL https://raw.githubusercontent.com/Netflixxp/NF/main/nf.sh)
    # bash <(curl -sSL "https://github.com/CoiaPrant/Netflix_Unlock_Information/raw/main/netflix.sh")
	# wget -N --no-check-certificate https://github.com/CoiaPrant/Netflix_Unlock_Information/raw/main/netflix.sh && chmod +x netflix.sh && ./netflix.sh

	wget -N --no-check-certificate -O ./netflix.sh https://github.com/CoiaPrant/MediaUnlock_Test/raw/main/check.sh && chmod +x ./netflix.sh && ./netflix.sh

    # wget -N -O nf https://github.com/sjlleo/netflix-verify/releases/download/2.01/nf_2.01_linux_amd64 && chmod +x nf && clear && ./nf
}


function vps_superspeed(){
	bash <(curl -Lso- https://git.io/superspeed)
	#wget -N --no-check-certificate https://raw.githubusercontent.com/ernisn/superspeed/master/superspeed.sh && chmod +x superspeed.sh && ./superspeed.sh
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




function installBBR(){
    wget -O tcp_old.sh -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp_old.sh && ./tcp_old.sh
}

function installBBR2(){
    
    if [[ -f ./tcp.sh ]];  then
        mv ./tcp.sh ./tcp_old.sh
    fi    
    wget -N --no-check-certificate "https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
}



function installWireguard(){
    bash <(wget -qO- https://github.com/jinwyp/one_click_script/raw/master/install_kernel.sh)
    # wget -N --no-check-certificate https://github.com/jinwyp/one_click_script/raw/master/install_kernel.sh && chmod +x ./install_kernel.sh && ./install_kernel.sh
}
























configNetworkRealIp=""
configNetworkLocalIp=""
configSSLDomain=""

configSSLAcmeScriptPath="${HOME}/.acme.sh"
configWebsiteFatherPath="${HOME}/website"
configSSLCertBakPath="${HOME}/sslbackup"
configSSLCertPath="${HOME}/website/cert"
configWebsitePath="${HOME}/website/html"
configTrojanWindowsCliPrefixPath=$(cat /dev/urandom | head -1 | md5sum | head -c 20)
configWebsiteDownloadPath="${configWebsitePath}/download/${configTrojanWindowsCliPrefixPath}"
configDownloadTempPath="${HOME}/temp"

configRanPath="${HOME}/ran"


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

promptInfoXrayInstall="V2ray"
promptInfoXrayVersion=""
promptInfoXrayName="v2ray"
isXray="no"

configV2rayWebSocketPath=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
configV2rayPort="$(($RANDOM + 10000))"
configV2rayVmesWSPort="$(($RANDOM + 10000))"
configV2rayVmessTCPPort="$(($RANDOM + 10000))"
configV2rayPortShowInfo=$configV2rayPort
configV2rayIsTlsShowInfo="tls"
configV2rayTrojanPort="$(($RANDOM + 10000))"

configV2rayPath="${HOME}/v2ray"
configV2rayAccessLogFilePath="${HOME}/v2ray-access.log"
configV2rayErrorLogFilePath="${HOME}/v2ray-error.log"
configV2rayProtocol="vmess"
configV2rayVlessMode=""
configReadme=${HOME}/readme_trojan_v2ray.txt


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

    if [[ $1 == "wgcf" ]] ; then
        versionWgcf=$(getGithubLatestReleaseVersion "ViRb3/wgcf")
        downloadFilenameWgcf="wgcf_${versionWgcf}_linux_amd64"
        echo "versionWgcf: ${versionWgcf}"
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
    echo
    echo
    green " 是否检测域名指向的IP正确 (默认检测，如果域名指向的IP不是本机器IP则无法继续. 如果已开启CDN不方便关闭可以选择否)"
    read -p "是否检测域名指向的IP正确? 请输入[Y/n]:" isDomainValidInput
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
	    green "  开始申请证书 acme.sh standalone mode !"
        echo

	    ${configSSLAcmeScriptPath}/acme.sh --issue --standalone -d ${configSSLDomain}  
        echo

        ${configSSLAcmeScriptPath}/acme.sh --installcert  -d ${configSSLDomain} \
        --key-file ${configSSLCertPath}/private.key \
        --fullchain-file ${configSSLCertPath}/fullchain.cer \
        --reloadcmd "systemctl restart nginx.service"

	else
        # https://github.com/m3ng9i/ran/issues/10

        mkdir -p ${configRanPath}
        
        if [[ -f "${configRanPath}/ran_linux_amd64" ]]; then
            nohup ${configRanPath}/ran_linux_amd64 -l=false -g=false -sa=true -p=80 -r=${configWebsitePath} >/dev/null 2>&1 &
        else

            downloadAndUnzip "https://github.com/m3ng9i/ran/releases/download/v0.1.5/ran_linux_amd64.zip" "${configRanPath}" "ran_linux_amd64.zip" 
            chmod +x ${configRanPath}/ran_linux_amd64
            nohup ${configRanPath}/ran_linux_amd64 -l=false -g=false -sa=true -p=80 -r=${configWebsitePath} >/dev/null 2>&1 &
        fi    


	    green "  开始申请证书 acme.sh webroot mode !"
        echo
        
        ${configSSLAcmeScriptPath}/acme.sh --issue -d ${configSSLDomain} --webroot ${configWebsitePath}
        echo

        ${configSSLAcmeScriptPath}/acme.sh --installcert -d ${configSSLDomain} \
        --key-file ${configSSLCertPath}/private.key \
        --fullchain-file ${configSSLCertPath}/fullchain.cer \
        --reloadcmd "systemctl restart nginx.service"

        sleep 4
        ps -C ran_linux_amd64 -o pid= | xargs -I {} kill {}
    fi

    green "=========================================="
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
    gzip  on;

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
    #gzip on;

    server {
        listen       80;
        server_name  $configSSLDomain;
        root $configWebsitePath;
        index index.php index.html index.htm;

        location /$configTrojanWebNginxPath {
            proxy_pass http://127.0.0.1:$configTrojanWebPort/;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Host \$http_host;
        }

        location ~* ^/(static|common|auth|trojan)/ {
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
    gzip  on;

    server {
        listen 443 ssl http2;
        listen [::]:443 http2;
        server_name  $configSSLDomain;

        ssl_certificate       ${configSSLCertPath}/fullchain.cer;
        ssl_certificate_key   ${configSSLCertPath}/private.key;
        ssl_protocols         TLSv1.2 TLSv1.3;
        ssl_ciphers           TLS-AES-256-GCM-SHA384:TLS-CHACHA20-POLY1305-SHA256:TLS-AES-128-GCM-SHA256:TLS-AES-128-CCM-8-SHA256:TLS-AES-128-CCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256;

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

    wget -P "${configWebsiteDownloadPath}" "https://github.com/jinwyp/one_click_script/raw/master/download/trojan-mac.zip"
    wget -P "${configWebsiteDownloadPath}" "https://github.com/jinwyp/one_click_script/raw/master/download/v2ray-windows.zip" 
    wget -P "${configWebsiteDownloadPath}" "https://github.com/jinwyp/one_click_script/raw/master/download/v2ray-mac.zip"

    # downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/trojan_client_all.zip" "${configWebsiteDownloadPath}" "trojan_client_all.zip"
    # downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/trojan-qt5.zip" "${configWebsiteDownloadPath}" "trojan-qt5.zip"
    # downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/v2ray_client_all.zip" "${configWebsiteDownloadPath}" "v2ray_client_all.zip"

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
	red "    nginx 配置路径 ${nginxConfigPath} "
	green "    nginx 访问日志 ${nginxAccessLogFilePath} "
	green "    nginx 错误日志 ${nginxErrorLogFilePath} "
    green "    nginx 查看日志命令: journalctl -n 50 -u nginx.service"
	green "    nginx 启动命令: systemctl start nginx.service  停止命令: systemctl stop nginx.service  重启命令: systemctl restart nginx.service"
	green "    nginx 查看运行状态命令: systemctl status nginx.service "

    green " ================================================== "

    cat >> ${configReadme} <<-EOF

Web服务器 nginx 安装成功! 伪装站点为 ${configSSLDomain}   
伪装站点的静态html内容放置在目录 ${configWebsitePath}, 可自行更换网站内容.
nginx 配置路径 ${nginxConfigPath}
nginx 访问日志 ${nginxAccessLogFilePath}
nginx 错误日志 ${nginxErrorLogFilePath}

nginx 查看日志命令: journalctl -n 50 -u nginx.service

nginx 启动命令: systemctl start nginx.service  
nginx 停止命令: systemctl stop nginx.service  
nginx 重启命令: systemctl restart nginx.service
nginx 查看运行状态命令: systemctl status nginx.service


EOF

	if [[ $1 == "trojan-web" ]] ; then
        cat >> ${configReadme} <<-EOF

安装的Trojan-web ${versionTrojanWeb} 可视化管理面板,访问地址  ${configSSLDomain}/${configTrojanWebNginxPath}
Trojan-web 停止命令: systemctl stop trojan-web.service  启动命令: systemctl start trojan-web.service  重启命令: systemctl restart trojan-web.service

EOF
	fi

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
        apt-get remove --purge nginx nginx-full nginx-common nginx-core
    fi



    mkdir -p ${configSSLCertBakPath}
    cp -f ${configSSLCertPath}/* ${configSSLCertBakPath}

    rm -rf ${configWebsiteFatherPath}
    rm -f ${nginxAccessLogFilePath}
    rm -f ${nginxErrorLogFilePath}

    rm -f ${configReadme}

    rm -rf "/etc/nginx"
    ${sudoCmd} bash ${configSSLAcmeScriptPath}/acme.sh --uninstall
    uninstall ${configSSLAcmeScriptPath}
    rm -rf ${configDownloadTempPath}

    green " ================================================== "
    green "  Nginx 卸载完毕 !"
    green " ================================================== "
}


function installTrojanV2rayWithNginx(){

    stopServiceNginx
    testLinuxPortUsage
    installPackage

    green " ================================================== "
    yellow " 请输入绑定到本VPS的域名 例如www.xxx.com: (此步骤请关闭CDN后安装)"
    if [[ $1 == "repair" ]] ; then
        blue " 务必与之前安装失败时使用的域名一致"
    fi
    green " ================================================== "

    read configSSLDomain

    echo
    echo

    green "是否申请证书? 默认为自动申请证书, 如果二次安装或已有证书 可以选否"
    green "如果已经有SSL证书文件请放到下面路径"
    red " ${configSSLDomain} 域名证书内容文件路径 ${configSSLCertPath}/fullchain.cer "
    red " ${configSSLDomain} 域名证书私钥文件路径 ${configSSLCertPath}/private.key "
    echo
    read -p "是否申请证书? 默认为自动申请证书,如果二次安装或已有证书可以选否 请输入[Y/n]:" isDomainSSLRequestInput
    isDomainSSLRequestInput=${isDomainSSLRequestInput:-Y}


    if compareRealIpWithLocalIp "${configSSLDomain}" ; then
        if [[ $isDomainSSLRequestInput == [Yy] ]]; then

            getHTTPSCertificate 
        else
            green " =================================================="
            green "   不申请域名的证书, 请把证书放到如下目录, 或自行修改trojan或v2ray配置!"
            green " ${configSSLDomain} 域名证书内容文件路径 ${configSSLCertPath}/fullchain.cer "
            green " ${configSSLDomain} 域名证书私钥文件路径 ${configSSLCertPath}/private.key "
            green " =================================================="
        fi


        if test -s ${configSSLCertPath}/fullchain.cer; then
            green " ================================================== "
            green "     SSL证书已检测到获取成功!"
            green " ================================================== "

            if [ "$isNginxWithSSL" = "no" ] ; then
                installWebServerNginx
            else
                installWebServerNginx "v2ray"
            fi

            if [ -z $1 ]; then
                installTrojanServer
            elif [ $1 = "both" ]; then
                installTrojanServer
                installV2ray
            else
                installV2ray
            fi
        else
            red "==================================="
            red " https证书没有申请成功，安装失败!"
            red " 请检查域名和DNS是否生效, 同一域名请不要一天内多次申请!"
            red " 请检查80和443端口是否开启, VPS服务商可能需要添加额外防火墙规则，例如阿里云、谷歌云等!"
            red " 重启VPS, 重新执行脚本, 可重新选择该项再次申请证书 ! "
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
        "${configTrojanPasswordPrefixInput}202001",
        "${configTrojanPasswordPrefixInput}202002",
        "${configTrojanPasswordPrefixInput}202003",
        "${configTrojanPasswordPrefixInput}202004",
        "${configTrojanPasswordPrefixInput}202005",
        "${configTrojanPasswordPrefixInput}202006",
        "${configTrojanPasswordPrefixInput}202007",
        "${configTrojanPasswordPrefixInput}202008",
        "${configTrojanPasswordPrefixInput}202009",
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

        # rm /etc/systemd/system/trojan.service   
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
        "${configTrojanPasswordPrefixInput}202001",
        "${configTrojanPasswordPrefixInput}202002",
        "${configTrojanPasswordPrefixInput}202003",
        "${configTrojanPasswordPrefixInput}202004",
        "${configTrojanPasswordPrefixInput}202005",
        "${configTrojanPasswordPrefixInput}202006",
        "${configTrojanPasswordPrefixInput}202007",
        "${configTrojanPasswordPrefixInput}202008",
        "${configTrojanPasswordPrefixInput}202009",
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
        "curves": "",
        "cipher": "",        
	    "prefer_server_cipher": false,
        "sni": "${configSSLDomain}",
        "alpn": [
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": true,
        "plain_http_response": "",
        "fallback_addr": "127.0.0.1",
        "fallback_port": 80,    
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

    ${sudoCmd} chmod +x ${osSystemMdPath}trojan${promptInfoTrojanName}.service
    ${sudoCmd} systemctl daemon-reload
    ${sudoCmd} systemctl start trojan${promptInfoTrojanName}.service
    ${sudoCmd} systemctl enable trojan${promptInfoTrojanName}.service


    if [ "$configV2rayVlessMode" != "trojan" ] ; then
        
    
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

    fi



    # 设置 cron 定时任务
    # https://stackoverflow.com/questions/610839/how-can-i-programmatically-create-a-new-cron-job

    # (crontab -l 2>/dev/null | grep -v '^[a-zA-Z]'; echo "15 4 * * 0,1,2,3,4,5,6 systemctl restart trojan.service") | sort - | uniq - | crontab -
    (crontab -l ; echo "10 4 * * 0,1,2,3,4,5,6 systemctl restart trojan${promptInfoTrojanName}.service") | sort - | uniq - | crontab -


	green "======================================================================"
	green "    Trojan${promptInfoTrojanName} Version: ${configTrojanBaseVersion} 安装成功 !"

    if [[ ${isInstallNginx} == "true" ]]; then
        green "    伪装站点为 https://${configSSLDomain}"
	    green "    伪装站点的静态html内容放置在目录 ${configWebsitePath}, 可自行更换网站内容!"
    fi

	red "    Trojan${promptInfoTrojanName} 服务器端配置路径 ${configTrojanBasePath}/server.json "
	red "    Trojan${promptInfoTrojanName} 运行日志文件路径: ${configTrojanLogFile} "
	green "    Trojan${promptInfoTrojanName} 查看日志命令: journalctl -n 50 -u trojan${promptInfoTrojanName}.service "

	green "    Trojan${promptInfoTrojanName} 停止命令: systemctl stop trojan${promptInfoTrojanName}.service  启动命令: systemctl start trojan${promptInfoTrojanName}.service  重启命令: systemctl restart trojan${promptInfoTrojanName}.service"
	green "    Trojan${promptInfoTrojanName} 查看运行状态命令:  systemctl status trojan${promptInfoTrojanName}.service "
	green "    Trojan${promptInfoTrojanName} 服务器 每天会自动重启, 防止内存泄漏. 运行 crontab -l 命令 查看定时重启命令 !"
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
	yellow "您指定前缀的密码共99个: 从 ${configTrojanPasswordPrefixInput}202000 到 ${configTrojanPasswordPrefixInput}202099 都可以使用"
	yellow "例如: 密码:${configTrojanPasswordPrefixInput}202011 或 密码:${configTrojanPasswordPrefixInput}202088 都可以使用"

    if [[ ${isTrojanGoSupportWebsocket} == "true" ]]; then
        yellow "Websocket path 路径为: /${configTrojanGoWebSocketPath}"
        # yellow "Websocket obfuscation_password 混淆密码为: ${trojanPasswordWS}"
        yellow "Websocket 双重TLS为: true 开启"
    fi

    echo
    green "======================================================================"
    yellow " Trojan${promptInfoTrojanName} 小火箭 Shadowrocket 链接地址"

    if [ "$isTrojanGo" = "yes" ] ; then
        if [[ ${isTrojanGoSupportWebsocket} == "true" ]]; then
            green " trojan://${trojanPassword1}@${configSSLDomain}:${configV2rayTrojanPort}?peer=${configSSLDomain}&sni=${configSSLDomain}&plugin=obfs-local;obfs=websocket;obfs-host=${configSSLDomain};obfs-uri=/${configTrojanGoWebSocketPath}#${configSSLDomain}_trojan_go_ws"
            echo
            yellow " 二维码 Trojan${promptInfoTrojanName} "
		    green "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=trojan%3a%2f%2f${trojanPassword1}%40${configSSLDomain}%3a${configV2rayTrojanPort}%3fallowInsecure%3d0%26peer%3d${configSSLDomain}%26plugin%3dobfs-local%3bobfs%3dwebsocket%3bobfs-host%3d${configSSLDomain}%3bobfs-uri%3d/${configTrojanGoWebSocketPath}%23${configSSLDomain}_trojan_go_ws"

            echo
            yellow " Trojan${promptInfoTrojanName} QV2ray 链接地址"
            green " trojan-go://${trojanPassword1}@${configSSLDomain}:${configV2rayTrojanPort}?sni=${configSSLDomain}&type=ws&host=${configSSLDomain}&path=%2F${configTrojanGoWebSocketPath}#${configSSLDomain}_trojan_go_ws"
        
        else
            green " trojan://${trojanPassword1}@${configSSLDomain}:${configV2rayTrojanPort}?peer=${configSSLDomain}&sni=${configSSLDomain}#${configSSLDomain}_trojan_go"
            echo
            yellow " 二维码 Trojan${promptInfoTrojanName} "
            green "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=trojan%3a%2f%2f${trojanPassword1}%40${configSSLDomain}%3a${configV2rayTrojanPort}%3fpeer%3d${configSSLDomain}%26sni%3d${configSSLDomain}%23${configSSLDomain}_trojan_go"

            echo
            yellow " Trojan${promptInfoTrojanName} QV2ray 链接地址"
            green " trojan-go://${trojanPassword1}@${configSSLDomain}:${configV2rayTrojanPort}?sni=${configSSLDomain}&type=original&host=${configSSLDomain}#${configSSLDomain}_trojan_go"
        fi

    else
        green " trojan://${trojanPassword1}@${configSSLDomain}:${configV2rayTrojanPort}?peer=${configSSLDomain}&sni=${configSSLDomain}#${configSSLDomain}_trojan"
        echo
        yellow " 二维码 Trojan${promptInfoTrojanName} "
		green "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=trojan%3a%2f%2f${trojanPassword1}%40${configSSLDomain}%3a${configV2rayTrojanPort}%3fpeer%3d${configSSLDomain}%26sni%3d${configSSLDomain}%23${configSSLDomain}_trojan"

    fi

	echo
	green "======================================================================"
	green "请下载相应的trojan客户端:"
	yellow "1 Windows 客户端下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/v2ray-windows.zip"
	#yellow "  Windows 客户端另一个版本下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/trojan-Qt5-windows.zip"
	yellow "  Windows 客户端命令行版本下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/trojan-win-cli.zip"
	yellow "  Windows 客户端命令行版本需要搭配浏览器插件使用，例如switchyomega等! "
    yellow "2 MacOS 客户端下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/v2ray-mac.zip"
    yellow "  MacOS 另一个客户端下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/trojan-mac.zip"
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

Trojan${promptInfoTrojanName} 运行日志文件路径: ${configTrojanLogFile} 
Trojan${promptInfoTrojanName} 查看日志命令: journalctl -n 50 -u trojan${promptInfoTrojanName}.service

Trojan${promptInfoTrojanName} 启动命令: systemctl start trojan${promptInfoTrojanName}.service
Trojan${promptInfoTrojanName} 停止命令: systemctl stop trojan${promptInfoTrojanName}.service  
Trojan${promptInfoTrojanName} 重启命令: systemctl restart trojan${promptInfoTrojanName}.service
Trojan${promptInfoTrojanName} 查看运行状态命令: systemctl status trojan${promptInfoTrojanName}.service

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
您指定前缀的密码共99个: 从 ${configTrojanPasswordPrefixInput}202000 到 ${configTrojanPasswordPrefixInput}202099 都可以使用
例如: 密码:${configTrojanPasswordPrefixInput}202011 或 密码:${configTrojanPasswordPrefixInput}202088 都可以使用

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






















function inputV2rayServerPort(){ 
	echo 
    echo
	if [[ $1 == "textMainPort" ]]; then
        read -p "是否自定义${promptInfoXrayName}的端口号? 直接回车默认为${configV2rayPortShowInfo}, 请输入自定义端口号[1-65535]:" isV2rayUserPortInput
        isV2rayUserPortInput=${isV2rayUserPortInput:-${configV2rayPortShowInfo}}
		checkPortInUse "${isV2rayUserPortInput}" $1 
	fi

	if [[ $1 == "textAdditionalPort" ]]; then
        green " 是否添加一个额外监听端口, 与主端口${configV2rayPort}一起同时工作"
        green " 一般用于 中转机无法使用443端口中转给目标主机时使用"
        read -p "是否给${promptInfoXrayName}添加额外的监听端口? 直接回车默认否, 请输入额外端口号[1-65535]:" isV2rayAdditionalPortInput
        isV2rayAdditionalPortInput=${isV2rayAdditionalPortInput:-999999}
        checkPortInUse "${isV2rayAdditionalPortInput}" $1 
	fi
}

function checkPortInUse(){ 
    if [ $1 = "999999" ]; then
        echo
    elif [[ $1 -gt 1 && $1 -le 65535 ]]; then
            
        netstat -tulpn | grep [0-9]:$1 -q ; 
        if [ $? -eq 1 ]; then 
            green "输入的端口号 $1 没有被占用, 继续安装..."  
            
        else 
            red "输入的端口号 $1 已被占用! 请退出安装, 检查端口是否已被占用 或 重新输入!" 
            inputV2rayServerPort $2 
        fi
    else
        red "输入的端口号错误! 必须是[1-65535]. 请重新输入" 
        inputV2rayServerPort $2 
    fi
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

    echo
    if [ -f "${configV2rayPath}/xray" ] || [ -f "${configV2rayPath}/v2ray" ] || [ -f "/usr/local/bin/v2ray" ] || [ -f "/usr/bin/v2ray" ]; then
        green " =================================================="
        green "     已安装过 V2ray 或 Xray, 退出安装 !"
        green " =================================================="
        exit
    fi

    green " =================================================="
    green "    开始安装 V2ray or Xray "
    green " =================================================="    
    echo


    if [[ ( $configV2rayVlessMode == "trojan" ) || ( $configV2rayVlessMode == "vlessxtlsonly" ) || ( $configV2rayVlessMode == "vlessxtlstrojan" ) ]] ; then
        promptInfoXrayName="xray"
        isXray="yes"
    else
        read -p "是否使用Xray内核? 直接回车默认为V2ray内核, 请输入[y/N]:" isV2rayOrXrayInput
        isV2rayOrXrayInput=${isV2rayOrXrayInput:-n}

        if [[ $isV2rayOrXrayInput == [Yy] ]]; then
            promptInfoXrayName="xray"
            isXray="yes"
        fi
    fi


    if [[ -n "$configV2rayVlessMode" ]]; then
         configV2rayProtocol="vless"
    else 

        read -p "是否使用VLESS协议? 直接回车默认为VMess协议, 请输入[y/N]:" isV2rayUseVLessInput
        isV2rayUseVLessInput=${isV2rayUseVLessInput:-n}

        if [[ $isV2rayUseVLessInput == [Yy] ]]; then
            configV2rayProtocol="vless"
        else
            configV2rayProtocol="vmess"
        fi

    fi

    echo
    green " =================================================="
    echo
    yellow " 是否使用 IPv6 解锁流媒体和避免弹出 Google reCAPTCHA 人机验证, 请选择:"
    red " 解锁需要先安装好 Wireguard 与 Cloudflare Warp, 可用本脚本第一项安装"
    echo
    green " 1. 不解锁"
    green " 2. 避免弹出 Google reCAPTCHA 人机验证"
    green " 3. 解锁 Netflex 限制"
    green " 4. 解锁 Youtube 和 Youtube Premium"
    green " 5. 解锁 全部流媒体 包括 Netflex, Youtube, Hulu, HBO, Disney, BBC, Fox, niconico 等"
    green " 11. 同时解锁 2 和 3 项,  即为 避免弹出 Google reCAPTCHA 人机验证 和 解锁 Netflex 限制"
    green " 12. 同时解锁 2 和 3 和 4 项, 即为 避免弹出 Google reCAPTCHA 人机验证 和 解锁 Netflex 和 Youtube 限制"
    green " 13. 同时解锁 全部流媒体 和 避免弹出 Google reCAPTCHA 人机验证"
    echo
    read -p "请输入解锁选项? 直接回车默认选1 不解锁, 请输入纯数字:" isV2rayUnlockGoogleInput
    isV2rayUnlockGoogleInput=${isV2rayUnlockGoogleInput:-1}

    V2rayUnlockText=""

    if [[ $isV2rayUnlockGoogleInput == "2" ]]; then
        V2rayUnlockText="\"geosite:google\""

    elif [[ $isV2rayUnlockGoogleInput == "3" ]]; then
        V2rayUnlockText="\"geosite:netflix\""
        
    elif [[ $isV2rayUnlockGoogleInput == "4" ]]; then
        V2rayUnlockText="\"geosite:youtube\""

    elif [[ $isV2rayUnlockGoogleInput == "5" ]]; then
        V2rayUnlockText="\"geosite:netflix\", \"geosite:youtube\", \"geosite:bahamut\", \"geosite:hulu\", \"geosite:hbo\", \"geosite:disney\", \"geosite:bbc\", \"geosite:4chan\", \"geosite:fox\", \"geosite:abema\", \"geosite:dmm\", \"geosite:niconico\", \"geosite:pixiv\", \"geosite:viu\""

    elif [[ $isV2rayUnlockGoogleInput == "11" ]]; then
        V2rayUnlockText="\"geosite:google\", \"geosite:netflix\""

    elif [[ $isV2rayUnlockGoogleInput == "12" ]]; then
        V2rayUnlockText="\"geosite:google\", \"geosite:netflix\", \"geosite:youtube\""

    elif [[ $isV2rayUnlockGoogleInput == "13" ]]; then
        V2rayUnlockText="\"geosite:google\", \"geosite:netflix\", \"geosite:youtube\", \"geosite:bahamut\", \"geosite:hulu\", \"geosite:hbo\", \"geosite:disney\", \"geosite:bbc\", \"geosite:4chan\", \"geosite:fox\", \"geosite:abema\", \"geosite:dmm\", \"geosite:niconico\", \"geosite:pixiv\", \"geosite:viu\""
    else
        V2rayUnlockText=""
    fi


					

    read -p "是否自定义${promptInfoXrayName}的密码? 直接回车默认创建随机密码, 请输入自定义UUID密码:" isV2rayUserPassordInput
    isV2rayUserPassordInput=${isV2rayUserPassordInput:-''}

    if [[ -z $isV2rayUserPassordInput ]]; then
        echo
    else
        v2rayPassword1=${isV2rayUserPassordInput}
    fi



    # 增加自定义端口号
    if [[ ${isInstallNginx} == "true" ]]; then
        configV2rayPortShowInfo=443
        
        if [[ $configV2rayVlessMode == "vlessxtlstrojan" ]]; then
            configV2rayPort=443
        fi
    else
        configV2rayPort="$(($RANDOM + 10000))"
        
        if [[ -n "$configV2rayVlessMode" ]]; then
            configV2rayPort=443
        fi
        configV2rayPortShowInfo=$configV2rayPort

        inputV2rayServerPort "textMainPort"

        configV2rayPort=${isV2rayUserPortInput}   
        configV2rayPortShowInfo=${isV2rayUserPortInput}   



        configV2rayWebSocketPath=$(cat /dev/urandom | head -1 | md5sum | head -c 8)

        read -p "是否自定义${promptInfoXrayName}的WS的Path? 直接回车默认创建随机路径, 请输入自定义路径(不要输入/):" isV2rayUserWSPathInput
        isV2rayUserWSPathInput=${isV2rayUserWSPathInput:-${configV2rayWebSocketPath}}

        if [[ -z $isV2rayUserWSPathInput ]]; then
            echo
        else
            configV2rayWebSocketPath=${isV2rayUserWSPathInput}
        fi


        
        
        inputV2rayServerPort "textAdditionalPort"

        if [[ $isV2rayAdditionalPortInput == "999999" ]]; then
            v2rayConfigAdditionalPortInput=""
        else
            
            read -r -d '' v2rayConfigAdditionalPortInput << EOM
        ,
        {
            "listen": "0.0.0.0",
            "port": ${isV2rayAdditionalPortInput}, 
            "protocol": "dokodemo-door",
            "settings": {
                "address": "127.0.0.1",
                "port": ${configV2rayPort},
                "network": "tcp, udp",
                "followRedirect": false 
            },
            "sniffing": {
            "enabled": true,
            "destOverride": ["http", "tls"]
            }
        }     
     
EOM

        fi

    fi




    
    if [ "$isXray" = "no" ] ; then
        getTrojanAndV2rayVersion "v2ray"
        green "    准备下载并安装 V2ray Version: ${versionV2ray} !"
        promptInfoXrayInstall="V2ray"
        promptInfoXrayVersion=${versionV2ray}
    else
        getTrojanAndV2rayVersion "xray"
        green "    准备下载并安装 Xray Version: ${versionXray} !"
        promptInfoXrayInstall="Xray"
        promptInfoXrayVersion=${versionXray}
    fi
    echo


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

    read -r -d '' v2rayConfigUserpasswordTrojanInput << EOM
                    {
                        "password": "${trojanPassword1}",
                        "level": 0,
                        "email": "password111@gmail.com"
                    },
                    {
                        "password": "${trojanPassword2}",
                        "level": 0,
                        "email": "password112@gmail.com"
                    },
                    {
                        "password": "${trojanPassword3}",
                        "level": 0,
                        "email": "password113@gmail.com"
                    },
                    {
                        "password": "${trojanPassword4}",
                        "level": 0,
                        "email": "password114@gmail.com"
                    },
                    {
                        "password": "${trojanPassword5}",
                        "level": 0,
                        "email": "password115@gmail.com"
                    },
                    {
                        "password": "${trojanPassword6}",
                        "level": 0,
                        "email": "password116@gmail.com"
                    },
                    {
                        "password": "${trojanPassword7}",
                        "level": 0,
                        "email": "password117@gmail.com"
                    },
                    {
                        "password": "${trojanPassword8}",
                        "level": 0,
                        "email": "password118@gmail.com"
                    },
                    {
                        "password": "${trojanPassword9}",
                        "level": 0,
                        "email": "password119@gmail.com"
                    },
                    {
                        "password": "${trojanPassword10}",
                        "level": 0,
                        "email": "password120@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202000",
                        "level": 0,
                        "email": "password200@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202001",
                        "level": 0,
                        "email": "password201@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202002",
                        "level": 0,
                        "email": "password202@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202003",
                        "level": 0,
                        "email": "password203@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202004",
                        "level": 0,
                        "email": "password204@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202005",
                        "level": 0,
                        "email": "password205@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202006",
                        "level": 0,
                        "email": "password206@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202007",
                        "level": 0,
                        "email": "password207@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202008",
                        "level": 0,
                        "email": "password208@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202009",
                        "level": 0,
                        "email": "password209@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202010",
                        "level": 0,
                        "email": "password210@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202011",
                        "level": 0,
                        "email": "password211@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202012",
                        "level": 0,
                        "email": "password212@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202013",
                        "level": 0,
                        "email": "password213@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202014",
                        "level": 0,
                        "email": "password214@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202015",
                        "level": 0,
                        "email": "password215@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202016",
                        "level": 0,
                        "email": "password216@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202017",
                        "level": 0,
                        "email": "password217@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202018",
                        "level": 0,
                        "email": "password218@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202019",
                        "level": 0,
                        "email": "password219@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202020",
                        "level": 0,
                        "email": "password220@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202021",
                        "level": 0,
                        "email": "password221@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202022",
                        "level": 0,
                        "email": "password222@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202023",
                        "level": 0,
                        "email": "password223@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202024",
                        "level": 0,
                        "email": "password224@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202025",
                        "level": 0,
                        "email": "password225@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202026",
                        "level": 0,
                        "email": "password226@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202027",
                        "level": 0,
                        "email": "password227@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202028",
                        "level": 0,
                        "email": "password228@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202029",
                        "level": 0,
                        "email": "password229@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202030",
                        "level": 0,
                        "email": "password230@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202031",
                        "level": 0,
                        "email": "password231@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202032",
                        "level": 0,
                        "email": "password232@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202033",
                        "level": 0,
                        "email": "password233@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202034",
                        "level": 0,
                        "email": "password234@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202035",
                        "level": 0,
                        "email": "password235@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202036",
                        "level": 0,
                        "email": "password236@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202037",
                        "level": 0,
                        "email": "password237@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202038",
                        "level": 0,
                        "email": "password238@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202039",
                        "level": 0,
                        "email": "password239@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202040",
                        "level": 0,
                        "email": "password240@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202041",
                        "level": 0,
                        "email": "password241@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202042",
                        "level": 0,
                        "email": "password242@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202043",
                        "level": 0,
                        "email": "password243@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202044",
                        "level": 0,
                        "email": "password244@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202045",
                        "level": 0,
                        "email": "password245@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202046",
                        "level": 0,
                        "email": "password246@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202047",
                        "level": 0,
                        "email": "password247@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202048",
                        "level": 0,
                        "email": "password248@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202049",
                        "level": 0,
                        "email": "password249@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202050",
                        "level": 0,
                        "email": "password250@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202051",
                        "level": 0,
                        "email": "password251@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202052",
                        "level": 0,
                        "email": "password252@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202053",
                        "level": 0,
                        "email": "password253@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202054",
                        "level": 0,
                        "email": "password254@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202055",
                        "level": 0,
                        "email": "password255@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202056",
                        "level": 0,
                        "email": "password256@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202057",
                        "level": 0,
                        "email": "password257@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202058",
                        "level": 0,
                        "email": "password258@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202059",
                        "level": 0,
                        "email": "password259@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202060",
                        "level": 0,
                        "email": "password260@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202061",
                        "level": 0,
                        "email": "password261@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202062",
                        "level": 0,
                        "email": "password262@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202063",
                        "level": 0,
                        "email": "password263@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202064",
                        "level": 0,
                        "email": "password264@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202065",
                        "level": 0,
                        "email": "password265@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202066",
                        "level": 0,
                        "email": "password266@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202067",
                        "level": 0,
                        "email": "password267@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202068",
                        "level": 0,
                        "email": "password268@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202069",
                        "level": 0,
                        "email": "password269@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202070",
                        "level": 0,
                        "email": "password270@gmail.com"
                    }                                       
EOM


    read -r -d '' v2rayConfigUserpasswordInput << EOM
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

    read -r -d '' v2rayConfigUserpasswordDirectInput << EOM
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
EOM


    if [[ $isV2rayUnlockGoogleInput == "1" ]]; then

        read -r -d '' v2rayConfigOutboundInput << EOM
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
EOM

    else

        read -r -d '' v2rayConfigOutboundInput << EOM
    "outbounds": [
        {
            "tag":"IP4_out",
            "protocol": "freedom",
            "settings": {}
        },
        {
            "tag":"IP6_out",
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv6" 
            }
        }
    ],    
    "routing": {
        "rules": [
            {
                "type": "field",
                "outboundTag": "IP6_out",
                "domain": [${V2rayUnlockText}] 
            },
            {
                "type": "field",
                "outboundTag": "IP4_out",
                "network": "udp,tcp"
            }
        ]
    }
EOM
        
    fi




    read -r -d '' v2rayConfigLogInput << EOM
    "log" : {
        "access": "${configV2rayAccessLogFilePath}",
        "error": "${configV2rayErrorLogFilePath}",
        "loglevel": "warning"
    },
EOM




    if [[ -z "$configV2rayVlessMode" ]]; then
        cat > ${configV2rayPath}/config.json <<-EOF
{
    ${v2rayConfigLogInput}
    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
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
        ${v2rayConfigAdditionalPortInput}
    ],
    ${v2rayConfigOutboundInput}
}
EOF
    fi


    if [[ "$configV2rayVlessMode" == "vlessws" ]]; then
        cat > ${configV2rayPath}/config.json <<-EOF
{
    ${v2rayConfigLogInput}
    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": 80
                    },
                    {
                        "path": "/${configV2rayWebSocketPath}",
                        "dest": ${configV2rayVmesWSPort},
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
            "port": ${configV2rayVmesWSPort},
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
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
        ${v2rayConfigAdditionalPortInput}
    ],
    ${v2rayConfigOutboundInput}
}
EOF
    fi


    if [[ "$configV2rayVlessMode" == "vmessws" ]]; then
        cat > ${configV2rayPath}/config.json <<-EOF
{
    ${v2rayConfigLogInput}
    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": 80
                    },
                    {
                        "path": "/${configV2rayWebSocketPath}",
                        "dest": ${configV2rayVmesWSPort},
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
            "port": ${configV2rayVmesWSPort},
            "listen": "127.0.0.1",
            "protocol": "vmess",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
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
                    ${v2rayConfigUserpasswordInput}
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
        ${v2rayConfigAdditionalPortInput}
    ],
    ${v2rayConfigOutboundInput}
}
EOF
    fi



    if [[  $configV2rayVlessMode == "vlessxtlstrojan" ]]; then
            cat > ${configV2rayPath}/config.json <<-EOF
{
    ${v2rayConfigLogInput}
    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordDirectInput}
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": ${configV2rayTrojanPort},
                        "xver": 1
                    },
                    {
                        "path": "/${configV2rayWebSocketPath}",
                        "dest": ${configV2rayVmesWSPort},
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
            "port": ${configV2rayTrojanPort},
            "listen": "127.0.0.1",
            "protocol": "trojan",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordTrojanInput}
                ],
                "fallbacks": [
                    {
                        "dest": 80 
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "none",
                "tcpSettings": {
                    "acceptProxyProtocol": true
                }
            }
        },
        {
            "port": ${configV2rayVmesWSPort},
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
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
        ${v2rayConfigAdditionalPortInput}
    ],
    ${v2rayConfigOutboundInput}
}
EOF
    fi


    if [[  $configV2rayVlessMode == "vlessxtlsonly" ]]; then
            cat > ${configV2rayPath}/config.json <<-EOF
{
    ${v2rayConfigLogInput}
    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordDirectInput}
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": 80
                    },
                    {
                        "path": "/${configV2rayWebSocketPath}",
                        "dest": ${configV2rayVmesWSPort},
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
            "port": ${configV2rayVmesWSPort},
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
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
        ${v2rayConfigAdditionalPortInput}
    ],
    ${v2rayConfigOutboundInput}
}
EOF
    fi


    if [[ $configV2rayVlessMode == "trojan" ]]; then

            cat > ${configV2rayPath}/config.json <<-EOF
{
    ${v2rayConfigLogInput}
    "inbounds": [
        {
            "port": ${configV2rayPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordDirectInput}
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": ${configV2rayTrojanPort},
                        "xver": 1
                    },
                    {
                        "path": "/${configTrojanGoWebSocketPath}",
                        "dest": ${configV2rayTrojanPort},
                        "xver": 1
                    },
                    {
                        "path": "/${configV2rayWebSocketPath}",
                        "dest": ${configV2rayVmesWSPort},
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
            "port": ${configV2rayVmesWSPort},
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
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
        ${v2rayConfigAdditionalPortInput}
    ],
    ${v2rayConfigOutboundInput}
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
    
    ${sudoCmd} systemctl enable ${promptInfoXrayName}.service
    ${sudoCmd} systemctl restart ${promptInfoXrayName}.service



    # 增加客户端配置说明
    if [[ ${isInstallNginx} != "true" ]]; then
        if [[ -z "$configV2rayVlessMode" ]]; then
                        
            configV2rayIsTlsShowInfo="none"
        fi
    fi






    cat > ${configV2rayPath}/clientConfig.json <<-EOF
=========== ${promptInfoXrayInstall}客户端配置参数 =============
{
    协议: ${configV2rayProtocol},
    地址: ${configSSLDomain},
    端口: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    加密方式: aes-128-gcm,  // 如果是Vless协议则为none
    传输协议: websocket,
    websocket路径:/${configV2rayWebSocketPath},
    底层传输协议:${configV2rayIsTlsShowInfo},
    别名:自己起个任意名称
}
EOF



    if [[ "$configV2rayVlessMode" == "vmessws" ]]; then

    cat > ${configV2rayPath}/clientConfig.json <<-EOF
当选择了17. 只安装v2ray VLess运行在443端口 (VLess-TCP-TLS) + (VMess-TCP-TLS) + (VMess-WS-TLS)  支持CDN, 不安装nginx
=========== ${promptInfoXrayInstall}客户端 VLess-TCP-TLS 配置参数 =============
{
    协议: VLess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    加密方式: none,  // 如果是Vless协议则为none
    传输协议: tcp ,
    websocket路径:无,
    底层传输:tls,
    别名:自己起个任意名称
}

=========== ${promptInfoXrayInstall}客户端 VMess-WS-TLS 配置参数 支持CDN =============
{
    协议: VMess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    加密方式: none,  // 如果是Vless协议则为none
    传输协议: websocket,
    websocket路径:/${configV2rayWebSocketPath},
    底层传输:tls,
    别名:自己起个任意名称
}

=========== ${promptInfoXrayInstall}客户端 VMess-TCP-TLS 配置参数 支持CDN =============
{
    协议: VMess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
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


    if [[ "$configV2rayVlessMode" == "vlessws" ]]; then

    cat > ${configV2rayPath}/clientConfig.json <<-EOF
当选择了16. 只安装v2ray VLess运行在443端口 (VLess-TCP-TLS) + (VLess-WS-TLS) 支持CDN, 不安装nginx
=========== ${promptInfoXrayInstall}客户端 VLess-TCP-TLS 配置参数 =============
{
    协议: VLess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    流控flow:  // 选择了16 为空
    加密方式: none,  // 如果是Vless协议则为none
    传输协议: tcp ,
    websocket路径:无,
    底层传输协议:tls,   
    别名:自己起个任意名称
}

=========== ${promptInfoXrayInstall}客户端 VLess-WS-TLS 配置参数 支持CDN =============
{
    协议: VLess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    流控flow:  // 选择了16 为空
    加密方式: none,  // 如果是Vless协议则为none
    传输协议: websocket,
    websocket路径:/${configV2rayWebSocketPath},
    底层传输:tls,     
    别名:自己起个任意名称
}
EOF
    fi


    if [[ "$configV2rayVlessMode" == "vlessxtlsonly" ]] || [[ "$configV2rayVlessMode" == "trojan" ]]; then
    cat > ${configV2rayPath}/clientConfig.json <<-EOF
=========== ${promptInfoXrayInstall}客户端 VLess-TCP-TLS 配置参数 =============
{
    协议: VLess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    流控flow: xtls-rprx-direct
    加密方式: none,  // 如果是Vless协议则为none
    传输协议: tcp ,
    websocket路径:无,
    底层传输协议:xtls, 
    别名:自己起个任意名称
}

=========== ${promptInfoXrayInstall}客户端 VLess-WS-TLS 配置参数 支持CDN =============
{
    协议: VLess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    流控flow: xtls-rprx-direct // 选择了16 为空, 选择了20-23 为 xtls-rprx-direct
    加密方式: none,  // 如果是Vless协议则为none
    传输协议: websocket,
    websocket路径:/${configV2rayWebSocketPath},
    底层传输:tls,     
    别名:自己起个任意名称
}
EOF
    fi

    if [[ "$configV2rayVlessMode" == "vlessxtlstrojan" ]]; then
    cat > ${configV2rayPath}/clientConfig.json <<-EOF
=========== ${promptInfoXrayInstall}客户端 VLess-TCP-TLS 配置参数 =============
{
    协议: VLess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    流控flow: xtls-rprx-direct
    加密方式: none,  
    传输协议: tcp ,
    websocket路径:无,
    底层传输协议:xtls, 
    别名:自己起个任意名称
}

=========== ${promptInfoXrayInstall}客户端 VLess-WS-TLS 配置参数 支持CDN =============
{
    协议: VLess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    流控flow: xtls-rprx-direct // 选择了16 为空, 选择了20-23 为 xtls-rprx-direct
    加密方式: none,  
    传输协议: websocket,
    websocket路径:/${configV2rayWebSocketPath},
    底层传输:tls,     
    别名:自己起个任意名称
}


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
您指定前缀的密码若干: 从 ${configTrojanPasswordPrefixInput}202000 到 ${configTrojanPasswordPrefixInput}202070 都可以使用

EOF
    fi



    # 设置 cron 定时任务
    # https://stackoverflow.com/questions/610839/how-can-i-programmatically-create-a-new-cron-job

    (crontab -l ; echo "20 4 * * 0,1,2,3,4,5,6 systemctl restart ${promptInfoXrayName}.service") | sort - | uniq - | crontab -


    green "======================================================================"
    green "    ${promptInfoXrayInstall} Version: ${promptInfoXrayVersion} 安装成功 !"

    if [[ ${isInstallNginx} == "true" ]]; then
        green "    伪装站点为 https://${configSSLDomain}!"
	    green "    伪装站点的静态html内容放置在目录 ${configWebsitePath}, 可自行更换网站内容!"
    fi
	
	red "    ${promptInfoXrayInstall} 服务器端配置路径 ${configV2rayPath}/config.json !"
	green "    ${promptInfoXrayInstall} 访问日志 ${configV2rayAccessLogFilePath} !"
	green "    ${promptInfoXrayInstall} 错误日志 ${configV2rayErrorLogFilePath} ! "
	green "    ${promptInfoXrayInstall} 查看日志命令: journalctl -n 50 -u ${promptInfoXrayName}.service "
	green "    ${promptInfoXrayInstall} 停止命令: systemctl stop ${promptInfoXrayName}.service  启动命令: systemctl start ${promptInfoXrayName}.service  重启命令: systemctl restart ${promptInfoXrayName}.service"
	green "    ${promptInfoXrayInstall} 查看运行状态命令:  systemctl status ${promptInfoXrayName}.service "
	green "    ${promptInfoXrayInstall} 服务器 每天会自动重启, 防止内存泄漏. 运行 crontab -l 命令 查看定时重启命令 !"
	green "======================================================================"
	echo ""
	yellow "${promptInfoXrayInstall} 配置信息如下, 请自行复制保存, 密码任选其一 (密码即用户ID或UUID) !!"
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




${promptInfoXrayInstall} Version: ${promptInfoXrayVersion} 安装成功 ! 
${promptInfoXrayInstall} 服务器端配置路径 ${configV2rayPath}/config.json 

${promptInfoXrayInstall} 访问日志 ${configV2rayAccessLogFilePath}
${promptInfoXrayInstall} 错误日志 ${configV2rayErrorLogFilePath}

${promptInfoXrayInstall} 查看日志命令: journalctl -n 50 -u ${promptInfoXrayName}.service

${promptInfoXrayInstall} 启动命令: systemctl start ${promptInfoXrayName}.service  
${promptInfoXrayInstall} 停止命令: systemctl stop ${promptInfoXrayName}.service  
${promptInfoXrayInstall} 重启命令: systemctl restart ${promptInfoXrayName}.service
${promptInfoXrayInstall} 查看运行状态命令:  systemctl status ${promptInfoXrayName}.service 

${promptInfoXrayInstall} 配置信息如下, 请自行复制保存, 密码任选其一 (密码即用户ID或UUID) !

服务器地址: ${configSSLDomain}  
端口: ${configV2rayPortShowInfo}
用户ID或密码1: ${v2rayPassword1}
用户ID或密码2: ${v2rayPassword2}
用户ID或密码3: ${v2rayPassword3}
用户ID或密码4: ${v2rayPassword4}
用户ID或密码5: ${v2rayPassword5}
用户ID或密码6: ${v2rayPassword6}
用户ID或密码7: ${v2rayPassword7}
用户ID或密码8: ${v2rayPassword8}
用户ID或密码9: ${v2rayPassword9}
用户ID或密码10: ${v2rayPassword10}



EOF

    cat "${configV2rayPath}/clientConfig.json" >> ${configReadme}
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

    ${sudoCmd} chmod +x ${configV2rayPath}/${promptInfoXrayName}
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
    installPackage

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
        ${sudoCmd} systemctl enable trojan-web.service
        ${sudoCmd} systemctl start trojan-web.service

        green " =================================================="
        green " Trojan-web 可视化管理面板: ${versionTrojanWeb} 安装成功!"
        green " Trojan可视化管理面板地址 https://${configSSLDomain}/${configTrojanWebNginxPath}"
        green " 开始运行命令 ${configTrojanWebPath}/trojan-web 进行初始化设置."
        green " =================================================="



        ${configTrojanWebPath}/trojan-web

        installWebServerNginx "trojan-web"

        # 命令补全环境变量
        echo "export PATH=$PATH:${configTrojanWebPath}" >> ${HOME}/.${osSystemShell}rc

        # (crontab -l ; echo '25 0 * * * "${configSSLAcmeScriptPath}"/acme.sh --cron --home "${configSSLAcmeScriptPath}" > /dev/null') | sort - | uniq - | crontab -
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
    

    # 移除trojan
    rm -rf /usr/bin/trojan
    rm -rf /usr/local/etc/trojan
    rm -f ${osSystemMdPath}trojan.service
    rm -f /etc/systemd/system/trojan.service
    rm -f /usr/local/etc/trojan/config.json


    # 移除trojan web 管理程序 
    # rm -f /usr/local/bin/trojan
    rm -rf ${configTrojanWebPath}
    rm -f ${osSystemMdPath}trojan-web.service
    rm -rf /var/lib/trojan-manager

    ${sudoCmd} systemctl daemon-reload


    # 移除trojan的专用数据库
    docker rm -f trojan-mysql
    docker rm -f trojan-mariadb
    rm -rf /home/mysql
    rm -rf /home/mariadb


    # 移除环境变量
    sed -i '/trojan/d' ${HOME}/.${osSystemShell}rc
    # source ${HOME}/.${osSystemShell}rc

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
    installPackage

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

    installPackage

    green " ================================================== "
    yellow " 请输入绑定到本VPS的域名 例如www.xxx.com: (此步骤请关闭CDN后和nginx后安装 避免80端口占用导致申请证书失败)"
    green " ================================================== "

    read configSSLDomain

    read -p "是否申请证书? 默认为自动申请证书,如果二次安装或已有证书可以选否 请输入[Y/n]:" isDomainSSLRequestInput
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
                red " 重启VPS, 重新执行脚本, 可重新选择该项再次申请证书 ! "
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

    elif [[ $1 == "both" ]] ; then
        installV2ray
        installTrojanServer
    else
        installV2ray
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
    red " 安装上面2个可视化管理面板 之前不能用本脚本或其他脚本安装过trojan或v2ray! 2个管理面板也无法同时安装"

    green " =================================================="
    green " 11. 单独申请域名SSL证书"
    green " 12. 只安装trojan 运行在443端口, 不安装nginx, 请确保443端口没有被nginx占用"
    green " 13. 只安装trojan-go 运行在443端口, 不支持CDN, 不开启websocket, 不安装nginx. 请确保80端口有监听,否则trojan-go无法启动"
    green " 14. 只安装trojan-go 运行在443端口, 支持CDN, 开启websocket, 不安装nginx. 请确保80端口有监听,否则trojan-go无法启动"    
    echo
    green " 15. 只安装V2ray或Xray (VLess或VMess协议) 开启websocket, 支持CDN, (VLess/VMess+WS) 不安装nginx,无TLS加密,方便与现有网站或宝塔面板集成"
    green " 16. 只安装V2ray VLess运行在443端口 (VLess-TCP-TLS) + (VLess-WS-TLS) 支持CDN, 不安装nginx"
    green " 17. 只安装V2ray VLess运行在443端口 (VLess-TCP-TLS) + (VMess-TCP-TLS) + (VMess-WS-TLS) 支持CDN, 不安装nginx"
    echo
    green " 20. 只安装Xray VLess运行在443端口 (VLess-TCP-XTLS direct) + (VLess-WS-TLS), 不安装nginx" 
    green " 21. 只安装Xray VLess运行在443端口 (VLess-TCP-XTLS direct) + (VLess-WS-TLS) + trojan, 支持VLess的CDN, 不安装nginx"    
    green " 22. 只安装Xray VLess运行在443端口 (VLess-TCP-XTLS direct) + (VLess-WS-TLS) + trojan-go, 支持VLess的CDN, 不安装nginx"   
    green " 23. 只安装Xray VLess运行在443端口 (VLess-TCP-XTLS direct) + (VLess-WS-TLS) + trojan-go, 支持VLess的CDN和trojan-go的CDN, 不安装nginx"   
    green " 24. 只安装Xray VLess运行在443端口 (VLess-TCP-XTLS direct) + (VLess-WS-TLS) + xray自带的trojan, 支持VLess的CDN, 不安装nginx"    

    red " 27. 卸载 trojan"    
    red " 28. 卸载 trojan-go"   
    red " 29. 卸载 v2ray或Xray"   
    green " =================================================="

    echo
    red " 以下是 VPS 测网速工具, 脚本测速会消耗大量 VPS 流量，请悉知！"
    green " 31. 测试VPS 是否支持Netflix, 检测IP解锁范围及对应所在的地区"
    echo
    green " 32. superspeed 三网纯测速 （全国各地三大运营商部分节点全面测速）"
    green " 33. 由teddysun 编写的Bench 综合测试 （包含系统信息 IO 测试 多处数据中心的节点测试 ）"
	green " 34. testrace 回程路由测试 （四网路由测试）"
	green " 35. LemonBench 快速全方位测试 （包含CPU内存性能、回程、速度）"
    green " 36. ZBench 综合网速测试 （包含节点测速, Ping 以及 路由测试）"
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
            configV2rayVlessMode="vlessxtlsonly"
            getHTTPSNoNgix "v2ray"
        ;; 
        21 )
            configV2rayVlessMode="trojan"
            getHTTPSNoNgix "both"
        ;;
        22 )
            configV2rayVlessMode="trojan"
            isTrojanGo="yes"
            getHTTPSNoNgix "both"
        ;;    
        23 )
            configV2rayVlessMode="trojan"
            isTrojanGo="yes"
            isTrojanGoSupportWebsocket="true"
            getHTTPSNoNgix "both"
        ;;
        24 )
            configV2rayVlessMode="vlessxtlstrojan"
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
            installPackage
            vps_netflix
        ;;                                                         
        32 )
            vps_superspeed
        ;;
        33 )
            vps_bench
        ;;        
        34 )
            vps_testrace
        ;;
        35 )
            vps_LemonBench
        ;;
        36 )
            vps_zbench
        ;;        
        41 )
            installBBR
        ;;
        42 )
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
        getLinuxOSRelease
        installSoftDownload
    fi

    green " ===================================================================================================="
    green " Trojan Trojan-go V2ray 一键安装脚本 | 2021-04-15 | By jinwyp | 系统支持：centos7+ / debian9+ / ubuntu16.04+"
    red " *请不要在任何生产环境使用此脚本 请不要有其他程序占用80和443端口"
    green " ===================================================================================================="
    green " 1. 安装 linux 内核 BBR Plus, 安装 WireGuard, 用于解锁 Netflix 限制 和避免弹出 Google reCAPTCHA 人机验证"
    echo
    green " 2. 安装 trojan 和 nginx 不支持CDN, trojan 运行在443端口"
    green " 3. 升级 trojan 到最新版本"
    red " 4. 卸载 trojan 与 nginx"
    echo
    green " 5. 安装 trojan-go 和 nginx 不支持CDN, 不开启websocket (兼容trojan客户端), trojan-go 运行在443端口"
    green " 6. 安装 trojan-go 和 nginx 支持CDN 开启websocket (兼容trojan客户端但不兼容websocket), trojan-go 运行在443端口"
    green " 7. 升级 trojan-go 到最新版本"
    red " 8. 卸载 trojan-go 与 nginx"
    echo
    green " 11. 安装 v2ray或xray 和 nginx, 支持 websocket tls1.3, 支持CDN, nginx 运行在443端口"
    green " 12. 安装 xray 和 nginx, (VLess-TCP-XTLS direct) + (VLess-WS-TLS) + xray自带的trojan, 支持CDN, xray 运行在443端口"  
    green " 13. 升级 v2ray或xray 到最新版本"
    red " 14. 卸载v2ray或xray 和 nginx"
    echo
    green " 21. 同时安装 trojan + v2ray或xray 和 nginx, 不支持CDN, trojan 运行在443端口"
    green " 22. 升级 v2ray或xray 和 trojan 到最新版本"
    red " 23. 卸载 trojan, v2ray或xray 和 nginx"
    echo
    green " 24. 同时安装 trojan-go + v2ray或xray 和 nginx, trojan-go不支持CDN, v2ray或xray 支持CDN, trojan-go 运行在443端口"
    green " 25. 同时安装 trojan-go + v2ray或xray 和 nginx, trojan-go 和 v2ray 都支持CDN, trojan-go 运行在443端口"
    green " 26. 升级 v2ray或xray 和 trojan-go 到最新版本"
    red " 27. 卸载 trojan-go, v2ray或xray 和 nginx"
    echo
    green " 28. 查看已安装的配置和用户密码等信息"
    green " 29. 子菜单 安装 trojan 和 v2ray 可视化管理面板, 测网速工具, Netflix 测试工具"
    green " 30. 不安装nginx, 只安装trojan或v2ray或xray, 可选安装SSL证书, 方便与现有网站或宝塔面板集成"
    green " =================================================="
    green " 31. 安装OhMyZsh与插件zsh-autosuggestions, Micro编辑器 等软件"
    green " 32. 开启root用户SSH登陆, 如谷歌云默认关闭root登录,可以通过此项开启"
    green " 33. 修改SSH 登陆端口号"
    green " 34. 设置时区为北京时间"
    green " 35. 用 VI 编辑 authorized_keys 文件, 方便填入公钥, 免密码登录, 增加安全性"
    green " 88. 升级脚本"
    green " 0. 退出脚本"
    echo
    read -p "请输入数字:" menuNumberInput
    case "$menuNumberInput" in
        1 )
            installWireguard
        ;;
        2 )
            installTrojanV2rayWithNginx
        ;;
        3 )
            upgradeTrojan
        ;;
        4 )
            removeNginx
            removeTrojan
        ;;
        5 )
            isTrojanGo="yes"
            installTrojanV2rayWithNginx
        ;;
        6 )
            isTrojanGo="yes"
            isTrojanGoSupportWebsocket="true"
            installTrojanV2rayWithNginx
        ;;
        7 )
            isTrojanGo="yes"
            upgradeTrojan
        ;;
        8 )
            isTrojanGo="yes"
            removeNginx
            removeTrojan
        ;;
        11 )
            isNginxWithSSL="yes"
            installTrojanV2rayWithNginx "v2ray"
        ;;
        12 )
            configV2rayVlessMode="vlessxtlstrojan"
            installTrojanV2rayWithNginx "v2ray"
        ;;        
        13 )
            upgradeV2ray
        ;;
        14 )
            removeNginx
            removeV2ray
        ;;
        21 )
            installTrojanV2rayWithNginx "both"
        ;;
        22 )
            upgradeTrojan
            upgradeV2ray
        ;;
        23 )
            removeNginx
            removeTrojan
            removeV2ray
        ;;
        24 )
            isTrojanGo="yes"
            installTrojanV2rayWithNginx "both"
        ;;
        25 )
            isTrojanGo="yes"
            isTrojanGoSupportWebsocket="true"
            installTrojanV2rayWithNginx "both"
        ;;
        26 )
            isTrojanGo="yes"
            upgradeTrojan
            upgradeV2ray
        ;;
        27 )
            isTrojanGo="yes"
            removeNginx
            removeTrojan
            removeV2ray
        ;;
        28 )
            cat "${configReadme}"
        ;;        
        31 )
            setLinuxDateZone
            installPackage
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
        35 )
            editLinuxLoginWithPublicKey
        ;;                 
        29 )
            startMenuOther
        ;;
        30 )
            startMenuOther
        ;;        
        81 )
            installBBR
        ;;
        82 )
            installBBR2
        ;;        
        83 )
            installPackage
        ;;
        88 )
            upgradeScript
        ;;
        99 )
            getTrojanAndV2rayVersion "trojan"
            getTrojanAndV2rayVersion "trojan-go"
            getTrojanAndV2rayVersion "trojan-web"
            getTrojanAndV2rayVersion "v2ray"
            getTrojanAndV2rayVersion "xray"
            getTrojanAndV2rayVersion "wgcf"
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

