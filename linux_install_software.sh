#!/bin/bash

export LC_ALL=C
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8


sudoCmd=""
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCmd="sudo"
fi


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

    green " OS info: ${osInfo}, ${osRelease}, ${osReleaseVersion}, ${osReleaseVersionNo}, ${osReleaseVersionCodeName}, ${osCPU} CPU ${osArchitecture}, ${osSystemShell}, ${osSystemPackage}, ${osSystemMdPath}"
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





function DSMEditHosts(){
	green " ================================================== "
	green " 准备打开VI 编辑/etc/hosts"
	green " 请用root 用户登录系统的SSH 运行本命令"
	green " ================================================== "

    # nameserver 223.5.5.5
    # nameserver 8.8.8.8

    HostFilePath="/etc/hosts"

    if ! grep -q "github" "${HostFilePath}"; then
        echo "199.232.69.194               github.global.ssl.fastly.net" >> ${HostFilePath}
        echo "185.199.108.153              assets-cdn.github.com" >> ${HostFilePath}
        echo "185.199.108.133              raw.githubusercontent.com" >> ${HostFilePath}
        echo "140.82.114.3                 github.com" >> ${HostFilePath}
        echo "104.16.16.35                 registry.npmjs.org" >> ${HostFilePath}
    fi

    

	vi ${HostFilePath}
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
            ${sudoCmd} yum module -y enable nginx:1.20
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











# 更新本脚本
function upgradeScript(){
    wget -Nq --no-check-certificate -O ./linux_install_software.sh "https://raw.githubusercontent.com/jinwyp/one_click_script/master/linux_install_software.sh"
    green " 本脚本升级成功! "
    chmod +x ./linux_install_software.sh
    sleep 2s
    exec "./linux_install_software.sh"
}

function installWireguard(){
    bash <(wget -qO- https://github.com/jinwyp/one_click_script/raw/master/install_kernel.sh)
    # wget -N --no-check-certificate https://github.com/jinwyp/one_click_script/raw/master/install_kernel.sh && chmod +x ./install_kernel.sh && ./install_kernel.sh
}












function toolboxSkybox(){
    wget -O skybox.sh https://raw.githubusercontent.com/BlueSkyXN/SKY-BOX/main/box.sh && chmod +x skybox.sh  && ./skybox.sh
}

function toolboxJcnf(){
    wget -O jcnfbox.sh https://raw.githubusercontent.com/Netflixxp/jcnf-box/main/jcnfbox.sh && chmod +x jcnfbox.sh && ./jcnfbox.sh
}



















































configDownloadTempPath="${HOME}/temp"

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
        green "===== 下载并解压tar.xz文件: $3 "
        wget -O ${configDownloadTempPath}/$3 $1
        tar xf ${configDownloadTempPath}/$3 -C ${configDownloadTempPath}
        mv ${configDownloadTempPath}/* $2
        rm -rf ${configDownloadTempPath}

    elif [[ $3 == *"tar.gz"* ]]; then
        green "===== 下载并解压tar.gz文件: $3 "
        wget -O ${configDownloadTempPath}/$3 $1
        tar zxvf ${configDownloadTempPath}/$3 -C ${configDownloadTempPath}
        mv ${configDownloadTempPath}/* $2
        rm -rf ${configDownloadTempPath}

    else
        green "===== 下载并解压zip文件:  $3 "
        wget -O ${configDownloadTempPath}/$3 $1
        unzip -d $2 ${configDownloadTempPath}/$3
        rm -rf ${configDownloadTempPath}
    fi

}




function getGithubLatestReleaseVersion(){
    # https://github.com/p4gefau1t/trojan-go/issues/63
    wget --no-check-certificate -qO- https://api.github.com/repos/$1/tags | grep 'name' | cut -d\" -f4 | head -1 | cut -b 2-
}
function getGithubLatestReleaseVersion2(){
    # https://github.com/p4gefau1t/trojan-go/issues/63
    wget --no-check-certificate -qO- https://api.github.com/repos/$1/tags | grep 'name' | cut -d\" -f4 | head -1 | cut -b 1-
}











function installNodejs(){

    if [ "$osRelease" == "centos" ] ; then

        if [ "$osReleaseVersion" == "8" ]; then
            ${sudoCmd} dnf module list nodejs
            ${sudoCmd} dnf module enable nodejs:14
            ${sudoCmd} dnf install nodejs
        fi

        if [ "$osReleaseVersion" == "7" ]; then
            curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
            ${sudoCmd} yum install -y nodejs
        fi

    else 
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
        echo 'export NVM_DIR="$HOME/.nvm"' >> ${HOME}/.zshrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ${HOME}/.zshrc
        source ${HOME}/.zshrc

        command -v nvm
        nvm --version
        nvm ls-remote
        nvm install --lts

    fi

    green " Nodejs 版本:"
    node --version 
    green " NPM 版本:"
    npm --version  

    green " =================================================="
    yellow " 准备安装 PM2 进程守护程序"
    green " =================================================="
    npm install -g pm2 

    green " ================================================== "
    green "   Nodejs 与 PM2 安装成功 !"
    green " ================================================== "

}





configDockerPath="${HOME}/download"

function installDocker(){

    echo
    green " =================================================="
    yellow " 准备安装 Docker 与 Docker Compose"
    green " =================================================="
    echo

    mkdir -p ${configDockerPath}
    cd ${configDockerPath}


    if [[ -s "/usr/bin/docker" ]]; then
        green " =================================================="
        green "  已安装过 Docker !"
        green " =================================================="
    
    else

        if [[ "${osInfo}" == "AlmaLinux" ]]; then
            # https://linuxconfig.org/install-docker-on-almalinux
            ${sudoCmd} dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            ${sudoCmd} dnf remove -y podman buildah 
            ${sudoCmd} dnf install -y docker-ce docker-ce-cli containerd.io

            
        else
            # curl -fsSL https://get.docker.com -o get-docker.sh  
            curl -sSL https://get.daocloud.io/docker -o get-docker.sh  
            chmod +x ./get-docker.sh
            sh get-docker.sh

        fi
        
        ${sudoCmd} systemctl start docker.service
        ${sudoCmd} systemctl enable docker.service
        
        echo
        docker version
        echo
    fi



    if [[ -s "/usr/local/bin/docker-compose" ]]; then
        green " =================================================="
        green "  已安装过 Docker Compose !"
        green " =================================================="
        
    else

        versionDockerCompose=$(getGithubLatestReleaseVersion "docker/compose")

        # dockerComposeUrl="https://github.com/docker/compose/releases/download/${versionDockerCompose}/docker-compose-$(uname -s)-$(uname -m)"
        dockerComposeUrl="https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64"
        dockerComposeUrl="https://get.daocloud.io/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64"
        
        echo
        green " Downloading  ${dockerComposeUrl}"
        echo

        ${sudoCmd} wget -O /usr/local/bin/docker-compose ${dockerComposeUrl}
        ${sudoCmd} chmod a+x /usr/local/bin/docker-compose

        rm -f `which dc` 
        rm -f "/usr/bin/docker-compose"
        ${sudoCmd} ln -s /usr/local/bin/docker-compose /usr/bin/dc
        ${sudoCmd} ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
        
    fi



    echo
    green " ================================================== "
    green "   Docker 与 Docker Compose 安装成功 !"
    green " ================================================== "
    echo
    docker-compose --version
    echo
    # systemctl status docker.service
}

function removeDocker(){

    if [ "$osRelease" == "centos" ] ; then

        sudo yum remove docker docker-common container-selinux docker-selinux docker-engine

    else 
        sudo apt-get remove docker docker-engine

    fi

    rm -fr /var/lib/docker/


    rm -f `which dc` 
    rm -f "/usr/bin/docker-compose"
    rm -f /usr/local/bin/docker-compose

    echo
    green " ================================================== "
    green "   Docker 已经卸载完毕 !"
    green " ================================================== "
    echo

}


function addDockerRegistry(){


        cat > "/etc/docker/daemon.json" <<-EOF

{
  "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
}


EOF

    sudo systemctl daemon-reload
    sudo systemctl restart docker
}




function installPortainer(){

    echo
    if [ -x "$(command -v docker)" ]; then
        green " Docker already installed"

    else
        red " Docker not install ! "
        exit
    fi

    echo
    docker volume create portainer_data

    echo
    docker pull portainer/portainer-ce
    
    echo
    docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce

    echo
    green " ================================================== "
    green "   Portainer 安装成功 !"
    green " ================================================== "
}

















































configCloudrevePath="/root/cloudreve"
configCloudreveDownloadFolder="${configCloudrevePath}/download"
configCloudreveCommandFolder="${configCloudrevePath}/web"
configCloudreveReadme="${configCloudrevePath}/web/readme.txt"
configCloudreveIni="${configCloudrevePath}/web/conf.ini"
configCloudrevePort="$(($RANDOM + 4000))"


function installCloudreve(){

    if [ -f "${configCloudreveCommandFolder}/cloudreve" ]; then
        green " =================================================="
        green "     Cloudreve Already installed !"
        green " =================================================="
        exit
    fi

    versionCloudreve=$(getGithubLatestReleaseVersion2 "cloudreve/Cloudreve")

    green " ================================================== "
    green "   Prepare to install Cloudreve ${versionCloudreve}"
    green " ================================================== "


    mkdir -p ${configCloudreveDownloadFolder}
    mkdir -p ${configCloudreveCommandFolder}
    cd ${configCloudrevePath}


    # https://github.com/cloudreve/Cloudreve/releases/download/3.4.2/cloudreve_3.4.2_linux_amd64.tar.gz
    # https://github.com/cloudreve/Cloudreve/releases/download/3.4.2/cloudreve_3.4.2_linux_arm.tar.gz
    # https://github.com/cloudreve/Cloudreve/releases/download/3.4.2/cloudreve_3.4.2_linux_arm64.tar.gz

    downloadFilenameCloudreve="cloudreve_${versionCloudreve}_linux_amd64.tar.gz"
    if [[ ${osArchitecture} == "arm" ]] ; then
        downloadFilenameCloudreve="cloudreve_${versionCloudreve}_linux_arm.tar.gz"
    fi
    if [[ ${osArchitecture} == "arm64" ]] ; then
        downloadFilenameCloudreve="cloudreve_${versionCloudreve}_linux_arm64.tar.gz"
    fi

    downloadAndUnzip "https://github.com/cloudreve/Cloudreve/releases/download/${versionCloudreve}/${downloadFilenameCloudreve}" "${configCloudreveDownloadFolder}" "${downloadFilenameCloudreve}"
    mv ${configCloudreveDownloadFolder}/cloudreve ${configCloudreveCommandFolder}/cloudreve

    chmod +x ${configCloudreveCommandFolder}/cloudreve
    cd ${configCloudreveCommandFolder}
    ./cloudreve >> ${configCloudreveReadme} &
    sleep 3

    pid=`ps -ef | grep cloudreve | grep -v grep | awk '{print $2}'`;kill $pid



        cat > ${osSystemMdPath}cloudreve.service <<-EOF
[Unit]
Description=Cloudreve
Documentation=https://docs.cloudreve.org
After=network.target
Wants=network.target

[Service]
WorkingDirectory=${configCloudreveCommandFolder}
ExecStart=${configCloudreveCommandFolder}/cloudreve -c ${configCloudreveIni}
Restart=on-abnormal
RestartSec=5s
KillMode=mixed

StandardOutput=null
StandardError=syslog

[Install]
WantedBy=multi-user.target
EOF


    sed -i "s/5212/${configCloudrevePort}/g" ${configCloudreveIni}
    sed -i "s/5212/${configCloudrevePort}/g" ${configCloudreveReadme}

    systemctl daemon-reload
    systemctl start cloudreve
    systemctl enable cloudreve



    echo
    green " ================================================== "
    green " Cloudreve Installed ! Working port: ${configCloudrevePort}"
    green " 如无法访问, 请设置防火墙规则 放行 ${configCloudrevePort} 端口"
    green " 查看运行状态命令: systemctl status cloudreve  重启: systemctl restart cloudreve "
    cat ${configCloudreveReadme}
    green " ================================================== "
}







function removeCloudreve(){

    echo
    read -p "是否确认卸载 Cloudreve? 直接回车默认卸载, 请输入[Y/n]:" isRemoveCloudreveInput
    isRemoveCloudreveInput=${isRemoveCloudreveInput:-Y}

    if [[ "${isRemoveCloudreveInput}" == [Yy] ]]; then
        echo

        if [[ -f "${configCloudreveCommandFolder}/cloudreve" ]]; then
            echo
            green " ================================================== "
            red " Prepare to uninstall Cloudreve"
            green " ================================================== "
            echo

            ${sudoCmd} systemctl stop cloudreve.service
            ${sudoCmd} systemctl disable cloudreve.service

            rm -rf ${configCloudrevePath}
            rm -f ${osSystemMdPath}cloudreve.service

            echo
            green " ================================================== "
            green "  Cloudreve removed !"
            green " ================================================== "
            
        else
            red " Cloudreve not found !"
        fi

    fi
}


















































configV2rayPoseidonPort="$(($RANDOM + 10000))"
configV2rayPoseidonPath="${HOME}/v2ray-poseidon"

configV2rayAccessLogFilePath="${HOME}/v2ray-poseidon-access.log"
configV2rayErrorLogFilePath="${HOME}/v2ray-poseidon-error.log"

function installV2rayPoseidon(){

    echo
    if [ -f "${configV2rayPoseidonPath}/v2ray-poseidon" ] || [ -f "/usr/bin/v2ray" ]; then
        green " =================================================="
        green "     已安装过 v2ray-poseidon 或 v2ray, 退出安装 !"
        green " =================================================="
        exit
    fi

    echo
    read -p "请选择直接运行模式还是Docker运行模式? 默认直接回车为直接运行模式, 选否则为Docker运行模式, 请输入[Y/n]:" isV2rayDockerNotInput
    isV2rayDockerNotInput=${isV2rayDockerNotInput:-Y}

    if [[ $isV2rayDockerNotInput == [Yy] ]]; then

        versionV2rayPoseidon=$(getGithubLatestReleaseVersion "ColetteContreras/v2ray-poseidon")
        echo
        green " =================================================="
        green "  开始安装 支持V2board面板的 服务器端程序 V2ray-Poseidon ${versionV2rayPoseidon}"
        green " =================================================="
        echo

        mkdir -p ${configV2rayPoseidonPath}
        cd ${configV2rayPoseidonPath}

        # https://github.com/ColetteContreras/v2ray-poseidon/releases/download/v2.2.0/v2ray-linux-64.zip
        downloadFilenameV2rayPoseidon="v2ray-linux-64.zip"

        downloadAndUnzip "https://github.com/ColetteContreras/v2ray-poseidon/releases/download/v${versionV2rayPoseidon}/${downloadFilenameV2rayPoseidon}" "${configV2rayPoseidonPath}" "${downloadFilenameV2rayPoseidon}"
        mv ${configV2rayPoseidonPath}/v2ray ${configV2rayPoseidonPath}/v2ray-poseidon
        cp ${configV2rayPoseidonPath}/config.json ${configV2rayPoseidonPath}/config_example.json
        chmod +x ${configV2rayPoseidonPath}/v2ray-poseidon

        sed -i "s/10086/${configV2rayPoseidonPort}/g" "${configV2rayPoseidonPath}/config.json"


        cat > ${osSystemMdPath}v2ray-poseidon.service <<-EOF
[Unit]
Description=V2Ray Poseidon Service
Documentation=https://poseidon-gfw.cc
After=network.target nss-lookup.target

[Service]
Type=simple
ExecStart=${configV2rayPoseidonPath}/v2ray-poseidon -config ${configV2rayPoseidonPath}/config.json
Restart=on-failure
# Don't restart in the case of configuration error
RestartPreventExitStatus=23
RestartSec=15
LimitNOFILE=655360

[Install]
WantedBy=multi-user.target

EOF


        ${sudoCmd} chmod +x ${osSystemMdPath}v2ray-poseidon.service
        ${sudoCmd} systemctl daemon-reload
        ${sudoCmd} systemctl enable v2ray-poseidon.service
        ${sudoCmd} systemctl start v2ray-poseidon.service
        
        green " ================================================== "
        green "   V2rayPoseidon 安装成功 "
        red "   V2rayPoseidon 服务器端配置路径 ${configV2rayPoseidonPath}/config.json "
        red "   V2rayPoseidon 运行访问日志文件路径: ${configV2rayAccessLogFilePath} "
        red "   V2rayPoseidon 运行错误日志文件路径: ${configV2rayErrorLogFilePath} "
        green "   V2rayPoseidon 查看运行日志命令: journalctl -n 100 -u v2ray-poseidon"

        green "   V2rayPoseidon 停止命令: systemctl stop v2ray-poseidon.service  启动命令: systemctl start v2ray-poseidon.service  重启命令: systemctl restart v2ray-poseidon.service"
        green "   V2rayPoseidon 查看运行状态命令:  systemctl status v2ray-poseidon.service "    
        green " ================================================== "


    else

        cd ${HOME}
        git clone https://github.com/ColetteContreras/v2ray-poseidon.git
        cd v2ray-poseidon

        green " ================================================== "
        green "   V2rayPoseidon 安装成功 "
        green " ================================================== "

    fi

    replaceV2rayPoseidonConfig

}



function replaceV2rayPoseidonConfig(){

    if test -s ${configV2rayPoseidonPath}/docker/v2board/ws-tls/docker-compose.yml; then

        echo
        green "请选择SSL证书申请方式 V2ray-Poseidon共有3种: 1 http方式, 2 手动放置证书文件, 3 dns方式 "
        green "本脚本提供2种 默认直接回车为 手动放置证书文件, 手动放置证书文件, 本脚本也会自动通过acme.sh申请证书"
        red "如选否 为 http 自动获取证书方式, 但由于acme.sh脚本2021年8月开始默认从 Letsencrypt 换到 ZeroSSL, 而V2ray-Poseidon已经很长时间没有更新 导致http申请证书模式会出现问题!"
        green "如需要使用 dns 申请SSL证书方式, 请手动修改 docker-compose.yml 配置文件"
        read -p "请选择SSL证书申请方式 ? 默认直接回车为手动放置证书文件, 选否则http申请模式, 请输入[Y/n]:" isSSLRequestHTTPInput
        isSSLRequestHTTPInput=${isSSLRequestHTTPInput:-Y}

        if [[ $isSSLRequestHTTPInput == [Yy] ]]; then
            echo
            getHTTPS

            sed -i "s?#- ./v2ray.crt:/etc/v2ray/v2ray.crt?- ${configSSLCertPath}/${configSSLCertFullchainFilename}:/etc/v2ray/v2ray.crt?g" ${configV2rayPoseidonPath}/docker/v2board/ws-tls/docker-compose.yml
            sed -i "s?#- ./v2ray.key:/etc/v2ray/v2ray.key?- ${configSSLCertPath}/${configSSLCertKeyFilename}:/etc/v2ray/v2ray.key?g" ${configV2rayPoseidonPath}/docker/v2board/ws-tls/docker-compose.yml
            
            sed -i 's/#- CERT_FILE=/- CERT_FILE=/g' ${configV2rayPoseidonPath}/docker/v2board/ws-tls/docker-compose.yml
            sed -i 's/#- KEY_FILE=/- KEY_FILE=/g' ${configV2rayPoseidonPath}/docker/v2board/ws-tls/docker-compose.yml

            sed -i "s/demo.oppapanel.xyz/${configSSLDomain}/g" ${configV2rayPoseidonPath}/docker/v2board/ws-tls/docker-compose.yml
        else
            echo
            green " ================================================== "
            yellow " 请输入绑定到本VPS的域名 例如www.xxx.com: (此步骤请关闭CDN后和nginx后安装 避免80端口占用导致申请证书失败)"
            green " ================================================== "

            read configSSLDomain

            sed -i 's/#- "80:80"/- "80:80"/g' ${configV2rayPoseidonPath}/docker/v2board/ws-tls/docker-compose.yml
            sed -i 's/CERT_MODE=dns/CERT_MODE=http/g' ${configV2rayPoseidonPath}/docker/v2board/ws-tls/docker-compose.yml
        fi

        read -p "请输入节点ID (纯数字):" inputV2boardNodeId
        sed -i "s/1,/${inputV2boardNodeId},/g" ${configV2rayPoseidonPath}/docker/v2board/ws-tls/config.json

        read -p "请输入面板域名 例如www.123.com 不要带有http或https前缀 结尾不要带/ :" inputV2boardDomain
        sed -i "s?http or https://YOUR V2BOARD DOMAIN?https://${inputV2boardDomain}?g" ${configV2rayPoseidonPath}/docker/v2board/ws-tls/config.json

        read -p "请输入token 即通信密钥:" inputV2boardWebApiKey
        sed -i "s/v2board token/${inputV2boardWebApiKey}/g" ${configV2rayPoseidonPath}/docker/v2board/ws-tls/config.json

        cd ${configV2rayPoseidonPath}/docker/v2board/ws-tls
        docker-compose up -d
    fi


    if test -s ${configV2rayPoseidonPath}/config.json; then

        echo
        getHTTPS

        echo
        read -p "请选择支持面板是v2board或sspanel? 默认直接回车为v2board, 选否则sspanel, 请输入[Y/n]:" isPanelV2boardInput
        isPanelV2boardInput=${isPanelV2boardInput:-Y}

        if [[ $isPanelV2boardInput == [Yy] ]]; then
            sed -i "s/sspanel-webapi/v2board/g" "${configV2rayPoseidonPath}/config.json"

            read -p "请输入token 即通信密钥:" inputV2boardWebApiKey
            sed -i 's/panelKey": ""/token": "v2board token"/g' ${configV2rayPoseidonPath}/config.json
            sed -i "s/v2board token/${inputV2boardWebApiKey}/g" ${configV2rayPoseidonPath}/config.json
    
            read -p "请输入面板域名 例如www.123.com 不要带有http或https前缀 结尾不要带/ :" inputV2boardDomain
            sed -i 's/panelUrl": ""/webapi": "YOUR V2BOARD DOMAIN"/g' ${configV2rayPoseidonPath}/config.json
            sed -i "s?YOUR V2BOARD DOMAIN?https://${inputV2boardDomain}?g" ${configV2rayPoseidonPath}/config.json

            sed -i 's/"loglevel": "debug"/"loglevel": "debug", "access": "configV2rayAccessLogFilePath", "error": "configV2rayErrorLogFilePath" /g' ${configV2rayPoseidonPath}/config.json
            sed -i "s/configV2rayAccessLogFilePath/${configV2rayAccessLogFilePath}/g" ${configV2rayPoseidonPath}/config.json
            sed -i "s/configV2rayErrorLogFilePath/${configV2rayErrorLogFilePath}/g" ${configV2rayPoseidonPath}/config.json
        fi


        read -p "请输入节点ID (纯数字 默认1):" inputV2boardNodeId
        inputV2boardNodeId=${inputV2boardNodeId:-1}
        sed -i "s/1,/${inputV2boardNodeId},/g" ${configV2rayPoseidonPath}/config.json

        ${sudoCmd} systemctl restart v2ray-poseidon.service
    fi

}

function removeV2rayPoseidon(){

    if [ -f "${configV2rayPoseidonPath}/README.md"  ]; then
        cd ${configV2rayPoseidonPath}/docker/v2board/ws-tls
        docker-compose stop
        rm -rf ${configV2rayPoseidonPath}
        echo
        green " ================================================== "
        green "  V2ray-Poseidon Docker 运行方式 卸载完毕 !"
        green " ================================================== "

    elif [ -f "${configV2rayPoseidonPath}/v2ray-poseidon"  ]; then
        echo
        green " ================================================== "
        red "  准备卸载已安装 V2ray-Poseidon "
        green " ================================================== "
        echo

        ${sudoCmd} systemctl stop v2ray-poseidon.service
        ${sudoCmd} systemctl disable v2ray-poseidon.service

        rm -rf ${configV2rayPoseidonPath}
        rm -f ${osSystemMdPath}v2ray-poseidon.service
        rm -f ${configV2rayAccessLogFilePath}
        rm -f ${configV2rayErrorLogFilePath}

        rm -rf /usr/bin/v2ray /etc/init.d/v2ray /lib/systemd/system/v2ray.service /etc/systemd/system/v2ray.service

        ${sudoCmd} systemctl daemon-reload
     
        echo
        green " ================================================== "
        green "  V2ray-Poseidon 卸载完毕 !"
        green " ================================================== "

    else
        green " ================================================== "
        red "  V2ray-Poseidon 没有安装 退出卸载 "
        green " ================================================== "
    fi



}


function manageV2rayPoseidon(){

    echo
    green " =================================================="
    echo
    green " 1. 启动 V2Ray-Poseidon 服务器端, 直接命令行 运行方式"
    green " 2. 重启 V2Ray-Poseidon 服务器端, 直接命令行 运行方式"
    green " 3. 停止 V2Ray-Poseidon 服务器端, 直接命令行 运行方式"
    green " 4. 查看 V2Ray-Poseidon 服务器端运行状态, 直接命令行 运行方式"
    green " 5. 查看 V2Ray-Poseidon 服务器端日志, 直接命令行 运行方式"
    echo
    green " 11. 启动 V2Ray-Poseidon 服务器端, Docker 运行方式"
    green " 12. 重启 V2Ray-Poseidon 服务器端, Docker 运行方式"
    green " 13. 停止 V2Ray-Poseidon 服务器端, Docker 运行方式"
    green " 14. 查看 V2Ray-Poseidon 服务器端日志, Docker 运行方式"
    green " 15. 清空 V2Ray-Poseidon Docker日志, Docker 运行方式"

    echo
    green " =================================================="
    green " 0. 退出脚本"
    echo
    read -p "请输入数字:" menuNumberInput
    case "$menuNumberInput" in
        1 )
            systemctl start v2ray-poseidon.service
        ;;   
        2 )
            systemctl restart v2ray-poseidon.service
        ;;
        3 )
            systemctl stop v2ray-poseidon.service
        ;;        
        4 )
            systemctl status v2ray-poseidon.service
        ;;        
        5 )
            journalctl -n 100 -u v2ray-poseidon
        ;;       
        11 )
            cd ${configV2rayPoseidonPath}/docker/v2board/ws-tls
            docker-compose up -d   
        ;;   
        12 )
            cd ${configV2rayPoseidonPath}/docker/v2board/ws-tls
            docker-compose restart 
        ;;
        13 )
            cd ${configV2rayPoseidonPath}/docker/v2board/ws-tls
            docker-compose stop   
        ;;        
        14 )
            cd ${configV2rayPoseidonPath}/docker/v2board/ws-tls
            docker-compose logs
        ;;        
        15 )
            truncate -s 0 /var/lib/docker/containers/*/*-json.log
        ;;   

        6 )
            echo
            echo "systemctl status wg-quick@wgcf"
            systemctl status wg-quick@wgcf
            red " 请查看上面 Active: 一行信息, 如果文字是绿色 active 则为启动正常, 否则启动失败"
            checkWireguardBootStatus
        ;;
        7 )
            echo
            echo "journalctl -n 50 -u wg-quick@wgcf"
            journalctl -n 50 -u wg-quick@wgcf
            red " 请查看上面包含 Error 的信息行, 查找启动失败的原因 "
        ;;        
        8 )
            echo
            echo "systemctl start wg-quick@wgcf"
            systemctl start wg-quick@wgcf
            green " Wireguard 已启动 !"
            checkWireguardBootStatus
        ;;        
        5 )
            echo
            echo "systemctl stop wg-quick@wgcf"
            systemctl stop wg-quick@wgcf
            green " Wireguard 已停止 !"
        ;;       
        6 )
            echo
            echo "systemctl restart wg-quick@wgcf"
            systemctl restart wg-quick@wgcf
            green " Wireguard 已重启 !"
            checkWireguardBootStatus
        ;;       
        7 )
            echo
            echo "cat ${configWireGuardConfigFilePath}"
            cat ${configWireGuardConfigFilePath}
        ;;       
        8 )
            echo
            echo "vi ${configWireGuardConfigFilePath}"
            vi ${configWireGuardConfigFilePath}
        ;; 
        0 )
            exit 1
        ;;
        * )
            clear
            red "请输入正确数字 !"
            sleep 2s
            checkWireguard
        ;;
    esac

}



function editV2rayPoseidonDockerWSConfig(){
    vi ${configV2rayPoseidonPath}/docker/v2board/ws-tls/config.json
}

function editV2rayPoseidonDockerComposeConfig(){
    vi ${configV2rayPoseidonPath}/docker/v2board/ws-tls/docker-compose.yml
}

function editV2rayPoseidonConfig(){
    vi ${configV2rayPoseidonPath}/config.json
}

















configSogaConfigFilePath="/etc/soga/soga.conf"

function installSoga(){
    echo
    green " =================================================="
    green "  开始安装 支持V2board面板的 服务器端程序 soga !"
    green " =================================================="
    echo

    # wget -O soga_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/sprov065/soga/master/install.sh" && chmod +x soga_install.sh && ./soga_install.sh
    wget -O soga_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/vaxilu/soga/master/install.sh" && chmod +x soga_install.sh && ./soga_install.sh

    replaceSogaConfig
}

function replaceSogaConfig(){

    if test -s ${configSogaConfigFilePath}; then

        echo
        green "请选择SSL证书申请方式 Soga共有3种: 1 http方式, 2 手动放置证书文件, 3 dns方式 "
        green "本脚本提供2种 默认直接回车为 http自动申请模式, 选否则手动放置证书文件同时本脚本也会自动通过acme.sh申请证书"
        green "如需要使用 dns 申请SSL证书方式, 请手动修改 soga.conf 配置文件"
        read -p "请选择SSL证书申请方式 ? 默认直接回车为http自动申请模式, 选否则手动放置证书文件同时也会自动申请证书, 请输入[Y/n]:" isSSLRequestHTTPInput
        isSSLRequestHTTPInput=${isSSLRequestHTTPInput:-Y}

        if [[ $isSSLRequestHTTPInput == [Yy] ]]; then
            echo
            green " ================================================== "
            yellow " 请输入绑定到本VPS的域名 例如www.xxx.com: (此步骤请关闭CDN后和nginx后安装 避免80端口占用导致申请证书失败)"
            green " ================================================== "

            read configSSLDomain

            sed -i 's/cert_mode=/cert_mode=http/g' ${configSogaConfigFilePath}
        else
            getHTTPS
            sed -i "s?cert_file=?cert_file=${configSSLCertPath}/${configSSLCertFullchainFilename}?g" ${configSogaConfigFilePath}
            sed -i "s?key_file=?key_file=${configSSLCertPath}/${configSSLCertKeyFilename}?g" ${configSogaConfigFilePath}

        fi

        sed -i 's/type=sspanel-uim/type=v2board/g' ${configSogaConfigFilePath}

        sed -i "s/cert_domain=/cert_domain=${configSSLDomain}/g" ${configSogaConfigFilePath}

        read -p "请输入面板域名 例如www.123.com 不要带有http或https前缀 结尾不要带/ :" inputV2boardDomain
        sed -i "s?webapi_url=?webapi_url=https://${inputV2boardDomain}/?g" ${configSogaConfigFilePath}

        read -p "请输入webapi key 即通信密钥:" inputV2boardWebApiKey
        sed -i "s/webapi_key=/webapi_key=${inputV2boardWebApiKey}/g" ${configSogaConfigFilePath}

        read -p "请输入节点ID (纯数字):" inputV2boardNodeId
        sed -i "s/node_id=1/node_id=${inputV2boardNodeId}/g" ${configSogaConfigFilePath}
    
        soga restart 

    fi

    manageSoga
}


function manageSoga(){
    echo -e ""
    echo "soga 管理脚本使用方法: "
    echo "------------------------------------------"
    echo "soga                    - 显示管理菜单 (功能更多)"
    echo "soga start              - 启动 soga"
    echo "soga stop               - 停止 soga"
    echo "soga restart            - 重启 soga"
    echo "soga status             - 查看 soga 状态"
    echo "soga enable             - 设置 soga 开机自启"
    echo "soga disable            - 取消 soga 开机自启"
    echo "soga log                - 查看 soga 日志"
    echo "soga update             - 更新 soga"
    echo "soga update x.x.x       - 更新 soga 指定版本"
    echo "soga config             - 显示配置文件内容"
    echo "soga config xx=xx yy=yy - 自动设置配置文件"
    echo "soga install            - 安装 soga"
    echo "soga uninstall          - 卸载 soga"
    echo "soga version            - 查看 soga 版本"
    echo "------------------------------------------"
}

function editSogaConfig(){
    vi ${configSogaConfigFilePath}
}



















configXrayRAccessLogFilePath="${HOME}/xrayr-access.log"
configXrayRErrorLogFilePath="${HOME}/xrayr-error.log"

configXrayRConfigFilePath="/etc/XrayR/config.yml"

function installXrayR(){
    echo
    green " =================================================="
    green "  开始安装 支持V2board面板的 服务器端程序 XrayR !"
    green " =================================================="
    echo

    testLinuxPortUsage

    wget -O xrayr_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh" && chmod +x xrayr_install.sh && ./xrayr_install.sh

    replaceXrayRConfig
}


function replaceXrayRConfig(){

    if test -s ${configXrayRConfigFilePath}; then

        echo
        green "请选择SSL证书申请方式 XrayR  共有4种: 1 http 方式, 2 file 手动放置证书文件, 3 dns 方式, 4 none 不申请证书"
        green "本脚本提供2种 默认直接回车为 http自动申请模式, 选否则手动放置证书文件同时本脚本也会自动通过acme.sh申请证书"
        green "如需要使用 dns 申请SSL证书方式, 请手动修改 ${configXrayRConfigFilePath} 配置文件"
    
        read -p "请选择SSL证书申请方式 ? 默认直接回车为http自动申请模式, 选否则手动放置证书文件同时也会自动申请证书, 请输入[Y/n]:" isSSLRequestHTTPInput
        isSSLRequestHTTPInput=${isSSLRequestHTTPInput:-Y}

        configXrayRSSLRequestMode="http"
        if [[ $isSSLRequestHTTPInput == [Yy] ]]; then
            echo
            green " ================================================== "
            yellow " 请输入绑定到本VPS的域名 例如www.xxx.com: (此步骤请关闭CDN后和nginx后安装 避免80端口占用导致申请证书失败)"
            green " ================================================== "

            read configSSLDomain

            
        else
            getHTTPS
            configXrayRSSLRequestMode="file"
        
            sed -i "s?./cert/node1.test.com.cert?${configSSLCertPath}/${configSSLCertFullchainFilename}?g" ${configXrayRConfigFilePath}
            sed -i "s?./cert/node1.test.com.key?${configSSLCertPath}/${configSSLCertKeyFilename}?g" ${configXrayRConfigFilePath}

        fi


        sed -i "s/CertMode: dns/CertMode: ${configXrayRSSLRequestMode}/g" ${configXrayRConfigFilePath}
        sed -i 's/CertDomain: "node1.test.com"/CertDomain: "www.xxxx.net"/g' ${configXrayRConfigFilePath}
        sed -i "s/www.xxxx.net/${configSSLDomain}/g" ${configXrayRConfigFilePath}

        echo
        read -p "请选择支持的面板类型 ? 默认直接回车为V2board, 选否则SSpanel, 请输入[Y/n]:" isXrayRPanelTypeInput
        isXrayRPanelTypeInput=${isXrayRPanelTypeInput:-Y}
        configXrayRPanelType="SSpanel"

        if [[ $isXrayRPanelTypeInput == [Yy] ]]; then
            configXrayRPanelType="V2board"
            sed -i 's/PanelType: "SSpanel"/PanelType: "V2board"/g' ${configXrayRConfigFilePath}
        fi

        
        echo
        green "请输入面板域名, 例如www.123.com 不要带有http或https前缀 结尾不要带/"
        green "请保证输入的V2board或其他面板域名支持Https 访问, 如要改成http请手动修改配置文件 ${configXrayRConfigFilePath}"
        read -p "请输入面板域名 :" inputV2boardDomain
        sed -i "s?http://127.0.0.1:667?https://${inputV2boardDomain}?g" ${configXrayRConfigFilePath}

        read -p "请输入ApiKey 即通信密钥:" inputV2boardWebApiKey
        sed -i "s/123/${inputV2boardWebApiKey}/g" ${configXrayRConfigFilePath}

        read -p "请输入节点ID (纯数字):" inputV2boardNodeId
        sed -i "s/41/${inputV2boardNodeId}/g" ${configXrayRConfigFilePath}
    

        echo
        read -p "请选择支持的节点类型 ? 默认直接回车为V2ray, 选否则为Trojan, 请输入[Y/n]:" isXrayRNodeTypeInput
        isXrayRNodeTypeInput=${isXrayRNodeTypeInput:-Y}
        configXrayRNodeType="V2ray"

        if [[ $isXrayRNodeTypeInput == [Nn] ]]; then
            configXrayRNodeType="Trojan"
            sed -i 's/NodeType: V2ray/NodeType: Trojan/g' ${configXrayRConfigFilePath}

        else
            echo
            read -p "是否给V2ray启用Vless协议 ? 默认直接回车选择否,默认启用Vmess协议, 选择是则启用Vless协议, 请输入[y/N]:" isXrayRVlessSupportInput
            isXrayRVlessSupportInput=${isXrayRVlessSupportInput:-N}

            if [[ $isXrayRVlessSupportInput == [Yy] ]]; then
                sed -i 's/EnableVless: false/EnableVless: true/g' ${configXrayRConfigFilePath}
            fi

            echo
            read -p "是否给V2ray启用XTLS ? 默认直接回车选择否,默认启用Tls, 选择是则启用XTLS, 请输入[y/N]:" isXrayRXTLSSupportInput
            isXrayRXTLSSupportInput=${isXrayRXTLSSupportInput:-N}

            if [[ $isXrayRXTLSSupportInput == [Yy] ]]; then
                sed -i 's/EnableXTLS: false/EnableXTLS: true/g' ${configXrayRConfigFilePath}
            fi

        fi


        sed -i "s?# ./access.Log?${configXrayRAccessLogFilePath}?g" ${configXrayRConfigFilePath}
        sed -i "s?# ./error.log?${configXrayRErrorLogFilePath}?g" ${configXrayRConfigFilePath}
        sed -i "s?Level: none?Level: info?g" ${configXrayRConfigFilePath}
            

        XrayR restart 

    fi

    manageXrayR
}


function manageXrayR(){
    echo -e ""
    echo "XrayR 管理脚本使用方法 (兼容使用xrayr执行，大小写不敏感): "
    echo "------------------------------------------"
    echo "XrayR                    - 显示管理菜单 (功能更多)"
    echo "XrayR start              - 启动 XrayR"
    echo "XrayR stop               - 停止 XrayR"
    echo "XrayR restart            - 重启 XrayR"
    echo "XrayR status             - 查看 XrayR 状态"
    echo "XrayR enable             - 设置 XrayR 开机自启"
    echo "XrayR disable            - 取消 XrayR 开机自启"
    echo "XrayR log                - 查看 XrayR 日志"
    echo "XrayR update             - 更新 XrayR"
    echo "XrayR update x.x.x       - 更新 XrayR 指定版本"
    echo "XrayR config             - 显示配置文件内容"
    echo "XrayR install            - 安装 XrayR"
    echo "XrayR uninstall          - 卸载 XrayR"
    echo "XrayR version            - 查看 XrayR 版本"
    echo "------------------------------------------"
}

function editXrayRConfig(){
    vi ${configXrayRConfigFilePath}
}


















function downgradeXray(){
    echo
    green " =================================================="
    green "  准备降级 Xray 和 Air-Universe !"
    green " =================================================="
    echo


    yellow " 请选择 Air-Universe 降级到的版本, 默认不降级"
    red " 注意 Air-Universe 最新版不支持 Xray 1.5.0或更老版本"
    red " 如需要使用Xray 1.5.0或更老版本的Xray, 请选择 Air-Universe 1.0.0或 0.9.2"
    green " 1. 不降级 使用最新版本"
    green " 2. 1.0.0"
    green " 3. 0.9.2"
    echo
    read -p "请选择Air-Universe版本? 直接回车默认选1, 请输入纯数字:" isAirUniverseVersionInput
    isAirUniverseVersionInput=${isAirUniverseVersionInput:-1}

    downloadAirUniverseVersion="1.0.2"
    downloadAirUniverseUrl="https://github.com/crossfw/Air-Universe/releases/download/v1.0.2/Air-Universe-linux-64.zip"

    if [[ "${isAirUniverseVersionInput}" == "2" ]]; then
        downloadAirUniverseVersion="1.0.0"
    elif [[ "${isAirUniverseVersionInput}" == "3" ]]; then
        downloadAirUniverseVersion="0.9.2"
    else
        echo
    fi

    if [[ "${isAirUniverseVersionInput}" == "1" ]]; then
        echo
        green " =================================================="
        green "  已选择不降级 使用最新版本 Air-Universe"
        green " =================================================="
        echo
    else
        # https://github.com/crossfw/Air-Universe/releases/download/v1.0.2/Air-Universe-linux-arm32-v6.zip
        # https://github.com/crossfw/Air-Universe/releases/download/v1.0.2/Air-Universe-linux-arm64-v8a.zip

        downloadAirUniverseUrl="https://github.com/crossfw/Air-Universe/releases/download/v${downloadAirUniverseVersion}/Air-Universe-linux-64.zip"
        airUniverseDownloadFilename="Air-Universe-linux-64_${downloadAirUniverseVersion}.zip"

        if [[ "${osArchitecture}" == "arm64" ]]; then
            downloadAirUniverseUrl="https://github.com/crossfw/Air-Universe/releases/download/v${downloadAirUniverseVersion}/Air-Universe-linux-arm64-v8a.zip"
            airUniverseDownloadFilename="Air-Universe-linux-arm64-v8a_${downloadAirUniverseVersion}.zip"
        fi

        if [[ "${osArchitecture}" == "arm" ]]; then
            downloadAirUniverseUrl="https://github.com/crossfw/Air-Universe/releases/download/v${downloadAirUniverseVersion}/Air-Universe-linux-arm32-v6.zip"
            airUniverseDownloadFilename="Air-Universe-linux-arm32-v6_${downloadAirUniverseVersion}.zip"
        fi


        airUniverseDownloadFolder="/root/airuniverse_temp"
        mkdir -p ${airUniverseDownloadFolder}

        wget -O ${airUniverseDownloadFolder}/${airUniverseDownloadFilename} ${downloadAirUniverseUrl}
        unzip -d ${airUniverseDownloadFolder} ${airUniverseDownloadFolder}/${airUniverseDownloadFilename}
        mv -f ${airUniverseDownloadFolder}/Air-Universe /usr/local/bin/au
        chmod +x /usr/local/bin/*

        rm -rf ${airUniverseDownloadFolder}

    fi



    echo
    yellow " 请选择Xray降级到的版本, 默认不降级"
    green " 1. 不降级 使用最新版本"

    if [[ "${isAirUniverseVersionInput}" == "1" ]]; then
        green " 2. 1.5.3"
    else
        green " 3. 1.5.0"
        green " 4. 1.4.5"
        green " 5. 1.4.3"
        green " 6. 1.4.2"
        green " 7. 1.4.0"
        green " 8. 1.3.1"
    fi

    echo
    read -p "请选择Xray版本? 直接回车默认选1, 请输入纯数字:" isXrayVersionInput
    isXrayVersionInput=${isXrayVersionInput:-1}

    downloadXrayVersion="1.5.0"
    downloadXrayUrl="https://github.com/XTLS/Xray-core/releases/download/v1.5.0/Xray-linux-64.zip"

    if [[ "${isXrayVersionInput}" == "2" ]]; then
        downloadXrayVersion="1.5.3"

    elif [[ "${isXrayVersionInput}" == "3" ]]; then
        downloadXrayVersion="1.5.0"

    elif [[ "${isXrayVersionInput}" == "4" ]]; then
        downloadXrayVersion="1.4.5"

    elif [[ "${isXrayVersionInput}" == "5" ]]; then
        downloadXrayVersion="1.4.3"

    elif [[ "${isXrayVersionInput}" == "6" ]]; then
        downloadXrayVersion="1.4.2"

    elif [[ "${isXrayVersionInput}" == "7" ]]; then
        downloadXrayVersion="1.4.0"

    elif [[ "${isXrayVersionInput}" == "8" ]]; then
        downloadXrayVersion="1.3.1"

    else
        echo
    fi

    if [[ "${isXrayVersionInput}" == "1" ]]; then
        echo
        green " =================================================="
        green "  已选择不降级 使用最新版本 Xray"
        green " =================================================="
        echo
    else

        # https://github.com/XTLS/Xray-core/releases/download/v1.5.2/Xray-linux-arm32-v6.zip

        downloadXrayUrl="https://github.com/XTLS/Xray-core/releases/download/v${downloadXrayVersion}/Xray-linux-64.zip"
        xrayDownloadFilename="Xray-linux-64_${downloadXrayVersion}.zip"

        if [[ "${osArchitecture}" == "arm64" ]]; then
            downloadXrayUrl="https://github.com/XTLS/Xray-core/releases/download/v${downloadXrayVersion}/Xray-linux-arm64-v8a.zip"
            xrayDownloadFilename="Xray-linux-arm64-v8a_${downloadXrayVersion}.zip"
        fi

        if [[ "${osArchitecture}" == "arm" ]]; then
            downloadXrayUrl="https://github.com/XTLS/Xray-core/releases/download/v${downloadXrayVersion}/Xray-linux-arm32-v6.zip"
            xrayDownloadFilename="Xray-linux-arm32-v6_${downloadXrayVersion}.zip"
        fi


        xrayDownloadFolder="/root/xray_temp"
        mkdir -p ${xrayDownloadFolder}

        wget -O ${xrayDownloadFolder}/${xrayDownloadFilename} ${downloadXrayUrl}
        unzip -d ${xrayDownloadFolder} ${xrayDownloadFolder}/${xrayDownloadFilename}
        mv -f ${xrayDownloadFolder}/xray /usr/local/bin
        chmod +x /usr/local/bin/*
        rm -rf ${xrayDownloadFolder}

    fi

    if [[ -z $1 ]]; then
        echo
        configSSLCertPath="/usr/local/share/au"
        
        airu stop
        systemctl stop xray.service

        chmod ugoa+rw ${configSSLCertPath}/*
        
        systemctl start xray.service
        airu start
        systemctl status xray.service
        echo
    fi    
}



configAirUniverseXrayAccessLogFilePath="${HOME}/air-universe-access.log"
configAirUniverseXrayErrorLogFilePath="${HOME}/air-universe-error.log"


configAirUniverseAccessLogFilePath="${HOME}/air-universe-access.log"
configAirUniverseErrorLogFilePath="${HOME}/air-universe-error.log"

configAirUniverseConfigFilePath="/usr/local/etc/au/au.json"
configAirUniverseXrayConfigFilePath="/usr/local/etc/xray/config.json"

configXrayPort="$(($RANDOM + 10000))"

function installAirUniverse(){
    echo
    green " =================================================="
    green "  开始安装 支持V2board面板的 服务器端程序 Air-Universe !"
    green " =================================================="
    echo
    
    if [ -z "$1" ]; then
        testLinuxPortUsage

        # bash -c "$(curl -L https://github.com/crossfw/Xray-install/raw/main/install-release.sh)" @ install  
        # bash <(curl -Ls https://raw.githubusercontent.com/crossfw/Air-Universe-install/master/install.sh)
        
        # bash <(curl -Ls https://raw.githubusercontent.com/crossfw/Air-Universe-install/master/AirU.sh)
        wget -O /root/airu_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/crossfw/Air-Universe-install/master/AirU.sh" 
        chmod +x /root/airu_install.sh 
        cp -f /root/airu_install.sh /usr/bin/airu
        
        /root/airu_install.sh install 

        (crontab -l ; echo "30 4 * * 0,1,2,3,4,5,6 systemctl restart xray.service ") | sort - | uniq - | crontab -
        (crontab -l ; echo "32 4 * * 0,1,2,3,4,5,6 /usr/bin/airu restart ") | sort - | uniq - | crontab -

        downgradeXray "norestart"
    else
        echo
    fi



    if test -s ${configAirUniverseConfigFilePath}; then

        echo
        green "请选择SSL证书申请方式 acme.sh 共有2种: 1 http方式, 2 dns方式, 3 不申请证书"
        green "Air-Universe 本身没有自动获取证书功能, 使用 acme.sh 申请证书"
        read -p "请选择SSL证书申请方式 ? 默认直接回车为1 http方式,  请输入纯数字:" isSSLRequestHTTPInput
        isSSLRequestHTTPInput=${isSSLRequestHTTPInput:-1}

        if [[  ( $isSSLRequestHTTPInput == "1" ) || ( $isSSLRequestHTTPInput == "2" ) ]]; then
            echo
            if [[ $isSSLRequestHTTPInput == "1" ]]; then
                getHTTPS "air" "http"
            else
                getHTTPS "air" "dns"
            fi

            airUniverseConfigNodeIdNumberInput=`grep "nodes_type"  ${configAirUniverseConfigFilePath} | awk -F  ":" '{print $2}'`

            read -r -d '' airUniverseConfigProxyInput << EOM
        
        "type": "xray",
        "auto_generate": true,
        "in_tags": ${airUniverseConfigNodeIdNumberInput},
        "api_address": "127.0.0.1",
        "api_port": ${configXrayPort},
        "force_close_tls": false,
        "log_path": "${configAirUniverseAccessLogFilePath}",
        "cert": {
            "cert_path": "${configSSLCertPath}/${configSSLCertFullchainFilename}",
            "key_path": "${configSSLCertPath}/${configSSLCertKeyFilename}"
        },
        "speed_limit_level": [0, 10, 30, 100, 150, 300, 1000]
        
EOM

            # https://stackoverflow.com/questions/6684487/sed-replace-with-variable-with-multiple-lines

            TEST="${airUniverseConfigProxyInput//\\/\\\\}"
            TEST="${TEST//\//\\/}"
            TEST="${TEST//&/\\&}"
            TEST="${TEST//$'\n'/\\n}"

            sed -i "s/\"type\":\"xray\"/${TEST}/g" ${configAirUniverseConfigFilePath}
            sed -i "s/10085/${configXrayPort}/g" ${configAirUniverseXrayConfigFilePath}


            replaceAirUniverseConfigWARP "norestart"
            
            chmod ugoa+rw ${configSSLCertPath}/${configSSLCertFullchainFilename}
            chmod ugoa+rw ${configSSLCertPath}/${configSSLCertKeyFilename}
            chmod ugoa+rw ${configSSLCertPath}/*

            echo
            green " =================================================="
            systemctl restart xray.service
            airu restart
            echo
            echo
            green " =================================================="
            green " Air-Universe 安装成功 !"
            green " =================================================="
            
            manageAirUniverse
        else
            echo
            green "不申请SSL证书"
            read -p "Press enter to continue. 按回车继续运行 airu 命令"
            airu
        fi


    else
        manageAirUniverse
    fi
    
}




function inputUnlockV2rayServerInfo(){
            echo
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


function replaceAirUniverseConfigWARP(){


    echo
    green " =================================================="
    yellow " 是否使用 DNS 解锁流媒体 Netflix HBO Disney 等流媒体网站"
    green " 如需解锁请填入 解锁 Netflix 的DNS服务器的IP地址, 例如 8.8.8.8"
    read -p "是否使用DNS解锁流媒体? 直接回车默认不解锁, 解锁请输入DNS服务器的IP地址:" isV2rayUnlockDNSInput
    isV2rayUnlockDNSInput=${isV2rayUnlockDNSInput:-n}

    V2rayDNSUnlockText="AsIs"
    v2rayConfigDNSInput=""

    if [[ "${isV2rayUnlockDNSInput}" == [Nn] ]]; then
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
    yellow " 是否使用 Cloudflare WARP 解锁 流媒体 Netflix 等网站"
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

    xrayConfigRuleInput=""
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
    echo
    yellow " 某大佬提供了可以解锁Netflix新加坡区的V2ray服务器, 不保证一直可用"
    read -p "是否通过神秘力量解锁Netflix新加坡区? 直接回车默认不解锁, 请输入[y/N]:" isV2rayUnlockGoNetflixInput
    isV2rayUnlockGoNetflixInput=${isV2rayUnlockGoNetflixInput:-n}

    v2rayConfigRouteGoNetflixInput=""
    v2rayConfigOutboundV2rayGoNetflixServerInput=""
    if [[ "${isV2rayUnlockGoNetflixInput}" == [Nn] ]]; then
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



    echo
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

    if [[ $isV2rayUnlockWarpModeInput == $isV2rayUnlockGoogleInput ]]; then
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

        read -r -d '' xrayConfigRuleInput << EOM
            {
                "type": "field",
                "outboundTag": "${V2rayUnlockVideoSiteOutboundTagText}",
                "domain": [${V2rayUnlockVideoSiteRuleText}] 
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

        read -r -d '' xrayConfigRuleInput << EOM
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
EOM
    fi


    read -r -d '' xrayConfigProxyInput << EOM
    
    ${v2rayConfigDNSInput}
    "outbounds": [
        {
            "tag": "IPv4_out",
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "${V2rayDNSUnlockText}"
            }
        },
        {
            "tag": "blackhole",
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
    ],
    "routing": {
        "rules": [
            {
                "inboundTag": [
                    "api"
                ],
                "outboundTag": "api",
                "type": "field"
            },
            ${xrayConfigRuleInput}
            ${v2rayConfigRouteGoNetflixInput}
            {
                "type": "field",
                "protocol": [
                    "bittorrent"
                ],
                "outboundTag": "blackhole"
            },
            {
                "type": "field",
                "ip": [
                    "127.0.0.1/32",
                    "10.0.0.0/8",
                    "fc00::/7",
                    "fe80::/10",
                    "172.16.0.0/12"
                ],
                "outboundTag": "blackhole"
            }
        ]
    }
}
EOM

    # https://stackoverflow.com/questions/31091332/how-to-use-sed-to-delete-multiple-lines-when-the-pattern-is-matched-and-stop-unt/31091398

    if [[ "${isV2rayUnlockWarpModeInput}" == "1" && "${isV2rayUnlockGoogleInput}" == "1"  && "${isV2rayUnlockGoNetflixInput}" == [Nn]  ]]; then
        if [[ "${isV2rayUnlockDNSInput}" == [Nn] ]]; then
            echo
        else
            TEST="${v2rayConfigDNSInput//\\/\\\\}"
            TEST="${TEST//\//\\/}"
            TEST="${TEST//&/\\&}"
            TEST="${TEST//$'\n'/\\n}"

            sed -i "/outbounds/i \    ${TEST}" ${configAirUniverseXrayConfigFilePath}

        fi
    else
        sed -i '/outbounds/,/^&/d' ${configAirUniverseXrayConfigFilePath}
        cat >> ${configAirUniverseXrayConfigFilePath} <<-EOF

  ${xrayConfigProxyInput}

EOF
    fi





    configSSLCertPath="/usr/local/share/au"
    chmod ugoa+rw ${configSSLCertPath}/${configSSLCertFullchainFilename}
    chmod ugoa+rw ${configSSLCertPath}/${configSSLCertKeyFilename}

    # -z 为空
    if [[ -z $1 ]]; then
        echo
        green " =================================================="
        green " 重启 xray 和 air-universe 服务 "
        systemctl restart xray.service
        airu restart
        green " =================================================="
        echo
    fi

}










function manageAirUniverse(){
    echo -e ""
    green " =================================================="       
    echo "    Air-Universe 管理脚本使用方法: "
    echo 
    echo "airu              - 显示管理菜单 (功能更多)"
    echo "airu start        - 启动 Air-Universe"
    echo "airu stop         - 停止 Air-Universe"
    echo "airu restart      - 重启 Air-Universe"
    echo "airu status       - 查看 Air-Universe 状态"
    echo "airu enable       - 设置 Air-Universe 开机自启"
    echo "airu disable      - 取消 Air-Universe 开机自启"
    echo "airu log          - 查看 Air-Universe 日志"
    echo "airu update x.x.x - 更新 Air-Universe 指定版本"
    echo "airu install      - 安装 Air-Universe"
    echo "airu uninstall    - 卸载 Air-Universe"
    echo "airu version      - 查看 Air-Universe 版本"
    echo "------------------------------------------"
    green " Air-Universe 配置文件 ${configAirUniverseConfigFilePath} "
    green " Xray 配置文件 ${configAirUniverseXrayConfigFilePath}"
    green " =================================================="    
    echo
}

function editAirUniverseConfig(){
    vi ${configAirUniverseConfigFilePath}
}

function editAirUniverseXrayConfig(){
    vi ${configAirUniverseXrayConfigFilePath}
}

function removeAirUniverse(){
    rm -rf /usr/local/etc/xray
    /root/airu_install.sh uninstall
}
























configNetworkRealIp=""
configNetworkLocalIp=""
configSSLDomain=""


configRanPath="${HOME}/ran"

configSSLAcmeScriptPath="${HOME}/.acme.sh"
configSSLCertPath="/root/.cert"
configSSLCertKeyFilename="server.key"
configSSLCertFullchainFilename="server.crt"

configWebsitePath="${HOME}/website/html"




function getHTTPSCertificate(){

    # 申请https证书
	mkdir -p ${configSSLCertPath}
	mkdir -p ${configWebsitePath}
	curl https://get.acme.sh | sh

    green "=========================================="

	if [[ $1 == "standalone" ]] ; then

	    green "  开始申请证书, acme.sh 通过 http standalone mode 申请 "
        echo

	    ${configSSLAcmeScriptPath}/acme.sh --issue --standalone -d ${configSSLDomain} --keylength ec-256 --server letsencrypt
        echo

        ${configSSLAcmeScriptPath}/acme.sh --installcert --ecc -d ${configSSLDomain} \
        --key-file ${configSSLCertPath}/${configSSLCertKeyFilename} \
        --fullchain-file ${configSSLCertPath}/${configSSLCertFullchainFilename} \
        --reloadcmd "systemctl restart nginx.service"

    elif [[ $1 == "dns" ]] ; then

        green "  开始申请证书, acme.sh 通过 dns mode 申请 "
        echo
        read -r -p "请输入您的邮箱Email 用于在 ZeroSSL.com 申请SSL证书:" isSSLDNSEmailInput
        ${configSSLAcmeScriptPath}/acme.sh --register-account  -m ${isSSLDNSEmailInput} --server zerossl

        echo
        green "请选择 DNS provider DNS 提供商: 1. CloudFlare, 2. AliYun, 3. DNSPod(Tencent) "
        red "注意 CloudFlare 针对某些免费的域名例如.tk .cf 等  不再支持使用API 申请DNS证书 "
        read -r -p "请选择 DNS 提供商 ? 默认直接回车为 1. CloudFlare, 请输入纯数字:" isSSLDNSProviderInput
        isSSLDNSProviderInput=${isSSLDNSProviderInput:-1}    

        
        if [ "$isSSLDNSProviderInput" == "1" ]; then
            read -r -p "Please Input CloudFlare Email: " cf_email
            export CF_Email="${cf_email}"
            read -r -p "Please Input CloudFlare Global API Key: " cf_key
            export CF_Key="${cf_key}"

            ${configSSLAcmeScriptPath}/acme.sh --issue -d "${configSSLDomain}" --dns dns_cf --force --keylength ec-256 --server zerossl --debug 

        elif [ "$isSSLDNSProviderInput" == "2" ]; then
            read -r -p "Please Input Ali Key: " Ali_Key
            export Ali_Key="${Ali_Key}"
            read -r -p "Please Input Ali Secret: " Ali_Secret
            export Ali_Secret="${Ali_Secret}"

            ${configSSLAcmeScriptPath}/acme.sh --issue -d "${configSSLDomain}" --dns dns_ali --force --keylength ec-256 --server zerossl --debug 

        elif [ "$isSSLDNSProviderInput" == "3" ]; then
            read -r -p "Please Input DNSPod ID: " DP_Id
            export DP_Id="${DP_Id}"
            read -r -p "Please Input DNSPod Key: " DP_Key
            export DP_Key="${DP_Key}"

            ${configSSLAcmeScriptPath}/acme.sh --issue -d "${configSSLDomain}" --dns dns_dp --force --keylength ec-256 --server zerossl --debug 
        fi

        ${configSSLAcmeScriptPath}/acme.sh --installcert --ecc -d ${configSSLDomain} \
        --key-file ${configSSLCertPath}/${configSSLCertKeyFilename} \
        --fullchain-file ${configSSLCertPath}/${configSSLCertFullchainFilename} \
        --reloadcmd "systemctl restart nginx.service"


	else

        mkdir -p ${configRanPath}
        
        if [[ -f "${configRanPath}/ran_linux_amd64" ]]; then
            echo
        else
            downloadAndUnzip "https://github.com/m3ng9i/ran/releases/download/v0.1.5/ran_linux_amd64.zip" "${configRanPath}" "ran_linux_amd64.zip" 
            chmod +x ${configRanPath}/ran_linux_amd64
        fi    

        echo
        echo "nohup ${configRanPath}/ran_linux_amd64 -l=false -g=false -sa=true -p=80 -r=${configWebsitePath} >/dev/null 2>&1 &"
        nohup ${configRanPath}/ran_linux_amd64 -l=false -g=false -sa=true -p=80 -r=${configWebsitePath} >/dev/null 2>&1 &
        echo

        green "  开始申请证书, acme.sh 通过 http webroot mode 申请, 并使用 ran 作为临时的web服务器 "
        echo
        echo
        green "默认通过Letsencrypt.org来申请证书, 如果证书申请失败, 例如一天内通过Letsencrypt.org申请次数过多, 可以选否通过BuyPass.com来申请."
        read -p "是否通过Letsencrypt.org来申请证书? 默认直接回车为是, 选否则通过BuyPass.com来申请, 请输入[Y/n]:" isDomainSSLFromLetInput
        isDomainSSLFromLetInput=${isDomainSSLFromLetInput:-Y}

        echo
        if [[ $isDomainSSLFromLetInput == [Yy] ]]; then
            ${configSSLAcmeScriptPath}/acme.sh --issue -d ${configSSLDomain} --webroot ${configWebsitePath} --keylength ec-256 --server letsencrypt
            
        else
            read -p "请输入邮箱地址, 用于BuyPass.com申请证书:" isDomainSSLFromBuyPassEmailInput
            isDomainSSLFromBuyPassEmailInput=${isDomainSSLFromBuyPassEmailInput:-test@gmail.com}

            echo
            ${configSSLAcmeScriptPath}/acme.sh --server https://api.buypass.com/acme/directory --register-account  --accountemail ${isDomainSSLFromBuyPassEmailInput}
            
            echo
            ${configSSLAcmeScriptPath}/acme.sh --server https://api.buypass.com/acme/directory --days 170 --issue -d ${configSSLDomain} --webroot ${configWebsitePath}  --keylength ec-256
        fi
        
        echo
        ${configSSLAcmeScriptPath}/acme.sh --installcert --ecc -d ${configSSLDomain} \
        --key-file ${configSSLCertPath}/${configSSLCertKeyFilename} \
        --fullchain-file ${configSSLCertPath}/${configSSLCertFullchainFilename} \
        --reloadcmd "systemctl restart nginx.service"

        sleep 4
        ps -C ran_linux_amd64 -o pid= | xargs -I {} kill {}
    fi

}



function compareRealIpWithLocalIp(){
    echo
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




function getHTTPS(){

    testLinuxPortUsage

    if [[ $1 == "air" ]] ; then
        configSSLCertPath="/usr/local/share/au"
    fi


    echo
    green " ================================================== "
    yellow " 请输入绑定到本VPS的域名 例如www.xxx.com: (此步骤请关闭CDN后和nginx后安装 避免80端口占用导致申请证书失败)"
    green " ================================================== "

    read configSSLDomain
    
    echo
    read -p "是否申请证书? 默认为自动申请证书,如果二次安装或已有证书可以选否 请输入[Y/n]?" isDomainSSLRequestInput
    isDomainSSLRequestInput=${isDomainSSLRequestInput:-Y}

    if compareRealIpWithLocalIp "${configSSLDomain}" ; then
        if [[ $isDomainSSLRequestInput == [Yy] ]]; then

            if [[ $1 == "air" ]] ; then
                if [[ $2 == "dns" ]] ; then
                    getHTTPSCertificate "dns"
                else
                    getHTTPSCertificate "standalone"
                fi
            else
                getHTTPSCertificate "standalone"
            fi


            if test -s ${configSSLCertPath}/${configSSLCertFullchainFilename}; then
                green " =================================================="
                green "   域名SSL证书申请成功 !"
                green " ${configSSLDomain} 域名证书内容文件路径 ${configSSLCertPath}/${configSSLCertFullchainFilename} "
                green " ${configSSLDomain} 域名证书私钥文件路径 ${configSSLCertPath}/${configSSLCertKeyFilename} "
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
            green "  不申请域名的证书, 请把证书放到如下目录, 或自行修改配置!"
            green "  ${configSSLDomain} 域名证书内容文件路径 ${configSSLCertPath}/${configSSLCertFullchainFilename} "
            green "  ${configSSLDomain} 域名证书私钥文件路径 ${configSSLCertPath}/${configSSLCertKeyFilename} "
            green " =================================================="
        fi
    else
        exit
    fi

}
































netflixMitmToolDownloadFolder="${HOME}/netflix_mitm_tool"
netflixMitmToolDownloadFilename="mitm-vip-unlocker-x86_64-linux-musl.zip"
netflixMitmToolUrl="https://github.com/jinwyp/one_click_script/raw/master/download/mitm-vip-unlocker-x86_64-linux-musl.zip"
configNetflixMitmPort="34567"
configNetflixMitmToken="-t token123"

function installShareNetflixAccount(){
    echo
    green " ================================================== "
    yellow " 准备安装Netflix账号共享 服务器端程序"
    yellow " 提供共享服务需要有一个Netflix账号 "
    yellow " 所安装的服务器 需要已原生解锁Netflix"
    red " 请务必用于私人用途 不要公开分享. Netflix也限制了同时在线人数"
    green " ================================================== "

    promptContinueOpeartion 

    echo
    read -p "是否生成随机的 端口号? 直接回车默认 34567 不生成随机端口号, 请输入[y/N]:" isNetflixMimePortInput
    isNetflixMimePortInput=${isNetflixMimePortInput:-n}

    if [[ $isNetflixMimePortInput == [Nn] ]]; then
        echo
    else
        configNetflixMitmPort="$(($RANDOM + 10000))"
    fi

    echo
    read -p "是否生成随机的管理员token密码? 直接回车默认 token123 不生成随机token, 请输入[y/N]:" isNetflixMimeTokenInput
    isNetflixMitmTokenInput=${isNetflixMitmTokenInput:-n}

    if [[ $isNetflixMitmTokenInput == [Nn] ]]; then
        echo
    else
        configNetflixMitmToken=""
    fi


    mkdir -p ${netflixMitmToolDownloadFolder}
    cd ${netflixMitmToolDownloadFolder}

    wget -P ${netflixMitmToolDownloadFolder} ${netflixMitmToolUrl}
    unzip -d ${netflixMitmToolDownloadFolder} ${netflixMitmToolDownloadFolder}/${netflixMitmToolDownloadFilename}
    chmod +x ./mitm-vip-unlocker
    ./mitm-vip-unlocker genca


    cat > ${osSystemMdPath}netflix_mitm.service <<-EOF
[Unit]
Description=mitm-vip-unlocker
After=network.target

[Service]
Type=simple
WorkingDirectory=${netflixMitmToolDownloadFolder}
PIDFile=${netflixMitmToolDownloadFolder}/mitm-vip-unlocker.pid
ExecStart=${netflixMitmToolDownloadFolder}/mitm-vip-unlocker run -b 0.0.0.0:${configNetflixMitmPort} ${configNetflixMitmToken}
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF

    ${sudoCmd} chmod +x ${osSystemMdPath}netflix_mitm.service
    ${sudoCmd} systemctl daemon-reload
    ${sudoCmd} systemctl start netflix_mitm.service
    #${sudoCmd} systemctl enable netflix_mitm.service

cat > ${netflixMitmToolDownloadFolder}/netflix_mitm_readme <<-EOF
用于给浏览器插件使用的管理员admin 的 token 为: ${configNetflixMitmToken}

服务器运行的端口号为: ${configNetflixMitmPort}


后续操作具体步骤如下:

1. 证书文件已生成, 默认在目录的 ${netflixMitmToolDownloadFolder}/ca/cert.crt 文件夹下, 请把cert.crt下载到本地
2. 在你自己的客户端机器上,安装好证书cert.crt 然后开启 http 代理, 代理服务器地址为:你的ip:${configNetflixMitmPort}

chrome 可以用 SwitchyOmega 插件作为 http代理 https://github.com/FelisCatus/SwitchyOmega 

新建一个情景例如名字叫奈飞代理 输入代理http服务器 你的ip 端口 ${configNetflixMitmPort}   
 
然后在自动切换 菜单里面 添加奈飞的几个域名 选择走奈飞代理这个情景 就可以了

netflix.com
netflix.net
nflxext.com
nflximg.net
nflxso.net
nflxvideo.net


3. 第一次使用需要上传的已登录Netflix账号的 cookie, 具体方法如下
使用Netflix账号登录Netflix官网. 然后安装 EditThisCookie 这个浏览器插件. 添加一个key为admin, value 值为 ${configNetflixMitmToken} 

一切已经完成, 其他设备就可以安装证书cert.crt, 使用http代理填入你的ip:${configNetflixMitmPort}, 就可以不需要账号看奈菲了


EOF

	green " ================================================== "
	green " Netflix账号共享 服务器端程序 安装成功 !"
    green " 重启命令: systemctl restart netflix_mitm.service"
	green " 查看运行状态命令:  systemctl status netflix_mitm.service "
	green " 查看日志命令: journalctl -n 40 -u netflix_mitm.service "
    echo
	green " 服务器运行的端口号为: ${configNetflixMitmPort}"
	green " 用于给浏览器插件使用的管理员admin的token为: ${configNetflixMitmToken}"
	green " 使用配置信息也可以查看 ${netflixMitmToolDownloadFolder}/netflix_mitm_readme "
    echo
    green " 后续操作具体步骤如下:"
    green " 1. 证书文件已生成, 默认在当前目录的ca文件夹下, 请把cert.crt下载到本地"
    green " 2. 在你自己的客户端机器上,安装好证书cert.crt 然后开启 http 代理, 代理服务器地址为:你的ip:${configNetflixMitmPort} "
    green " chrome 可以用 SwitchyOmega 插件作为 http代理 https://github.com/FelisCatus/SwitchyOmega "
    echo
    green " 3. 第一次使用需要上传的已登录Netflix账号的 cookie, 具体方法如下"
    green " 使用Netflix账号登录Netflix官网. 然后安装 EditThisCookie 这个浏览器插件. 添加一个key为admin, value 值为 ${configNetflixMitmToken} "
    green " EditThisCookie 浏览器插件 https://chrome.google.com/webstore/detail/editthiscookie/fngmhnnpilhplaeedifhccceomclgfbg"
    echo
    green " 一切已经完成, 其他设备就可以安装证书cert.crt, 使用http代理填入你的ip:${configNetflixMitmPort}, 就可以不需要账号看奈菲了"
    green " ================================================== "

}



function removeShareNetflixAccount(){
    if [[ -f "${netflixMitmToolDownloadFolder}/mitm-vip-unlocker" ]]; then
        echo
        green " ================================================== "
        red " 准备卸载已安装的 Netflix账号共享服务器端程序 mitm-vip-unlocker"
        green " ================================================== "
        echo

        ${sudoCmd} systemctl stop netflix_mitm.service
        ${sudoCmd} systemctl disable netflix_mitm.service
        ${sudoCmd} systemctl daemon-reload

        rm -rf ${netflixMitmToolDownloadFolder}
        rm -f ${osSystemMdPath}netflix_mitm.service

        echo
        green " ================================================== "
        green "  Netflix账号共享服务器端程序 mitm-vip-unlocker 卸载完毕 !"
        green " ================================================== "
        
    else
        red " 系统没有安装 Netflix账号共享服务器端程序 mitm-vip-unlocker, 退出卸载"
    fi
}













































function start_menu(){
    clear

    if [[ $1 == "first" ]] ; then
        getLinuxOSRelease
        installSoftDownload
    fi

    if [[ ${configLanguage} == "cn" ]] ; then
    green " =================================================="
    green " Linux 常用工具 一键安装脚本 | 2022-3-27 | By jinwyp | 系统支持：centos7+ / debian9+ / ubuntu16.04+"
    green " =================================================="
    green " 1. 安装 linux 内核 BBR Plus, 安装 WireGuard, 用于解锁 Netflix 限制 和避免弹出 Google reCAPTCHA 人机验证"
    echo
    green " 5. 用 VI 编辑 authorized_keys 文件 填入公钥, 用于SSH免密码登录 增加安全性"
    green " 6. 修改 SSH 登陆端口号"
    green " 7. 设置时区为北京时间"
    green " 8. 用VI 编辑 /etc/hosts"
    
    echo
    green " 11. 安装 Vim Nano Micro 编辑器"
    green " 12. 安装 Nodejs 与 PM2"
    green " 13. 安装 Docker 与 Docker Compose"
    red " 14. 卸载 Docker 与 Docker Compose"
    green " 15. 设置 Docker Hub 镜像 "
    green " 16. 安装 Portainer "
    green " 17. 安装 Cloudreve 云盘系统 "
    red " 18. 卸载 Cloudreve 云盘系统 "

    echo
    green " 21. 安装 V2Ray-Poseidon 服务器端"
    red " 22. 卸载 V2Ray-Poseidon"
    green " 23. 停止, 重启, 查看日志, 管理 V2Ray-Poseidon"
    echo
    green " 25. 编辑 V2Ray-Poseidon 直接命令行 方式运行 配置文件 v2ray-poseidon/config.json"
    green " 26. 编辑 V2Ray-Poseidon Docker WS-TLS 模式 Docker方式运行 配置文件 v2ray-poseidon/docker/v2board/ws-tls/config.json"
    green " 27. 编辑 V2Ray-Poseidon Docker WS-TLS 模式 Docker Compose 配置文件 v2ray-poseidon/docker/v2board/ws-tls/docker-compose.yml"
    
    echo
    green " 31. 安装 Soga 服务器端"
    green " 32. 停止, 重启, 查看日志等, 管理 Soga 服务器端"
    green " 33. 编辑 Soga 配置文件 ${configSogaConfigFilePath}"
    
    echo
    green " 41. 安装 XrayR 服务器端"
    green " 42. 停止, 重启, 查看日志等, 管理 XrayR 服务器端"
    green " 43. 编辑 XrayR 配置文件 ${configXrayRConfigFilePath}"

    echo
    green " 51. 安装 Air-Universe 服务器端"
    red " 52. 卸载 Air-Universe"
    green " 53. 停止, 重启, 查看日志等, 管理 Air-Universe 服务器端"
    green " 54. 编辑 Air-Universe 配置文件 ${configAirUniverseConfigFilePath}"
    green " 55. 编辑 Air-Universe Xray配置文件 ${configAirUniverseXrayConfigFilePath}"
    green " 56. 配合WARP(Wireguard) 使用IPV6 解锁 google人机验证和 Netflix等流媒体网站"
    green " 57. 降级 Air-Universe 到 0.9.2, 降级 Xray 到 1.5或1.4"
    green " 58. 重新申请证书 并修改 Air-Universe 配置文件 ${configAirUniverseConfigFilePath}"
    echo 
    green " 71. 单独申请域名SSL证书"
    green " 72. 安装共享Netflix账号服务器端, 可以不用奈菲账号直接看奈菲"
    green " 73. 卸载共享Netflix账号服务器端"
    echo
    green " 81. 工具脚本合集 by BlueSkyXN "
    green " 82. 工具脚本合集 by jcnf "
    echo
    green " 88. 升级脚本"
    green " 0. 退出脚本"

    else
    green " =================================================="
    green " Linux tools installation script | 2022-3-27 | By jinwyp | OS support：centos7+ / debian9+ / ubuntu16.04+"
    green " =================================================="
    green " 1. Install linux kernel,  bbr plus kernel, WireGuard and Cloudflare WARP. Unlock Netflix geo restriction and avoid Google reCAPTCHA"
    echo
    green " 5. Using VI open authorized_keys file, enter your public key. Then save file. In order to login VPS without Password"
    green " 6. Modify SSH login port number. Secure your VPS"
    green " 7. Set timezone to Beijing time"
    green " 8. Using VI open /etc/hosts file"
    
    echo
    green " 11. Install Vim Nano Micro editor"
    green " 12. Install Nodejs and PM2"
    green " 13. Install Docker and Docker Compose"
    red " 14. Remove Docker and Docker Compose"
    green " 15. Set Docker Hub Registry"
    green " 16. Install Portainer "
    green " 17. Install Cloudreve cloud storage system"
    red " 18. Remove Cloudreve cloud storage system"

    echo
    green " 21. Install V2Ray-Poseidon server side"
    red " 22. Remove V2Ray-Poseidon"
    green " 23. Stop, restart, show log, manage V2Ray-Poseidon"
    echo
    green " 25. Using VI open V2Ray-Poseidon config file v2ray-poseidon/config.json (direct command line running mode)"
    green " 26. Using VI open V2Ray-Poseidon Docker WS-TLS Mode config file v2ray-poseidon/docker/v2board/ws-tls/config.json (Docker mode)"
    green " 27. Using VI open V2Ray-Poseidon Docker WS-TLS Mode Docker Compose config file v2ray-poseidon/docker/v2board/ws-tls/docker-compose.yml (Docker mode)"
    
    echo
    green " 31. Install Soga server side "
    green " 32. Stop, restart, show log, manage Soga server side "
    green " 33. Using VI open Soga config file ${configSogaConfigFilePath}"
    
    echo
    green " 41. Install XrayR server side "
    green " 42. Stop, restart, show log, manage XrayR server side "
    green " 43. Using VI open XrayR config file ${configXrayRConfigFilePath}"

    echo
    green " 51. Install Air-Universe server side "
    red " 52. Remove Air-Universe"
    green " 53. Stop, restart, show log, manage Air-Universe server side "
    green " 54. Using VI open Air-Universe config file ${configAirUniverseConfigFilePath}"
    green " 55. Using VI open Air-Universe Xray config file ${configAirUniverseXrayConfigFilePath}"
    green " 56. Using WARP(Wireguard) and IPV6 Unlock Netflix geo restriction and avoid Google reCAPTCHA"
    green " 57. Downgrade Air-Universe to 0.9.2, downgrade Xray to 1.5 / 1.4"
    green " 58. Redo to get a free SSL certificate for domain name and modify Air-Universe config file ${configAirUniverseConfigFilePath}"
    echo 
    green " 71. Get a free SSL certificate for domain name only"
    echo
    green " 81. toolset by BlueSkyXN "
    green " 82. toolset by jcnf "
    echo
    green " 88. upgrade this script to latest version"
    green " 0. exit"

    fi


    echo
    read -p "Please input number:" menuNumberInput
    case "$menuNumberInput" in
        1 )
            installWireguard
        ;;    
        5 )
            editLinuxLoginWithPublicKey
        ;;
        6 )
            changeLinuxSSHPort
            sleep 10s
            start_menu
        ;;
        7 )
            setLinuxDateZone
            sleep 4s
            start_menu
        ;;
        8 )
            DSMEditHosts
        ;;
        11 )
            installSoftEditor
        ;;
        12 )
            installPackage
            installSoftEditor
            installNodejs
        ;;
        13 )
            testLinuxPortUsage
            setLinuxDateZone
            installPackage
            installDocker
        ;;
        14 )
            removeDocker 
        ;;
        15 )
            addDockerRegistry
        ;;
        16 )
            installPortainer 
        ;;
        17 )
            installCloudreve
        ;;
        18 )
            removeCloudreve
        ;;        
        20 )
            installPython3
            installPython3Rembg
        ;;


        21 )
            setLinuxDateZone
            installPackage
            installV2rayPoseidon
        ;;
        22 )
            removeV2rayPoseidon
        ;;
        23 )
            manageV2rayPoseidon
        ;;
        25 )
            editV2rayPoseidonConfig
        ;;
        26 )
            editV2rayPoseidonDockerWSConfig
        ;;
        27 )
            editV2rayPoseidonDockerComposeConfig
        ;;
       
        31 )
            setLinuxDateZone
            installSoga 
        ;;
        32 )
            manageSoga
        ;;                                        
        33 )
            editSogaConfig
        ;; 
        41 )
            setLinuxDateZone
            installXrayR
        ;;
        42 )
            manageXrayR
        ;;                                        
        43 )
            editXrayRConfig
        ;; 
        51 )
            setLinuxDateZone
            installAirUniverse
        ;;
        52 )
            removeAirUniverse
        ;;                                        
        53 )
            manageAirUniverse
        ;;                                        
        54 )
            editAirUniverseConfig
        ;; 
        55 )
            editAirUniverseXrayConfig
        ;; 
        56 )
            replaceAirUniverseConfigWARP
        ;; 
        57 )
            downgradeXray
        ;;
        58 )
            installAirUniverse "ssl"
        ;;        
        71 )
            getHTTPS
        ;;     
        72 )
            installShareNetflixAccount
        ;;
        73 )
            removeShareNetflixAccount
        ;;          
        81 )
            toolboxSkybox
        ;;                        
        82 )
            toolboxJcnf
        ;;      
        88 )
            upgradeScript
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






function setLanguage(){
    echo
    green " =================================================="
    green " Please choose your language"
    green " 1. 中文"
    green " 2. English"  
    echo
    read -p "Please input your language:" languageInput
    
    case "${languageInput}" in
        1 )
            echo "cn" > ${configLanguageFilePath}
            showMenu
        ;;
        2 )
            echo "en" > ${configLanguageFilePath}
            showMenu
        ;;
        * )
            red " Please input the correct number !"
            setLanguage
        ;;
    esac

}

configLanguageFilePath="${HOME}/language_setting_v2ray_trojan.md"
configLanguage="cn"

function showMenu(){

    if [ -f "${configLanguageFilePath}" ]; then
        configLanguage=$(cat ${configLanguageFilePath})

        case "${configLanguage}" in
        cn )
            start_menu "first"
        ;;
        en )
            start_menu "first"
        ;;
        * )
            setLanguage
        ;;
        esac
    else
        setLanguage
    fi
}

showMenu
