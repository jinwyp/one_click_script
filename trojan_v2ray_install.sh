#!/bin/bash

export LC_ALL=C
#export LANG=C
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8


sudoCmd=""
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCmd="sudo"
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




osCPU=""
osArchitecture="arm"
osInfo=""
osRelease=""
osReleaseVersion=""
osReleaseVersionNo=""
osReleaseVersionNoShort=""
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
		aarch64)    dpkg --print-architecture | grep -q "arm64" && osArchitecture="arm64" || osArchitecture="arm" ;;
		* )     osArchitecture="arm" ;;
	esac
}


function checkCPU(){
	osCPUText=$(cat /proc/cpuinfo | grep vendor_id | uniq)
	if [[ $osCPUText =~ "GenuineIntel" ]]; then
		osCPU="intel"
    elif [[ $osCPUText =~ "AMD" ]]; then
        osCPU="amd"
    else
        echo
    fi

	# green " Status 状态显示--当前CPU是: $osCPU"
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

    osReleaseVersionNoShort=$(echo $osReleaseVersionNo | sed 's/\..*//')
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




function promptContinueOpeartion(){
	read -p "是否继续操作? 直接回车默认继续操作, 请输入[Y/n]:" isContinueInput
	isContinueInput=${isContinueInput:-Y}

	if [[ $isContinueInput == [Yy] ]]; then
		echo ""
	else 
		exit 1
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
        red "检测到80端口被占用，占用进程为：${process80} "
        red "==========================================================="
        promptContinueOpeartion
    fi

    if [ -n "$osPort443" ]; then
        process443=`netstat -tlpn | awk -F '[: ]+' '$5=="443"{print $9}'`
        red "============================================================="
        red "检测到443端口被占用，占用进程为：${process443} "
        red "============================================================="
        promptContinueOpeartion
    fi

    osSELINUXCheck=$(grep SELINUX= /etc/selinux/config | grep -v "#")
    if [ "$osSELINUXCheck" == "SELINUX=enforcing" ]; then
        red "======================================================================="
        red "检测到SELinux为开启强制模式状态, 为防止申请证书失败 将关闭SELinux. 请先重启VPS后，再执行本脚本"
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
        red "检测到SELinux为宽容模式状态, 为防止申请证书失败, 将关闭SELinux. 请先重启VPS后，再执行本脚本"
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
        if  [[ ${osReleaseVersionNoShort} == "6" || ${osReleaseVersionNoShort} == "5" ]]; then
            green " =================================================="
            red " 本脚本不支持 Centos 6 或 Centos 6 更早的版本"
            green " =================================================="
            exit
        fi

        red " 关闭防火墙 firewalld"
        ${sudoCmd} systemctl stop firewalld
        ${sudoCmd} systemctl disable firewalld

    elif [ "$osRelease" == "ubuntu" ]; then
        if  [[ ${osReleaseVersionNoShort} == "14" || ${osReleaseVersionNoShort} == "12" ]]; then
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

            if  [[ ${osReleaseVersionNoShort} == "7" ]]; then
                yum -y install policycoreutils-python
            elif  [[ ${osReleaseVersionNoShort} == "8" ]]; then
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


# 设置北京时区
function setLinuxDateZone(){

    tempCurrentDateZone=$(date +'%z')

    echo
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
    echo

    if [ "$osRelease" == "centos" ]; then   
        if  [[ ${osReleaseVersionNoShort} == "7" ]]; then
            $osSystemPackage -y install ntpdate
            ntpdate -q 0.rhel.pool.ntp.org
            systemctl enable ntpd
            systemctl restart ntpd
            ntpdate -u  pool.ntp.org

        elif  [[ ${osReleaseVersionNoShort} == "8" ]]; then
            $osSystemPackage -y install chrony
            systemctl enable chronyd
            systemctl restart chronyd

            firewall-cmd --permanent --add-service=ntp
            firewall-cmd --reload    

            chronyc sources

            echo
        fi
        
    else
        $osSystemPackage install -y ntp
        systemctl enable ntp
        systemctl restart ntp
    fi    
}








# 软件安装
function installSoftDownload(){
	if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
		if ! dpkg -l | grep -qw wget; then
			${osSystemPackage} -y install wget git unzip
			
			# https://stackoverflow.com/questions/11116704/check-if-vt-x-is-activated-without-having-to-reboot-in-linux
			${osSystemPackage} -y install cpu-checker
		fi

		if ! dpkg -l | grep -qw curl; then
			${osSystemPackage} -y install curl git unzip
			
			${osSystemPackage} -y install cpu-checker
		fi

	elif [[ "${osRelease}" == "centos" ]]; then
        if ! rpm -qa | grep -qw wget; then
		    ${osSystemPackage} -y install wget curl git unzip
        elif ! rpm -qa | grep -qw git; then
		    ${osSystemPackage} -y install wget curl git unzip
		fi
	fi 
}


function installPackage(){
    echo
    green " =================================================="
    yellow " 开始安装软件"
    green " =================================================="
    echo

    if [ "$osRelease" == "centos" ]; then
       
        # rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm

        cat > "/etc/yum.repos.d/nginx.repo" <<-EOF
[nginx]
name=nginx repo
baseurl=https://nginx.org/packages/centos/$osReleaseVersionNoShort/\$basearch/
gpgcheck=0
enabled=1
sslverify=0

EOF
        if ! rpm -qa | grep -qw iperf3; then
			${sudoCmd} ${osSystemPackage} install -y epel-release

            ${osSystemPackage} install -y curl wget git unzip zip tar bind-utils
            ${osSystemPackage} install -y xz jq redhat-lsb-core 
            ${osSystemPackage} install -y iputils
            ${osSystemPackage} install -y iperf3
		fi

        ${osSystemPackage} update -y


        # https://www.cyberciti.biz/faq/how-to-install-and-use-nginx-on-centos-8/
        if  [[ ${osReleaseVersionNoShort} == "8" ]]; then
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
deb [arch=amd64] https://nginx.org/packages/ubuntu/ $osReleaseVersionCodeName nginx
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
deb [arch=amd64] http://nginx.org/packages/debian/ $osReleaseVersionCodeName nginx
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

    echo
    green " =================================================="
    yellow " 开始安装 ZSH"
    green " =================================================="
    echo

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
        yellow " 开始安装 oh-my-zsh"
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
            red "chsh command unsuccessful. Change your default shell manually."
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








# 更新本脚本
function upgradeScript(){
    wget -Nq --no-check-certificate -O ./trojan_v2ray_install.sh "https://raw.githubusercontent.com/jinwyp/one_click_script/master/trojan_v2ray_install.sh"
    green " 本脚本升级成功! "
    chmod +x ./trojan_v2ray_install.sh
    sleep 2s
    exec "./trojan_v2ray_install.sh"
}

function installWireguard(){
    bash <(wget -qO- https://github.com/jinwyp/one_click_script/raw/master/install_kernel.sh)
    # wget -N --no-check-certificate https://github.com/jinwyp/one_click_script/raw/master/install_kernel.sh && chmod +x ./install_kernel.sh && ./install_kernel.sh
}







# 网络测速

function vps_netflix(){
    # bash <(curl -sSL https://raw.githubusercontent.com/Netflixxp/NF/main/nf.sh)
    # bash <(curl -sSL "https://github.com/CoiaPrant/Netflix_Unlock_Information/raw/main/netflix.sh")
    # bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh)

	# wget -N --no-check-certificate https://github.com/CoiaPrant/Netflix_Unlock_Information/raw/main/netflix.sh && chmod +x netflix.sh && ./netflix.sh
    # wget -N --no-check-certificate -O netflixcheck https://github.com/sjlleo/netflix-verify/releases/download/2.61/nf_2.61_linux_amd64 && chmod +x ./netflixcheck && ./netflixcheck -method full

	wget -N --no-check-certificate -O ./netflix.sh https://github.com/CoiaPrant/MediaUnlock_Test/raw/main/check.sh && chmod +x ./netflix.sh && ./netflix.sh
}

function vps_netflix2(){
	wget -N --no-check-certificate -O ./netflix.sh https://github.com/lmc999/RegionRestrictionCheck/raw/main/check.sh && chmod +x ./netflix.sh && ./netflix.sh
}

function vps_netflix_jin(){
    # wget -qN --no-check-certificate -O ./nf.sh https://raw.githubusercontent.com/jinwyp/SimpleNetflix/dev/nf.sh && chmod +x ./nf.sh
	wget -qN --no-check-certificate -O ./nf.sh https://raw.githubusercontent.com/jinwyp/one_click_script/master/netflix_check.sh && chmod +x ./nf.sh && ./nf.sh
}


function vps_netflixgo(){
    wget -qN --no-check-certificate -O netflixGo https://github.com/sjlleo/netflix-verify/releases/download/2.61/nf_2.61_linux_amd64 && chmod +x ./netflixGo && ./netflixGo -method full
    echo
    echo
    wget -qN --no-check-certificate -O disneyplusGo https://github.com/sjlleo/VerifyDisneyPlus/releases/download/1.01/dp_1.01_linux_amd64 && chmod +x ./disneyplusGo && ./disneyplusGo
}


function vps_superspeed(){
	bash <(curl -Lso- https://git.io/superspeed.sh)
    #wget -N --no-check-certificate https://raw.githubusercontent.com/flyzy2005/superspeed/master/superspeed.sh && chmod +x superspeed.sh && ./superspeed.sh
    #wget -N --no-check-certificate https://raw.githubusercontent.com/zq/superspeed/master/superspeed.sh && chmod +x superspeed.sh && ./superspeed.sh

    # bash <(curl -Lso- https://git.io/superspeed)
	#wget -N --no-check-certificate https://raw.githubusercontent.com/ernisn/superspeed/master/superspeed.sh && chmod +x superspeed.sh && ./superspeed.sh
	
	#wget -N --no-check-certificate https://raw.githubusercontent.com/oooldking/script/master/superspeed.sh && chmod +x superspeed.sh && ./superspeed.sh
}

function vps_yabs(){
	curl -sL yabs.sh | bash
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
    wget -N --no-check-certificate -O LemonBench.sh https://ilemonra.in/LemonBenchIntl && chmod +x LemonBench.sh && ./LemonBench.sh fast
}

function vps_autoBestTrace(){
    wget -N --no-check-certificate -O autoBestTrace.sh https://raw.githubusercontent.com/zq/shell/master/autoBestTrace.sh && chmod +x autoBestTrace.sh && ./autoBestTrace.sh
}




function installBBR(){
    wget -N --no-check-certificate -O tcp_old.sh "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp_old.sh && ./tcp_old.sh
}

function installBBR2(){
    wget -N --no-check-certificate "https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
}





function installBTPanel(){
    if [ "$osRelease" == "centos" ]; then
        yum install -y wget && wget -O install.sh http://download.bt.cn/install/install_6.0.sh && sh install.sh
    else
        # curl -sSO http://download.bt.cn/install/install_panel.sh && bash install_panel.sh
        wget -O install.sh http://download.bt.cn/install/install-ubuntu_6.0.sh && sudo bash install.sh

    fi
}

function installBTPanelCrack(){
    if [ "$osRelease" == "centos" ]; then
        yum install -y wget && wget -O install.sh https://download.fenhao.me/install/install_6.0.sh && sh install.sh
    else
        wget -O install.sh https://download.fenhao.me/install/install-ubuntu_6.0.sh && sudo bash install.sh
    fi
}

function installBTPanelCrack2(){
    if [ "$osRelease" == "centos" ]; then
        yum install -y wget && wget -O install.sh http://v7.hostcli.com/install/install_6.0.sh && sh install.sh
    else
        wget -O install.sh http://v7.hostcli.com/install/install-ubuntu_6.0.sh && sudo bash install.sh
    fi
}









































configNetworkRealIp=""
configNetworkLocalIp=""
configSSLDomain=""




configWebsiteFatherPath="${HOME}/website"
configWebsitePath="${HOME}/website/html"

configTrojanWindowsCliPrefixPath=$(cat /dev/urandom | head -1 | md5sum | head -c 20)
configWebsiteDownloadPath="${configWebsitePath}/download/${configTrojanWindowsCliPrefixPath}"
configDownloadTempPath="${HOME}/temp"



versionTrojan="1.16.0"
downloadFilenameTrojan="trojan-${versionTrojan}-linux-amd64.tar.xz"

versionTrojanGo="0.10.5"
downloadFilenameTrojanGo="trojan-go-linux-amd64.zip"

versionV2ray="4.44.0"
downloadFilenameV2ray="v2ray-linux-64.zip"

versionXray="1.5.2"
downloadFilenameXray="Xray-linux-64.zip"

versionTrojanWeb="2.10.5"
downloadFilenameTrojanWeb="trojan-linux-amd64"

isTrojanMultiPassword="no"
promptInfoTrojanName=""
isTrojanGo="yes"
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

configInstallNginxMode=""
nginxConfigPath="/etc/nginx/nginx.conf"
nginxAccessLogFilePath="${HOME}/nginx-access.log"
nginxErrorLogFilePath="${HOME}/nginx-error.log"

promptInfoXrayInstall="V2ray"
promptInfoXrayVersion=""
promptInfoXrayName="v2ray"
promptInfoXrayNameServiceName=""
isXray="no"

configV2rayWebSocketPath=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
configV2rayGRPCServiceName=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
configV2rayPort="$(($RANDOM + 10000))"
configV2rayGRPCPort="$(($RANDOM + 10000))"
configV2rayVmesWSPort="$(($RANDOM + 10000))"
configV2rayVmessTCPPort="$(($RANDOM + 10000))"
configV2rayPortShowInfo=$configV2rayPort
configV2rayPortGRPCShowInfo=$configV2rayGRPCPort
configV2rayIsTlsShowInfo="tls"
configV2rayTrojanPort="$(($RANDOM + 10000))"

configV2rayPath="${HOME}/v2ray"
configV2rayAccessLogFilePath="${HOME}/v2ray-access.log"
configV2rayErrorLogFilePath="${HOME}/v2ray-error.log"
configV2rayVmessImportLinkFile1Path="${configV2rayPath}/vmess_link1.json"
configV2rayVmessImportLinkFile2Path="${configV2rayPath}/vmess_link2.json"
configV2rayVlessImportLinkFile1Path="${configV2rayPath}/vless_link1.json"
configV2rayVlessImportLinkFile2Path="${configV2rayPath}/vless_link2.json"

configV2rayProtocol="vmess"
configV2rayWorkingMode=""
configV2rayWorkingNotChangeMode=""
configV2rayStreamSetting=""


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

    echo ""

    if [[ $1 == "trojan" ]] ; then
        versionTrojan=$(getGithubLatestReleaseVersion "trojan-gfw/trojan")
        downloadFilenameTrojan="trojan-${versionTrojan}-linux-amd64.tar.xz"
        echo "versionTrojan: ${versionTrojan}"
    fi

    if [[ $1 == "trojan-go" ]] ; then
        versionTrojanGo=$(getGithubLatestReleaseVersion "p4gefau1t/trojan-go")
        echo "versionTrojanGo: ${versionTrojanGo}"  
    fi

    if [[ $1 == "v2ray" ]] ; then
        # versionV2ray=$(getGithubLatestReleaseVersion "v2fly/v2ray-core")
        echo "versionV2ray: ${versionV2ray}"
    fi

    if [[ $1 == "xray" ]] ; then
        versionXray=$(getGithubLatestReleaseVersion "XTLS/Xray-core")
        echo "versionXray: ${versionXray}"
    fi

    if [[ $1 == "trojan-web" ]] ; then
        versionTrojanWeb=$(getGithubLatestReleaseVersion "Jrohy/trojan")
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









function compareRealIpWithLocalIp(){
    echo
    green " 是否检测域名指向的IP正确 直接回车默认检测"
    red " 如果域名指向的IP不是本机IP, 或已开启CDN不方便关闭 或只有IPv6的VPS 可以选否不检测"
    read -p "是否检测域名指向的IP正确? 请输入[Y/n]:" isDomainValidInput
    isDomainValidInput=${isDomainValidInput:-Y}

    if [[ $isDomainValidInput == [Yy] ]]; then
        if [ -n $1 ]; then
            configNetworkRealIp=`ping $1 -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
            # https://unix.stackexchange.com/questions/22615/how-can-i-get-my-external-ip-address-in-a-shell-script
            configNetworkLocalIp1="$(curl http://whatismyip.akamai.com/)"
            configNetworkLocalIp2="$(curl https://checkip.amazonaws.com/)"
            #configNetworkLocalIp3="$(curl https://ipv4.icanhazip.com/)"
            #configNetworkLocalIp4="$(curl https://v4.ident.me/)"
            #configNetworkLocalIp5="$(curl https://api.ip.sb/ip)"
            #configNetworkLocalIp6="$(curl https://ipinfo.io/ip)"
            

            #configNetworkLocalIPv61="$(curl https://ipv6.icanhazip.com/)"
            #configNetworkLocalIPv62="$(curl https://v6.ident.me/)"


            green " ================================================== "
            green " 域名解析地址为 ${configNetworkRealIp}, 本VPS的IP为 ${configNetworkLocalIp1} "

            echo
            if [[ ${configNetworkRealIp} == ${configNetworkLocalIp1} || ${configNetworkRealIp} == ${configNetworkLocalIp2} ]] ; then

                green " 域名解析的IP正常!"
                green " ================================================== "
                true
            else
                red " 域名解析地址与本VPS的IP地址不一致!"
                red " 本次安装失败，请确保域名解析正常, 请检查域名和DNS是否生效!"
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


acmeSSLRegisterEmailInput=""
function getHTTPSCertificateCheckEmail(){
    if [ -z ${acmeSSLRegisterEmailInput} ]; then
        red " 请输入邮箱地址不能为空, 请重新输入!"
        getHTTPSCertificateInputEmail
    fi
}
function getHTTPSCertificateInputEmail(){
    echo
    read -p "请输入邮箱地址, 用于申请证书:" acmeSSLRegisterEmailInput
    getHTTPSCertificateCheckEmail
}


acmeSSLDays="89"
acmeSSLServerName="letsencrypt"
acmeSSLDNSProvider="dns_cf"

configRanPath="${HOME}/ran"
configSSLAcmeScriptPath="${HOME}/.acme.sh"
configSSLCertPath="${HOME}/website/cert"

configSSLCertKeyFilename="private.key"
configSSLCertFullchainFilename="fullchain.cer"


function getHTTPSCertificateWithAcme(){

    # 申请https证书
	mkdir -p ${configSSLCertPath}
	mkdir -p ${configWebsitePath}
	curl https://get.acme.sh | sh


    echo
    green " ================================================== "
    green " 请选择证书提供商, 默认通过 Letsencrypt.org 来申请证书 "
    green " 如果证书申请失败, 例如一天内通过 Letsencrypt.org 申请次数过多, 可选 BuyPass.com 或 ZeroSSL.com 来申请."
    green " 1 Letsencrypt.org "
    green " 2 BuyPass.com "
    green " 3 ZeroSSL.com "
    echo
    read -p "请选择证书提供商? 默认直接回车为通过 Letsencrypt.org 申请, 请输入纯数字:" isDomainSSLFromLetInput
    isDomainSSLFromLetInput=${isDomainSSLFromLetInput:-1}
    
    
    if [[ "$isDomainSSLFromLetInput" == "2" ]]; then
        getHTTPSCertificateInputEmail
        acmeSSLDays="179"
        acmeSSLServerName="buypass"
        echo
        ${configSSLAcmeScriptPath}/acme.sh --register-account --accountemail ${acmeSSLRegisterEmailInput} --server buypass
        
    elif [[ "$isDomainSSLFromLetInput" == "3" ]]; then
        getHTTPSCertificateInputEmail
        acmeSSLServerName="zerossl"
        echo
        ${configSSLAcmeScriptPath}/acme.sh --register-account -m ${acmeSSLRegisterEmailInput} --server zerossl
    else
        acmeSSLServerName="letsencrypt"
        #${configSSLAcmeScriptPath}/acme.sh --issue -d ${configSSLDomain} --webroot ${configWebsitePath} --keylength ec-256 --days 89 --server letsencrypt
    fi

    echo
    green " ================================================== "
    green " 请选择 acme.sh 脚本申请SSL证书方式: 1 http方式, 2 dns方式 "
    green " 默认直接回车为 http 申请方式, 选否则为 dns 方式"
    echo
    read -r -p "请选择SSL证书申请方式 ? 默认直接回车为http方式, 选否则为 dns 方式申请证书, 请输入[Y/n]:" isAcmeSSLRequestMethodInput
    isAcmeSSLRequestMethodInput=${isAcmeSSLRequestMethodInput:-Y}

    echo

    if [[ $isAcmeSSLRequestMethodInput == [Yy] ]]; then
        acmeSSLHttpWebrootMode=""

        if [ -z $1 ]; then
            green " ================================================== "
            green " 请选择 http 申请证书方式: 默认为 3. webroot 并使用 ran 作为临时的Web服务器 "
            green " 1 standalone 模式, 适合没有安装Web服务器, 请确保80端口不被占用. 注意:三个月后续签时80端口被占用会导致续签失败!"
            green " 2 webroot 模式, 适合已经安装Web服务器, 例如 Caddy Apache 或 Nginx, 请确保Web服务器已经运行在80端口"
            green " 3 webroot 模式 并使用 ran 作为临时的Web服务器, 推荐使用此方式, 可以正常续签"
            green " 4 nginx 模式 适合已经安装 Nginx, 请确保 Nginx 已经运行"
            echo
            read -p "请选择http申请证书方式? 默认回车为 3 webroot 并用ran作为临时的Web服务器申请, 请输入纯数字:" isAcmeSSLWebrootModeInput
            isAcmeSSLWebrootModeInput=${isAcmeSSLWebrootModeInput:-3}
            
            if [[ ${isAcmeSSLWebrootModeInput} == "1" ]]; then
                acmeSSLHttpWebrootMode="standalone"
            elif [[ ${isAcmeSSLWebrootModeInput} == "2" ]]; then
                acmeSSLHttpWebrootMode="webroot"
            elif [[ ${isAcmeSSLWebrootModeInput} == "4" ]]; then
                acmeSSLHttpWebrootMode="nginx"
            else
                acmeSSLHttpWebrootMode="webrootran"
            fi
        else
            if [[ $1 == "standalone" ]]; then
                acmeSSLHttpWebrootMode="standalone"
            elif [[ $1 == "webroot" ]]; then
                acmeSSLHttpWebrootMode="webroot"
            elif [[ $1 == "webrootran" ]] ; then
                acmeSSLHttpWebrootMode="webrootran"
            elif [[ $1 == "nginx" ]] ; then
                acmeSSLHttpWebrootMode="nginx"
            fi
        fi

        echo
        if [[ ${acmeSSLHttpWebrootMode} == "standalone" ]] ; then
            green " 开始申请证书 acme.sh 通过 http standalone mode 从 ${acmeSSLServerName} 申请, 请确保80端口不被占用 "
            
            echo
            ${configSSLAcmeScriptPath}/acme.sh --issue -d ${configSSLDomain} --standalone --keylength ec-256 --days ${acmeSSLDays} --server ${acmeSSLServerName}
        
        elif [[ ${acmeSSLHttpWebrootMode} == "webroot" ]] ; then
            green " 开始申请证书, acme.sh 通过 http webroot mode 从 ${acmeSSLServerName} 申请, 请确保web服务器 例如 nginx 已经运行在80端口 "
            
            echo
            read -r -p "请输入Web服务器的html网站根目录路径? 例如/usr/share/nginx/html:" isDomainSSLNginxWebrootFolderInput
            echo " 您输入的网站根目录路径为 ${isDomainSSLNginxWebrootFolderInput}"

            if [ -z ${isDomainSSLNginxWebrootFolderInput} ]; then
                red " 输入的Web服务器的 html网站根目录路径不能为空, 网站根目录将默认设置为 ${configWebsitePath}, 请修改你的web服务器配置后再申请证书!"
                configWebsitePath="${HOME}/website/html"
            else
                configWebsitePath="${isDomainSSLNginxWebrootFolderInput}"
            fi
            
            echo
            ${configSSLAcmeScriptPath}/acme.sh --issue -d ${configSSLDomain} --webroot ${configWebsitePath} --keylength ec-256 --days ${acmeSSLDays} --server ${acmeSSLServerName}
        
        elif [[ ${acmeSSLHttpWebrootMode} == "nginx" ]] ; then
            green " 开始申请证书, acme.sh 通过 http nginx mode 从 ${acmeSSLServerName} 申请, 请确保web服务器 nginx 已经运行 "
            
            echo
            ${configSSLAcmeScriptPath}/acme.sh --issue -d ${configSSLDomain} --nginx --keylength ec-256 --days ${acmeSSLDays} --server ${acmeSSLServerName}

        elif [[ ${acmeSSLHttpWebrootMode} == "webrootran" ]] ; then

            # https://github.com/m3ng9i/ran/issues/10

            ranDownloadUrl="https://github.com/m3ng9i/ran/releases/download/v0.1.6/ran_linux_amd64.zip"
            ranDownloadFileName="ran_linux_amd64"
            
            if [[ "${osArchitecture}" == "arm64" || "${osArchitecture}" == "arm" ]]; then
                ranDownloadUrl="https://github.com/m3ng9i/ran/releases/download/v0.1.6/ran_linux_arm64.zip"
                ranDownloadFileName="ran_linux_arm64"
            fi


            mkdir -p ${configRanPath}
            
            if [[ -f "${configRanPath}/${ranDownloadFileName}" ]]; then
                green " 检测到 ran 已经下载过, 准备启动 ran 临时的web服务器 "
            else
                green " 开始下载 ran 作为临时的web服务器 "
                downloadAndUnzip "${ranDownloadUrl}" "${configRanPath}" "${ranDownloadFileName}" 
                chmod +x "${configRanPath}/${ranDownloadFileName}"
            fi

            echo "nohup ${configRanPath}/${ranDownloadFileName} -l=false -g=false -sa=true -p=80 -r=${configWebsitePath} >/dev/null 2>&1 &"
            nohup ${configRanPath}/${ranDownloadFileName} -l=false -g=false -sa=true -p=80 -r=${configWebsitePath} >/dev/null 2>&1 &
            echo
            
            green " 开始申请证书, acme.sh 通过 http webroot mode 从 ${acmeSSLServerName} 申请, 并使用 ran 作为临时的web服务器 "
            echo
            ${configSSLAcmeScriptPath}/acme.sh --issue -d ${configSSLDomain} --webroot ${configWebsitePath} --keylength ec-256 --days ${acmeSSLDays} --server ${acmeSSLServerName}

            sleep 4
            ps -C ${ranDownloadFileName} -o pid= | xargs -I {} kill {}
        fi

    else
        green " 开始申请证书, acme.sh 通过 dns mode 申请 "

        echo
        green "请选择 DNS provider DNS 提供商: 1 CloudFlare, 2 AliYun,  3 DNSPod(Tencent), 4 GoDaddy "
        red "注意 CloudFlare 针对某些免费域名例如 .tk .cf 等  不再支持使用API 申请DNS证书 "
        echo
        read -r -p "请选择 DNS 提供商 ? 默认直接回车为 1. CloudFlare, 请输入纯数字:" isAcmeSSLDNSProviderInput
        isAcmeSSLDNSProviderInput=${isAcmeSSLDNSProviderInput:-1}    

        
        if [ "$isAcmeSSLDNSProviderInput" == "2" ]; then
            read -r -p "Please Input Ali Key: " Ali_Key
            export Ali_Key="${Ali_Key}"
            read -r -p "Please Input Ali Secret: " Ali_Secret
            export Ali_Secret="${Ali_Secret}"
            acmeSSLDNSProvider="dns_ali"

        elif [ "$isAcmeSSLDNSProviderInput" == "3" ]; then
            read -r -p "Please Input DNSPod API ID: " DP_Id
            export DP_Id="${DP_Id}"
            read -r -p "Please Input DNSPod API Key: " DP_Key
            export DP_Key="${DP_Key}"
            acmeSSLDNSProvider="dns_dp"

        elif [ "$isAcmeSSLDNSProviderInput" == "4" ]; then
            read -r -p "Please Input GoDaddy API Key: " gd_Key
            export GD_Key="${gd_Key}"
            read -r -p "Please Input GoDaddy API Secret: " gd_Secret
            export GD_Secret="${gd_Secret}"
            acmeSSLDNSProvider="dns_gd"

        else
            read -r -p "Please Input CloudFlare Email: " cf_email
            export CF_Email="${cf_email}"
            read -r -p "Please Input CloudFlare Global API Key: " cf_key
            export CF_Key="${cf_key}"
            acmeSSLDNSProvider="dns_cf"
        fi
        
        echo
        ${configSSLAcmeScriptPath}/acme.sh --issue -d "${configSSLDomain}" --dns ${acmeSSLDNSProvider} --force --keylength ec-256 --server ${acmeSSLServerName} --debug 
        
    fi

    echo
    ${configSSLAcmeScriptPath}/acme.sh --installcert --ecc -d ${configSSLDomain} \
    --key-file ${configSSLCertPath}/${configSSLCertKeyFilename} \
    --fullchain-file ${configSSLCertPath}/${configSSLCertFullchainFilename} \
    --reloadcmd "systemctl restart nginx.service"

    green " ================================================== "
}




function getHTTPSCertificateStep1(){
    echo
    green " ================================================== "
    yellow " 请输入解析到本VPS的域名 例如 www.xxx.com: (此步骤请关闭CDN后安装)"
    read -p "请输入解析到本VPS的域名:" configSSLDomain

    if compareRealIpWithLocalIp "${configSSLDomain}" ; then
        echo
        green " =================================================="
        green " 是否申请证书? 默认直接回车为申请证书, 如第二次安装或已有证书 可以选否"
        green " 如果已经有SSL证书文件 请放到下面路径"
        red " ${configSSLDomain} 域名证书内容文件路径 ${configSSLCertPath}/${configSSLCertFullchainFilename} "
        red " ${configSSLDomain} 域名证书私钥文件路径 ${configSSLCertPath}/${configSSLCertKeyFilename} "
        echo

        read -p "是否申请证书? 默认直接回车为自动申请证书,请输入[Y/n]:" isDomainSSLRequestInput
        isDomainSSLRequestInput=${isDomainSSLRequestInput:-Y}

        if [[ $isDomainSSLRequestInput == [Yy] ]]; then
            getHTTPSCertificateWithAcme 
        else
            green " =================================================="
            green " 不申请域名的证书, 请把证书放到如下目录, 或自行修改trojan或v2ray配置!"
            green " ${configSSLDomain} 域名证书内容文件路径 ${configSSLCertPath}/${configSSLCertFullchainFilename} "
            green " ${configSSLDomain} 域名证书私钥文件路径 ${configSSLCertPath}/${configSSLCertKeyFilename} "
            green " =================================================="
        fi
    else
        exit
    fi

}








function installWebServerNginx(){

    echo
    green " ================================================== "
    yellow "     开始安装 Web服务器 nginx !"
    green " ================================================== "
    echo

    if test -s ${nginxConfigPath}; then
        green " ================================================== "
        red "     Nginx 已存在, 退出安装!"
        green " ================================================== "
        exit
    fi

    stopServiceV2ray
    
    ${osSystemPackage} install -y nginx-mod-stream
    ${osSystemPackage} install -y nginx
    ${sudoCmd} systemctl enable nginx.service
    ${sudoCmd} systemctl stop nginx.service

    # 解决出现的nginx warning 错误 Failed to parse PID from file /run/nginx.pid: Invalid argument
    # https://www.kancloud.cn/tinywan/nginx_tutorial/753832
    
    mkdir -p /etc/systemd/system/nginx.service.d
    printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
    
    ${sudoCmd} systemctl daemon-reload
    



    nginxConfigServerHttpInput=""
    nginxConfigStreamConfigInput=""
    nginxConfigNginxModuleInput=""

    if [[ "${configInstallNginxMode}" == "noSSL" ]]; then
        if [[ ${configV2rayWorkingNotChangeMode} == "true" ]]; then
            inputV2rayStreamSettings
        fi

        read -r -d '' nginxConfigServerHttpInput << EOM
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

        location /$configV2rayGRPCServiceName {
            grpc_pass grpc://127.0.0.1:$configV2rayGRPCPort;
            grpc_connect_timeout 60s;
            grpc_read_timeout 720m;
            grpc_send_timeout 720m;
            grpc_set_header X-Real-IP \$remote_addr;
            grpc_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }  
    }

EOM

    elif [[ "${configInstallNginxMode}" == "v2raySSL" ]]; then
        inputV2rayStreamSettings

        read -r -d '' nginxConfigServerHttpInput << EOM
    server {
        listen 443 ssl http2;
        listen [::]:443 http2;
        server_name  $configSSLDomain;

        ssl_certificate       ${configSSLCertPath}/$configSSLCertFullchainFilename;
        ssl_certificate_key   ${configSSLCertPath}/$configSSLCertKeyFilename;
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

        location /$configV2rayGRPCServiceName {
            grpc_pass grpc://127.0.0.1:$configV2rayGRPCPort;
            grpc_connect_timeout 60s;
            grpc_read_timeout 720m;
            grpc_send_timeout 720m;
            grpc_set_header X-Real-IP \$remote_addr;
            grpc_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }
    }

    server {
        listen 80;
        listen [::]:80;
        server_name  $configSSLDomain;
        return 301 https://$configSSLDomain\$request_uri;
    }

EOM

    elif [[ "${configInstallNginxMode}" == "sni" ]]; then

        if [ "$osRelease" == "centos" ]; then
        read -r -d '' nginxConfigNginxModuleInput << EOM
load_module /usr/lib64/nginx/modules/ngx_stream_module.so;
EOM
        else
        read -r -d '' nginxConfigNginxModuleInput << EOM
load_module /usr/lib/nginx/modules/ngx_stream_module.so;
EOM
        fi



        nginxConfigStreamFakeWebsiteDomainInput=""

        nginxConfigStreamOwnWebsiteInput=""
        nginxConfigStreamOwnWebsiteMapInput=""

        if [[ "${isNginxSNIModeInput}" == "4" || "${isNginxSNIModeInput}" == "5" || "${isNginxSNIModeInput}" == "6" ]]; then

            read -r -d '' nginxConfigStreamOwnWebsiteInput << EOM
    server {
        listen 8000 ssl http2;
        listen [::]:8000 http2;
        server_name  $configNginxSNIDomainWebsite;

        ssl_certificate       ${configNginxSNIDomainWebsiteCertPath}/$configSSLCertFullchainFilename;
        ssl_certificate_key   ${configNginxSNIDomainWebsiteCertPath}/$configSSLCertKeyFilename;
        ssl_protocols         TLSv1.2 TLSv1.3;
        ssl_ciphers           TLS-AES-256-GCM-SHA384:TLS-CHACHA20-POLY1305-SHA256:TLS-AES-128-GCM-SHA256:TLS-AES-128-CCM-8-SHA256:TLS-AES-128-CCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256;

        # Config for 0-RTT in TLSv1.3
        ssl_early_data on;
        ssl_stapling on;
        ssl_stapling_verify on;
        add_header Strict-Transport-Security "max-age=31536000";
        
        root $configWebsitePath;
        index index.php index.html index.htm;

    }

    server {
        listen 80;
        listen [::]:80;
        server_name  $configNginxSNIDomainWebsite;
        return 301 https://$configNginxSNIDomainWebsite\$request_uri;
    }
EOM 

            read -r -d '' nginxConfigStreamOwnWebsiteMapInput << EOM
        ${configNginxSNIDomainWebsite} web;
EOM
        fi


        nginxConfigStreamTrojanMapInput=""
        nginxConfigStreamTrojanUpstreamInput=""

        if [[ "${isNginxSNIModeInput}" == "1" || "${isNginxSNIModeInput}" == "2" || "${isNginxSNIModeInput}" == "4" || "${isNginxSNIModeInput}" == "5" ]]; then
            
            nginxConfigStreamFakeWebsiteDomainInput="${configNginxSNIDomainTrojan}"

            read -r -d '' nginxConfigStreamTrojanMapInput << EOM
        ${configNginxSNIDomainTrojan} trojan;
EOM

            read -r -d '' nginxConfigStreamTrojanUpstreamInput << EOM
    upstream trojan {
        server 127.0.0.1:$configV2rayTrojanPort;
    }
EOM
        fi


        nginxConfigStreamV2rayMapInput=""
        nginxConfigStreamV2rayUpstreamInput=""

        if [[ "${isNginxSNIModeInput}" == "1" || "${isNginxSNIModeInput}" == "3" || "${isNginxSNIModeInput}" == "4" || "${isNginxSNIModeInput}" == "6" ]]; then

            nginxConfigStreamFakeWebsiteDomainInput="${nginxConfigStreamFakeWebsiteDomainInput} ${configNginxSNIDomainV2ray}"

            read -r -d '' nginxConfigStreamV2rayMapInput << EOM
        ${configNginxSNIDomainV2ray} v2ray;
EOM

            read -r -d '' nginxConfigStreamV2rayUpstreamInput << EOM
    upstream v2ray {
        server 127.0.0.1:$configV2rayPort;
    }
EOM
        fi


        read -r -d '' nginxConfigServerHttpInput << EOM
    server {
        listen       80;
        server_name  $nginxConfigStreamFakeWebsiteDomainInput;
        root $configWebsitePath;
        index index.php index.html index.htm;

    }

    ${nginxConfigStreamOwnWebsiteInput}

EOM


        read -r -d '' nginxConfigStreamConfigInput << EOM
stream {
    map \$ssl_preread_server_name \$filtered_sni_name {
        ${nginxConfigStreamOwnWebsiteMapInput}
        ${nginxConfigStreamTrojanMapInput}
        ${nginxConfigStreamV2rayMapInput}
    }
    
    ${nginxConfigStreamTrojanUpstreamInput}

    ${nginxConfigStreamV2rayUpstreamInput}

    upstream web {
        server 127.0.0.1:8000;
    }

    server {
        listen 443;
        listen [::]:443;
        resolver 8.8.8.8;
        ssl_preread on;
        proxy_pass \$filtered_sni_name;
    }
}

EOM

    elif [[ "${configInstallNginxMode}" == "trojanWeb" ]]; then

        read -r -d '' nginxConfigServerHttpInput << EOM
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

EOM

    else

        echo

    fi


        cat > "${nginxConfigPath}" <<-EOF

${nginxConfigNginxModuleInput}

user  root;
worker_processes  1;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}


${nginxConfigStreamConfigInput}


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


    ${nginxConfigServerHttpInput}

}


EOF




    # 下载伪装站点 并设置伪装网站
    rm -rf ${configWebsitePath}/*
    mkdir -p ${configWebsiteDownloadPath}

    downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/website2.zip" "${configWebsitePath}" "website2.zip"


    if [ "${configInstallNginxMode}" != "trojanWeb" ] ; then
        wget -P "${configWebsiteDownloadPath}" "https://github.com/jinwyp/one_click_script/raw/master/download/trojan-mac.zip"
        wget -P "${configWebsiteDownloadPath}" "https://github.com/jinwyp/one_click_script/raw/master/download/v2ray-windows.zip" 
        wget -P "${configWebsiteDownloadPath}" "https://github.com/jinwyp/one_click_script/raw/master/download/v2ray-mac.zip"
    fi


    # downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/trojan_client_all.zip" "${configWebsiteDownloadPath}" "trojan_client_all.zip"
    # downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/trojan-qt5.zip" "${configWebsiteDownloadPath}" "trojan-qt5.zip"
    # downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/v2ray_client_all.zip" "${configWebsiteDownloadPath}" "v2ray_client_all.zip"

    #wget -P "${configWebsiteDownloadPath}" "https://github.com/jinwyp/one_click_script/raw/master/download/v2ray-android.zip"

    ${sudoCmd} systemctl start nginx.service

    green " ================================================== "
    green "       Web服务器 nginx 安装成功!!"
    green "    伪装站点为 http://${configSSLDomain}"

	if [[ "${configInstallNginxMode}" == "trojanWeb" ]] ; then
	    yellow "    Trojan-web ${versionTrojanWeb} 可视化管理面板地址  http://${configSSLDomain}/${configTrojanWebNginxPath} "
	    green "    Trojan-web 可视化管理面板 可执行文件路径 ${configTrojanWebPath}/trojan-web"
        green "    Trojan-web 停止命令: systemctl stop trojan-web.service  启动命令: systemctl start trojan-web.service  重启命令: systemctl restart trojan-web.service"
	    green "    Trojan 服务器端可执行文件路径 /usr/bin/trojan/trojan"
	    green "    Trojan 服务器端配置路径 /usr/local/etc/trojan/config.json "
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

	if [[ "${configInstallNginxMode}" == "trojanWeb" ]] ; then
        cat >> ${configReadme} <<-EOF

安装的Trojan-web ${versionTrojanWeb} 可视化管理面板 
访问地址  http://${configSSLDomain}/${configTrojanWebNginxPath}
Trojan-web 停止命令: systemctl stop trojan-web.service  
Trojan-web 启动命令: systemctl start trojan-web.service  
Trojan-web 重启命令: systemctl restart trojan-web.service

Trojan 服务器端配置路径 /usr/local/etc/trojan/config.json
Trojan 停止命令: systemctl stop trojan.service
Trojan 启动命令: systemctl start trojan.service
Trojan 重启命令: systemctl restart trojan.service
Trojan 查看运行状态命令: systemctl status trojan.service

EOF
	fi

}

function removeNginx(){

    echo
    read -p "是否确认卸载Nginx? 直接回车默认卸载, 请输入[Y/n]:" isRemoveNginxServerInput
    isRemoveNginxServerInput=${isRemoveNginxServerInput:-Y}

    if [[ "${isRemoveNginxServerInput}" == [Yy] ]]; then


        echo
        if [[ -f "${nginxConfigPath}" ]]; then
            green " ================================================== "
            red " 准备卸载已安装的nginx"
            green " ================================================== "
            echo

            ${sudoCmd} systemctl stop nginx.service
            ${sudoCmd} systemctl disable nginx.service

            if [ "$osRelease" == "centos" ]; then
                yum remove -y nginx-mod-stream
                yum remove -y nginx
            else
                apt autoremove -y --purge nginx nginx-common nginx-core
                apt-get remove --purge nginx nginx-full nginx-common nginx-core
            fi


            rm -f ${nginxAccessLogFilePath}
            rm -f ${nginxErrorLogFilePath}

            rm -f ${configReadme}
            rm -rf "/etc/nginx"
            
            rm -rf ${configDownloadTempPath}

            echo
            read -p "是否删除证书 和 卸载acme.sh申请证书工具, 由于一天内申请证书有次数限制, 默认建议不删除证书,  请输入[y/N]:" isDomainSSLRemoveInput
            isDomainSSLRemoveInput=${isDomainSSLRemoveInput:-n}

            
            if [[ $isDomainSSLRemoveInput == [Yy] ]]; then
                rm -rf ${configWebsiteFatherPath}
                ${sudoCmd} bash ${configSSLAcmeScriptPath}/acme.sh --uninstall
                
                echo
                green " ================================================== "
                green "  Nginx 卸载完毕, SSL 证书文件已删除!"
                
            else
                rm -rf ${configWebsitePath}
                echo
                green " ================================================== "
                green "  Nginx 卸载完毕, 已保留 SSL 证书文件 到 ${configSSLCertPath} "
            fi

            green " ================================================== "
        else
            red " 系统没有安装 nginx, 退出卸载"
        fi
        echo

    fi    
}



















configNginxSNIDomainWebsite=""
configNginxSNIDomainV2ray=""
configNginxSNIDomainTrojan=""

configSSLCertPath="${HOME}/website/cert"
configNginxSNIDomainTrojanCertPath="${HOME}/website/cert/nginxsni/trojan"
configNginxSNIDomainV2rayCertPath="${HOME}/website/cert/nginxsni/v2ray"
configNginxSNIDomainWebsiteCertPath="${HOME}/website/cert/nginxsni/web"

function checkNginxSNIDomain(){

    if compareRealIpWithLocalIp "$2" ; then

        if [ "$1" = "trojan" ]; then
            configNginxSNIDomainTrojan=$2
            configSSLCertPath="${configNginxSNIDomainTrojanCertPath}"

        elif [ "$1" = "v2ray" ]; then
            configNginxSNIDomainV2ray=$2
            configSSLCertPath="${configNginxSNIDomainV2rayCertPath}"

        elif [ "$1" = "website" ]; then
            configNginxSNIDomainWebsite=$2
            configSSLCertPath="${configNginxSNIDomainWebsiteCertPath}"
        fi
        
        configSSLDomain="$2"
        mkdir -p ${configSSLCertPath}

        echo
        green " =================================================="
        green " 是否申请证书? 默认直接回车为申请证书, 如第二次安装或已有证书 可以选否"
        green " 如果已经有SSL证书文件 请放到下面路径"
        red " ${configSSLDomain} 域名证书内容文件路径 ${configSSLCertPath}/${configSSLCertFullchainFilename} "
        red " ${configSSLDomain} 域名证书私钥文件路径 ${configSSLCertPath}/${configSSLCertKeyFilename} "
        echo

        read -p "是否申请证书? 默认直接回车为自动申请证书,请输入[Y/n]:" isDomainSSLRequestInput
        isDomainSSLRequestInput=${isDomainSSLRequestInput:-Y}

        if [[ $isDomainSSLRequestInput == [Yy] ]]; then
            getHTTPSCertificateWithAcme 
        else
            green " =================================================="
            green " 不申请域名的证书, 请把证书放到如下目录, 或自行修改trojan或v2ray配置!"
            green " ${configSSLDomain} 域名证书内容文件路径 ${configSSLCertPath}/${configSSLCertFullchainFilename} "
            green " ${configSSLDomain} 域名证书私钥文件路径 ${configSSLCertPath}/${configSSLCertKeyFilename} "
            green " =================================================="
        fi
    else
        inputNginxSNIDomain $1
    fi

}

function inputNginxSNIDomain(){
    echo
    green " ================================================== "

    if [ "$1" = "trojan" ]; then
        yellow " 请输入解析到本VPS的域名 用于给Trojan使用, 例如 www.xxx.com: (此步骤请关闭CDN后安装)"
        read -p "请输入解析到本VPS的域名:" configNginxSNIDomainDefault
        
    elif [ "$1" = "v2ray" ]; then
        yellow " 请输入解析到本VPS的域名 用于给V2ray使用, 例如 www.xxx.com: (此步骤请关闭CDN后安装)"
        read -p "请输入解析到本VPS的域名:" configNginxSNIDomainDefault
        
    elif [ "$1" = "website" ]; then
        yellow " 请输入解析到本VPS的域名 用于给现有网站使用, 例如 www.xxx.com: (此步骤请关闭CDN后安装)"
        read -p "请输入解析到本VPS的域名:" configNginxSNIDomainDefault

    fi

    checkNginxSNIDomain $1 ${configNginxSNIDomainDefault}
    
}

function installTrojanV2rayWithNginx(){

    stopServiceNginx
    testLinuxPortUsage
    installPackage

    echo
    if [ "$1" = "v2ray" ]; then
        read -p "是否不申请域名的证书 直接使用本VPS的IP安装? 默认直接回车为不申请证书,请输入[Y/n]:" isDomainIPRequestInput
        isDomainIPRequestInput=${isDomainIPRequestInput:-Y}

        if [[ $isDomainIPRequestInput == [Yy] ]]; then
            echo
            read -p "请输入本VPS的IP 或 解析到本VPS的域名:" configSSLDomain
            installV2ray
            exit
        fi

    elif [ "$1" = "nginxSNI_trojan_v2ray" ]; then
        green " ================================================== "
        green " 请选择 Nginx SNI + Trojan + V2ray 的安装模式, 默认为1"
        green " 1. Nginx + Trojan + V2ray + 伪装网站"
        green " 2. Nginx + Trojan + 伪装网站"
        green " 3. Nginx + V2ray + 伪装网站"
        green " 4. Nginx + Trojan + V2ray + 已有网站共存"
        green " 5. Nginx + Trojan + 已有网站共存"
        green " 6. Nginx + V2ray + 已有网站共存"


        read -p "请选择 Nginx SNI 的安装模式 直接回车默认选1, 请输入纯数字:" isNginxSNIModeInput
        isNginxSNIModeInput=${isNginxSNIModeInput:-1}

        if [[ "${isNginxSNIModeInput}" == "1" ]]; then
            inputNginxSNIDomain "trojan"
            inputNginxSNIDomain "v2ray"
            

            installWebServerNginx
            installTrojanServer
            installV2ray

        elif [[ "${isNginxSNIModeInput}" == "2" ]]; then
            inputNginxSNIDomain "trojan"

            installWebServerNginx
            installTrojanServer

        elif [[ "${isNginxSNIModeInput}" == "3" ]]; then
            inputNginxSNIDomain "v2ray"

            installWebServerNginx
            installV2ray

        elif [[ "${isNginxSNIModeInput}" == "4" ]]; then
            inputNginxSNIDomain "trojan"
            inputNginxSNIDomain "v2ray"
            inputNginxSNIDomain "website"

            installWebServerNginx
            installTrojanServer
            installV2ray

        elif [[ "${isNginxSNIModeInput}" == "5" ]]; then
            inputNginxSNIDomain "trojan"
            inputNginxSNIDomain "website"

            installWebServerNginx
            installTrojanServer

        elif [[ "${isNginxSNIModeInput}" == "6" ]]; then
            inputNginxSNIDomain "v2ray"
            inputNginxSNIDomain "website"

            installWebServerNginx
            installV2ray
            
        fi


        exit
    fi


    getHTTPSCertificateStep1

    echo
    if test -s ${configSSLCertPath}/${configSSLCertFullchainFilename}; then
    
        green " ================================================== "
        green " 已检测到域名 ${configSSLDomain} 的证书文件 获取成功!"
        green " ${configSSLDomain} 域名证书内容文件路径 ${configSSLCertPath}/${configSSLCertFullchainFilename} "
        green " ${configSSLDomain} 域名证书私钥文件路径 ${configSSLCertPath}/${configSSLCertKeyFilename} "        
        green " ================================================== "
        echo

        if [ "$1" == "trojan_nginx" ]; then
            installWebServerNginx
            installTrojanServer

        elif [ "$1" = "trojan" ]; then
            installTrojanServer

        elif [ "$1" = "nginx_v2ray" ]; then
            installWebServerNginx
            installV2ray

        elif [ "$1" = "v2ray_nginxOptional" ]; then
            echo
            green " 是否安装 Nginx 用于提供伪装网站, 如果已有网站或搭配宝塔面板请选择N不安装"
            read -p "是否确安装Nginx伪装网站? 直接回车默认安装, 请输入[Y/n]:" isInstallNginxServerInput
            isInstallNginxServerInput=${isInstallNginxServerInput:-Y}

            if [[ "${isInstallNginxServerInput}" == [Yy] ]]; then
                installWebServerNginx
            fi

            if [[ "${configV2rayWorkingMode}" == "trojan" ]]; then
                installTrojanServer
            fi
            installV2ray

        elif [ "$1" = "v2ray" ]; then
            installV2ray

        elif [ "$1" = "trojan_nginx_v2ray" ]; then
            installWebServerNginx
            installTrojanServer
            installV2ray

        else
            echo
        fi
    else
        red " ================================================== "
        red " https证书没有申请成功，安装失败!"
        red " 请检查域名和DNS是否生效, 同一域名请不要一天内多次申请!"
        red " 请检查80和443端口是否开启, VPS服务商可能需要添加额外防火墙规则，例如阿里云、谷歌云等!"
        red " 重启VPS, 重新执行脚本, 可重新选择该项再次申请证书 ! "
        red " ================================================== "
        exit
    fi    
}


















function downloadTrojanBin(){

    if [ "${isTrojanGo}" = "no" ] ; then
        if [ -z $1 ]; then
            tempDownloadTrojanPath="${configTrojanPath}"
        else
            tempDownloadTrojanPath="${configDownloadTempPath}/upgrade/trojan"
            mv -f ${configDownloadTempPath}/upgrade/trojan/trojan ${configTrojanPath}
        fi    
        # https://github.com/trojan-gfw/trojan/releases/download/v1.16.0/trojan-1.16.0-linux-amd64.tar.xz
        if [[ ${osArchitecture} == "arm" || ${osArchitecture} == "arm64" ]] ; then
            red "Trojan not support arm on linux! "
            exit
        fi

        downloadAndUnzip "https://github.com/trojan-gfw/trojan/releases/download/v${versionTrojan}/${downloadFilenameTrojan}" "${tempDownloadTrojanPath}" "${downloadFilenameTrojan}"
    else
        if [ -z $1 ]; then
            tempDownloadTrojanPath="${configTrojanGoPath}"
        else
            tempDownloadTrojanPath="${configDownloadTempPath}/upgrade/trojan-go"
            mv -f ${configDownloadTempPath}/upgrade/trojan-go/trojan-go ${configTrojanGoPath}
        fi 

        # https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-amd64.zip
        if [[ ${osArchitecture} == "arm" ]] ; then
            downloadFilenameTrojanGo="trojan-go-linux-arm.zip"
        fi
        if [[ ${osArchitecture} == "arm64" ]] ; then
            downloadFilenameTrojanGo="trojan-go-linux-armv8.zip"
        fi
        downloadAndUnzip "https://github.com/p4gefau1t/trojan-go/releases/download/v${versionTrojanGo}/${downloadFilenameTrojanGo}" "${tempDownloadTrojanPath}" "${downloadFilenameTrojanGo}"
    fi 
}

function checkTrojanGoInstall(){
    if [ -f "${configTrojanPath}/trojan" ] ; then
        configTrojanBasePath="${configTrojanPath}"
        promptInfoTrojanName=""
        isTrojanGo="no"
    fi

    if [ -f "${configTrojanGoPath}/trojan-go" ] ; then
        configTrojanBasePath="${configTrojanGoPath}"
        promptInfoTrojanName="-go"
        isTrojanGo="yes"
    fi

    if [ -n "$1" ] ; then
        if [[ -f "${configTrojanBasePath}/trojan${promptInfoTrojanName}" ]]; then
            green " =================================================="
            green "  已安装过 Trojan${promptInfoTrojanName} , 退出安装 !"
            green " =================================================="
            exit
        fi
    fi

}

function getTrojanGoInstallInfo(){
    if [ "${isTrojanGo}" = "yes" ] ; then
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



    checkTrojanGoInstall "exitInfo"

    if [ "${isTrojanGoSupportWebsocket}" = "true" ] ; then
        isTrojanGo="yes"
    else
        echo
        green " =================================================="
        green " 请选择安装 trojan-go 还是 原版trojan, 选Y为安装trojan-go, 选N为安装原版trojan"
        read -p "请选择安装trojan-go 还是 原版trojan? 直接回车默认为trojan-go, 请输入[Y/n]:" isInstallTrojanTypeInput
        isInstallTrojanTypeInput=${isInstallTrojanTypeInput:-Y}

        if [[ "${isInstallTrojanTypeInput}" == [Yy] ]]; then
            isTrojanGo="yes"

            echo
            green " 请选择是否开启 trojan-go 的 Websocket 用于CDN中转, 注意原版trojan客户端不支持 Websocket"
            read -p "请选择是否开启 Websocket? 直接回车默认开启, 请输入[Y/n]:" isTrojanGoWebsocketInput
            isTrojanGoWebsocketInput=${isTrojanGoWebsocketInput:-Y}

            if [[ "${isTrojanGoWebsocketInput}" == [Yy] ]]; then
                isTrojanGoSupportWebsocket="true"
            else
                isTrojanGoSupportWebsocket="false"
            fi

        else
            isTrojanGo="no"
        fi

    fi

    getTrojanGoInstallInfo

    green " =================================================="
    green " 开始安装 Trojan${promptInfoTrojanName} Version: ${configTrojanBaseVersion} !"
    yellow " 请输入 trojan${promptInfoTrojanName} 密码的前缀? (会生成若干随机密码和带有该前缀的密码)"
    green " =================================================="

    read configTrojanPasswordPrefixInput
    configTrojanPasswordPrefixInput=${configTrojanPasswordPrefixInput:-jin}


    if [[ "$configV2rayWorkingMode" != "trojan" && "$configV2rayWorkingMode" != "sni" ]] ; then
        configV2rayTrojanPort=443

        inputV2rayServerPort "textMainTrojanPort"
        configV2rayTrojanPort=${isTrojanUserPortInput}         
    fi

    if [[ "$configV2rayWorkingMode" == "sni" ]] ; then
        configSSLCertPath="${configNginxSNIDomainTrojanCertPath}"
        configSSLDomain=${configNginxSNIDomainTrojan}    
    fi

    mkdir -p ${configTrojanBasePath}
    cd ${configTrojanBasePath}
    rm -rf ${configTrojanBasePath}/*

    downloadTrojanBin

    if [ "${isTrojanMultiPassword}" = "no" ] ; then
    read -r -d '' trojanConfigUserpasswordInput << EOM
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
        "${configTrojanPasswordPrefixInput}202020"
EOM

    else

    read -r -d '' trojanConfigUserpasswordInput << EOM
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
EOM

    fi






    if [ "$isTrojanGo" = "no" ] ; then

        # 增加trojan 服务器端配置
	    cat > ${configTrojanBasePath}/server.json <<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": ${configV2rayTrojanPort},
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        ${trojanConfigUserpasswordInput}
    ],
    "log_level": 1,
    "ssl": {
        "cert": "${configSSLCertPath}/$configSSLCertFullchainFilename",
        "key": "${configSSLCertPath}/$configSSLCertKeyFilename",
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
    "local_port": ${configV2rayTrojanPort},
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        ${trojanConfigUserpasswordInput}
    ],
    "log_level": 1,
    "log_file": "${configTrojanGoLogFile}",
    "ssl": {
        "verify": true,
        "verify_hostname": true,
        "cert": "${configSSLCertPath}/$configSSLCertFullchainFilename",
        "key": "${configSSLCertPath}/$configSSLCertKeyFilename",
        "sni": "${configSSLDomain}",
        "fallback_addr": "127.0.0.1",
        "fallback_port": 80, 
        "fingerprint": "chrome"
    },
    "websocket": {
        "enabled": ${isTrojanGoSupportWebsocket},
        "path": "/${configTrojanGoWebSocketPath}",
        "host": "${configSSLDomain}"
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


    if [ "${configV2rayWorkingMode}" == "nouse" ] ; then
        
    
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
    cp ${configSSLCertPath}/${configSSLCertFullchainFilename} ${configTrojanBasePath}/trojan-win-cli/${configSSLCertFullchainFilename}

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
        "cert": "$configSSLCertFullchainFilename",
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

    if [[ ${configInstallNginxMode} == "noSSL" ]]; then
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
	# blue  "----------------------------------------"
    echo
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

    tempTextInfoTrojanPassword="您指定前缀的密码共100个: 从 ${configTrojanPasswordPrefixInput}202000 到 ${configTrojanPasswordPrefixInput}202099 都可以使用"
    if [ "${isTrojanMultiPassword}" = "no" ] ; then
        tempTextInfoTrojanPassword="您指定前缀的密码共20个: 从 ${configTrojanPasswordPrefixInput}202001 到 ${configTrojanPasswordPrefixInput}202020 都可以使用"
    fi
	yellow "${tempTextInfoTrojanPassword}" 
	yellow "例如: 密码:${configTrojanPasswordPrefixInput}202002 或 密码:${configTrojanPasswordPrefixInput}202019 都可以使用"

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
	#yellow "  Windows 客户端命令行版本下载：http://${configSSLDomain}/download/${configTrojanWindowsCliPrefixPath}/trojan-win-cli.zip"
	#yellow "  Windows 客户端命令行版本需要搭配浏览器插件使用，例如switchyomega等! "
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
	green "访问 https://www.v2rayssr.com/vpn-client.html 下载 客户端 及教程"
	#green "访问 https://www.v2rayssr.com/trojan-1.html 下载 浏览器插件 客户端 及教程"
    green "访问 https://westworldss.com/portal/page/download 下载 客户端 及教程"
	green "======================================================================"
	green "其他 Windows 客户端:"
	green "https://dl.trojan-cdn.com/trojan (exe为Win客户端, dmg为Mac客户端)"
	green "https://github.com/Qv2ray/Qv2ray/releases (exe为Win客户端, dmg为Mac客户端)"
	green "https://github.com/Dr-Incognito/V2Ray-Desktop/releases (exe为Win客户端, dmg为Mac客户端)"
	green "https://github.com/Fndroid/clash_for_windows_pkg/releases"
	green "======================================================================"
	green "其他 Mac 客户端:"
	green "https://dl.trojan-cdn.com/trojan (exe为Win客户端, dmg为Mac客户端)"
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
${tempTextInfoTrojanPassword}
例如: 密码:${configTrojanPasswordPrefixInput}202002 或 密码:${configTrojanPasswordPrefixInput}202019 都可以使用

如果是trojan-go开启了Websocket，那么Websocket path 路径为: /${configTrojanGoWebSocketPath}

小火箭链接:
trojan://${trojanPassword1}@${configSSLDomain}:${configV2rayTrojanPort}?peer=${configSSLDomain}&sni=${configSSLDomain}#${configSSLDomain}_trojan"

二维码 Trojan${promptInfoTrojanName}
https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=trojan%3a%2f%2f${trojanPassword1}%40${configSSLDomain}%3a${configV2rayTrojanPort}%3fpeer%3d${configSSLDomain}%26sni%3d${configSSLDomain}%23${configSSLDomain}_trojan

EOF
}

function upgradeTrojan(){

    checkTrojanGoInstall

    if [[ -f "${configTrojanPath}/trojan" || -f "${configTrojanGoPath}/trojan-go" ]]; then

        getTrojanGoInstallInfo

        green " ================================================== "
        green "     开始升级 Trojan${promptInfoTrojanName} Version: ${configTrojanBaseVersion}"
        green " ================================================== "

        ${sudoCmd} systemctl stop trojan${promptInfoTrojanName}.service
        mkdir -p ${configDownloadTempPath}/upgrade/trojan${promptInfoTrojanName}
        downloadTrojanBin "upgrade"
        ${sudoCmd} systemctl start trojan${promptInfoTrojanName}.service

        green " ================================================== "
        green "     升级成功 Trojan${promptInfoTrojanName} Version: ${configTrojanBaseVersion} !"
        green " ================================================== "

    else
        red " 系统没有安装 trojan${promptInfoTrojanName}, 退出卸载"
    fi
}

function removeTrojan(){

    echo
    read -p "是否确认卸载 trojan 或 trojan-go? 直接回车默认卸载, 请输入[Y/n]:" isRemoveTrojanServerInput
    isRemoveTrojanServerInput=${isRemoveTrojanServerInput:-Y}

    if [[ "${isRemoveTrojanServerInput}" == [Yy] ]]; then
        

        echo
        checkTrojanGoInstall

        if [[ -f "${configTrojanPath}/trojan" || -f "${configTrojanGoPath}/trojan-go" ]]; then
            echo
            green " ================================================== "
            red " 准备卸载已安装的trojan${promptInfoTrojanName}"
            green " ================================================== "
            echo

            ${sudoCmd} systemctl stop trojan${promptInfoTrojanName}.service
            ${sudoCmd} systemctl disable trojan${promptInfoTrojanName}.service

            rm -rf ${configTrojanBasePath}
            rm -f ${osSystemMdPath}trojan${promptInfoTrojanName}.service
            rm -f ${configTrojanLogFile}
            rm -f ${configTrojanGoLogFile}

            rm -f ${configReadme}

            crontab -l | grep -v "trojan${promptInfoTrojanName}"  | crontab -

            echo
            green " ================================================== "
            green "  trojan${promptInfoTrojanName} 卸载完毕 !"
            green "  crontab 定时任务 删除完毕 !"
            green " ================================================== "
            
        else
            red " 系统没有安装 trojan${promptInfoTrojanName}, 退出卸载"
        fi

    fi
}































function downloadV2rayXrayBin(){
    if [ -z $1 ]; then
        tempDownloadV2rayPath="${configV2rayPath}"
    else
        tempDownloadV2rayPath="${configDownloadTempPath}/upgrade/${promptInfoXrayName}"
    fi

    if [ "$isXray" = "no" ] ; then
        # https://github.com/v2fly/v2ray-core/releases/download/v4.41.1/v2ray-linux-64.zip
        # https://github.com/v2fly/v2ray-core/releases/download/v4.41.1/v2ray-linux-arm32-v6.zip
        # https://github.com/v2fly/v2ray-core/releases/download/v4.44.0/v2ray-linux-arm64-v8a.zip
        
        if [[ ${osArchitecture} == "arm" ]] ; then
            downloadFilenameV2ray="v2ray-linux-arm32-v6.zip"
        fi
        if [[ ${osArchitecture} == "arm64" ]] ; then
            downloadFilenameV2ray="v2ray-linux-arm64-v8a.zip"
        fi

        downloadAndUnzip "https://github.com/v2fly/v2ray-core/releases/download/v${versionV2ray}/${downloadFilenameV2ray}" "${tempDownloadV2rayPath}" "${downloadFilenameV2ray}"

    else
        # https://github.com/XTLS/Xray-core/releases/download/v1.5.0/Xray-linux-64.zip
        # https://github.com/XTLS/Xray-core/releases/download/v1.5.2/Xray-linux-arm32-v6.zip
        if [[ ${osArchitecture} == "arm" ]] ; then
            downloadFilenameXray="Xray-linux-arm32-v6.zip"
        fi
        if [[ ${osArchitecture} == "arm64" ]] ; then
            downloadFilenameXray="Xray-linux-arm64-v8a.zip"
        fi

        downloadAndUnzip "https://github.com/XTLS/Xray-core/releases/download/v${versionXray}/${downloadFilenameXray}" "${tempDownloadV2rayPath}" "${downloadFilenameXray}"
    fi
}



function inputV2rayStreamSettings(){
    echo
    green " =================================================="
    yellow " 请选择 V2ray或Xray的 StreamSettings 底层传输协议, 默认为3 Websocket"
    echo
    green " 1. TCP "
    green " 2. KCP "
    green " 3. WebSocket 支持CDN"
    green " 4. HTTP/2 (注意Nginx不支持HTTP/2的转发)"
    green " 5. QUIC "
    green " 6. gRPC 支持CDN"
    green " 7. WebSocket + gRPC 支持CDN"
    echo
    read -p "请选择底层传输协议? 直接回车默认选3 Websocket, 请输入纯数字:" isV2rayStreamSettingInput
    isV2rayStreamSettingInput=${isV2rayStreamSettingInput:-3}

    if [[ $isV2rayStreamSettingInput == 1 ]]; then
        configV2rayStreamSetting="tcp"

    elif [[ $isV2rayStreamSettingInput == 2 ]]; then
        configV2rayStreamSetting="kcp"
        inputV2rayKCPSeedPassword

    elif [[ $isV2rayStreamSettingInput == 4 ]]; then
        configV2rayStreamSetting="h2"
        inputV2rayWSPath "h2"
    elif [[ $isV2rayStreamSettingInput == 5 ]]; then
        configV2rayStreamSetting="quic"
        inputV2rayKCPSeedPassword "quic"

    elif [[ $isV2rayStreamSettingInput == 6 ]]; then
        configV2rayStreamSetting="grpc"

    elif [[ $isV2rayStreamSettingInput == 7 ]]; then
        configV2rayStreamSetting="wsgrpc"

    else
        configV2rayStreamSetting="ws"
        inputV2rayWSPath
    fi


    if [[ "${configInstallNginxMode}" == "v2raySSL" || ${configV2rayWorkingNotChangeMode} == "true" ]]; then

         if [[ "${configV2rayStreamSetting}" == "grpc" ]]; then
            inputV2rayGRPCPath

        elif [[ "${configV2rayStreamSetting}" == "wsgrpc" ]]; then
            inputV2rayWSPath
            inputV2rayGRPCPath
        fi

    else

        if [[ "${configV2rayStreamSetting}" == "grpc" ]]; then
            inputV2rayServerPort "textMainGRPCPort"

            configV2rayGRPCPort=${isV2rayUserPortGRPCInput}   
            configV2rayPortGRPCShowInfo=${isV2rayUserPortGRPCInput}   

            inputV2rayGRPCPath

        elif [[ "${configV2rayStreamSetting}" == "wsgrpc" ]]; then
            inputV2rayWSPath

            inputV2rayServerPort "textMainGRPCPort"

            configV2rayGRPCPort=${isV2rayUserPortGRPCInput}   
            configV2rayPortGRPCShowInfo=${isV2rayUserPortGRPCInput}   

            inputV2rayGRPCPath
        fi

    fi
}

function inputV2rayKCPSeedPassword(){ 
    echo
    configV2rayKCPSeedPassword=$(cat /dev/urandom | head -1 | md5sum | head -c 4)

    configV2rayKCPQuicText="KCP的Seed 混淆密码"
    if [[ $1 == "quic" ]]; then
        configV2rayKCPQuicText="QUIC 的key密钥"
    fi 

    read -p "是否自定义${promptInfoXrayName}的 ${configV2rayKCPQuicText}? 直接回车默认创建随机密码, 请输入自定义密码:" isV2rayUserKCPSeedInput
    isV2rayUserKCPSeedInput=${isV2rayUserKCPSeedInput:-${configV2rayKCPSeedPassword}}

    if [[ -z $isV2rayUserKCPSeedInput ]]; then
        echo
    else
        configV2rayKCPSeedPassword=${isV2rayUserKCPSeedInput}
    fi
}


function inputV2rayWSPath(){ 
    echo
    configV2rayWebSocketPath=$(cat /dev/urandom | head -1 | md5sum | head -c 8)

    configV2rayWSH2Text="WS"
    if [[ $1 == "h2" ]]; then
        configV2rayWSH2Text="HTTP2"
    fi 

    read -p "是否自定义${promptInfoXrayName}的 ${configV2rayWSH2Text}的Path? 直接回车默认创建随机路径, 请输入自定义路径(不要输入/):" isV2rayUserWSPathInput
    isV2rayUserWSPathInput=${isV2rayUserWSPathInput:-${configV2rayWebSocketPath}}

    if [[ -z $isV2rayUserWSPathInput ]]; then
        echo
    else
        configV2rayWebSocketPath=${isV2rayUserWSPathInput}
    fi
}

function inputV2rayGRPCPath(){ 
    echo
    configV2rayGRPCServiceName=$(cat /dev/urandom | head -1 | md5sum | head -c 8)

    read -p "是否自定义${promptInfoXrayName}的 gRPC 的serviceName ? 直接回车默认创建随机路径, 请输入自定义路径(不要输入/):" isV2rayUserGRPCPathInput
    isV2rayUserGRPCPathInput=${isV2rayUserGRPCPathInput:-${configV2rayGRPCServiceName}}

    if [[ -z $isV2rayUserGRPCPathInput ]]; then
        echo
    else
        configV2rayGRPCServiceName=${isV2rayUserGRPCPathInput}
    fi
}


function inputV2rayServerPort(){  
    echo
	if [[ $1 == "textMainPort" ]]; then
        green " 是否自定义${promptInfoXrayName}的端口号? 如要支持cloudflare的CDN, 需要使用cloudflare支持的HTTPS端口号 例如 443 8443 2053 2083 2087 2096 端口"
        green " 具体请看cloudflare官方文档 https://developers.cloudflare.com/fundamentals/get-started/network-ports"
        read -p "是否自定义${promptInfoXrayName}的端口号? 直接回车默认为${configV2rayPortShowInfo}, 请输入自定义端口号[1-65535]:" isV2rayUserPortInput
        isV2rayUserPortInput=${isV2rayUserPortInput:-${configV2rayPortShowInfo}}
		checkPortInUse "${isV2rayUserPortInput}" $1 
	fi

	if [[ $1 == "textMainGRPCPort" ]]; then
        green " 如果使用gRPC 协议并要支持cloudflare的CDN, 需要输入 443 端口才可以"
        read -p "是否自定义${promptInfoXrayName} gRPC的端口号? 直接回车默认为${configV2rayPortGRPCShowInfo}, 请输入自定义端口号[1-65535]:" isV2rayUserPortGRPCInput
        isV2rayUserPortGRPCInput=${isV2rayUserPortGRPCInput:-${configV2rayPortGRPCShowInfo}}
		checkPortInUse "${isV2rayUserPortGRPCInput}" $1 
	fi    

	if [[ $1 == "textAdditionalPort" ]]; then
        green " 是否添加一个额外监听端口, 与主端口${configV2rayPort}一起同时工作"
        green " 一般用于 中转机无法使用443端口 使用额外端口中转给目标主机时使用"
        read -p "是否给${promptInfoXrayName}添加额外的监听端口? 直接回车默认否, 请输入额外端口号[1-65535]:" isV2rayAdditionalPortInput
        isV2rayAdditionalPortInput=${isV2rayAdditionalPortInput:-999999}
        checkPortInUse "${isV2rayAdditionalPortInput}" $1 
	fi


    if [[ $1 == "textMainTrojanPort" ]]; then
        green "是否自定义Trojan${promptInfoTrojanName}的端口号? 直接回车默认为${configV2rayTrojanPort}"
        read -p "是否自定义Trojan${promptInfoTrojanName}的端口号? 直接回车默认为${configV2rayTrojanPort}, 请输入自定义端口号[1-65535]:" isTrojanUserPortInput
        isTrojanUserPortInput=${isTrojanUserPortInput:-${configV2rayTrojanPort}}
		checkPortInUse "${isTrojanUserPortInput}" $1 
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


v2rayVmessLinkQR1=""
v2rayVmessLinkQR2=""
v2rayVlessLinkQR1=""
v2rayVlessLinkQR2=""
v2rayPassword1UrlEncoded=""

function rawUrlEncode() {
    # https://stackoverflow.com/questions/296536/how-to-urlencode-data-for-curl-command


    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * )               printf -v o '%%%02x' "'$c"
        esac
        encoded+="${o}"
    done
    echo
    green "== URL Encoded: ${encoded}"    # You can either set a return variable (FASTER) 
    v2rayPassword1UrlEncoded="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

function generateVmessImportLink(){
    # https://github.com/2dust/v2rayN/wiki/%E5%88%86%E4%BA%AB%E9%93%BE%E6%8E%A5%E6%A0%BC%E5%BC%8F%E8%AF%B4%E6%98%8E(ver-2)

    configV2rayVmessLinkConfigTls="tls"
    if [[ "${configV2rayIsTlsShowInfo}" == "none" ]]; then
        configV2rayVmessLinkConfigTls=""
    fi

    configV2rayVmessLinkStreamSetting1="${configV2rayStreamSetting}"
    configV2rayVmessLinkStreamSetting2=""
    if [[ "${configV2rayStreamSetting}" == "wsgrpc" ]]; then
        configV2rayVmessLinkStreamSetting1="ws"
        configV2rayVmessLinkStreamSetting2="grpc"
    fi

    if [[ "${configV2rayWorkingMode}" == "vlessTCPVmessWS" ]]; then
        configV2rayVmessLinkStreamSetting1="ws"
        configV2rayVmessLinkStreamSetting2="tcp"

        configV2rayVmessLinkConfigPath="${configV2rayWebSocketPath}"
        configV2rayVmessLinkConfigPath2="tcp${configV2rayWebSocketPath}" 

        configV2rayVmessLinkConfigTls="tls"      
    fi



    configV2rayVmessLinkConfigHost="${configSSLDomain}"
    if [[ "${configV2rayStreamSetting}" == "quic" ]]; then
        configV2rayVmessLinkConfigHost="none"
    fi

    configV2rayVmessLinkConfigPath=""
    configV2rayVmessLinkConfigPath2=""
    if [[ "${configV2rayStreamSetting}" == "kcp" || "${configV2rayStreamSetting}" == "quic" ]]; then
        configV2rayVmessLinkConfigPath="${configV2rayKCPSeedPassword}"

    elif [[ "${configV2rayStreamSetting}" == "h2" || "${configV2rayStreamSetting}" == "ws" ]]; then
        configV2rayVmessLinkConfigPath="${configV2rayWebSocketPath}"

    elif [[ "${configV2rayStreamSetting}" == "grpc" ]]; then
        configV2rayVmessLinkConfigPath="${configV2rayGRPCServiceName}"

    elif [[ "${configV2rayStreamSetting}" == "wsgrpc" ]]; then
        configV2rayVmessLinkConfigPath="${configV2rayWebSocketPath}"
        configV2rayVmessLinkConfigPath2="${configV2rayGRPCServiceName}"
    fi

    cat > ${configV2rayVmessImportLinkFile1Path} <<-EOF
{
    "v": "2",
    "ps": "${configSSLDomain}_${configV2rayProtocol}_${configV2rayVmessLinkStreamSetting1}",
    "add": "${configSSLDomain}",
    "port": "${configV2rayPortShowInfo}",
    "id": "${v2rayPassword1}",
    "aid": "0",
    "net": "${configV2rayVmessLinkStreamSetting1}",
    "type": "none",
    "host": "${configV2rayVmessLinkConfigHost}",
    "path": "${configV2rayVmessLinkConfigPath}",
    "tls": "${configV2rayVmessLinkConfigTls}",
    "sni": "${configSSLDomain}"
}

EOF

    cat > ${configV2rayVmessImportLinkFile2Path} <<-EOF
{
    "v": "2",
    "ps": "${configSSLDomain}_${configV2rayProtocol}_${configV2rayVmessLinkStreamSetting2}",
    "add": "${configSSLDomain}",
    "port": "${configV2rayPortShowInfo}",
    "id": "${v2rayPassword1}",
    "aid": "0",
    "net": "${configV2rayVmessLinkStreamSetting2}",
    "type": "none",
    "host": "${configV2rayVmessLinkConfigHost}",
    "path": "${configV2rayVmessLinkConfigPath2}",
    "tls": "${configV2rayVmessLinkConfigTls}",
    "sni": "${configSSLDomain}"
}

EOF

    v2rayVmessLinkQR1="vmess://$(cat ${configV2rayVmessImportLinkFile1Path} | base64 -w 0)"
    v2rayVmessLinkQR2="vmess://$(cat ${configV2rayVmessImportLinkFile2Path} | base64 -w 0)"
}

function generateVLessImportLink(){
    # https://github.com/XTLS/Xray-core/discussions/716


    generateVmessImportLink
    rawUrlEncode "${v2rayPassword1}"

    if [[ "${configV2rayStreamSetting}" == "" ]]; then

        configV2rayVlessXtlsFlow="tls"
        if [[ "${configV2rayIsTlsShowInfo}" == "xtls" ]]; then
            configV2rayVlessXtlsFlow="xtls&flow=xtls-rprx-direct"
        fi

        if [[ "$configV2rayWorkingMode" == "vlessgRPC" ]]; then
            cat > ${configV2rayVlessImportLinkFile1Path} <<-EOF
${configV2rayProtocol}://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPortShowInfo}?encryption=none&security=${configV2rayVlessXtlsFlow}&type=grpc&host=${configSSLDomain}&serviceName=%2f${configV2rayGRPCServiceName}#${configSSLDomain}+gRPC_protocol
EOF
        else
            cat > ${configV2rayVlessImportLinkFile1Path} <<-EOF
${configV2rayProtocol}://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPortShowInfo}?encryption=none&security=${configV2rayVlessXtlsFlow}&type=tcp&host=${configSSLDomain}#${configSSLDomain}+TCP_protocol
EOF

            cat > ${configV2rayVlessImportLinkFile2Path} <<-EOF
${configV2rayProtocol}://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPortShowInfo}?encryption=none&security=tls&type=ws&host=${configSSLDomain}&path=%2f${configV2rayWebSocketPath}#${configSSLDomain}+WebSocket_protocol
EOF
        fi

        v2rayVlessLinkQR1="$(cat ${configV2rayVlessImportLinkFile1Path})"
        v2rayVlessLinkQR2="$(cat ${configV2rayVlessImportLinkFile2Path})"
    else

	    if [[ "${configV2rayProtocol}" == "vless" ]]; then

            cat > ${configV2rayVlessImportLinkFile1Path} <<-EOF
${configV2rayProtocol}://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPortShowInfo}?encryption=none&security=${configV2rayIsTlsShowInfo}&type=${configV2rayVmessLinkStreamSetting1}&host=${configSSLDomain}&path=%2f${configV2rayVmessLinkConfigPath}&headerType=none&seed=${configV2rayKCPSeedPassword}&quicSecurity=none&key=${configV2rayKCPSeedPassword}&serviceName=%2f${configV2rayVmessLinkConfigPath}#${configSSLDomain}+${configV2rayVmessLinkStreamSetting1}_protocol
EOF
            cat > ${configV2rayVlessImportLinkFile2Path} <<-EOF
${configV2rayProtocol}://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPortShowInfo}?encryption=none&security=${configV2rayIsTlsShowInfo}&type=${configV2rayVmessLinkStreamSetting2}&host=${configSSLDomain}&path=%2f${configV2rayVmessLinkConfigPath2}&headerType=none&seed=${configV2rayKCPSeedPassword}&quicSecurity=none&key=${configV2rayKCPSeedPassword}&serviceName=%2f${configV2rayVmessLinkConfigPath2}#${configSSLDomain}+${configV2rayVmessLinkStreamSetting1}_protocol
EOF

            v2rayVlessLinkQR1="$(cat ${configV2rayVlessImportLinkFile1Path})"
            v2rayVlessLinkQR2="$(cat ${configV2rayVlessImportLinkFile2Path})"
	    fi

    fi



}




function inputUnlockV2rayServerInfo(){
            echo
            yellow " 请选择可解锁流媒体的V2ray或Xray服务器的协议 "
            green " 1. VLess + TCP + TLS"
            green " 2. VLess + TCP + XTLS"
            green " 3. VLess + WS + TLS (支持CDN)"
            green " 4. VMess + TCP + TLS"
            green " 5. VMess + WS + TLS (支持CDN)"
            echo
            read -p "请选择协议? 直接回车默认选3, 请输入纯数字:" isV2rayUnlockServerProtocolInput
            isV2rayUnlockServerProtocolInput=${isV2rayUnlockServerProtocolInput:-3}

            isV2rayUnlockOutboundServerProtocolText="vless"
            if [[ $isV2rayUnlockServerProtocolInput == "4" || $isV2rayUnlockServerProtocolInput == "5" ]]; then
                isV2rayUnlockOutboundServerProtocolText="vmess"
            fi

            isV2rayUnlockOutboundServerTCPText="tcp"
            unlockOutboundServerWebSocketSettingText=""
            if [[ $isV2rayUnlockServerProtocolInput == "3" ||  $isV2rayUnlockServerProtocolInput == "5" ]]; then
                isV2rayUnlockOutboundServerTCPText="ws"
                echo
                yellow " 请填写可解锁流媒体的V2ray或Xray服务器Websocket Path, 默认为/"
                read -p "请填写Websocket Path? 直接回车默认为/ , 请输入(不要包含/):" isV2rayUnlockServerWSPathInput
                isV2rayUnlockServerWSPathInput=${isV2rayUnlockServerWSPathInput:-""}
                read -r -d '' unlockOutboundServerWebSocketSettingText << EOM
                ,
                "wsSettings": {
                    "path": "/${isV2rayUnlockServerWSPathInput}"
                }
EOM
            fi


            unlockOutboundServerXTLSFlowText=""
            isV2rayUnlockOutboundServerTLSText="tls"
            if [[ $isV2rayUnlockServerProtocolInput == "2" ]]; then
                isV2rayUnlockOutboundServerTCPText="tcp"
                isV2rayUnlockOutboundServerTLSText="xtls"

                echo
                yellow " 请选择可解锁流媒体的V2ray或Xray服务器 XTLS模式下的Flow "
                green " 1. VLess + TCP + XTLS (xtls-rprx-direct) 推荐"
                green " 2. VLess + TCP + XTLS (xtls-rprx-splice) 此项可能会无法连接"
                read -p "请选择Flow 参数? 直接回车默认选1, 请输入纯数字:" isV2rayUnlockServerFlowInput
                isV2rayUnlockServerFlowInput=${isV2rayUnlockServerFlowInput:-1}

                unlockOutboundServerXTLSFlowValue="xtls-rprx-direct"
                if [[ $isV2rayUnlockServerFlowInput == "1" ]]; then
                    unlockOutboundServerXTLSFlowValue="xtls-rprx-direct"
                else
                    unlockOutboundServerXTLSFlowValue="xtls-rprx-splice"
                fi
                read -r -d '' unlockOutboundServerXTLSFlowText << EOM
                                "flow": "${unlockOutboundServerXTLSFlowValue}",
EOM
            fi


            echo
            yellow " 请填写可解锁流媒体的V2ray或Xray服务器地址, 例如 www.example.com"
            read -p "请填写可解锁流媒体服务器地址? 直接回车默认为本机, 请输入:" isV2rayUnlockServerDomainInput
            isV2rayUnlockServerDomainInput=${isV2rayUnlockServerDomainInput:-127.0.0.1}

            echo
            yellow " 请填写可解锁流媒体的V2ray或Xray服务器端口号, 例如 443"
            read -p "请填写可解锁流媒体服务器地址? 直接回车默认为443, 请输入:" isV2rayUnlockServerPortInput
            isV2rayUnlockServerPortInput=${isV2rayUnlockServerPortInput:-443}

            echo
            yellow " 请填写可解锁流媒体的V2ray或Xray服务器的用户UUID, 例如 4aeaf80d-f89e-46a2-b3dc-bb815eae75ba"
            read -p "请填写用户UUID? 直接回车默认为111, 请输入:" isV2rayUnlockServerUserIDInput
            isV2rayUnlockServerUserIDInput=${isV2rayUnlockServerUserIDInput:-111}



            read -r -d '' v2rayConfigOutboundV2rayServerInput << EOM
        {
            "tag": "V2Ray_out",
            "protocol": "${isV2rayUnlockOutboundServerProtocolText}",
            "settings": {
                "vnext": [
                    {
                        "address": "${isV2rayUnlockServerDomainInput}",
                        "port": ${isV2rayUnlockServerPortInput},
                        "users": [
                            {
                                "id": "${isV2rayUnlockServerUserIDInput}",
                                "encryption": "none",
                                ${unlockOutboundServerXTLSFlowText}
                                "level": 0
                            }
                        ]
                    }
                ]
            },
            "streamSettings": {
                "network": "${isV2rayUnlockOutboundServerTCPText}",
                "security": "${isV2rayUnlockOutboundServerTLSText}",
                "${isV2rayUnlockOutboundServerTLSText}Settings": {
                    "serverName": "${isV2rayUnlockServerDomainInput}"
                }
                ${unlockOutboundServerWebSocketSettingText}
            }
        },
EOM
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


    if [[ ( $configV2rayWorkingMode == "trojan" ) || ( $configV2rayWorkingMode == "vlessTCPVmessWS" ) || ( $configV2rayWorkingMode == "vlessTCPWS" ) || ( $configV2rayWorkingMode == "vlessTCPWSgRPC" ) || ( $configV2rayWorkingMode == "vlessTCPWSTrojan" ) || ( $configV2rayWorkingMode == "sni" ) ]]; then
        echo
        green " 是否使用XTLS代替TLS加密, XTLS是Xray特有的加密方式, 速度更快, 默认使用TLS加密"
        green " 由于V2ray不支持XTLS, 如果选择XTLS加密将使用Xray内核提供服务"
        read -p "是否使用XTLS? 直接回车默认为TLS加密, 请输入[y/N]:" isXrayXTLSInput
        isXrayXTLSInput=${isXrayXTLSInput:-n}

        if [[ $isXrayXTLSInput == [Yy] ]]; then
            promptInfoXrayName="xray"
            isXray="yes"
            configV2rayIsTlsShowInfo="xtls"
        else
            read -p "是否使用Xray内核? 直接回车默认为V2ray内核, 请输入[y/N]:" isV2rayOrXrayCoreInput
            isV2rayOrXrayCoreInput=${isV2rayOrXrayCoreInput:-n}

            if [[ $isV2rayOrXrayCoreInput == [Yy] ]]; then
                promptInfoXrayName="xray"
                isXray="yes"
            fi        
        fi
    else
        read -p "是否使用Xray内核? 直接回车默认为V2ray内核, 请输入[y/N]:" isV2rayOrXrayCoreInput
        isV2rayOrXrayCoreInput=${isV2rayOrXrayCoreInput:-n}

        if [[ $isV2rayOrXrayCoreInput == [Yy] ]]; then
            promptInfoXrayName="xray"
            isXray="yes"
        fi
    fi


    if [[ -n "${configV2rayWorkingMode}" ]]; then
    
        if [[ "${configV2rayWorkingMode}" != "sni" ]]; then
            configV2rayProtocol="vless"

            configV2rayPort=443
            configV2rayPortShowInfo=$configV2rayPort

            inputV2rayServerPort "textMainPort"
            configV2rayPort=${isV2rayUserPortInput}   
            configV2rayPortShowInfo=${isV2rayUserPortInput} 

        else
            configV2rayProtocol="vless"

            configV2rayPortShowInfo=443
            configV2rayPortGRPCShowInfo=443
        fi

    else
        echo
        read -p "是否使用VLESS协议? 直接回车默认为VMess协议, 请输入[y/N]:" isV2rayUseVLessInput
        isV2rayUseVLessInput=${isV2rayUseVLessInput:-n}

        if [[ $isV2rayUseVLessInput == [Yy] ]]; then
            configV2rayProtocol="vless"
        else
            configV2rayProtocol="vmess"
        fi

        
        if [[ ${configInstallNginxMode} == "v2raySSL" ]]; then
            configV2rayPortShowInfo=443
            configV2rayPortGRPCShowInfo=443

        else
            if [[ ${configV2rayWorkingNotChangeMode} == "true" ]]; then
                configV2rayPortShowInfo=443
                configV2rayPortGRPCShowInfo=443

            else
                configV2rayIsTlsShowInfo="none"

                configV2rayPort="$(($RANDOM + 10000))"
                configV2rayPortShowInfo=$configV2rayPort

                inputV2rayServerPort "textMainPort"
                configV2rayPort=${isV2rayUserPortInput}   
                configV2rayPortShowInfo=${isV2rayUserPortInput}  

                inputV2rayStreamSettings
            fi


        fi
    fi

    if [[ "$configV2rayWorkingMode" == "sni" ]] ; then
        configSSLCertPath="${configNginxSNIDomainV2rayCertPath}"
        configSSLDomain=${configNginxSNIDomainV2ray}
    fi

    
    # 增加任意门
    if [[ ${configInstallNginxMode} == "v2raySSL" ]]; then
        echo
    else
        
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
                "destOverride": ["http", "tls", "quic"]
            }
        }     
EOM

        fi
    fi



    echo
    read -p "是否自定义${promptInfoXrayName}的密码? 直接回车默认创建随机密码, 请输入自定义UUID密码:" isV2rayUserPassordInput
    isV2rayUserPassordInput=${isV2rayUserPassordInput:-''}

    if [ -z "${isV2rayUserPassordInput}" ]; then
        isV2rayUserPassordInput=""
    else
        v2rayPassword1=${isV2rayUserPassordInput}
    fi














    echo
    echo
    isV2rayUnlockWarpModeInput="1"
    V2rayDNSUnlockText="AsIs"
    V2rayUnlockVideoSiteOutboundTagText=""
    unlockWARPServerIpInput="127.0.0.1"
    unlockWARPServerPortInput="40000"
    green " =================================================="
    yellow " 是否要解锁 Netflix HBO Disney+ 等流媒体网站"
    read -p "是否要解锁流媒体网站? 直接回车默认不解锁, 请输入[y/N]:" isV2rayUnlockStreamWebsiteInput
    isV2rayUnlockStreamWebsiteInput=${isV2rayUnlockStreamWebsiteInput:-n}

    if [[ $isV2rayUnlockStreamWebsiteInput == [Yy] ]]; then





    echo
    green " =================================================="
    yellow " 是否使用 DNS 解锁 Netflix HBO Disney+ 等流媒体网站"
    green " 如需解锁请填入 解锁 Netflix 的DNS服务器的IP地址, 例如 8.8.8.8"
    read -p "是否使用DNS解锁流媒体? 直接回车默认不解锁, 解锁请输入DNS服务器的IP地址:" isV2rayUnlockDNSInput
    isV2rayUnlockDNSInput=${isV2rayUnlockDNSInput:-n}

    V2rayDNSUnlockText="AsIs"
    v2rayConfigDNSInput=""

    if [[ $isV2rayUnlockDNSInput == [Nn] ]]; then
        V2rayDNSUnlockText="AsIs"
    else
        V2rayDNSUnlockText="UseIP"
        read -r -d '' v2rayConfigDNSInput << EOM
    "dns": {
        "servers": [
            {
                "address": "${isV2rayUnlockDNSInput}",
                "port": 53,
                "domains": [
                    "geosite:netflix",
                    "geosite:youtube",
                    "geosite:bahamut",
                    "geosite:hulu",
                    "geosite:hbo",
                    "geosite:disney",
                    "geosite:bbc",
                    "geosite:4chan",
                    "geosite:fox",
                    "geosite:abema",
                    "geosite:dmm",
                    "geosite:niconico",
                    "geosite:pixiv",
                    "geosite:bilibili",
                    "geosite:viu",
                    "geosite:pornhub"
                ]
            },
        "localhost"
        ]
    }, 
EOM

    fi



    echo
    echo
    green " =================================================="
    yellow " 是否使用 Cloudflare WARP 解锁 Netflix 等流媒体网站"
    echo
    green " 1. 不使用解锁"
    green " 2. 使用 WARP Sock5 代理解锁 推荐使用"
    green " 3. 使用 WARP IPv6 解锁"
    green " 4. 通过转发到可解锁的v2ray或xray服务器解锁"
    echo
    green " 默认选1 不解锁. 选择2,3解锁需要安装好 Wireguard 与 Cloudflare WARP, 可重新运行本脚本选择第一项安装".
    red " 推荐先安装 Wireguard 与 Cloudflare WARP 后,再安装v2ray或xray. 实际上先安装v2ray或xray, 后安装Wireguard 与 Cloudflare WARP也没问题"
    red " 但如果先安装v2ray或xray, 选了解锁google或其他流媒体, 那么会暂时无法访问google和其他视频网站, 需要继续安装Wireguard 与 Cloudflare WARP解决"
    echo
    read -p "请输入? 直接回车默认选1 不解锁, 请输入纯数字:" isV2rayUnlockWarpModeInput
    isV2rayUnlockWarpModeInput=${isV2rayUnlockWarpModeInput:-1}
    
    V2rayUnlockVideoSiteRuleText=""
    V2rayUnlockGoogleRuleText=""
    
    v2rayConfigRouteInput=""
    V2rayUnlockVideoSiteOutboundTagText=""
    unlockWARPServerIpInput="127.0.0.1"
    unlockWARPServerPortInput="40000"
    configWARPPortFilePath="${HOME}/wireguard/warp-port"
    configWARPPortLocalServerPort="40000"
    configWARPPortLocalServerText=""

    if [[ -f "${configWARPPortFilePath}" ]]; then
        configWARPPortLocalServerPort="$(cat ${configWARPPortFilePath})"
        configWARPPortLocalServerText="检测到本机已安装 WARP Sock5, 端口号 ${configWARPPortLocalServerPort}"
    fi

    if [[ $isV2rayUnlockWarpModeInput == "1" ]]; then
        echo
    else
        if [[ $isV2rayUnlockWarpModeInput == "2" ]]; then
            V2rayUnlockVideoSiteOutboundTagText="WARP_out"

            echo
            read -p "请输入WARP Sock5 代理服务器地址? 直接回车默认本机 127.0.0.1, 请输入:" unlockWARPServerIpInput
            unlockWARPServerIpInput=${unlockWARPServerIpInput:-127.0.0.1}

            echo
            yellow " ${configWARPPortLocalServerText}"
            read -p "请输入WARP Sock5 代理服务器端口号? 直接回车默认${configWARPPortLocalServerPort}, 请输入纯数字:" unlockWARPServerPortInput
            unlockWARPServerPortInput=${unlockWARPServerPortInput:-$configWARPPortLocalServerPort}

        elif [[ $isV2rayUnlockWarpModeInput == "3" ]]; then

            V2rayUnlockVideoSiteOutboundTagText="IPv6_out"

        elif [[ $isV2rayUnlockWarpModeInput == "4" ]]; then

            echo
            green " 已选择4 通过转发到可解锁的v2ray或xray服务器解锁"
            green " 可自行修改v2ray或xray配置, 在 outbounds 字段中增加一个tag为 V2Ray_out 的可解锁的v2ray服务器"

            V2rayUnlockVideoSiteOutboundTagText="V2Ray_out"

            inputUnlockV2rayServerInfo
        fi



        echo
        echo
        green " =================================================="
        yellow " 请选择要解锁的流媒体网站:"
        echo
        green " 1. 不解锁"
        green " 2. 解锁 Netflix 限制"
        green " 3. 解锁 Youtube 和 Youtube Premium"
        green " 4. 解锁 Pornhub, 解决视频变成玉米无法观看问题"
        green " 5. 同时解锁 Netflix 和 Pornhub 限制"
        green " 6. 同时解锁 Netflix, Youtube 和 Pornhub 限制"
        green " 7. 同时解锁 Netflix, Hulu, HBO, Disney 和 Pornhub 限制"
        green " 8. 同时解锁 Netflix, Hulu, HBO, Disney, Youtube 和 Pornhub 限制"
        green " 9. 解锁 全部流媒体 包括 Netflix, Youtube, Hulu, HBO, Disney, BBC, Fox, niconico, dmm, Pornhub 等"
        echo
        read -p "请输入解锁选项? 直接回车默认选1 不解锁, 请输入纯数字:" isV2rayUnlockVideoSiteInput
        isV2rayUnlockVideoSiteInput=${isV2rayUnlockVideoSiteInput:-1}

        if [[ $isV2rayUnlockVideoSiteInput == "2" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:netflix\""
            
        elif [[ $isV2rayUnlockVideoSiteInput == "3" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:youtube\""

        elif [[ $isV2rayUnlockVideoSiteInput == "4" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:pornhub\""

        elif [[ $isV2rayUnlockVideoSiteInput == "5" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:netflix\", \"geosite:pornhub\""

        elif [[ $isV2rayUnlockVideoSiteInput == "6" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:netflix\", \"geosite:youtube\", \"geosite:pornhub\""

        elif [[ $isV2rayUnlockVideoSiteInput == "7" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:netflix\", \"geosite:hulu\", \"geosite:hbo\", \"geosite:disney\", \"geosite:pornhub\""

        elif [[ $isV2rayUnlockVideoSiteInput == "8" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:netflix\", \"geosite:youtube\", \"geosite:hulu\", \"geosite:hbo\", \"geosite:disney\", \"geosite:pornhub\""

        elif [[ $isV2rayUnlockVideoSiteInput == "9" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:netflix\", \"geosite:youtube\", \"geosite:bahamut\", \"geosite:hulu\", \"geosite:hbo\", \"geosite:disney\", \"geosite:bbc\", \"geosite:4chan\", \"geosite:fox\", \"geosite:abema\", \"geosite:dmm\", \"geosite:niconico\", \"geosite:pixiv\", \"geosite:viu\", \"geosite:pornhub\""

        fi

    fi





    echo
    yellow " 某大佬提供了可以解锁Netflix新加坡区的V2ray服务器, 不保证一直可用"
    read -p "是否通过神秘力量解锁Netflix新加坡区? 直接回车默认不解锁, 请输入[y/N]:" isV2rayUnlockGoNetflixInput
    isV2rayUnlockGoNetflixInput=${isV2rayUnlockGoNetflixInput:-n}

    v2rayConfigRouteGoNetflixInput=""
    v2rayConfigOutboundV2rayGoNetflixServerInput=""
    if [[ $isV2rayUnlockGoNetflixInput == [Nn] ]]; then
        echo
    else
        removeString="\"geosite:netflix\", "
        V2rayUnlockVideoSiteRuleText=${V2rayUnlockVideoSiteRuleText#"$removeString"}
        read -r -d '' v2rayConfigRouteGoNetflixInput << EOM
            {
                "type": "field",
                "outboundTag": "GoNetflix",
                "domain": [ "geosite:netflix" ] 
            },
EOM

        read -r -d '' v2rayConfigOutboundV2rayGoNetflixServerInput << EOM
        {
            "tag": "GoNetflix",
            "protocol": "vmess",
            "streamSettings": {
                "network": "ws",
                "security": "tls",
                "tlsSettings": {
                    "allowInsecure": false
                },
                "wsSettings": {
                    "path": "ws"
                }
            },
            "mux": {
                "enabled": true,
                "concurrency": 8
            },
            "settings": {
                "vnext": [{
                    "address": "free-sg-01.gonetflix.xyz",
                    "port": 443,
                    "users": [
                        { "id": "402d7490-6d4b-42d4-80ed-e681b0e6f1f9", "security": "auto", "alterId": 0 }
                    ]
                }]
            }
        },
EOM
    fi







    fi




    echo
    green " =================================================="
    yellow " 请选择 避免弹出 Google reCAPTCHA 人机验证的方式"
    echo
    green " 1. 不解锁"
    green " 2. 使用 WARP Sock5 代理解锁"
    green " 3. 使用 WARP IPv6 解锁 推荐使用"
    green " 4. 通过转发到可解锁的v2ray或xray服务器解锁"
    echo
    read -p "请输入解锁选项? 直接回车默认选1 不解锁, 请输入纯数字:" isV2rayUnlockGoogleInput
    isV2rayUnlockGoogleInput=${isV2rayUnlockGoogleInput:-1}

    if [[ "${isV2rayUnlockWarpModeInput}" == "${isV2rayUnlockGoogleInput}" ]]; then
        V2rayUnlockVideoSiteRuleText+=", \"geosite:google\" "
        V2rayUnlockVideoSiteRuleTextFirstChar="${V2rayUnlockVideoSiteRuleText:0:1}"

        if [[ $V2rayUnlockVideoSiteRuleTextFirstChar == "," ]]; then
            V2rayUnlockVideoSiteRuleText="${V2rayUnlockVideoSiteRuleText:1}"
        fi

        # 修复一个都不解锁的bug 都选1的bug
        if [[ -z "${V2rayUnlockVideoSiteOutboundTagText}" ]]; then
            V2rayUnlockVideoSiteOutboundTagText="IPv6_out"
            V2rayUnlockVideoSiteRuleText="\"test.com\""
        fi

        read -r -d '' v2rayConfigRouteInput << EOM
    "routing": {
        "rules": [
            ${v2rayConfigRouteGoNetflixInput}
            {
                "type": "field",
                "outboundTag": "${V2rayUnlockVideoSiteOutboundTagText}",
                "domain": [${V2rayUnlockVideoSiteRuleText}] 
            },
            {
                "type": "field",
                "outboundTag": "IPv4_out",
                "network": "udp,tcp"
            }
        ]
    },
EOM

    else
        V2rayUnlockGoogleRuleText="\"geosite:google\""

        if [[ $isV2rayUnlockGoogleInput == "2" ]]; then
            V2rayUnlockGoogleOutboundTagText="WARP_out"
            echo
            read -p "请输入WARP Sock5 代理服务器地址? 直接回车默认本机 127.0.0.1, 请输入:" unlockWARPServerIpInput
            unlockWARPServerIpInput=${unlockWARPServerIpInput:-127.0.0.1}

            echo
            yellow " ${configWARPPortLocalServerText}"
            read -p "请输入WARP Sock5 代理服务器端口号? 直接回车默认${configWARPPortLocalServerPort}, 请输入纯数字:" unlockWARPServerPortInput
            unlockWARPServerPortInput=${unlockWARPServerPortInput:-$configWARPPortLocalServerPort}       

        elif [[ $isV2rayUnlockGoogleInput == "3" ]]; then
            V2rayUnlockGoogleOutboundTagText="IPv6_out"

        elif [[ $isV2rayUnlockGoogleInput == "4" ]]; then
            V2rayUnlockGoogleOutboundTagText="V2Ray_out"
            inputUnlockV2rayServerInfo
        else
            V2rayUnlockGoogleOutboundTagText="IPv4_out"
        fi

        # 修复一个都不解锁的bug 都选1的bug
        if [[ -z "${V2rayUnlockVideoSiteOutboundTagText}" ]]; then
            V2rayUnlockVideoSiteOutboundTagText="IPv6_out"
            V2rayUnlockVideoSiteRuleText="\"test.com\""
        fi
        
        read -r -d '' v2rayConfigRouteInput << EOM
    "routing": {
        "rules": [
            ${v2rayConfigRouteGoNetflixInput}
            {
                "type": "field",
                "outboundTag": "${V2rayUnlockGoogleOutboundTagText}",
                "domain": [${V2rayUnlockGoogleRuleText}] 
            },
            {
                "type": "field",
                "outboundTag": "${V2rayUnlockVideoSiteOutboundTagText}",
                "domain": [${V2rayUnlockVideoSiteRuleText}] 
            },
            {
                "type": "field",
                "outboundTag": "IPv4_out",
                "network": "udp,tcp"
            }
        ]
    },
EOM
    fi


    read -r -d '' v2rayConfigOutboundInput << EOM
    "outbounds": [
        {
            "tag":"IPv4_out",
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "${V2rayDNSUnlockText}"
            }
        },        
        {
            "tag": "blocked",
            "protocol": "blackhole",
            "settings": {}
        },

        ${v2rayConfigOutboundV2rayServerInput}
        ${v2rayConfigOutboundV2rayGoNetflixServerInput}
        {
            "tag":"IPv6_out",
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv6" 
            }
        },
        {
            "tag": "WARP_out",
            "protocol": "socks",
            "settings": {
                "servers": [
                    {
                        "address": "${unlockWARPServerIpInput}",
                        "port": ${unlockWARPServerPortInput}
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp"
            }
        }
    ]

EOM












    echo
    green " =================================================="
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

    downloadV2rayXrayBin


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

    if [ "${isTrojanMultiPassword}" = "no" ] ; then
    read -r -d '' v2rayConfigUserpasswordTrojanInput << EOM
                    {
                        "password": "${trojanPassword1}", "level": 0, "email": "password111@gmail.com"
                    },
                    {
                        "password": "${trojanPassword2}", "level": 0, "email": "password112@gmail.com"
                    },
                    {
                        "password": "${trojanPassword3}", "level": 0, "email": "password113@gmail.com"
                    },
                    {
                        "password": "${trojanPassword4}", "level": 0, "email": "password114@gmail.com"
                    },
                    {
                        "password": "${trojanPassword5}", "level": 0, "email": "password115@gmail.com"
                    },
                    {
                        "password": "${trojanPassword6}", "level": 0, "email": "password116@gmail.com"
                    },
                    {
                        "password": "${trojanPassword7}", "level": 0, "email": "password117@gmail.com"
                    },
                    {
                        "password": "${trojanPassword8}", "level": 0, "email": "password118@gmail.com"
                    },
                    {
                        "password": "${trojanPassword9}", "level": 0, "email": "password119@gmail.com"
                    },
                    {
                        "password": "${trojanPassword10}", "level": 0, "email": "password120@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202001", "level": 0, "email": "password201@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202002", "level": 0, "email": "password202@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202003", "level": 0, "email": "password203@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202004", "level": 0, "email": "password204@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202005", "level": 0, "email": "password205@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202006", "level": 0, "email": "password206@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202007", "level": 0, "email": "password207@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202008", "level": 0, "email": "password208@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202009", "level": 0, "email": "password209@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202010", "level": 0, "email": "password210@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202011", "level": 0, "email": "password211@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202012", "level": 0, "email": "password212@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202013", "level": 0, "email": "password213@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202014", "level": 0, "email": "password214@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202015", "level": 0, "email": "password215@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202016", "level": 0, "email": "password216@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202017", "level": 0, "email": "password217@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202018", "level": 0, "email": "password218@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202019", "level": 0, "email": "password219@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202020", "level": 0, "email": "password220@gmail.com"
                    }
EOM
    else

    read -r -d '' v2rayConfigUserpasswordTrojanInput << EOM
                    {
                        "password": "${trojanPassword1}", "level": 0, "email": "password111@gmail.com"
                    },
                    {
                        "password": "${trojanPassword2}", "level": 0, "email": "password112@gmail.com"
                    },
                    {
                        "password": "${trojanPassword3}", "level": 0, "email": "password113@gmail.com"
                    },
                    {
                        "password": "${trojanPassword4}", "level": 0, "email": "password114@gmail.com"
                    },
                    {
                        "password": "${trojanPassword5}", "level": 0, "email": "password115@gmail.com"
                    },
                    {
                        "password": "${trojanPassword6}", "level": 0, "email": "password116@gmail.com"
                    },
                    {
                        "password": "${trojanPassword7}", "level": 0, "email": "password117@gmail.com"
                    },
                    {
                        "password": "${trojanPassword8}", "level": 0, "email": "password118@gmail.com"
                    },
                    {
                        "password": "${trojanPassword9}", "level": 0, "email": "password119@gmail.com"
                    },
                    {
                        "password": "${trojanPassword10}", "level": 0, "email": "password120@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202000", "level": 0, "email": "password200@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202001", "level": 0, "email": "password201@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202002", "level": 0, "email": "password202@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202003", "level": 0, "email": "password203@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202004", "level": 0, "email": "password204@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202005", "level": 0, "email": "password205@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202006", "level": 0, "email": "password206@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202007", "level": 0, "email": "password207@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202008", "level": 0, "email": "password208@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202009", "level": 0, "email": "password209@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202010", "level": 0, "email": "password210@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202011", "level": 0, "email": "password211@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202012", "level": 0, "email": "password212@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202013", "level": 0, "email": "password213@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202014", "level": 0, "email": "password214@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202015", "level": 0, "email": "password215@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202016", "level": 0, "email": "password216@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202017", "level": 0, "email": "password217@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202018", "level": 0, "email": "password218@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202019", "level": 0, "email": "password219@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202020", "level": 0, "email": "password220@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202021", "level": 0, "email": "password221@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202022", "level": 0, "email": "password222@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202023", "level": 0, "email": "password223@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202024", "level": 0, "email": "password224@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202025", "level": 0, "email": "password225@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202026", "level": 0, "email": "password226@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202027", "level": 0, "email": "password227@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202028", "level": 0, "email": "password228@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202029", "level": 0, "email": "password229@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202030", "level": 0, "email": "password230@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202031", "level": 0, "email": "password231@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202032", "level": 0, "email": "password232@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202033", "level": 0, "email": "password233@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202034", "level": 0, "email": "password234@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202035", "level": 0, "email": "password235@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202036", "level": 0, "email": "password236@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202037", "level": 0, "email": "password237@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202038", "level": 0, "email": "password238@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202039", "level": 0, "email": "password239@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202040", "level": 0, "email": "password240@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202041", "level": 0, "email": "password241@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202042", "level": 0, "email": "password242@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202043", "level": 0, "email": "password243@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202044", "level": 0, "email": "password244@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202045", "level": 0, "email": "password245@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202046", "level": 0, "email": "password246@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202047", "level": 0, "email": "password247@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202048", "level": 0, "email": "password248@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202049", "level": 0, "email": "password249@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202050", "level": 0, "email": "password250@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202051", "level": 0, "email": "password251@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202052", "level": 0, "email": "password252@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202053", "level": 0, "email": "password253@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202054", "level": 0, "email": "password254@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202055", "level": 0, "email": "password255@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202056", "level": 0, "email": "password256@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202057", "level": 0, "email": "password257@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202058", "level": 0, "email": "password258@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202059", "level": 0, "email": "password259@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202060", "level": 0, "email": "password260@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202061", "level": 0, "email": "password261@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202062", "level": 0, "email": "password262@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202063", "level": 0, "email": "password263@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202064", "level": 0, "email": "password264@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202065", "level": 0, "email": "password265@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202066", "level": 0, "email": "password266@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202067", "level": 0, "email": "password267@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202068", "level": 0, "email": "password268@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202069", "level": 0, "email": "password269@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202070", "level": 0, "email": "password270@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202071", "level": 0, "email": "password271@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202072", "level": 0, "email": "password272@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202073", "level": 0, "email": "password273@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202074", "level": 0, "email": "password274@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202075", "level": 0, "email": "password275@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202076", "level": 0, "email": "password276@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202077", "level": 0, "email": "password277@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202078", "level": 0, "email": "password278@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202079", "level": 0, "email": "password279@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202080", "level": 0, "email": "password280@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202081", "level": 0, "email": "password281@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202082", "level": 0, "email": "password282@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202083", "level": 0, "email": "password283@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202084", "level": 0, "email": "password284@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202085", "level": 0, "email": "password285@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202086", "level": 0, "email": "password286@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202087", "level": 0, "email": "password287@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202088", "level": 0, "email": "password288@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202089", "level": 0, "email": "password289@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202090", "level": 0, "email": "password290@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202091", "level": 0, "email": "password291@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202092", "level": 0, "email": "password292@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202093", "level": 0, "email": "password293@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202094", "level": 0, "email": "password294@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202095", "level": 0, "email": "password295@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202096", "level": 0, "email": "password296@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202097", "level": 0, "email": "password297@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202098", "level": 0, "email": "password298@gmail.com"
                    },
                    {
                        "password": "${configTrojanPasswordPrefixInput}202099", "level": 0, "email": "password299@gmail.com"
                    }

EOM
    fi

    if [[ "${configV2rayIsTlsShowInfo}" == "xtls"  ]]; then
    read -r -d '' v2rayConfigUserpasswordInput << EOM
                    {
                        "id": "${v2rayPassword1}", "flow": "xtls-rprx-direct", "level": 0, "email": "password11@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword2}", "flow": "xtls-rprx-direct", "level": 0, "email": "password12@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword3}", "flow": "xtls-rprx-direct", "level": 0, "email": "password13@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword4}", "flow": "xtls-rprx-direct", "level": 0, "email": "password14@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword5}", "flow": "xtls-rprx-direct", "level": 0, "email": "password15@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword6}", "flow": "xtls-rprx-direct", "level": 0, "email": "password16@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword7}", "flow": "xtls-rprx-direct", "level": 0, "email": "password17@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword8}", "flow": "xtls-rprx-direct", "level": 0, "email": "password18@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword9}", "flow": "xtls-rprx-direct", "level": 0, "email": "password19@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword10}", "flow": "xtls-rprx-direct", "level": 0, "email": "password20@gmail.com"
                    }
EOM

    else
    read -r -d '' v2rayConfigUserpasswordInput << EOM
                    {
                        "id": "${v2rayPassword1}", "level": 0, "email": "password11@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword2}", "level": 0, "email": "password12@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword3}", "level": 0, "email": "password13@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword4}", "level": 0, "email": "password14@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword5}", "level": 0, "email": "password15@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword6}", "level": 0, "email": "password16@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword7}", "level": 0, "email": "password17@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword8}", "level": 0, "email": "password18@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword9}", "level": 0, "email": "password19@gmail.com"
                    },
                    {
                        "id": "${v2rayPassword10}", "level": 0, "email": "password20@gmail.com"
                    }
EOM

    fi










    v2rayConfigInboundInput=""

    if [[ "${configV2rayStreamSetting}" == "grpc" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM

    "inbounds": [
        {
            "port": ${configV2rayGRPCPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "grpc",
                "security": "none",
                "grpcSettings": {
                    "serviceName": "${configV2rayGRPCServiceName}" 
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],

EOM

    elif [[ "${configV2rayStreamSetting}" == "ws" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM

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
                "security": "none",
                "wsSettings": {
                    "path": "/${configV2rayWebSocketPath}"
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],

EOM


    elif [[ "${configV2rayStreamSetting}" == "wsgrpc" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM

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
                "security": "none",
                "wsSettings": {
                    "path": "/${configV2rayWebSocketPath}"
                }
            }
        },
        {
            "port": ${configV2rayGRPCPort},
            "protocol": "${configV2rayProtocol}",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "grpc",
                "security": "none",
                "grpcSettings": {
                    "serviceName": "${configV2rayGRPCServiceName}" 
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],

EOM

    elif [[ "${configV2rayStreamSetting}" == "tcp" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM

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
                "network": "tcp",
                "security": "none",
                "tcpSettings": {
                    "acceptProxyProtocol": false,
                    "header": {
                        "type": "none"
                    }
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],

EOM


    elif [[ "${configV2rayStreamSetting}" == "kcp" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM

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
                "network": "kcp",
                "security": "none",
                "kcpSettings": {
                    "seed": "${configV2rayKCPSeedPassword}"
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],

EOM

    elif [[ "${configV2rayStreamSetting}" == "h2" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM

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
                "network": "h2",
                "security": "none",
                "httpSettings": {
                    "path": "/${configV2rayWebSocketPath}"
                }            
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],

EOM

    elif [[ "${configV2rayStreamSetting}" == "quic" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM

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
                "network": "quic",
                "security": "none",
                "quicSettings": {
                    "security": "aes-128-gcm",
                    "key": "${configV2rayKCPSeedPassword}",
                    "header": {
                        "type": "none"
                    }
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],

EOM

    fi









    if [[ "$configV2rayWorkingMode" == "vlessTCPVmessWS" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM
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
                "security": "${configV2rayIsTlsShowInfo}",
                "${configV2rayIsTlsShowInfo}Settings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "${configSSLCertPath}/$configSSLCertFullchainFilename",
                            "keyFile": "${configSSLCertPath}/$configSSLCertKeyFilename"
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
EOM 

    elif [[ "$configV2rayWorkingMode" == "vlessgRPC" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM
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
                    }
                ]
            },
            "streamSettings": {
                "network": "grpc",
                "security": "tls",
                "tlsSettings": {
                    "alpn": [
                        "h2", 
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "${configSSLCertPath}/$configSSLCertFullchainFilename",
                            "keyFile": "${configSSLCertPath}/$configSSLCertKeyFilename"
                        }
                    ]
                },
                "grpcSettings": {
                    "serviceName": "${configV2rayGRPCServiceName}"
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],
EOM


    elif [[ $configV2rayWorkingMode == "vlessTCPWS" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM
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
                "security": "${configV2rayIsTlsShowInfo}",
                "${configV2rayIsTlsShowInfo}Settings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "${configSSLCertPath}/$configSSLCertFullchainFilename",
                            "keyFile": "${configSSLCertPath}/$configSSLCertKeyFilename"
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
EOM


    elif [[ "$configV2rayWorkingMode" == "vlessTCPWSgRPC" || "$configV2rayWorkingMode" == "sni" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM
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
                        "path": "/${configV2rayGRPCServiceName}",
                        "dest": ${configV2rayGRPCPort},
                        "xver": 1
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "${configV2rayIsTlsShowInfo}",
                "${configV2rayIsTlsShowInfo}Settings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "${configSSLCertPath}/$configSSLCertFullchainFilename",
                            "keyFile": "${configSSLCertPath}/$configSSLCertKeyFilename"
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
        },
        {
            "port": ${configV2rayGRPCPort},
            "protocol": "vless",
            "settings": {
                "clients": [
                    ${v2rayConfigUserpasswordInput}
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "grpc",
                "security": "none",
                "grpcSettings": {
                    "serviceName": "${configV2rayGRPCServiceName}"
                }
            }
        }
        ${v2rayConfigAdditionalPortInput}
    ],
EOM


    elif [[  $configV2rayWorkingMode == "vlessTCPWSTrojan" ]]; then

        read -r -d '' v2rayConfigInboundInput << EOM
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
                "security": "${configV2rayIsTlsShowInfo}",
                "${configV2rayIsTlsShowInfo}Settings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "${configSSLCertPath}/$configSSLCertFullchainFilename",
                            "keyFile": "${configSSLCertPath}/$configSSLCertKeyFilename"
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
EOM



    elif [[ $configV2rayWorkingMode == "trojan" ]]; then
read -r -d '' v2rayConfigInboundInput << EOM
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
                "security": "${configV2rayIsTlsShowInfo}",
                "${configV2rayIsTlsShowInfo}Settings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "${configSSLCertPath}/$configSSLCertFullchainFilename",
                            "keyFile": "${configSSLCertPath}/$configSSLCertKeyFilename"
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
EOM

    fi



    cat > ${configV2rayPath}/config.json <<-EOF
{
    "log" : {
        "access": "${configV2rayAccessLogFilePath}",
        "error": "${configV2rayErrorLogFilePath}",
        "loglevel": "warning"
    },
    ${v2rayConfigDNSInput}
    ${v2rayConfigInboundInput}
    ${v2rayConfigRouteInput}
    ${v2rayConfigOutboundInput}
}
EOF















    # 增加 V2ray启动脚本
    if [ "$isXray" = "no" ] ; then
    
        cat > ${osSystemMdPath}${promptInfoXrayName}${promptInfoXrayNameServiceName}.service <<-EOF
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
        cat > ${osSystemMdPath}${promptInfoXrayName}${promptInfoXrayNameServiceName}.service <<-EOF
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
    ${sudoCmd} chmod +x ${osSystemMdPath}${promptInfoXrayName}${promptInfoXrayNameServiceName}.service
    ${sudoCmd} systemctl daemon-reload
    
    ${sudoCmd} systemctl enable ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service
    ${sudoCmd} systemctl restart ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service








    generateVLessImportLink

    if [[ "${configV2rayStreamSetting}" == "tcp" ]]; then
        cat > ${configV2rayPath}/clientConfig.json <<-EOF
=========== ${promptInfoXrayInstall}客户端配置参数 =============
{
    协议: ${configV2rayProtocol},
    地址: ${configSSLDomain},
    端口: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    额外id/AlterID: 0,  // AlterID, Vmess 请填0, 如果是Vless协议则不需要该项
    加密方式: aes-128-gcm,  // 如果是Vless协议则为none
    传输协议: tcp,
    底层传输协议: ${configV2rayIsTlsShowInfo},
    别名:自己起个任意名称
}

导入链接 Vmess Base64 格式:
${v2rayVmessLinkQR1}

导入链接 Vless 格式:
${v2rayVlessLinkQR1}

EOF

    elif [[ "${configV2rayStreamSetting}" == "kcp" ]]; then
        cat > ${configV2rayPath}/clientConfig.json <<-EOF
=========== ${promptInfoXrayInstall}客户端配置参数 =============
{
    协议: ${configV2rayProtocol},
    地址: ${configSSLDomain},
    端口: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    额外id/AlterID: 0,  // AlterID, Vmess 请填0, 如果是Vless协议则不需要该项
    加密方式: aes-128-gcm,  // 如果是Vless协议则为none
    传输协议: kcp,
    底层传输协议: ${configV2rayIsTlsShowInfo},
    seed 混淆密码: "${configV2rayKCPSeedPassword}",
    别名:自己起个任意名称
}

导入链接 Vmess Base64 格式:
${v2rayVmessLinkQR1}

导入链接 Vless 格式:
${v2rayVlessLinkQR1}


EOF

    elif [[ "${configV2rayStreamSetting}" == "h2" ]]; then
        cat > ${configV2rayPath}/clientConfig.json <<-EOF
=========== ${promptInfoXrayInstall}客户端配置参数 =============
{
    协议: ${configV2rayProtocol},
    地址: ${configSSLDomain},
    端口: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    额外id/AlterID: 0,  // AlterID, Vmess 请填0, 如果是Vless协议则不需要该项
    加密方式: aes-128-gcm,  // 如果是Vless协议则为none
    传输协议: h2,
    底层传输协议: ${configV2rayIsTlsShowInfo},
    path路径:/${configV2rayWebSocketPath},
    别名:自己起个任意名称
}

导入链接 Vmess Base64 格式:
${v2rayVmessLinkQR1}

导入链接 Vless 格式:
${v2rayVlessLinkQR1}

EOF

    elif [[ "${configV2rayStreamSetting}" == "quic" ]]; then
        cat > ${configV2rayPath}/clientConfig.json <<-EOF
=========== ${promptInfoXrayInstall}客户端配置参数 =============
{
    协议: ${configV2rayProtocol},
    地址: ${configSSLDomain},
    端口: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    额外id/AlterID: 0,  // AlterID, Vmess 请填0, 如果是Vless协议则不需要该项
    加密方式: aes-128-gcm,  // 如果是Vless协议则为none
    传输协议: quic,
    底层传输协议: ${configV2rayIsTlsShowInfo},
    Quic security: none,
    key 加密时所用的密钥: "${configV2rayKCPSeedPassword}",
    别名:自己起个任意名称
}

导入链接 Vmess Base64 格式:
${v2rayVmessLinkQR1}

导入链接 Vless 格式:
${v2rayVlessLinkQR1}

EOF


    elif [[ "${configV2rayStreamSetting}" == "grpc" ]]; then
        cat > ${configV2rayPath}/clientConfig.json <<-EOF
=========== ${promptInfoXrayInstall}客户端配置参数 =============
{
    协议: ${configV2rayProtocol},
    地址: ${configSSLDomain},
    端口: ${configV2rayPortGRPCShowInfo},
    uuid: ${v2rayPassword1},
    额外id/AlterID: 0,  // AlterID, Vmess 请填0, 如果是Vless协议则不需要该项
    加密方式: aes-128-gcm,  // 如果是Vless协议则为none
    传输协议: gRPC,
    gRPC serviceName: ${configV2rayGRPCServiceName},
    底层传输协议: ${configV2rayIsTlsShowInfo},
    别名:自己起个任意名称
}

导入链接 Vmess Base64 格式:
${v2rayVmessLinkQR1}

导入链接 Vless 格式:
${v2rayVlessLinkQR1}

EOF

    elif [[ "${configV2rayStreamSetting}" == "wsgrpc" ]]; then
        cat > ${configV2rayPath}/clientConfig.json <<-EOF
=========== ${promptInfoXrayInstall} 客户端配置参数 =============
{
    协议: ${configV2rayProtocol},
    地址: ${configSSLDomain},
    端口: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    额外id/AlterID: 0,  // AlterID, Vmess 请填0, 如果是Vless协议则不需要该项
    加密方式: aes-128-gcm,  // 如果是Vless协议则为none
    传输协议: websocket,
    websocket路径:/${configV2rayWebSocketPath},
    底层传输协议: ${configV2rayIsTlsShowInfo},
    别名:自己起个任意名称
}

导入链接 Vmess Base64 格式:
${v2rayVmessLinkQR1}

导入链接 Vless 格式:
${v2rayVlessLinkQR1}


=========== ${promptInfoXrayInstall} gRPC 客户端配置参数 =============
{
    协议: ${configV2rayProtocol},
    地址: ${configSSLDomain},
    端口: ${configV2rayPortGRPCShowInfo},
    uuid: ${v2rayPassword1},
    额外id/AlterID: 0,  // AlterID, Vmess 请填0, 如果是Vless协议则不需要该项
    加密方式: aes-128-gcm,  // 如果是Vless协议则为none
    传输协议: gRPC,
    gRPC serviceName: ${configV2rayGRPCServiceName},
    底层传输协议: ${configV2rayIsTlsShowInfo},
    别名:自己起个任意名称
}

导入链接 Vmess Base64 格式:
${v2rayVmessLinkQR2}

导入链接 Vless 格式:
${v2rayVlessLinkQR2}

EOF

    elif [[ "${configV2rayStreamSetting}" == "ws" ]]; then
        cat > ${configV2rayPath}/clientConfig.json <<-EOF
=========== ${promptInfoXrayInstall}客户端配置参数 =============
{
    协议: ${configV2rayProtocol},
    地址: ${configSSLDomain},
    端口: ${configV2rayPortShowInfo},
    uuid: ${v2rayPassword1},
    额外id/AlterID: 0,  // AlterID, Vmess 请填0, 如果是Vless协议则不需要该项
    加密方式: aes-128-gcm,  // 如果是Vless协议则为none
    传输协议: websocket,
    websocket路径:/${configV2rayWebSocketPath},
    底层传输协议: ${configV2rayIsTlsShowInfo},
    别名:自己起个任意名称
}

导入链接 Vmess Base64 格式:
${v2rayVmessLinkQR1}

导入链接 Vless 格式:
${v2rayVlessLinkQR1}

EOF

    fi





    if [[ "$configV2rayWorkingMode" == "vlessTCPVmessWS" ]]; then

        cat > ${configV2rayPath}/clientConfig.json <<-EOF

VLess运行在443端口 (VLess-TCP-TLS) + (VMess-TCP-TLS) + (VMess-WS-TLS)  支持CDN

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
    底层传输协议: ${configV2rayIsTlsShowInfo},
    别名:自己起个任意名称
}

导入链接 Vless 格式:
${v2rayVlessLinkQR1}


=========== ${promptInfoXrayInstall}客户端 VMess-WS-TLS 配置参数 支持CDN =============
{
    协议: VMess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    加密方式: auto,  // 如果是Vless协议则为none
    传输协议: websocket,
    websocket路径:/${configV2rayWebSocketPath},
    底层传输:tls,
    别名:自己起个任意名称
}

导入链接 Vmess Base64 格式:
${v2rayVmessLinkQR1}

导入链接新版:
vmess://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPort}?encryption=auto&security=tls&type=ws&host=${configSSLDomain}&path=%2f${configV2rayWebSocketPath}#${configSSLDomain}+ws_protocol


=========== ${promptInfoXrayInstall}客户端 VMess-TCP-TLS 配置参数 支持CDN =============
{
    协议: VMess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    加密方式: auto,  // 如果是Vless协议则为none
    传输协议: tcp,
    路径:/tcp${configV2rayWebSocketPath},
    底层传输:tls,
    别名:自己起个任意名称
}

导入链接 Vmess Base64 格式:
${v2rayVmessLinkQR2}

导入链接新版:
vmess://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPort}?encryption=auto&security=tls&type=tcp&host=${configSSLDomain}&path=%2ftcp${configV2rayWebSocketPath}#${configSSLDomain}+tcp_protocol

EOF

    elif [[ "$configV2rayWorkingMode" == "vlessgRPC" ]]; then

    cat > ${configV2rayPath}/clientConfig.json <<-EOF
 VLess运行在443端口 (VLess-gRPC-TLS) 支持CDN

=========== ${promptInfoXrayInstall}客户端 VLess-gRPC-TLS 配置参数 支持CDN =============
{
    协议: VLess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    流控flow:  空,
    加密方式: none,  
    传输协议: gRPC,
    gRPC serviceName: ${configV2rayGRPCServiceName},
    底层传输协议: tls,
    别名:自己起个任意名称
}

导入链接 Vless 格式:
${v2rayVlessLinkQR1}

EOF

    elif [[ "$configV2rayWorkingMode" == "vlessTCPWS" ]]; then

    cat > ${configV2rayPath}/clientConfig.json <<-EOF
VLess运行在443端口 (VLess-TCP-TLS) + (VLess-WS-TLS) 支持CDN

=========== ${promptInfoXrayInstall}客户端 VLess-TCP-TLS 配置参数 =============
{
    协议: VLess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    流控flow: 空
    加密方式: none, 
    传输协议: tcp ,
    websocket路径:无,
    底层传输协议: ${configV2rayIsTlsShowInfo},
    别名:自己起个任意名称
}

导入链接 Vless 格式:
${v2rayVlessLinkQR1}


=========== ${promptInfoXrayInstall}客户端 VLess-WS-TLS 配置参数 支持CDN =============
{
    协议: VLess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    流控flow: 空,
    加密方式: none,  
    传输协议: websocket,
    websocket路径:/${configV2rayWebSocketPath},
    底层传输:tls,     
    别名:自己起个任意名称
}

导入链接 Vless 格式:
vless://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPort}?encryption=none&security=tls&type=ws&host=${configSSLDomain}&path=%2f${configV2rayWebSocketPath}#${configSSLDomain}+ws_protocol

EOF

    elif [[ "$configV2rayWorkingMode" == "vlessTCPWSgRPC" || "$configV2rayWorkingMode" == "sni" ]]; then

    cat > ${configV2rayPath}/clientConfig.json <<-EOF
VLess运行在443端口 (VLess-TCP-TLS) + (VLess-WS-TLS) + (VLess-gRPC-TLS)支持CDN

=========== ${promptInfoXrayInstall}客户端 VLess-TCP-TLS 配置参数 =============
{
    协议: VLess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    流控flow: 空
    加密方式: none, 
    传输协议: tcp ,
    websocket路径:无,
    底层传输协议: ${configV2rayIsTlsShowInfo},
    别名:自己起个任意名称
}

导入链接 Vless 格式:
${v2rayVlessLinkQR1}


=========== ${promptInfoXrayInstall}客户端 VLess-WS-TLS 配置参数 支持CDN =============
{
    协议: VLess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    流控flow: 空,
    加密方式: none,  
    传输协议: websocket,
    websocket路径:/${configV2rayWebSocketPath},
    底层传输:tls,     
    别名:自己起个任意名称
}

导入链接 Vless 格式:
vless://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPort}?encryption=none&security=tls&type=ws&host=${configSSLDomain}&path=%2f${configV2rayWebSocketPath}#${configSSLDomain}+ws_protocol


=========== ${promptInfoXrayInstall}客户端 VLess-gRPC-TLS 配置参数 支持CDN =============
{
    协议: VLess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    流控flow:  空,
    加密方式: none,  
    传输协议: gRPC,
    gRPC serviceName: ${configV2rayGRPCServiceName},
    底层传输:tls,     
    别名:自己起个任意名称
}

导入链接 Vless 格式:
vless://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPort}?encryption=none&security=tls&type=grpc&serviceName=${configV2rayGRPCServiceName}&host=${configSSLDomain}#${configSSLDomain}+gRPC_protocol

EOF

    elif [[ "$configV2rayWorkingMode" == "vlessTCPWSTrojan" ]]; then
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
    底层传输协议: ${configV2rayIsTlsShowInfo},
    别名:自己起个任意名称
}

导入链接 Vless 格式:
${v2rayVlessLinkQR1}


=========== ${promptInfoXrayInstall}客户端 VLess-WS-TLS 配置参数 支持CDN =============
{
    协议: VLess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    流控flow: 空, 
    加密方式: none,  
    传输协议: websocket,
    websocket路径:/${configV2rayWebSocketPath},
    底层传输:tls,     
    别名:自己起个任意名称
}

导入链接:
vless://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPort}?encryption=none&security=tls&type=ws&host=${configSSLDomain}&path=%2f${configV2rayWebSocketPath}#${configSSLDomain}+ws_protocol


=========== Trojan${promptInfoTrojanName}服务器地址: ${configSSLDomain}  端口: $configV2rayPort

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
您指定前缀的密码共20个: 从 ${configTrojanPasswordPrefixInput}202001 到 ${configTrojanPasswordPrefixInput}202020 都可以使用
例如: 密码:${configTrojanPasswordPrefixInput}202002 或 密码:${configTrojanPasswordPrefixInput}202019 都可以使用

小火箭链接:
trojan://${trojanPassword1}@${configSSLDomain}:${configV2rayPort}?peer=${configSSLDomain}&sni=${configSSLDomain}#${configSSLDomain}_trojan

二维码 Trojan${promptInfoTrojanName}
https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=trojan%3a%2f%2f${trojanPassword1}%40${configSSLDomain}%3a${configV2rayPort}%3fpeer%3d${configSSLDomain}%26sni%3d${configSSLDomain}%23${configSSLDomain}_trojan

EOF

    elif [[ "$configV2rayWorkingMode" == "trojan" ]]; then
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
    底层传输协议: ${configV2rayIsTlsShowInfo},
    别名:自己起个任意名称
}

导入链接 Vless 格式:
${v2rayVlessLinkQR1}


=========== ${promptInfoXrayInstall}客户端 VLess-WS-TLS 配置参数 支持CDN =============
{
    协议: VLess,
    地址: ${configSSLDomain},
    端口: ${configV2rayPort},
    uuid: ${v2rayPassword1},
    额外id: 0,  // AlterID 如果是Vless协议则不需要该项
    流控flow: 空, 
    加密方式: none,  
    传输协议: websocket,
    websocket路径:/${configV2rayWebSocketPath},
    底层传输:tls,     
    别名:自己起个任意名称
}

导入链接:
vless://${v2rayPassword1UrlEncoded}@${configSSLDomain}:${configV2rayPort}?encryption=none&security=tls&type=ws&host=${configSSLDomain}&path=%2f${configV2rayWebSocketPath}#${configSSLDomain}+ws_protocol


=========== Trojan${promptInfoTrojanName}服务器地址: ${configSSLDomain}  端口: $configV2rayTrojanPort

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
您指定前缀的密码共20个: 从 ${configTrojanPasswordPrefixInput}202001 到 ${configTrojanPasswordPrefixInput}202020 都可以使用
例如: 密码:${configTrojanPasswordPrefixInput}202002 或 密码:${configTrojanPasswordPrefixInput}202019 都可以使用

小火箭链接:
trojan://${trojanPassword1}@${configSSLDomain}:${configV2rayTrojanPort}?peer=${configSSLDomain}&sni=${configSSLDomain}#${configSSLDomain}_trojan

二维码 Trojan${promptInfoTrojanName}
https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=trojan%3a%2f%2f${trojanPassword1}%40${configSSLDomain}%3a${configV2rayTrojanPort}%3fpeer%3d${configSSLDomain}%26sni%3d${configSSLDomain}%23${configSSLDomain}_trojan

EOF
    fi



    # 设置 cron 定时任务
    # https://stackoverflow.com/questions/610839/how-can-i-programmatically-create-a-new-cron-job

    (crontab -l ; echo "20 4 * * 0,1,2,3,4,5,6 systemctl restart ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service") | sort - | uniq - | crontab -


    green "======================================================================"
    green "    ${promptInfoXrayInstall} Version: ${promptInfoXrayVersion} 安装成功 !"

    if [[ -n ${configInstallNginxMode} ]]; then
        green "    伪装站点为 https://${configSSLDomain}!"
	    green "    伪装站点的静态html内容放置在目录 ${configWebsitePath}, 可自行更换网站内容!"
    fi
	
	red "    ${promptInfoXrayInstall} 服务器端配置路径 ${configV2rayPath}/config.json !"
	green "    ${promptInfoXrayInstall} 访问日志 ${configV2rayAccessLogFilePath} !"
	green "    ${promptInfoXrayInstall} 错误日志 ${configV2rayErrorLogFilePath} ! "
	green "    ${promptInfoXrayInstall} 查看日志命令: journalctl -n 50 -u ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service "
	green "    ${promptInfoXrayInstall} 停止命令: systemctl stop ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service  启动命令: systemctl start ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service "
	green "    ${promptInfoXrayInstall} 重启命令: systemctl restart ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service"
	green "    ${promptInfoXrayInstall} 查看运行状态命令:  systemctl status ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service "
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
    yellow "全平台客户端程序汇总 https://tlanyan.pp.ua/v2ray-clients-download/ "
    yellow "其他客户端程序请看 https://www.v2fly.org/awesome/tools.html "
    green "======================================================================"

    cat >> ${configReadme} <<-EOF


${promptInfoXrayInstall} Version: ${promptInfoXrayVersion} 安装成功 ! 
${promptInfoXrayInstall} 服务器端配置路径 ${configV2rayPath}/config.json 

${promptInfoXrayInstall} 访问日志 ${configV2rayAccessLogFilePath}
${promptInfoXrayInstall} 错误日志 ${configV2rayErrorLogFilePath}

${promptInfoXrayInstall} 查看日志命令: journalctl -n 50 -u ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service

${promptInfoXrayInstall} 启动命令: systemctl start ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service  
${promptInfoXrayInstall} 停止命令: systemctl stop ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service  
${promptInfoXrayInstall} 重启命令: systemctl restart ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service
${promptInfoXrayInstall} 查看运行状态命令:  systemctl status ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service 

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

    echo
    read -p "是否确认卸载 V2ray 或 Xray? 直接回车默认卸载, 请输入[Y/n]:" isRemoveV2rayServerInput
    isRemoveV2rayServerInput=${isRemoveV2rayServerInput:-Y}

    if [[ "${isRemoveV2rayServerInput}" == [Yy] ]]; then


        if [[ -f "${configV2rayPath}/xray" || -f "${configV2rayPath}/v2ray" ]]; then

            if [ -f "${configV2rayPath}/xray" ]; then
                promptInfoXrayName="xray"
                isXray="yes"
            fi

            if [ -f "${osSystemMdPath}${promptInfoXrayName}-jin.service" ]; then
                promptInfoXrayNameServiceName="-jin"
            else
                promptInfoXrayNameServiceName=""
            fi

            echo
            green " ================================================== "
            red " 准备卸载已安装 ${promptInfoXrayName}${promptInfoXrayNameServiceName} "
            green " ================================================== "
            echo

            ${sudoCmd} systemctl stop ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service
            ${sudoCmd} systemctl disable ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service


            rm -rf ${configV2rayPath}
            rm -f ${osSystemMdPath}${promptInfoXrayName}${promptInfoXrayNameServiceName}.service
            rm -f ${configV2rayAccessLogFilePath}
            rm -f ${configV2rayErrorLogFilePath}

            crontab -l | grep -v "${promptInfoXrayName}${promptInfoXrayNameServiceName}" | crontab -

            echo
            green " ================================================== "
            green "  ${promptInfoXrayName}${promptInfoXrayNameServiceName} 卸载完毕 !"
            green " ================================================== "
            
        else
            red " 系统没有安装 ${promptInfoXrayName}${promptInfoXrayNameServiceName}, 退出卸载"
        fi
        echo

    fi

}


function upgradeV2ray(){

    if [[ -f "${configV2rayPath}/xray" || -f "${configV2rayPath}/v2ray" ]]; then
        if [ -f "${configV2rayPath}/xray" ]; then
            promptInfoXrayName="xray"
            isXray="yes"
        fi

        if [ -f "${osSystemMdPath}${promptInfoXrayName}-jin.service " ]; then
            promptInfoXrayNameServiceName="-jin"
        else
            promptInfoXrayNameServiceName=""
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


        ${sudoCmd} systemctl stop ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service

        mkdir -p ${configDownloadTempPath}/upgrade/${promptInfoXrayName}

        downloadV2rayXrayBin "upgrade"

        if [ "$isXray" = "no" ] ; then
            mv -f ${configDownloadTempPath}/upgrade/${promptInfoXrayName}/v2ctl ${configV2rayPath}
        fi

        mv -f ${configDownloadTempPath}/upgrade/${promptInfoXrayName}/${promptInfoXrayName} ${configV2rayPath}
        mv -f ${configDownloadTempPath}/upgrade/${promptInfoXrayName}/geoip.dat ${configV2rayPath}
        mv -f ${configDownloadTempPath}/upgrade/${promptInfoXrayName}/geosite.dat ${configV2rayPath}

        ${sudoCmd} chmod +x ${configV2rayPath}/${promptInfoXrayName}
        ${sudoCmd} systemctl start ${promptInfoXrayName}${promptInfoXrayNameServiceName}.service


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
                
    else
        red " 系统没有安装 ${promptInfoXrayName}${promptInfoXrayNameServiceName}, 退出卸载"
    fi
    echo
}











































function downloadTrojanWebBin(){
    # https://github.com/Jrohy/trojan/releases/download/v2.12.2/trojan-linux-amd64
    # https://github.com/Jrohy/trojan/releases/download/v2.12.2/trojan-linux-arm64
    
    if [[ ${osArchitecture} == "arm" || ${osArchitecture} == "arm64" ]] ; then
        downloadFilenameTrojanWeb="trojan-linux-arm64"
    fi

    if [ -z $1 ]; then
        wget -O ${configTrojanWebPath}/trojan-web --no-check-certificate "https://github.com/Jrohy/trojan/releases/download/v${versionTrojanWeb}/${downloadFilenameTrojanWeb}"
    else
        wget -O ${configDownloadTempPath}/upgrade/trojan-web/trojan-web "https://github.com/Jrohy/trojan/releases/download/v${versionTrojanWeb}/${downloadFilenameTrojanWeb}"
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
        downloadTrojanWebBin
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
        echo
        red " 后续安装步骤: "
        green " 根据提示选择 1. Let's Encrypt 证书, 申请SSL证书 "
        green " 证书申请成功后. 继续根据提示 再选择 1.安装docker版mysql(mariadb)."
        green " mysql(mariadb)启动成功后, 继续根据提示 输入第一个trojan用户的账号密码, 回车后出现 '欢迎使用trojan管理程序' "
        green " 出现 '欢迎使用trojan管理程序'后 需要不输入数字直接按回车, 这样就会继续安装 nginx 直到完成 "
        echo
        green " nginx 安装成功会显示可视化管理面板网址, 请保存下来. 如果没有显示管理面板网址则表明安装失败. "
        green " =================================================="

        read -p "按回车继续安装. Press enter to continue"

        ${configTrojanWebPath}/trojan-web

        installWebServerNginx

        # 命令补全环境变量
        echo "export PATH=$PATH:${configTrojanWebPath}" >> ${HOME}/.${osSystemShell}rc

        # (crontab -l ; echo '25 0 * * * "${configSSLAcmeScriptPath}"/acme.sh --cron --home "${configSSLAcmeScriptPath}" > /dev/null') | sort - | uniq - | crontab -
        (crontab -l ; echo "30 4 * * 0,1,2,3,4,5,6 systemctl restart trojan-web.service") | sort - | uniq - | crontab -

    else
        exit
    fi
}

function upgradeTrojanWeb(){
    getTrojanAndV2rayVersion "trojan-web"
    green " =================================================="
    green "    开始升级 Trojan-web 可视化管理面板: ${versionTrojanWeb} !"
    green " =================================================="

    ${sudoCmd} systemctl stop trojan-web.service

    mkdir -p ${configDownloadTempPath}/upgrade/trojan-web
    downloadTrojanWebBin "upgrade"
    
    mv -f ${configDownloadTempPath}/upgrade/trojan-web/trojan-web ${configTrojanWebPath}
    chmod +x ${configTrojanWebPath}/trojan-web

    ${sudoCmd} systemctl start trojan-web.service
    ${sudoCmd} systemctl restart trojan.service


    green " ================================================== "
    green "     升级成功 Trojan-web 可视化管理面板: ${versionTrojanWeb} !"
    green " ================================================== "
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

    crontab -l | grep -v "trojan-web"  | crontab -

    green " ================================================== "
    green "  Trojan-web 卸载完毕 !"
    green " ================================================== "
}

function runTrojanWebGetSSL(){
    ${sudoCmd} systemctl stop trojan-web.service
    ${sudoCmd} systemctl stop nginx.service
    ${sudoCmd} systemctl stop trojan.service
    ${configTrojanWebPath}/trojan-web tls
    ${sudoCmd} systemctl start trojan-web.service
    ${sudoCmd} systemctl start nginx.service
    ${sudoCmd} systemctl restart trojan.service
}

function runTrojanWebCommand(){
    ${configTrojanWebPath}/trojan-web
}




























function installXUI(){

    stopServiceNginx
    testLinuxPortUsage
    installPackage

    green " ================================================== "
    yellow " 请输入绑定到本VPS的域名 例如www.xxx.com: (此步骤请关闭CDN后安装)"
    green " ================================================== "

    read configSSLDomain
    if compareRealIpWithLocalIp "${configSSLDomain}" ; then

        green " =================================================="
        green "    开始安装 X-UI 可视化管理面板 !"
        green " =================================================="

        # wget -O x_ui_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/sprov065/x-ui/master/install.sh" && chmod +x x_ui_install.sh && ./x_ui_install.sh
        wget -O x_ui_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh" && chmod +x x_ui_install.sh && ./x_ui_install.sh

        green "X-UI 可视化管理面板地址 http://${configSSLDomain}:54321"
        green " 请确保 54321 端口已经放行, 例如检查linux防火墙或VPS防火墙 54321 端口是否开启"
        green "X-UI 可视化管理面板 默认管理员用户 admin 密码 admin, 为保证安全,请登陆后尽快修改默认密码 "
        green " =================================================="

    else
        exit
    fi
}
function removeXUI(){
    green " =================================================="
    /usr/bin/x-ui
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

        bash <(curl -Ls https://raw.githubusercontent.com/tszho-t/v2-ui/master/v2-ui.sh)

        # wget -O v2_ui_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/sprov065/v2-ui/master/install.sh" && chmod +x v2_ui_install.sh && ./v2_ui_install.sh
        # wget -O v2_ui_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/tszho-t/v2-ui/master/install.sh" && chmod +x v2_ui_install.sh && ./v2_ui_install.sh

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




















































function startMenuOther(){
    clear
    green " =================================================="
    red " 安装下面3个可视化管理面板 之前不能用本脚本或其他脚本安装过trojan或v2ray! "
    red " 如果已安装过 trojan 或 v2ray 请先卸载或重做干净系统! 3个管理面板无法同时安装"
    echo
    green " 1. 安装 trojan-web (trojan 和 trojan-go 可视化管理面板) 和 nginx 伪装网站"
    green " 2. 升级 trojan-web 到最新版本"
    green " 3. 重新申请证书"
    green " 4. 查看日志, 管理用户, 查看配置等功能"
    red " 5. 卸载 trojan-web 和 nginx "
    echo
    green " 6. 安装 V2ray 可视化管理面板V2-UI, 可以同时支持trojan"
    green " 7. 升级 V2-UI 到最新版本"
    red " 8. 卸载 V2-UI"
    echo
    green " 9. 安装 Xray 可视化管理面板 X-UI, 可以同时支持trojan"
    red " 10. 升级 或 卸载 X-UI"
    echo
    green " =================================================="
    red " 以下是 VPS 测网速工具, 脚本测速会消耗大量 VPS 流量，请悉知！"
    green " 41. superspeed 三网纯测速 （全国各地三大运营商部分节点全面测速）推荐使用 "
    green " 42. yet-another-bench-script 综合测试 （包含 CPU IO 测试 国际多个数据节点网速测试）推荐使用"
    green " 43. 由teddysun 编写的Bench 综合测试 （包含系统信息 IO 测试 国内多个数据节点网速测试）"
	green " 44. LemonBench 快速全方位测试 （包含CPU内存性能、回程、节点测速） "
    green " 45. ZBench 综合网速测试 （包含节点测速, Ping 以及 路由测试）"
    green " 46. testrace 回程路由测试 by nanqinlang （四网路由 上海电信 厦门电信 浙江杭州联通 浙江杭州移动 北京教育网）"
    green " 47. autoBestTrace 回程路由测试 (广州电信 上海电信 厦门电信 重庆联通 成都联通 上海移动 成都移动 成都教育网)"
    echo
    green " =================================================="
    green " 51. 测试VPS 是否支持 Netflix 非自制剧解锁 支持 WARP sock5 测试, 推荐使用 "
    green " 52. 测试VPS 是否支持 Netflix, Go语言版本 推荐使用 by sjlleo, 推荐使用"
    green " 53. 测试VPS 是否支持 Netflix, 检测IP解锁范围及对应所在的地区, 原版 by CoiaPrant"
    green " 54. 测试VPS 是否支持 Netflix, Disney, Hulu 等等更多流媒体平台, 新版 by lmc999"
    echo
    green " 61. 安装 官方宝塔面板"
    green " 62. 安装 宝塔面板破解版 by fenhao.me"
    green " 63. 安装 宝塔面板纯净版 by hostcli.com"
    echo
    green " 99. 返回上级菜单"
    green " 0. 退出脚本"
    echo
    read -p "请输入数字:" menuNumberInput
    case "$menuNumberInput" in
        1 )
            setLinuxDateZone
            configInstallNginxMode="trojanWeb"
            installTrojanWeb
        ;;
        2 )
            upgradeTrojanWeb
        ;;
        3 )
            runTrojanWebGetSSL
        ;;
        4 )
            runTrojanWebCommand
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
            removeV2rayUI
        ;;
        9 )
            setLinuxDateZone
            installXUI
        ;;
        10 )
            removeXUI
        ;;                                        
        41 )
            vps_superspeed
        ;;
        42 )
            vps_yabs
        ;;        
        43 )
            vps_bench
        ;;
        44 )
            vps_LemonBench
        ;;
        45 )
            vps_zbench
        ;;
        46 )
            vps_testrace
        ;;        
        47 )
            vps_autoBestTrace
        ;;        
        51 )
            vps_netflix_jin
        ;;
        52 )
            vps_netflixgo
        ;;
        53 )
            vps_netflix
        ;;
        54 )
            vps_netflix2
        ;;
        61 )
            installBTPanel
        ;;
        62 )
            installBTPanelCrack
        ;;
        63 )
            installBTPanelCrack2
        ;;
        81 )
            installBBR
        ;;
        82 )
            installBBR2
        ;;
        99)
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
    green " Trojan Trojan-go V2ray Xray 一键安装脚本 | 2022-1-16| By jinwyp | 系统支持：centos7+ / debian9+ / ubuntu16.04+"
    green " ===================================================================================================="
    green " 1. 安装linux内核 bbr plus, 安装WireGuard, 用于解锁 Netflix 限制和避免弹出 Google reCAPTCHA 人机验证"
    echo
    green " 2. 安装 trojan 或 trojan-go 和 nginx, 不支持CDN, trojan 或 trojan-go 运行在443端口"
    green " 3. 安装 trojan-go 和 nginx, 支持CDN 开启websocket, trojan-go 运行在443端口"
    green " 4. 只安装 trojan 或 trojan-go 运行在443或自定义端口, 不安装nginx, 方便与现有网站或宝塔面板集成"
    green " 5. 升级 trojan 或 trojan-go 到最新版本"
    red " 6. 卸载 trojan 或 trojan-go 和 nginx"
    echo
    green " 11. 安装 v2ray或xray 和 nginx ([Vmess/Vless]-[TCP/WS/gRPC/H2/QUIC]-TLS), 支持CDN, nginx 运行在443端口"
    green " 12. 只安装 v2ray或xray ([Vmess/Vless]-[TCP/WS/gRPC/H2/QUIC]), 无TLS加密, 方便与现有网站或宝塔面板集成"
    echo
    green " 13. 安装 v2ray或xray (VLess-TCP-[TLS/XTLS])+(VMess-TCP-TLS)+(VMess-WS-TLS) 支持CDN, 可选安装nginx, VLess运行在443端口"
    green " 14. 安装 v2ray或xray (VLess-gRPC-TLS) 支持CDN, 可选安装nginx, VLess运行在443端口"
    green " 15. 安装 v2ray或xray (VLess-TCP-[TLS/XTLS])+(VLess-WS-TLS) 支持CDN, 可选安装nginx, VLess运行在443端口"
    #green " 16. 安装 v2ray或xray (VLess-TCP-[TLS/XTLS])+(VLess-WS-TLS)+(VLess-gRPC-TLS) 支持CDN, 可选安装nginx, VLess运行在443端口" 
    green " 17. 安装 v2ray或xray (VLess-TCP-[TLS/XTLS])+(VLess-WS-TLS)+xray自带的trojan, 支持CDN, 可选安装nginx, VLess运行在443端口"  
    green " 18. 升级 v2ray或xray 到最新版本"
    red " 19. 卸载 v2ray或xray 和 nginx"
    echo
    green " 21. 同时安装 v2ray或xray 和 trojan或trojan-go (VLess-TCP-[TLS/XTLS])+(VLess-WS-TLS)+Trojan, 支持CDN, 可选安装nginx, VLess运行在443端口"  
    green " 22. 同时安装 nginx, v2ray或xray 和 trojan或trojan-go (VLess/Vmess-WS-TLS)+Trojan, 支持CDN, trojan或torjan-go运行在443端口"  
    green " 23. 同时安装 nginx, v2ray或xray 和 trojan或trojan-go, 通过 nginx SNI 分流, 支持CDN, 支持与现有网站共存, nginx 运行在443端口 "
    red " 24. 卸载 trojan, v2ray或xray 和 nginx"
    echo
    green " 25. 查看已安装的配置和用户密码等信息"
    green " 26. 单独申请域名SSL证书"
    green " 30. 子菜单 安装 trojan 和 v2ray 可视化管理面板, VPS测速工具, Netflix测试解锁工具, 安装宝塔面板等"
    green " =================================================="
    green " 31. 安装OhMyZsh与插件zsh-autosuggestions, Micro编辑器 等软件"
    green " 32. 开启root用户SSH登陆, 如谷歌云默认关闭root登录,可以通过此项开启"
    green " 33. 修改SSH 登陆端口号"
    green " 34. 设置时区为北京时间"
    green " 35. 用 VI 编辑 authorized_keys 文件 填入公钥, 用于SSH免密码登录 增加安全性"
    green " 88. 升级脚本"
    green " 0. 退出脚本"
    echo
    read -p "请输入数字:" menuNumberInput
    case "$menuNumberInput" in
        1 )
            installWireguard
        ;;
        2 )
            configInstallNginxMode="noSSL"
            installTrojanV2rayWithNginx "trojan_nginx"
        ;;
        3 )
            configInstallNginxMode="noSSL"
            isTrojanGoSupportWebsocket="true"
            installTrojanV2rayWithNginx "trojan_nginx"
        ;;
        4 )
            installTrojanV2rayWithNginx "trojan"
        ;;
        5 )
            upgradeTrojan
        ;;
        6 )
            removeTrojan
            removeNginx
        ;;
        11 )
            configInstallNginxMode="v2raySSL"
            configV2rayWorkingMode=""
            installTrojanV2rayWithNginx "nginx_v2ray"
        ;;
        12 )
            configInstallNginxMode=""
            configV2rayWorkingMode=""
            installTrojanV2rayWithNginx "v2ray"
        ;;
        13 )
            configInstallNginxMode="noSSL"
            configV2rayWorkingMode="vlessTCPVmessWS"
            installTrojanV2rayWithNginx "v2ray_nginxOptional"
        ;;
        14 )
            configInstallNginxMode="noSSL"
            configV2rayWorkingMode="vlessgRPC"
            installTrojanV2rayWithNginx "v2ray_nginxOptional"
        ;;
        15 )
            configInstallNginxMode="noSSL"
            configV2rayWorkingMode="vlessTCPWS"
            installTrojanV2rayWithNginx "v2ray_nginxOptional"
        ;;
        16 )
            configInstallNginxMode="noSSL"
            configV2rayWorkingMode="vlessTCPWSgRPC"
            installTrojanV2rayWithNginx "v2ray_nginxOptional"
        ;;
        17 )
            configInstallNginxMode="noSSL"
            configV2rayWorkingMode="vlessTCPWSTrojan"
            installTrojanV2rayWithNginx "v2ray_nginxOptional"
        ;; 
        18)
            upgradeV2ray
        ;;
        19 )
            removeV2ray
            removeNginx
        ;;
        21 )
            configInstallNginxMode="noSSL"
            configV2rayWorkingMode="trojan"
            installTrojanV2rayWithNginx "v2ray_nginxOptional"
        ;;
        22 )
            configInstallNginxMode="noSSL"
            configV2rayWorkingMode=""
            configV2rayWorkingNotChangeMode="true"
            installTrojanV2rayWithNginx "trojan_nginx_v2ray"
        ;;
        23 )
            configInstallNginxMode="sni"
            configV2rayWorkingMode="sni"
            installTrojanV2rayWithNginx "nginxSNI_trojan_v2ray"
        ;;
        24 )
            removeV2ray
            removeTrojan
            removeNginx
        ;;
        25 )
            cat "${configReadme}"
        ;;        
        26 )
            installTrojanV2rayWithNginx
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
        66 )
            promptInfoXrayNameServiceName="-jin"
            echo "promptInfoXrayNameServiceName: -jin"
            sleep 3s
            start_menu
        ;;
        67 )
            isTrojanMultiPassword="yes"
            echo "isTrojanMultiPassword: yes"
            sleep 3s
            start_menu
        ;;
        77 )
            vps_netflixgo
            vps_netflix_jin
        ;;
        80 )
            installPackage
        ;;
        81 )
            installBBR
        ;;
        82 )
            installBBR2
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

