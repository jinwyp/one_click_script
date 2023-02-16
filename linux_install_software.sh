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



function showHeaderGreen(){
    echo
    green " =================================================="

    for parameter in "$@"
    do
        if [[ -n "${parameter}" ]]; then
            green " ${parameter}"
        fi
    done

    green " =================================================="
    echo
}
function showHeaderRed(){
    echo
    red " =================================================="
    for parameter in "$@"
    do
        if [[ -n "${parameter}" ]]; then
            red " ${parameter}"
        fi
    done
    red " =================================================="
    echo
}
function showInfoGreen(){
    echo
    for parameter in "$@"
    do
        if [[ -n "${parameter}" ]]; then
            green " ${parameter}"
        fi
    done
    echo
}


function promptContinueOpeartion(){
	read -p "是否继续操作? 直接回车默认继续操作, 请输入[Y/n]:" isContinueInput
	isContinueInput=${isContinueInput:-Y}

	if [[ $isContinueInput == [Yy] ]]; then
		echo ""
	else 
		exit
	fi
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

        if [ -n "$VERSION_CODENAME" ]; then
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
	read -r -p "是否继续操作? 直接回车默认继续操作, 请输入[Y/n]:" isContinueInput
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

    osPort80=$(netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 80)
    osPort443=$(netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 443)

    if [ -n "$osPort80" ]; then
        process80=$(netstat -tlpn | awk -F '[: ]+' '$5=="80"{print $9}')
        red "==========================================================="
        red "检测到80端口被占用，占用进程为：${process80} "
        red "==========================================================="
        promptContinueOpeartion
    fi

    if [ -n "$osPort443" ]; then
        process443=$(netstat -tlpn | awk -F '[: ]+' '$5=="443"{print $9}')
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

        if ! command -v ufw &> /dev/null; then
            echo "ufw command could not be found"
        else
            ufw disable
        fi


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
            if command -v semanage &> /dev/null; then
                semanage port -a -t ssh_port_t -p tcp ${osSSHLoginPortInput}
            fi

            if command -v firewall-cmd &> /dev/null; then
                firewall-cmd --permanent --zone=public --add-port=$osSSHLoginPortInput/tcp 
                firewall-cmd --reload
            fi


            ${sudoCmd} systemctl restart sshd.service

        fi

        if [ "$osRelease" == "ubuntu" ] || [ "$osRelease" == "debian" ] ; then
            
            if ! command -v semanage &> /dev/null; then
                echo "semanage command could not be found"
            else
                semanage port -a -t ssh_port_t -p tcp $osSSHLoginPortInput
            fi

            if ! command -v ufw &> /dev/null; then
                echo "ufw command could not be found"
            else
                ${sudoCmd} ufw allow $osSSHLoginPortInput/tcp
            fi


            ${sudoCmd} service ssh restart
            ${sudoCmd} systemctl restart ssh
        fi

        green "设置成功, 请记住设置的端口号 ${osSSHLoginPortInput}!"
        green "登陆服务器命令: ssh -p ${osSSHLoginPortInput} root@111.111.111.your ip !"
    else
        red "输入的端口号错误! 范围: 22,1025~65534"
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

                yellow " 设置成功! 当前时区已设置为 $(date -R)"
                green " =================================================="
            fi
        fi

    fi
    echo

    if [ "$osRelease" == "centos" ]; then   
        if  [[ ${osReleaseVersionNoShort} == "7" ]]; then
            systemctl stop chronyd
            systemctl disable chronyd

            $osSystemPackage -y install ntpdate
            $osSystemPackage -y install ntp
            ntpdate -q 0.rhel.pool.ntp.org
            systemctl enable ntpd
            systemctl restart ntpd
            ntpdate -u  pool.ntp.org

        elif  [[ ${osReleaseVersionNoShort} == "8" || ${osReleaseVersionNoShort} == "9" ]]; then
            $osSystemPackage -y install chrony
            systemctl enable chronyd
            systemctl restart chronyd

            if command -v firewall-cmd &> /dev/null; then
                firewall-cmd --permanent --add-service=ntp
                firewall-cmd --reload
            fi

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
			${osSystemPackage} -y install wget git unzip curl apt-transport-https
			
			# https://stackoverflow.com/questions/11116704/check-if-vt-x-is-activated-without-having-to-reboot-in-linux
			${osSystemPackage} -y install cpu-checker
		fi

		if ! dpkg -l | grep -qw curl; then
			${osSystemPackage} -y install curl git unzip wget apt-transport-https
			
			${osSystemPackage} -y install cpu-checker
		fi

	elif [[ "${osRelease}" == "centos" ]]; then

        if  [[ ${osReleaseVersion} == "8.1.1911" || ${osReleaseVersion} == "8.2.2004" || ${osReleaseVersion} == "8.0.1905" ]]; then

            # https://techglimpse.com/failed-metadata-repo-appstream-centos-8/

            cd /etc/yum.repos.d/
            sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
            sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
            yum update -y

            sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
            sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*

            ${sudoCmd} dnf install centos-release-stream -y
            ${sudoCmd} dnf swap centos-{linux,stream}-repos -y
            ${sudoCmd} dnf distro-sync -y
        fi
        
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

    
    # sed -i '1s/^/nameserver 1.1.1.1 \n/' /etc/resolv.conf


    if [ "$osRelease" == "centos" ]; then
       
        # rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
        rm -f /etc/yum.repos.d/nginx.repo
        # cat > "/etc/yum.repos.d/nginx.repo" <<-EOF
# [nginx]
# name=nginx repo
# baseurl=https://nginx.org/packages/centos/$osReleaseVersionNoShort/\$basearch/
# gpgcheck=0
# enabled=1
# sslverify=0
# 
# EOF

        if ! rpm -qa | grep -qw iperf3; then
			${sudoCmd} ${osSystemPackage} install -y epel-release

            ${osSystemPackage} install -y curl wget git unzip zip tar bind-utils htop net-tools
            ${osSystemPackage} install -y xz jq redhat-lsb-core 
            ${osSystemPackage} install -y iputils
            ${osSystemPackage} install -y iperf3
		fi

        ${osSystemPackage} update -y


        # https://www.cyberciti.biz/faq/how-to-install-and-use-nginx-on-centos-8/
        if  [[ ${osReleaseVersionNoShort} == "8" || ${osReleaseVersionNoShort} == "9" ]]; then
            ${sudoCmd} yum module -y reset nginx
            ${sudoCmd} yum module -y enable nginx:1.20
            ${sudoCmd} yum module list nginx
        fi

    elif [ "$osRelease" == "ubuntu" ]; then
        
        # https://joshtronic.com/2018/12/17/how-to-install-the-latest-nginx-on-debian-and-ubuntu/
        # https://www.nginx.com/resources/wiki/start/topics/tutorials/install/
        
        $osSystemPackage install -y gnupg2 curl ca-certificates lsb-release ubuntu-keyring
        # wget -O - https://nginx.org/keys/nginx_signing.key | ${sudoCmd} apt-key add -
        curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

        rm -f /etc/apt/sources.list.d/nginx.list

        cat > "/etc/apt/sources.list.d/nginx.list" <<-EOF
deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg]   https://nginx.org/packages/ubuntu/ $osReleaseVersionCodeName nginx
# deb [arch=amd64] https://nginx.org/packages/ubuntu/ $osReleaseVersionCodeName nginx
# deb-src https://nginx.org/packages/ubuntu/ $osReleaseVersionCodeName nginx
EOF

        echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n"  | sudo tee /etc/apt/preferences.d/99-nginx

        if [[ "${osReleaseVersionNoShort}" == "22" || "${osReleaseVersionNoShort}" == "21" ]]; then
            echo
        fi



        ${osSystemPackage} update -y

        if ! dpkg -l | grep -qw iperf3; then
            ${sudoCmd} ${osSystemPackage} install -y software-properties-common
            ${osSystemPackage} install -y curl wget git unzip zip tar htop
            ${osSystemPackage} install -y xz-utils jq lsb-core lsb-release
            ${osSystemPackage} install -y iputils-ping
            ${osSystemPackage} install -y iperf3
		fi    

    elif [ "$osRelease" == "debian" ]; then
        # ${sudoCmd} add-apt-repository ppa:nginx/stable -y
        ${osSystemPackage} update -y

        apt install -y gnupg2
        apt install -y curl ca-certificates lsb-release
        wget https://nginx.org/keys/nginx_signing.key -O- | apt-key add - 

        rm -f /etc/apt/sources.list.d/nginx.list
        if [[ "${osReleaseVersionNoShort}" == "12" ]]; then
            echo
        else
            cat > "/etc/apt/sources.list.d/nginx.list" <<-EOF
deb https://nginx.org/packages/mainline/debian/ $osReleaseVersionCodeName nginx
deb-src https://nginx.org/packages/mainline/debian $osReleaseVersionCodeName nginx
EOF
        fi


        ${osSystemPackage} update -y

        if ! dpkg -l | grep -qw iperf3; then
            ${osSystemPackage} install -y curl wget git unzip zip tar htop
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
        $osSystemPackage install -y xz  vim-minimal vim-enhanced vim-common nano
    else
        $osSystemPackage install -y vim-gui-common vim-runtime vim nano
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


function installCasaOS(){
    wget -O- https://get.casaos.io | bash
}
function removeCasaOS(){
    casaos-uninstall
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
    wget --no-check-certificate -qO- https://api.github.com/repos/$1/tags | grep 'name' | cut -d\" -f4 | sort -r | head -1 | cut -b 1-
}











function installNodejs(){
    
    showHeaderGreen "Prepare to install Nodejs"

    if [ "$osRelease" == "centos" ] ; then

        if [ "$osReleaseVersion" == "7" ]; then
            curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
            ${sudoCmd} yum install -y nodejs
        else
            ${sudoCmd} dnf module list nodejs
            ${sudoCmd} dnf module switch-to nodejs:16 -y
            ${sudoCmd} dnf module enable nodejs:16 -y
            ${sudoCmd} dnf module list nodejs
            ${sudoCmd} dnf install -y nodejs
        fi

    else 
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
        echo 'export NVM_DIR="$HOME/.nvm"' >> ${HOME}/.zshrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ${HOME}/.zshrc
        source ${HOME}/.zshrc

        command -v nvm
        nvm --version
        nvm ls-remote
        nvm install --lts

    fi

    echo
    green " Nodejs 版本:"
    node --version 
    echo
    green " NPM 版本:"
    npm --version  

    showHeaderGreen "准备安装 PM2 进程守护程序"
    npm install -g pm2 

    showHeaderGreen "Nodejs 与 PM2 安装成功 !"
}




configDockerDownloadPath="${HOME}/download"
configDockerComposePath="/usr/local/lib/docker/cli-plugins"

function installDocker(){

    showHeaderGreen "准备安装 Docker 与 Docker Compose"

    mkdir -p ${configDockerDownloadPath}
    cd ${configDockerDownloadPath}


    if [[ -s "/usr/bin/docker" ]]; then
        showHeaderRed "已安装过 Docker. Docker already installed!"
    else

        if [[ "${osInfo}" == "AlmaLinux" ]]; then
            ${sudoCmd} yum module remove container-tools
            # https://linuxconfig.org/install-docker-on-almalinux
            ${sudoCmd} dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            ${sudoCmd} dnf remove -y podman buildah 
            ${sudoCmd} dnf install -y docker-ce docker-ce-cli containerd.io
 
        else
            # curl -fsSL https://get.docker.com -o get-docker.sh  
            curl -sSL https://get.daocloud.io/docker -o ${configDockerDownloadPath}/get-docker.sh  
            chmod +x ${configDockerDownloadPath}/get-docker.sh
            ${configDockerDownloadPath}/get-docker.sh

        fi
        ${sudoCmd}
        ${sudoCmd} systemctl start docker.service
        ${sudoCmd} systemctl enable docker.service
        
        showHeaderGreen "Docker installed successfully !"
        docker version
        echo
    fi


    if [[ -s "/usr/local/bin/docker-compose" ]]; then
        showHeaderRed "已安装过 Docker Compose. Docker Compose already installed!"
    else

        versionDockerCompose=$(getGithubLatestReleaseVersion "docker/compose")

        # dockerComposeUrl="https://github.com/docker/compose/releases/download/v${versionDockerCompose}/docker-compose-$(uname -s)-$(uname -m)"
        dockerComposeUrl="https://github.com/docker/compose/releases/download/v2.9.0/docker-compose-linux-x86_64"
        dockerComposeUrl="https://get.daocloud.io/docker/compose/releases/download/v${versionDockerCompose}/docker-compose-linux-x86_64"
        
        showInfoGreen "Downloading  ${dockerComposeUrl}"


        mkdir -p ${configDockerComposePath}

        ${sudoCmd} wget -O ${configDockerComposePath}/docker-compose "${dockerComposeUrl}"
        ${sudoCmd} chmod a+x ${configDockerComposePath}/docker-compose
        ${sudoCmd} ln -s ${configDockerComposePath}/docker-compose /usr/local/bin/docker-compose
        #${sudoCmd} ln -s ${configDockerComposePath}/docker-compose /usr/bin/docker-compose

        rm -f "$(which dc)"
        ${sudoCmd} ln -s ${configDockerComposePath}/docker-compose /usr/bin/dc
        
        # rm -f "/usr/bin/docker-compose"
        # ${sudoCmd} ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
        
        showHeaderGreen "Docker-Compose installed successfully !"
        docker compose version
        echo
    fi

    showHeaderGreen "Docker 与 Docker Compose 安装成功 !"
    # systemctl status docker.service
}

function removeDocker(){

    if [ "$osRelease" == "centos" ] ; then

        sudo yum remove docker docker-common container-selinux docker-selinux docker-engine

    else 
        sudo apt-get remove docker docker-engine

    fi

    rm -rf /var/lib/docker/

    rm -f "$(which dc)" 
    rm -f "/usr/bin/docker-compose"
    rm -f "/usr/local/bin/docker-compose"
    rm -f "${DOCKER_CONFIG}/cli-plugins/docker-compose"

    showHeaderGreen "Docker 已经卸载完毕 !"
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

    ${sudoCmd} systemctl daemon-reload
    ${sudoCmd} systemctl restart docker
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

    showHeaderGreen " Portainer 安装成功. Running at port 8000 !"
}

















































acmeSSLRegisterEmailInput=""
isDomainSSLGoogleEABKeyInput=""
isDomainSSLGoogleEABIdInput=""

function getHTTPSCertificateCheckEmail(){
    if [ -z $2 ]; then
        
        if [[ $1 == "email" ]]; then
            red " 输入邮箱地址不能为空, 请重新输入!"
            getHTTPSCertificateInputEmail
        elif [[ $1 == "googleEabKey" ]]; then
            red " 输入EAB key 不能为空, 请重新输入!"
            getHTTPSCertificateInputGoogleEABKey
        elif [[ $1 == "googleEabId" ]]; then
            red " 输入EAB Id 不能为空, 请重新输入!"
            getHTTPSCertificateInputGoogleEABId            
        fi
    fi
}
function getHTTPSCertificateInputEmail(){
    echo
    read -r -p "请输入邮箱地址, 用于申请证书:" acmeSSLRegisterEmailInput
    getHTTPSCertificateCheckEmail "email" "${acmeSSLRegisterEmailInput}"
}
function getHTTPSCertificateInputGoogleEABKey(){
    echo
    read -r -p "请输入 Google EAB key :" isDomainSSLGoogleEABKeyInput
    getHTTPSCertificateCheckEmail "googleEabKey" "${isDomainSSLGoogleEABKeyInput}"
}
function getHTTPSCertificateInputGoogleEABId(){
    echo
    read -r -p "请输入 Google EAB id :" isDomainSSLGoogleEABIdInput
    getHTTPSCertificateCheckEmail "googleEabId" "${isDomainSSLGoogleEABIdInput}"
}

configNetworkRealIp=""
configSSLDomain=""

acmeSSLDays="89"
acmeSSLServerName="letsencrypt"
acmeSSLDNSProvider="dns_cf"

configRanPath="${HOME}/ran"
configSSLAcmeScriptPath="${HOME}/.acme.sh"
configWebsiteFatherPath="/nginxweb"
configSSLCertPath="${configWebsiteFatherPath}/cert"
configSSLCertPathV2board="${configWebsiteFatherPath}/cert/v2board"
configSSLCertKeyFilename="server.key"
configSSLCertFullchainFilename="server.crt"




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
    green " 4 Google Public CA "
    echo
    read -r -p "请选择证书提供商? 默认直接回车为通过 Letsencrypt.org 申请, 请输入纯数字:" isDomainSSLFromLetInput
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

    elif [[ "$isDomainSSLFromLetInput" == "4" ]]; then
        green " ================================================== "
        yellow " 请先按照如下链接申请 google Public CA  https://hostloc.com/thread-993780-1-1.html"
        yellow " 具体可参考 https://github.com/acmesh-official/acme.sh/wiki/Google-Public-CA"
        getHTTPSCertificateInputEmail
        acmeSSLServerName="google"
        getHTTPSCertificateInputGoogleEABKey
        getHTTPSCertificateInputGoogleEABId
        ${configSSLAcmeScriptPath}/acme.sh --register-account -m ${acmeSSLRegisterEmailInput} --server google --eab-kid ${isDomainSSLGoogleEABIdInput} --eab-hmac-key ${isDomainSSLGoogleEABKeyInput}    
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

        if [[ "${isInstallNginx}" == "true" ]]; then
            acmeDefaultValue="3"
            acmeDefaultText="3. webroot 并使用ran作为临时的Web服务器"
            acmeSSLHttpWebrootMode="webrootran"
        else
            acmeDefaultValue="1"
            acmeDefaultText="1. standalone 模式"
            acmeSSLHttpWebrootMode="standalone"
        fi

        if [ -z "$1" ]; then
            green " ================================================== "
            green " 请选择 http 申请证书方式: 默认直接回车为 ${acmeDefaultText} "
            green " 1 standalone 模式, 适合没有安装Web服务器, 如已选择不安装Nginx 请选择此模式. 请确保80端口不被占用. 注意:三个月后续签时80端口被占用会导致续签失败!"
            green " 2 webroot 模式, 适合已经安装Web服务器, 例如 Caddy Apache 或 Nginx, 请确保Web服务器已经运行在80端口"
            green " 3 webroot 模式 并使用 ran 作为临时的Web服务器, 如已选择同时安装Nginx，请使用此模式, 可以正常续签"
            green " 4 nginx 模式 适合已经安装 Nginx, 请确保 Nginx 已经运行"
            echo
            read -r -p "请选择http申请证书方式? 默认为 ${acmeDefaultText}, 请输入纯数字:" isAcmeSSLWebrootModeInput
       
            isAcmeSSLWebrootModeInput=${isAcmeSSLWebrootModeInput:-${acmeDefaultValue}}
            
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
            

            if [ -z "${isDomainSSLNginxWebrootFolderInput}" ]; then
                red " 输入的Web服务器的 html网站根目录路径不能为空, 网站根目录将默认设置为 ${configWebsitePath}, 请修改你的web服务器配置后再申请证书!"
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
    if [[ ${isAcmeSSLWebrootModeInput} == "1" ]]; then
        ${configSSLAcmeScriptPath}/acme.sh --installcert --ecc -d ${configSSLDomain} \
        --key-file ${configSSLCertPath}/${configSSLCertKeyFilename} \
        --fullchain-file ${configSSLCertPath}/${configSSLCertFullchainFilename} 
    else
        ${configSSLAcmeScriptPath}/acme.sh --installcert --ecc -d ${configSSLDomain} \
        --key-file ${configSSLCertPath}/${configSSLCertKeyFilename} \
        --fullchain-file ${configSSLCertPath}/${configSSLCertFullchainFilename} \
        --reloadcmd "systemctl restart nginx.service"
    fi
    green " ================================================== "

}



function compareRealIpWithLocalIp(){
    echo
    echo
    green " 是否检测域名指向的IP正确 直接回车默认检测"
    red " 如果域名指向的IP不是本机IP, 或已开启CDN不方便关闭 或只有IPv6的VPS 可以选否不检测"
    read -r -p "是否检测域名指向的IP正确? 请输入[Y/n]:" isDomainValidInput
    isDomainValidInput=${isDomainValidInput:-Y}

    if [[ $isDomainValidInput == [Yy] ]]; then
        if [ -n "$1" ]; then
            configNetworkRealIp=$(ping $1 -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
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
            if [[ ${configNetworkRealIp} == "${configNetworkLocalIp1}" || ${configNetworkRealIp} == "${configNetworkLocalIp2}" ]] ; then

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
isDomainSSLGoogleEABKeyInput=""
isDomainSSLGoogleEABIdInput=""



function getHTTPSCertificateStep1(){

    testLinuxPortUsage

    echo
    green " ================================================== "
    yellow " 请输入绑定到本VPS的域名 例如www.xxx.com: (此步骤请关闭CDN后和nginx后安装 避免80端口占用导致申请证书失败)"
    read -r -p "请输入解析到本VPS的域名:" configSSLDomain
    
    if compareRealIpWithLocalIp "${configSSLDomain}" ; then
        echo
        green " =================================================="
        green " 是否申请证书? 默认直接回车为申请证书, 如第二次安装或已有证书 可以选否"
        green " 如果已经有SSL证书文件 请放到下面路径"
        red " ${configSSLDomain} 域名证书内容文件路径 ${configSSLCertPath}/${configSSLCertFullchainFilename} "
        red " ${configSSLDomain} 域名证书私钥文件路径 ${configSSLCertPath}/${configSSLCertKeyFilename} "
        echo

        read -r -p "是否申请证书? 默认直接回车为自动申请证书,请输入[Y/n]?" isDomainSSLRequestInput
        isDomainSSLRequestInput=${isDomainSSLRequestInput:-Y}

        if [[ $isDomainSSLRequestInput == [Yy] ]]; then
            
            getHTTPSCertificateWithAcme ""

            if test -s "${configSSLCertPath}/${configSSLCertFullchainFilename}"; then
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




















































































configAlistPort="$(($RANDOM + 4000))"
configAlistPort="5244"
configAlistSystemdServicePath="/etc/systemd/system/alist.service"


function installAlist(){
    echo
    green " =================================================="
    green " 请选择 安装/更新/删除 Alist "
    green " 1. 安装 Alist "
    green " 2. 安装 Alist + Nginx (需要域名 并已解析到本机IP)"
    green " 3. 更新 Alist"  
    red " 4. 删除 Alist"     
    echo
    read -r -p "请输入纯数字, 默认为安装:" languageInput
    
    createUserWWW

    case "${languageInput}" in
        1 )
            curl -fsSL "https://nn.ci/alist.sh" | bash -s install
            sed -i "/^\[Service\]/a \User=www-data" ${configAlistSystemdServicePath}
            ${sudoCmd} systemctl daemon-reload
            ${sudoCmd} systemctl restart alist       
        ;;
        2 )
            curl -fsSL "https://nn.ci/alist.sh" | bash -s install
            sed -i "/^\[Service\]/a \User=www-data" ${configAlistSystemdServicePath}
            ${sudoCmd} systemctl daemon-reload
            ${sudoCmd} systemctl restart alist    

            green " ================================================== "
            echo
            green "是否安装 Nginx web服务器, 安装Nginx可以提高安全性并提供更多功能"
            green "如要安装 Nginx 需要提供域名, 并设置好域名DNS已解析到本机IP"
            read -r -p "是否安装 Nginx web服务器? 直接回车默认安装, 请输入[Y/n]:" isNginxAlistInstallInput
            isNginxAlistInstallInput=${isNginxAlistInstallInput:-Y}

            if [[ "${isNginxAlistInstallInput}" == [Yy] ]]; then
                isInstallNginx="true"
                configSSLCertPath="${configSSLCertPath}/alist"
                getHTTPSCertificateStep1
                configInstallNginxMode="alist"
                installWebServerNginx
            fi
        ;;        
        3 )
            curl -fsSL "https://nn.ci/alist.sh" | bash -s update
        ;;
        4 )
            curl -fsSL "https://nn.ci/alist.sh" | bash -s uninstall
        ;;
        * )
            exit
        ;;
    esac
    echo
    green " =================================================="
    green " Alist 安装路径为 /opt/alist "
    green " =================================================="

}
function installAlistCert(){
        configSSLCertPath="${configSSLCertPath}/alist"
        getHTTPSCertificateStep1
}   































wwwUsername="www-data"
function createUserWWW(){
	isHaveWwwUser=$(cat /etc/passwd | cut -d ":" -f 1 | grep ^${wwwUsername}$)
	if [ "${isHaveWwwUser}" != "${wwwUsername}" ]; then
		${sudoCmd} groupadd ${wwwUsername}
		${sudoCmd} useradd -s /usr/sbin/nologin -g ${wwwUsername} ${wwwUsername} --no-create-home         
	fi
}
function createNewUserNologin(){
    newUsername=${1:-etherpad}
    if [[ -z $(cat /etc/passwd | grep ${newUsername}) ]]; then
        ${sudoCmd} useradd -M -s /sbin/nologin ${newUsername}
    fi
}
function createNewUser(){
    newUsername=${1:-etherpad}
    if [[ -z $(cat /etc/passwd | grep ${newUsername}) ]]; then
        ${sudoCmd} useradd -rm ${newUsername} -U
        if [ "$osRelease" == "centos" ]; then
            usermod -aG wheel ${newUsername}
        else
            usermod -aG sudo ${newUsername} 
        fi
    fi
}

configCloudrevePath="/usr/local/cloudreve"
configCloudreveDownloadCodeFolder="${configCloudrevePath}/download"
configCloudreveCommandFolder="${configCloudrevePath}/cmd"
configCloudreveReadme="${configCloudrevePath}/cmd/readme.txt"
configCloudreveIni="${configCloudrevePath}/cmd/conf.ini"
configCloudrevePort="$(($RANDOM + 4000))"


function installCloudreve(){

    if [ -f "${configCloudreveCommandFolder}/cloudreve" ]; then
        green " =================================================="
        green "     Cloudreve Already installed !"
        green " =================================================="
        exit
    fi

    createUserWWW

    versionCloudreve=$(getGithubLatestReleaseVersion2 "cloudreve/Cloudreve")

    green " ================================================== "
    green "   Prepare to install Cloudreve ${versionCloudreve}"
    green " ================================================== "


    mkdir -p ${configCloudreveDownloadCodeFolder}
    mkdir -p ${configCloudreveCommandFolder}
    cd ${configCloudrevePath}


    # https://github.com/cloudreve/Cloudreve/releases/download/3.5.3/cloudreve_3.5.3_linux_amd64.tar.gz
    # https://github.com/cloudreve/Cloudreve/releases/download/3.4.2/cloudreve_3.4.2_linux_arm.tar.gz
    # https://github.com/cloudreve/Cloudreve/releases/download/3.4.2/cloudreve_3.4.2_linux_arm64.tar.gz
    

    downloadFilenameCloudreve="cloudreve_${versionCloudreve}_linux_amd64.tar.gz"
    if [[ ${osArchitecture} == "arm" ]] ; then
        downloadFilenameCloudreve="cloudreve_${versionCloudreve}_linux_arm.tar.gz"
    fi
    if [[ ${osArchitecture} == "arm64" ]] ; then
        downloadFilenameCloudreve="cloudreve_${versionCloudreve}_linux_arm64.tar.gz"
    fi

    downloadAndUnzip "https://github.com/cloudreve/Cloudreve/releases/download/${versionCloudreve}/${downloadFilenameCloudreve}" "${configCloudreveDownloadCodeFolder}" "${downloadFilenameCloudreve}"

    mv ${configCloudreveDownloadCodeFolder}/cloudreve ${configCloudreveCommandFolder}/cloudreve
    chmod +x ${configCloudreveCommandFolder}/cloudreve


    cd ${configCloudreveCommandFolder}
    echo "nohup ${configCloudreveCommandFolder}/cloudreve > ${configCloudreveReadme} 2>&1 &"
    nohup ${configCloudreveCommandFolder}/cloudreve > ${configCloudreveReadme} 2>&1 &
    sleep 3
    pidCloudreve=$(ps -ef | grep cloudreve | grep -v grep | awk '{print $2}')
    echo "kill -9 ${pidCloudreve}"
    kill -9 ${pidCloudreve}
    echo

    ${sudoCmd} chown -R ${wwwUsername}:${wwwUsername} ${configCloudrevePath}
    ${sudoCmd} chmod -R 771 ${configCloudrevePath}


    cat > ${osSystemMdPath}cloudreve.service <<-EOF
[Unit]
Description=Cloudreve
Documentation=https://docs.cloudreve.org
After=network.target
Wants=network.target

[Service]
User=${wwwUsername}
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

    echo
    echo "Install cloudreve systemmd service ..."
    sed -i "s/5212/${configCloudrevePort}/g" ${configCloudreveIni}
    sed -i "s/5212/${configCloudrevePort}/g" ${configCloudreveReadme}

    systemctl daemon-reload
    systemctl start cloudreve
    systemctl enable cloudreve

    ${configCloudreveCommandFolder}/cloudreve -eject

    ${sudoCmd} chown -R ${wwwUsername}:${wwwUsername} ${configCloudrevePath}
    ${sudoCmd} chmod -R 771 ${configCloudrevePath}


    echo
    green " ================================================== "
    green " Cloudreve Installed ! Working port: ${configCloudrevePort}"
    green " Please visit http://your ip:${configCloudrevePort}"
    green " 如无法访问, 请设置Firewall防火墙规则 放行 ${configCloudrevePort} 端口"
    green " 查看运行状态命令: systemctl status cloudreve  重启: systemctl restart cloudreve "
    green " Cloudreve INI 配置文件路径: ${configCloudreveIni}"
    green " Cloudreve 默认SQLite 数据库文件路径: ${configCloudreveCommandFolder}/cloudreve.db"
    green " Cloudreve readme 账号密码文件路径: ${configCloudreveReadme}"
    

    cat ${configCloudreveReadme}
    green " ================================================== "

    echo
    green "是否继续安装 Nginx web服务器, 安装Nginx可以提高安全性并提供更多功能"
    green "如要安装 Nginx 需要提供域名, 并设置好域名DNS已解析到本机IP"
    read -p "是否安装 Nginx web服务器? 直接回车默认安装, 请输入[Y/n]:" isNginxInstallInput
    isNginxInstallInput=${isNginxInstallInput:-Y}

    if [[ "${isNginxInstallInput}" == [Yy] ]]; then
        isInstallNginx="true"
        configSSLCertPath="${configSSLCertPath}/cloudreve"
        getHTTPSCertificateStep1
        configInstallNginxMode="cloudreve"
        installWebServerNginx
    fi

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

            rm -rf "${configSSLCertPath}/cloudreve"

            rm -rf ${configCloudrevePath}
            rm -f ${osSystemMdPath}cloudreve.service
            rm -f "${nginxConfigSiteConfPath}/cloudreve_site.conf"
            
            systemctl restart nginx.service
            showHeaderGreen "  Cloudreve removed !"
            
        else
            showHeaderRed " Cloudreve not found !"
        fi

    fi

    removeNginx
}






























configWebsitePath="${configWebsiteFatherPath}/html"
nginxAccessLogFilePath="${configWebsiteFatherPath}/nginx-access.log"
nginxErrorLogFilePath="${configWebsiteFatherPath}/nginx-error.log"

nginxConfigPath="/etc/nginx/nginx.conf"
nginxConfigSiteConfPath="/etc/nginx/conf.d"
nginxCloudreveStoragePath="${configWebsitePath}/cloudreve_storage"
nginxAlistStoragePath="${configWebsitePath}/alist_storage"
nginxTempPath="/var/lib/nginx/tmp"
nginxProxyTempPath="/var/lib/nginx/proxy_temp"
isInstallNginx="false"

function installWebServerNginx(){

    echo
    green " ================================================== "
    yellow "     开始安装 Web服务器 nginx !"
    green " ================================================== "
    echo

    if test -s ${nginxConfigPath}; then
        showHeaderRed "Nginx 已存在, 是否继续安装?" "Nginx already exists. Continue the installation? "
        promptContinueOpeartion

        ${sudoCmd} systemctl stop nginx.service
    else

        isInstallNginx="true"

        createUserWWW
        nginxUser="${wwwUsername} ${wwwUsername}"
        
        if [ "$osRelease" == "centos" ]; then
            ${osSystemPackage} install -y nginx-mod-stream
        else
            echo
            groupadd -r -g 4 adm

            apt autoremove -y
            apt-get remove --purge -y nginx-common
            apt-get remove --purge -y nginx-core
            apt-get remove --purge -y libnginx-mod-stream
            apt-get remove --purge -y libnginx-mod-http-xslt-filter libnginx-mod-http-geoip2 libnginx-mod-stream-geoip2 libnginx-mod-mail libnginx-mod-http-image-filter

            apt autoremove -y --purge nginx nginx-common nginx-core
            apt-get remove --purge -y nginx nginx-full nginx-common nginx-core

            #${osSystemPackage} install -y libnginx-mod-stream
        fi

        ${osSystemPackage} install -y nginx
        ${sudoCmd} systemctl enable nginx.service
        ${sudoCmd} systemctl stop nginx.service

        # 解决出现的nginx warning 错误 Failed to parse PID from file /run/nginx.pid: Invalid argument
        # https://www.kancloud.cn/tinywan/nginx_tutorial/753832
        
        mkdir -p /etc/systemd/system/nginx.service.d
        printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
        
        ${sudoCmd} systemctl daemon-reload

    fi





    mkdir -p ${configWebsitePath}
    mkdir -p "${nginxConfigSiteConfPath}"

    rm -rf ${configWebsitePath}/*
    downloadAndUnzip "https://github.com/jinwyp/one_click_script/raw/master/download/website2.zip" "${configWebsitePath}" "website2.zip"


    nginxConfigServerHttpInput=""

    if [[ "${configInstallNginxMode}" == "airuniverse" ]]; then
        configV2rayWebSocketPath=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
        
        echo
        read -r -p "是否自定义xray的 Websocket 的Path? 直接回车默认创建随机路径, 请输入自定义路径(不要输入/):" isV2rayUserWSPathInput
        isV2rayUserWSPathInput=${isV2rayUserWSPathInput:-${configV2rayWebSocketPath}}
        
        if [[ -z $isV2rayUserWSPathInput ]]; then
            echo
        else
            configV2rayWebSocketPath=${isV2rayUserWSPathInput}
        fi

        configV2rayWebSocketPath="9b08c0d789"

        echo
        read -r -p "输入xray的端口号? 直接回车默认为8799, 请输入自定义端口号[1-65535]:" configV2rayPort
        configV2rayPort=${configV2rayPort:-8799}

        cat > "${nginxConfigSiteConfPath}/airuniverse.conf" <<-EOF

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
    }

    server {
        listen  80;
        server_name  $configSSLDomain;
        root $configWebsitePath;
        index index.php index.html index.htm;
    }

EOF

    elif [[ "${configInstallNginxMode}" == "ghost" ]]; then

        cat > "${nginxConfigSiteConfPath}/ghost_site.conf" <<-EOF

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

        location / {
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header Host \$http_host;
            proxy_pass http://127.0.0.1:3468;

            # 如果您要使用本地存储策略，请将下一行注释符删除，并更改大小为理论最大文件尺寸
            client_max_body_size  7000m;
        }
    }

    server {
        listen 80;
        listen [::]:80;

        server_name  $configSSLDomain;
        root ${configGhostSitePath}/system/nginx-root; # Used for acme.sh SSL verification (https://acme.sh)
        index index.php index.html index.htm;

        location / {
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header Host \$http_host;
            proxy_pass http://127.0.0.1:3468;
        }

        location ~ /.well-known {
            allow all;
        }

        client_max_body_size 50m;
    }


EOF

    elif [[ "${configInstallNginxMode}" == "cloudreve" ]]; then
        mkdir -p ${configWebsitePath}/static
        cp -f -R ${configCloudreveCommandFolder}/statics/* ${configWebsitePath}/static
        mv -f ${configWebsitePath}/static/static/* ${configWebsitePath}/static

        mkdir -p ${nginxCloudreveStoragePath}
        ${sudoCmd} chown -R ${wwwUsername}:${wwwUsername} ${nginxCloudreveStoragePath}
        ${sudoCmd} chmod -R 774 ${nginxCloudreveStoragePath}

        cat > "${nginxConfigSiteConfPath}/cloudreve_site.conf" <<-EOF

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

        location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$ {
            expires      3d;
            error_log /dev/null;
            access_log /dev/null;
        }
        
        location ~ .*\.(js|css)?$ {
            expires      24h;
            error_log /dev/null;
            access_log /dev/null; 
        }
        
        location /static {
            root $configWebsitePath;
        }

        location / {

            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header Host \$http_host;
            proxy_redirect off;
            proxy_pass http://127.0.0.1:${configCloudrevePort};

            # 如果您要使用本地存储策略，请将下一行注释符删除，并更改大小为理论最大文件尺寸
            client_max_body_size   7000m;
        }
    }

    server {
        listen 80;
        listen [::]:80;
        server_name  $configSSLDomain;
        return 301 https://$configSSLDomain\$request_uri;
    }

EOF


    elif [[ "${configInstallNginxMode}" == "alist" ]]; then

        mkdir -p ${nginxAlistStoragePath}
        ${sudoCmd} chown -R ${wwwUsername}:${wwwUsername} ${nginxAlistStoragePath}
        ${sudoCmd} chmod -R 774 ${nginxAlistStoragePath}

        cat > "${nginxConfigSiteConfPath}/alist_site.conf" <<-EOF

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

        location / {

            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header Host \$http_host;
            proxy_set_header Range \$http_range;
            proxy_set_header If-Range \$http_if_range;
            proxy_redirect off;
            proxy_pass http://127.0.0.1:${configAlistPort};

            # 上传的最大文件尺寸
            client_max_body_size   20000m;
        }
    }

    server {
        listen 80;
        listen [::]:80;
        server_name  $configSSLDomain;
        return 301 https://$configSSLDomain\$request_uri;
    }

EOF
    elif [[ "${configInstallNginxMode}" == "grist" ]]; then

        cat > "${nginxConfigSiteConfPath}/grist_site.conf" <<-EOF

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

        location / {

            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header Host \$http_host;
            proxy_set_header Range \$http_range;
            proxy_set_header If-Range \$http_if_range;
            proxy_redirect off;
            proxy_pass http://127.0.0.1:8484;

        }
    }

    server {
        listen 80;
        listen [::]:80;
        server_name  $configSSLDomain;
        return 301 https://$configSSLDomain\$request_uri;
    }
EOF

    elif [[ "${configInstallNginxMode}" == "nocodb" ]]; then

        cat > "${nginxConfigSiteConfPath}/nocodb_site.conf" <<-EOF

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

        location / {

            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header Host \$http_host;
            proxy_set_header Range \$http_range;
            proxy_set_header If-Range \$http_if_range;
            proxy_redirect off;
            proxy_pass http://127.0.0.1:8080;

        }
    }

    server {
        listen 80;
        listen [::]:80;
        server_name  $configSSLDomain;
        return 301 https://$configSSLDomain\$request_uri;
    }
EOF

    elif [[ "${configInstallNginxMode}" == "etherpad" ]]; then

        cat > "${nginxConfigSiteConfPath}/etherpad_site.conf" <<-EOF

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

        location / {

            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header Host \$http_host;
            proxy_set_header Range \$http_range;
            proxy_set_header If-Range \$http_if_range;
            proxy_redirect off;
            proxy_pass http://127.0.0.1:9001;

        }
    }

    server {
        listen 80;
        listen [::]:80;
        server_name  $configSSLDomain;
        return 301 https://$configSSLDomain\$request_uri;
    }
EOF

    else
        echo
    fi


    # https://raw.githubusercontent.com/nginx/nginx/master/conf/mime.types

    cat > "${nginxConfigPath}" <<-EOF

include /etc/nginx/modules-enabled/*.conf;

# user  ${nginxUser};
user root;
worker_processes  auto;
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
    proxy_temp_path ${nginxProxyTempPath} 1 2;
    client_body_temp_path ${nginxTempPath}/client_body 1 2;

    ${nginxConfigServerHttpInput}
    
    include ${nginxConfigSiteConfPath}/*.conf; 
}

EOF




    ${sudoCmd} chown -R ${wwwUsername}:${wwwUsername} ${configWebsiteFatherPath}
    ${sudoCmd} chmod -R 774 ${configWebsiteFatherPath}

    # /var/lib/nginx/tmp/client_body /var/lib/nginx/tmp/proxy 权限问题
    mkdir -p "${nginxTempPath}/client_body"
    mkdir -p "${nginxTempPath}/proxy"
    mkdir -p "${nginxProxyTempPath}"

    
    ${sudoCmd} chown -R ${wwwUsername}:${wwwUsername} ${nginxTempPath}
    ${sudoCmd} chmod -R 775 ${nginxTempPath}

    ${sudoCmd} chown -R ${wwwUsername}:${wwwUsername} ${nginxProxyTempPath}
    ${sudoCmd} chmod -R 775 ${nginxProxyTempPath}
    
    ${sudoCmd} systemctl start nginx.service

    echo
    green " ================================================== "
    green " Web服务器 nginx 安装成功. 站点为 https://${configSSLDomain}"
    echo
	red " nginx 配置路径 ${nginxConfigPath} "
	green " nginx 访问日志 ${nginxAccessLogFilePath},  错误日志 ${nginxErrorLogFilePath}  "
    green " nginx 查看日志命令: journalctl -n 50 -u nginx.service"
	green " nginx 启动命令: systemctl start nginx.service  停止命令: systemctl stop nginx.service  重启命令: systemctl restart nginx.service"
	green " nginx 查看运行状态命令: systemctl status nginx.service "
    green " ================================================== "
    echo

    if [[ "${configInstallNginxMode}" == "alist" ]]; then
        green " Alist Installed ! Working port: ${configAlistPort}"
        green " Please visit https://${configSSLDomain}"
        green " 启动命令: systemctl start alist  停止命令: systemctl stop alist "
        green " 查看运行状态命令: systemctl status alist  重启: systemctl restart alist "
        green " Cloudreve INI 配置文件路径: /opt/alist/data/config.json "
        green " Cloudreve 默认SQLite 数据库文件路径: /opt/alist/data/data.db"
        red " 请在管理面板-> 账号-> 添加-> 类型选择 本地,  把 根目录路径 设置为 ${nginxAlistStoragePath}"

        green " ================================================== "
    fi

    if [[ "${configInstallNginxMode}" == "cloudreve" ]]; then
        green " Cloudreve Installed ! Working port: ${configCloudrevePort}"
        green " Please visit https://${configSSLDomain}"
        green " 查看运行状态命令: systemctl status cloudreve  重启: systemctl restart cloudreve "
        green " Cloudreve INI 配置文件路径: ${configCloudreveIni}"
        green " Cloudreve 默认SQLite 数据库文件路径: ${configCloudreveCommandFolder}/cloudreve.db"
        green " Cloudreve readme 账号密码文件路径: ${configCloudreveReadme}"
        red " 请在管理面板->存储策略->编辑默认存储策略->存储路径 设置为 ${nginxCloudreveStoragePath}"

        cat ${configCloudreveReadme}
        green " ================================================== "
    fi
}

function removeNginx(){

    echo
    read -r -p "是否确认卸载Nginx? 直接回车默认卸载, 请输入[Y/n]:" isRemoveNginxServerInput
    isRemoveNginxServerInput=${isRemoveNginxServerInput:-Y}

    if [[ "${isRemoveNginxServerInput}" == [Yy] ]]; then

        echo
        if [[ -f "${nginxConfigPath}" ]]; then
        
            showHeaderRed "准备卸载已安装的nginx"

            ${sudoCmd} systemctl stop nginx.service
            ${sudoCmd} systemctl disable nginx.service

            if [ "$osRelease" == "centos" ]; then
                yum remove -y nginx-mod-stream
                yum remove -y nginx
            else
                apt autoremove -y
                apt-get remove --purge -y nginx-common
                apt-get remove --purge -y nginx-core
                apt-get remove --purge -y libnginx-mod-stream
                apt-get remove --purge -y libnginx-mod-http-xslt-filter libnginx-mod-http-geoip2 libnginx-mod-stream-geoip2 libnginx-mod-mail libnginx-mod-http-image-filter

                apt autoremove -y --purge nginx nginx-common nginx-core
                apt-get remove --purge -y nginx nginx-full nginx-common nginx-core
            fi


            rm -f ${nginxAccessLogFilePath}
            rm -f ${nginxErrorLogFilePath}
            rm -f ${nginxConfigPath}
            rm -rf ${nginxConfigSiteConfPath}

            rm -rf "/etc/nginx"
            
            rm -rf ${configDownloadTempPath}

            echo
            read -r -p "是否删除证书 和 卸载acme.sh申请证书工具, 由于一天内申请证书有次数限制, 默认建议不删除证书,  请输入[y/N]:" isDomainSSLRemoveInput
            isDomainSSLRemoveInput=${isDomainSSLRemoveInput:-n}

            
            if [[ $isDomainSSLRemoveInput == [Yy] ]]; then
                rm -rf ${configWebsiteFatherPath}
                ${sudoCmd} bash ${configSSLAcmeScriptPath}/acme.sh --uninstall
                
                showHeaderGreen "Nginx 卸载完毕, SSL 证书文件已删除!"

            else
                rm -rf ${configWebsitePath}
                showHeaderGreen "Nginx 卸载完毕, 已保留 SSL 证书文件 到 ${configSSLCertPath} "
            fi

        else
            showHeaderRed "系统没有安装 Nginx, 退出卸载"
        fi
        echo

    fi    
}




















































configEtherpadProjectPath="${HOME}/etherpad"
configEtherpadDockerPath="${HOME}/etherpad/docker"

# Online collaborative Document
function installEtherpad(){
    if [[ -d "${configEtherpadDockerPath}" ]]; then
        showHeaderRed " Etherpad already installed !"
        exit
    fi
    showHeaderGreen "开始 使用Docker方式 安装 Etherpad "

    createNewUserNologin "etherpad"
    ${sudoCmd} mkdir -p "${configEtherpadDockerPath}/data"
    cd "${configEtherpadDockerPath}" || exit

    ${sudoCmd} chown -R etherpad:root "${configEtherpadDockerPath}"
    ${sudoCmd} chmod -R 774 "${configEtherpadDockerPath}"

    docker pull etherpad/etherpad



    read -r -p "请输入Admin的密码 (默认为admin):" configEtherpadPasswordInput
    configEtherpadPasswordInput=${configEtherpadPasswordInput:-admin}
    echo

    green " ================================================== "
    echo
    green "是否安装 Nginx web服务器, 安装Nginx可以提高安全性并提供更多功能"
    green "如要安装 Nginx 需要提供域名, 并设置好域名DNS已解析到本机IP"
    echo
    read -r -p "是否安装 Nginx web服务器? 直接回车默认安装, 请输入[Y/n]:" isNginxInstallInput
    isNginxInstallInput=${isNginxInstallInput:-Y}

    echo
    echo "docker run -d -p 9001:9001 -e ADMIN_PASSWORD=${configEtherpadPasswordInput} --name etherpad etherpad/etherpad"
    echo

    if [[ "${isNginxInstallInput}" == [Yy] ]]; then
        isInstallNginx="true"
        configSSLCertPath="${configSSLCertPath}/etherpad"
        getHTTPSCertificateStep1
        configInstallNginxMode="etherpad"
        installWebServerNginx

        docker run -d -p 9001:9001 -e 'ADMIN_PASSWORD=${configEtherpadPasswordInput}' -e TRUST_PROXY=true -v ${configEtherpadDockerPath}/data:/opt/etherpad-lite/var --name etherpad etherpad/etherpad

        ${sudoCmd} systemctl restart nginx.service
        showHeaderGreen "Etherpad install success !  https://${configSSLDomain}" \
        "Admin panel: https://${configSSLDomain}/admin   User: admin, Password: ${configEtherpadPasswordInput}" 
    else
        docker run -d -p 9001:9001 -e 'ADMIN_PASSWORD=${configEtherpadPasswordInput}' -v ${configEtherpadDockerPath}/data:/opt/etherpad-lite/var --name etherpad etherpad/etherpad

        showHeaderGreen "Etherpad install success !  http://your_ip:9001/" \
        "Admin panel: http://your_ip:9001/admin  User: admin, Password: ${configEtherpadPasswordInput}" 
    fi
}

function removeEtherpad(){
    echo
    read -r -p "是否确认卸载Etherpad? 直接回车默认卸载, 请输入[Y/n]:" isRemoveEtherpadInput
    isRemoveEtherpadInput=${isRemoveEtherpadInput:-Y}

    if [[ "${isRemoveEtherpadInput}" == [Yy] ]]; then

        echo
        if [[ -d "${configEtherpadDockerPath}" ]]; then

            showHeaderGreen "准备卸载已安装的 Etherpad"

            dockerIDEtherpad=$(docker ps -a -q --filter ancestor=etherpad/etherpad --format="{{.ID}}")
            if [[ -n "${dockerIDEtherpad}" ]]; then
                ${sudoCmd} docker stop "${dockerIDEtherpad}"
                ${sudoCmd} docker rm "${dockerIDEtherpad}"
            fi

            rm -rf "${configEtherpadProjectPath}"
            rm -f "${nginxConfigSiteConfPath}/etherpad_site.conf"
            
            systemctl restart nginx.service
            showHeaderGreen "已成功卸载 Etherpad Docker 版本 !"
            
        else
            showHeaderRed "系统没有安装 Etherpad, 退出卸载"
        fi

    fi
    removeNginx
}






configNocoDBProjectPath="${HOME}/nocodb"
configNocoDBDockerPath="${HOME}/nocodb/docker"

# Online Spreadsheet
function installNocoDB(){

    if [[ -d "${configNocoDBDockerPath}" ]]; then
        showHeaderRed " NocoDB already installed !"
        exit
    fi
    showHeaderGreen "开始 使用Docker方式 安装 NocoDB "

    ${sudoCmd} mkdir -p "${configNocoDBDockerPath}/data"
    cd "${configNocoDBDockerPath}" || exit

    docker pull nocodb/nocodb:latest


    green " ================================================== "
    echo
    green "是否安装 Nginx web服务器, 安装Nginx可以提高安全性并提供更多功能"
    green "如要安装 Nginx 需要提供域名, 并设置好域名DNS已解析到本机IP"
    echo
    read -r -p "是否安装 Nginx web服务器? 直接回车默认安装, 请输入[Y/n]:" isNginxInstallInput
    isNginxInstallInput=${isNginxInstallInput:-Y}

    echo
    echo "docker run -d --name nocodb -p 8080:8080  -v ${configNocoDBDockerPath}/data:/usr/app/data/ nocodb/nocodb:latest"
    echo

    if [[ "${isNginxInstallInput}" == [Yy] ]]; then
        isInstallNginx="true"
        configSSLCertPath="${configSSLCertPath}/nocodb"
        getHTTPSCertificateStep1
        configInstallNginxMode="nocodb"
        installWebServerNginx

        docker run -d --name nocodb -p 8080:8080 -v ${configNocoDBDockerPath}/data:/usr/app/data/ nocodb/nocodb:latest

        ${sudoCmd} systemctl restart nginx.service
        showHeaderGreen "NocoDB install success !  https://${configSSLDomain}" 
    else
        docker run -d --name nocodb -p 8080:8080 -v ${configNocoDBDockerPath}/data:/usr/app/data/ nocodb/nocodb:latest

        showHeaderGreen "NocoDB install success !  http://your_ip:8080/dashboard" 
    fi

}
function removeNocoDB(){
    echo
    read -r -p "是否确认卸载NocoDB? 直接回车默认卸载, 请输入[Y/n]:" isRemoveNocoDBInput
    isRemoveNocoDBInput=${isRemoveNocoDBInput:-Y}

    if [[ "${isRemoveNocoDBInput}" == [Yy] ]]; then

        echo
        if [[ -d "${configNocoDBDockerPath}" ]]; then

            showHeaderGreen "准备卸载已安装的 NocoDB"

            dockerIDNocoDB=$(docker ps -a -q --filter ancestor=nocodb/nocodb --format="{{.ID}}")
            if [[ -n "${dockerIDNocoDB}" ]]; then
                ${sudoCmd} docker stop "${dockerIDNocoDB}"
                ${sudoCmd} docker rm "${dockerIDNocoDB}"
            fi

            rm -rf "${configNocoDBProjectPath}"
            rm -f "${nginxConfigSiteConfPath}/nocodb_site.conf"
            
            systemctl restart nginx.service
            showHeaderGreen "已成功卸载 NocoDB Docker 版本 !"
            
        else
            showHeaderRed "系统没有安装 NocoDB, 退出卸载"
        fi

    fi
    removeNginx
}



configGristProjectPath="${HOME}/grist"
configGristDockerPath="${HOME}/grist/docker"
configGristSecretKey="$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 32 | head -c 12)"

# Online Spreadsheet
function installGrist(){

    if [[ -d "${configGristDockerPath}" ]]; then
        showHeaderRed " Grist already installed !"
        exit
    fi
    showHeaderGreen "开始 使用Docker方式 安装 Grist "

    ${sudoCmd} mkdir -p ${configGristDockerPath}/persist
    cd "${configGristDockerPath}" || exit

    docker pull gristlabs/grist

    echo
    green " GRIST_SESSION_SECRET:  ${configGristSecretKey}"
    echo

    read -r -p "请输入邮箱:" configGristEmailInput
    configGristEmailInput=${configGristEmailInput:-you@example.com}
    echo

    read -r -p "请输入Team名称:" configGristTeamInput
    configGristTeamInput=${configGristTeamInput:-singleteam}
    echo


    green " ================================================== "
    echo
    green "是否安装 Nginx web服务器, 安装Nginx可以提高安全性并提供更多功能"
    green "如要安装 Nginx 需要提供域名, 并设置好域名DNS已解析到本机IP"
    echo
    read -r -p "是否安装 Nginx web服务器? 直接回车默认安装, 请输入[Y/n]:" isNginxInstallInput
    isNginxInstallInput=${isNginxInstallInput:-Y}

    echo
    echo "docker run -d -p 8484:8484 -v ${configGristDockerPath}/persist:/persist -e GRIST_SANDBOX_FLAVOR=gvisor -e GRIST_SINGLE_ORG=${configGristTeamInput} -e GRIST_SESSION_SECRET=${configGristSecretKey} --env GRIST_DEFAULT_EMAIL=${configGristEmailInput} gristlabs/grist"
    echo

    if [[ "${isNginxInstallInput}" == [Yy] ]]; then
        isInstallNginx="true"
        configSSLCertPath="${configSSLCertPath}/grist"
        getHTTPSCertificateStep1
        configInstallNginxMode="grist"
        installWebServerNginx

        docker run -d --name grist -p 8484:8484 -v ${configGristDockerPath}/persist:/persist -e GRIST_SANDBOX_FLAVOR=gvisor -e GRIST_SINGLE_ORG=${configGristTeamInput} \
        -e GRIST_SESSION_SECRET=${configGristSecretKey} --env GRIST_DEFAULT_EMAIL=${configGristEmailInput} -e APP_HOME_URL="https://${configSSLDomain}"  gristlabs/grist

        ${sudoCmd} systemctl restart nginx.service
        showHeaderGreen "Grist install success !  https://${configSSLDomain}" 
    else
        docker run -d --name grist -p 8484:8484 -v ${configGristDockerPath}/persist:/persist -e GRIST_SANDBOX_FLAVOR=gvisor -e GRIST_SINGLE_ORG=${configGristTeamInput} \
        -e GRIST_SESSION_SECRET=${configGristSecretKey} --env GRIST_DEFAULT_EMAIL=${configGristEmailInput} gristlabs/grist

        showHeaderGreen "Grist install success !  http://your_ip:8484" 
    fi

}
function removeGrist(){
    echo
    read -r -p "是否确认卸载Grist? 直接回车默认卸载, 请输入[Y/n]:" isRemoveGristInput
    isRemoveGristInput=${isRemoveGristInput:-Y}

    if [[ "${isRemoveGristInput}" == [Yy] ]]; then

        echo
        if [[ -d "${configGristDockerPath}" ]]; then

            showHeaderGreen "准备卸载已安装的 Grist"

            dockerIDGrist=$(docker ps -a -q --filter ancestor=gristlabs/grist --format="{{.ID}}")
            if [[ -n "${dockerIDGrist}" ]]; then
                ${sudoCmd} docker stop "${dockerIDGrist}"
                ${sudoCmd} docker rm "${dockerIDGrist}"
            fi


            rm -rf "${configGristProjectPath}"
            rm -f "${nginxConfigSiteConfPath}/grist_site.conf"
            
            systemctl restart nginx.service
            showHeaderGreen "已成功卸载 Grist Docker 版本 !"
        else
            showHeaderRed "系统没有安装 Grist, 退出卸载"
        fi
    fi

    removeNginx
}




































# Video Conference System 视频会议系统 安装
function installJitsiMeet(){

    showHeaderGreen "准备安装 视频会议系统 Jitsi Meet !" \
    "Minimum Requirements: 4 GB RAM + 2 core CPU "

    echo
    green " =================================================="
    green " 请选择安装方式: (默认为 1 Docker方式)"
    echo
    green " 1. Install Jitsi Meet by Docker"
    green " 2. Install Jitsi Meet directly, only support Debian 10 / Ubuntu 20.04"   
    echo
    read -r -p "请输入纯数字, 默认为1 Docker方式:" jitsimeetDockerInput
    
    case "${jitsimeetDockerInput}" in
        1 )
            installJitsiMeetByDocker    
        ;;
        2 )
            installJitsiMeetOnUbuntu
        ;;        
    
        * )
            installJitsiMeetByDocker
        ;;
    esac
}

configJitsiMeetProjectPath="${HOME}/jitsi_meet"
configJitsiMeetDockerPath="${HOME}/jitsi_meet/docker"
configJitsiMeetDownloadPath="${HOME}/jitsi_meet/download"

function installJitsiMeetByDocker(){
    
    if [ -f "${configJitsiMeetDockerPath}/docker-compose.yml" ]; then
        showHeaderRed "Jitsi Meet already installed !"
        exit
    fi

    showHeaderGreen "开始安装 Jitsi Meet by Docker"

    mkdir -p "${configJitsiMeetDownloadPath}"

    versionJitsiMeet=$(getGithubLatestReleaseVersion2 "jitsi/docker-jitsi-meet")
    #versionJitsiMeet="stable-7648-1"

    downloadAndUnzip "https://github.com/jitsi/docker-jitsi-meet/archive/refs/tags/${versionJitsiMeet}.zip" "${configJitsiMeetProjectPath}" "${versionJitsiMeet}.zip"

    # https://github.com/jitsi/docker-jitsi-meet/archive/refs/tags/stable-7439-2.zip

    mv -f "${configJitsiMeetProjectPath}/docker-jitsi-meet-${versionJitsiMeet}" "${configJitsiMeetProjectPath}/docker"

    cd "${configJitsiMeetDockerPath}" || exit
    cp -f "${configJitsiMeetDockerPath}/env.example"  "${configJitsiMeetDockerPath}/.env"

    "${configJitsiMeetDockerPath}/gen-passwords.sh"

    mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}

    configLocalVPSIp="$(curl https://ipv4.icanhazip.com/)"

    green " =================================================="
    echo
    read -r -p "请输入已解析到本机的域名: " configSSLDomain
    echo
    read -r -p "请输入邮箱用于申请SSL域名证书: " configEmailForSSLDomain
    echo

    sed -i "s|HTTP_PORT=8000|HTTP_PORT=80|g" "${configJitsiMeetDockerPath}/.env"
    sed -i "s|HTTPS_PORT=8443|HTTPS_PORT=443|g" "${configJitsiMeetDockerPath}/.env"
    sed -i "/HTTPS_PORT=443/a \ \nENABLE_HTTP_REDIRECT=1 \n " "${configJitsiMeetDockerPath}/.env"

    sed -i "s|#PUBLIC_URL=https:\/\/meet.example.com|PUBLIC_URL=https:\/\/${configSSLDomain}|g" "${configJitsiMeetDockerPath}/.env"
    sed -i "s|#DOCKER_HOST_ADDRESS=192.168.1.1|DOCKER_HOST_ADDRESS=${configLocalVPSIp}|g" "${configJitsiMeetDockerPath}/.env"
    
    sed -i "s|#ENABLE_LETSENCRYPT=1|ENABLE_LETSENCRYPT=1|g" "${configJitsiMeetDockerPath}/.env"
    sed -i "s|#LETSENCRYPT_DOMAIN=meet.example.com|LETSENCRYPT_DOMAIN=${configSSLDomain}|g" "${configJitsiMeetDockerPath}/.env"
    sed -i "s|#LETSENCRYPT_EMAIL=alice@atlanta.net|LETSENCRYPT_EMAIL=${configEmailForSSLDomain}|g" "${configJitsiMeetDockerPath}/.env"

    


    addPasswordForJitsiMeetDocker "first"


    showHeaderGreen "Jitsi Meet installed successfully!" "Visit https://${configSSLDomain} " \
    "停止命令: docker-compose down | 启动命令: docker-compose up -d " \
    "Jitsi Meet 项目文件路径 ${configJitsiMeetDockerPath} " \
    "Web 配置文件路径 ${HOME}/.jitsi-meet-cfg/web/config.js " \
    "查看日志 web: docker-compose logs -t -f web" \
    "查看日志 prosody: docker-compose logs -t -f prosody" \
    "查看日志 jvb: docker-compose logs -t -f jvb" \
    "查看日志 jicofo: docker-compose logs -t -f jicofo" 


}

function addPasswordForJitsiMeetDocker(){

    cd "${configJitsiMeetDockerPath}" || exit

    if [[ -z "$1" ]]; then
        
        docker-compose down
    else
        echo
    fi

    green " =================================================="
    echo
    green " 是否需要密码才能发起会议? 默认为否 任何人都能发起会议"
    echo
    read -r -p "是否需要密码才能发起会议? 直接回车默认为否, 请输入[y/N]:" isJitsiMeetNeedPasswordInput
    isJitsiMeetNeedPasswordInput=${isJitsiMeetNeedPasswordInput:-N}

    if [[ ${isJitsiMeetNeedPasswordInput} == [Yy] ]]; then

        sed -i "s|#ENABLE_AUTH=1|ENABLE_AUTH=1|g" "${configJitsiMeetDockerPath}/.env"
        sed -i "s|#AUTH_TYPE=internal|AUTH_TYPE=internal|g" "${configJitsiMeetDockerPath}/.env"

        sed -i "s|#ENABLE_GUESTS=1|ENABLE_GUESTS=1|g" "${configJitsiMeetDockerPath}/.env"

        docker-compose up -d

        echo
        read -r -p "请输入发起会议用户名, 直接回车默认为jitsi : " isJitsiMeetUsernameInput
        isJitsiMeetUsernameInput=${isJitsiMeetUsernameInput:-jitsi}
        echo
        read -r -p "请输入用户的密码, 直接回车默认为jitsi :" isJitsiMeetUserPasswordInput
        isJitsiMeetUserPasswordInput=${isJitsiMeetUserPasswordInput:-jitsi}
        echo


        docker-compose exec prosody prosodyctl --config /config/prosody.cfg.lua register ${isJitsiMeetUsernameInput} meet.jitsi ${isJitsiMeetUserPasswordInput}

        # User list: find /config/data/meet%2ejitsi/accounts -type f -exec basename {} .dat \;

    else

        sed -i "s|#\?ENABLE_AUTH=1|#ENABLE_AUTH=1|g" "${configJitsiMeetDockerPath}/.env"
        sed -i "s|#\?AUTH_TYPE=internal|#AUTH_TYPE=internal|g" "${configJitsiMeetDockerPath}/.env"

        sed -i "s|#\?ENABLE_GUESTS=1|#ENABLE_GUESTS=1|g" "${configJitsiMeetDockerPath}/.env"

        docker-compose up -d
    fi

    showHeaderGreen "Check document below for JWT and LDAP authentication" \
    "Docs: https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker#authentication"

}



configJitsiMeetVideoBridgeFilePath="/etc/jitsi/videobridge/sip-communicator.properties"
configJitsiMeetNginxConfigFolderPath="/etc/nginx/sites-available"
configJitsiMeetNginxConfigFolder2Path="/etc/nginx/sites-enabled"
configJitsiMeetNginxConfigOriginalFolderPath="/etc/nginx/conf.d"

function installJitsiMeetOnUbuntu(){

    if [ "$osRelease" == "centos" ]; then
        showHeaderRed "不支持 CentOS 系统!  Not support CentOS!"
        exit
    else
        sed -i '/packages.prosody.im/d' /etc/apt/sources.list

        ${sudoCmd} apt update -y 
        ${sudoCmd} apt install -y apt-transport-https

        if [ "$osRelease" == "ubuntu" ]; then
            ${sudoCmd} apt-add-repository universe -y
            ${sudoCmd} apt update -y 
        fi
    fi

    # Add the Prosody package repository
    echo "deb http://packages.prosody.im/debian $(lsb_release -sc) main" | ${sudoCmd} tee -a /etc/apt/sources.list
    wget https://prosody.im/files/prosody-debian-packages.key -O- | ${sudoCmd} apt-key add -

    # Add the Jitsi package repository
    curl https://download.jitsi.org/jitsi-key.gpg.key | ${sudoCmd} sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
    echo "deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/" | ${sudoCmd} tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null
    
    green " =================================================="
    ${sudoCmd} apt-get -y update
    green " =================================================="
    
    showInfoGreen "Setting firewall rules"
    ${sudoCmd} ufw allow 80/tcp
    ${sudoCmd} ufw allow 443/tcp
    ${sudoCmd} ufw allow 10000/udp

    ${sudoCmd} ufw allow 3478/udp
    ${sudoCmd} ufw allow 5349/tcp

    echo
    #echo "ufw enable"
    #${sudoCmd} ufw enable
    echo
    echo "ufw status verbose"
    ${sudoCmd} ufw status verbose


    showHeaderGreen "开始安装 Jitsi Meet"

    mkdir -p ${configJitsiMeetNginxConfigFolderPath}
    mkdir -p ${configJitsiMeetNginxConfigFolder2Path}
    
    # https://jitsi.org/downloads/ubuntu-debian-installations-instructions/    
    ${sudoCmd} apt-get -y install jitsi-meet

    #sudo apt-get -y install jigasi


    showHeaderGreen "Setting up nginx configuration"

    #configJitsiMeetNginxConfigFilePath="${configJitsiMeetNginxConfigFolderPath}/${configSSLDomain}.conf"
    #sed -i "s|jitsi-meet.example.com|${configSSLDomain}|g" "${configJitsiMeetNginxConfigFilePath}"

    ln -s ${configJitsiMeetNginxConfigFolderPath}/* ${configJitsiMeetNginxConfigOriginalFolderPath}/
    ${sudoCmd} systemctl restart nginx


    showHeaderGreen "Generate certificate with letsencrypt"
    ${sudoCmd} /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh

    # configSSLCertPath="${configSSLCertPath}/jitsimeet"
    # getHTTPSCertificateStep1

    # cp -f ${configSSLCertPath}/fullchain.cer "/etc/jitsi/meet/${configSSLDomain}.crt"
    # cp -f ${configSSLCertPath}/private.key "/etc/jitsi/meet/${configSSLDomain}.key"

    # /nginxweb/cert/jitsimeet/fullchain.cer
    # /nginxweb/cert/jitsimeet/private.key


    showHeaderGreen "Setting up jitsi meet local IP configuration"

    configLocalVPSIp="$(curl https://ipv4.icanhazip.com/)"
    echo
    read -r -p "请输入本机IP: 直接回车默认为 ${configLocalVPSIp}" jitsimeetVPSIPInput
    jitsimeetVPSIPInput=${jitsimeetVPSIPInput:-${configLocalVPSIp}}

    sed -i 's|#\?org.ice4j.ice.harvest.STUN_MAPPING_HARVESTER_ADDRESSES|#org.ice4j.ice.harvest.STUN_MAPPING_HARVESTER_ADDRESSES|g' ${configJitsiMeetVideoBridgeFilePath}

    sed -i '/org.ice4j.ice.harvest.NAT_HARVESTER_LOCAL_ADDRESS/d' ${configJitsiMeetVideoBridgeFilePath}
    sed -i '/org.ice4j.ice.harvest.NAT_HARVESTER_PUBLIC_ADDRESS/d' ${configJitsiMeetVideoBridgeFilePath}

    echo "org.ice4j.ice.harvest.NAT_HARVESTER_LOCAL_ADDRESS=${jitsimeetVPSIPInput}" >> ${configJitsiMeetVideoBridgeFilePath}
    echo "org.ice4j.ice.harvest.NAT_HARVESTER_PUBLIC_ADDRESS=${jitsimeetVPSIPInput}" >> ${configJitsiMeetVideoBridgeFilePath}


    sed -i 's|#\?DefaultLimitNOFILE=.*|DefaultLimitNOFILE=65000|g' /etc/systemd/system.conf
    sed -i 's|#\?DefaultLimitNPROC=.*|DefaultLimitNPROC=65000|g' /etc/systemd/system.conf
    sed -i 's|#\?DefaultTasksMax=.*|DefaultTasksMax=65000|g' /etc/systemd/system.conf


    echo
    systemctl show --property DefaultLimitNPROC
    systemctl show --property DefaultLimitNOFILE
    systemctl show --property DefaultTasksMax

    ${sudoCmd} systemctl daemon-reload 

    secureAddPasswordForJitsiMeet "first"

    showHeaderGreen "Jitsi Meet installed successfully!" "Running port 80 443 4443 10000 3478 5349 !" \
    "重启 Videobridge 命令: systemctl restart jitsi-videobridge2 | Log: /var/log/jitsi/jvb.log" \
    "重启 jicofo 命令: systemctl restart jicofo | Log: /var/log/jitsi/jicofo.log" \
    "重启 XMPP 命令: systemctl restart prosody | Log: /var/log/prosody/prosody.log"

}

function secureAddPasswordForJitsiMeet(){
    if [ -f "${configJitsiMeetDockerPath}/.env" ]; then
        addPasswordForJitsiMeetDocker
        exit
    fi
    
    green " =================================================="
    echo
    read -r -p "请输入已解析到本机的域名: " configSSLDomain
    echo

    configJitsiMeetConfigFilePath="/etc/jitsi/meet/${configSSLDomain}-config.js"
    configJitsiMeetProsodyFilePath="/etc/prosody/conf.avail/${configSSLDomain}.cfg.lua"
    configJitsiMeetJicofoFilePath="/etc/jitsi/jicofo/jicofo.conf"

    echo
    green " 是否需要密码才能发起会议? 默认为否 任何人都能发起会议"
    echo
    read -r -p "是否需要密码才能发起会议? 直接回车默认为否, 请输入[y/N]:" isJitsiMeetNeedPasswordInput
    isJitsiMeetNeedPasswordInput=${isJitsiMeetNeedPasswordInput:-N}

    if [[ ${isJitsiMeetNeedPasswordInput} == [Yy] ]]; then

        #sed -i 's|#\?authentication =.*|authentication = "jitsi-anonymous"|g' "${configJitsiMeetProsodyFilePath}"
        #sed -i 's|#\?authentication =.*|authentication = "internal_plain"|g' "${configJitsiMeetProsodyFilePath}"
        sed -i 's|#\?authentication =.*|authentication = "internal_hashed"|g' "${configJitsiMeetProsodyFilePath}"

        read -r -d '' configJitsiMeetProsodyVhost << EOM
VirtualHost "guest.${configSSLDomain}"
    authentication = "anonymous"
    c2s_require_encryption = false

EOM

        TEST1="${configJitsiMeetProsodyVhost//\\/\\\\}"
        TEST1="${TEST1//\//\\/}"
        TEST1="${TEST1//&/\\&}"
        TEST1="${TEST1//$'\n'/\\n}"

        sed -i "/muc_lobby_whitelist /a ${TEST1} \ \ " "${configJitsiMeetProsodyFilePath}"

        sed -i "/anonymousdomain/a \        anonymousdomain: 'guest.${configSSLDomain}'," "${configJitsiMeetConfigFilePath}"


        read -r -d '' configJitsiMeetJicofoVhost << EOM
    authentication: {
        enabled: true
        type: XMPP
        login-url: ${configSSLDomain}
    }

EOM

        TEST3="${configJitsiMeetJicofoVhost//\\/\\\\}"
        TEST3="${TEST3//\//\\/}"
        TEST3="${TEST3//&/\\&}"
        TEST3="${TEST3//$'\n'/\\n}"

        sed -i "/xmpp/i \    ${TEST3} \ \ " "${configJitsiMeetJicofoFilePath}"


        echo
        read -r -p "请输入发起会议用户名, 直接回车默认为jitsi : " isJitsiMeetUsernameInput
        isJitsiMeetUsernameInput=${isJitsiMeetUsernameInput:-jitsi}
        echo
        read -r -p "请输入用户的密码, 直接回车默认为jitsi :" isJitsiMeetUserPasswordInput
        isJitsiMeetUserPasswordInput=${isJitsiMeetUserPasswordInput:-jitsi}
        echo

        ${sudoCmd} prosodyctl register "${isJitsiMeetUsernameInput}" "${configSSLDomain}" "${isJitsiMeetUserPasswordInput}"
        # User list:  /var/lib/prosody/v%2evr360%2ecf/accounts
   
        echo 
        green "Use the following command to add new user: " 
        yellow "prosodyctl register username domain_name password"
        green "Docs: https://prosody.im/doc/prosodyctl#user-management"
        echo
        echo

        showHeaderGreen "Please manually modify Jigasi configuration if you are using Jigasi" "Docs: https://jitsi.github.io/handbook/docs/devops-guide/secure-domain/"

    else 
        echo
        # https://stackoverflow.com/questions/4396974/sed-or-awk-delete-n-lines-following-a-pattern

        if [[ -z "$1" ]]; then
            sed -i 's|#\?authentication =.*|authentication = "jitsi-anonymous"|g' "${configJitsiMeetProsodyFilePath}"
            sed -i "/guest.${configSSLDomain}/{N;N;d}" "${configJitsiMeetProsodyFilePath}"

            sed -i "/anonymousdomain: 'guest.${configSSLDomain}/d" "${configJitsiMeetConfigFilePath}"

            sed -i "/authentication:/,+4d" "${configJitsiMeetJicofoFilePath}"
        fi
    fi

    ${sudoCmd} systemctl daemon-reload 
    ${sudoCmd} systemctl restart prosody
    ${sudoCmd} systemctl restart jicofo
    ${sudoCmd} systemctl restart jitsi-videobridge2
    ${sudoCmd} systemctl restart nginx

}

function removeJitsiMeet(){

    
    if [ -f "${configJitsiMeetDockerPath}/.env" ]; then
        showHeaderGreen "准备卸载 Jitsi Meet Docker "

        cd "${configJitsiMeetDockerPath}" || exit

        docker-compose down

        rm -rf "${configJitsiMeetDockerPath}"
        rm -rf "${HOME}/.jitsi-meet-cfg"

        showHeaderGreen "已成功卸载 Jitsi Meet Docker 版本 !"
    else
        showHeaderRed "没有发现 Jitsi Meet Docker !"

        showHeaderGreen "准备卸载 视频会议系统 Jitsi Meet 非Docker 安装版本 !"

        if [ "$osRelease" == "centos" ]; then
            showHeaderRed " 不支持 CentOS 系统"
        else

            ${sudoCmd} apt purge -y jigasi jitsi-meet jitsi-meet-web-config jitsi-meet-prosody jitsi-meet-turnserver jitsi-meet-web jicofo jitsi-videobridge2 prosody
            ${sudoCmd} apt autoremove -y
            ${sudoCmd} apt purge -y jicofo jitsi-videobridge2 
            ${sudoCmd} apt autoremove -y

            rm -f /etc/prosody/prosody.cfg.lua
            rm -rf /etc/letsencrypt/live/*
            rm -rf /etc/letsencrypt/archive/*
            rm -f /etc/letsencrypt/renewal/*
            rm -f /etc/letsencrypt/keys/*

            showHeaderGreen "已成功卸载 Jitsi Meet 非Docker 安装版本 !"
        fi

        removeNginx    
    fi

    
}








































































configGhostProjectPath="/opt/ghost"
configGhostDockerPath="/opt/ghost/docker"
configGhostSitePath="/opt/ghost/site"
ghostUser="ghostsite"

function installCMSGhost(){
    if [[ -d "${configGhostDownloadPath}" ]]; then
        showHeaderRed "Ghost already installed !"
        exit
    fi
    showHeaderGreen "Prepare to install Ghost !"

    if ! command -v npm &> /dev/null ; then
        showHeaderRed "Npm could not be found, Please install Nodejs first !"
        exit
    fi

    isInstallNginx="true"
    configSSLCertPath="${configSSLCertPath}/ghost"
    getHTTPSCertificateStep1
    configInstallNginxMode="ghost"
    installWebServerNginx


    
    createNewUser "${ghostUser}"
    # passwd "${ghostUser}" ghost2022user

    # https://stackoverflow.com/questions/714915/using-the-passwd-command-from-within-a-shell-script
    echo "ghost2022user" | passwd "${ghostUser}" --stdin
    red " Password for linux user ghostsite: ghost2022user"
    echo

    ${sudoCmd} mkdir -p "${configGhostSitePath}"

    ${sudoCmd} chown -R ${ghostUser}:${ghostUser} "${configGhostProjectPath}"
    ${sudoCmd} chmod -R 775  "${configGhostProjectPath}"

    cd "${configGhostSitePath}" || exit
    ${sudoCmd} npm install ghost-cli@latest -g
    
    # su - "ghost" -c cd "${configGhostSitePath}"

    su - ${ghostUser} << EOF
    echo "--------------------"
    echo "Current user:"
    whoami
    echo
    cd "${configGhostSitePath}"
    ghost install --port 3468 --db=sqlite3 --no-setup-nginx --no-setup-ssl --no-setup-mysql --no-stack --no-prompt --dir ${configGhostSitePath} --url https://${configSSLDomain}
    echo "--------------------"
EOF

    echo
    echo "Current user: $(whoami)"
    echo

    showHeaderGreen "Ghost installed successfully! " \
    "Ghost Admin panel:  http://localhost:3468/ghost" \
    "The SQLite3 database located in ${configGhostSitePath}/content/data"

    showHeaderGreen " Please manually run following command if installation failed: " \
    "su - ${ghostUser}" \
    "cd ${configGhostSitePath}" \
    "ghost install --port 3468 --db=sqlite3 --no-setup-nginx --no-setup-ssl --no-setup-mysql --no-stack --no-prompt --dir ${configGhostSitePath} --url https://${configSSLDomain}"
    red "Input password 'ghost2022user' when ask for linux user 'ghostsite' password"


        read -r -d '' ghostConfigEmailInput << EOM
    "mail": {
      "from": "annajscool@freair.com",
      "transport": "SMTP",
      "options": {
        "host": "smtp.gmail.com",
        "service": "Gmail",
        "port": "465",
        "secure": true,
        "auth": {
          "user": "jinwyp2@gmail.com",
          "pass": "aslgotjzmwrkuvto"
        }
      }
    },
EOM


}


function removeCMSGhost(){
    echo
    read -r -p "是否确认卸载Ghost? 直接回车默认卸载, 请输入[Y/n]:" isRemoveGhostInput
    isRemoveGhostInput=${isRemoveGhostInput:-Y}

    if [[ "${isRemoveGhostInput}" == [Yy] ]]; then

        echo
        if [[ -d "${configGhostSitePath}" ]]; then

            showHeaderGreen "准备卸载已安装的 Ghost"

    su - ${ghostUser} << EOF
    echo "--------------------"
    echo "Current user:"
    whoami
    echo
    cd "${configGhostSitePath}"
    ghost stop
    ghost uninstall
    echo "--------------------"
EOF

            userdel -r "${ghostUser}"

            rm -rf "${configGhostSitePath}"
            rm -f "${nginxConfigSiteConfPath}/ghost_site.conf"
            
            systemctl restart nginx.service
            showHeaderGreen "已成功卸载 Ghost !"
        else
            showHeaderRed "系统没有安装 Ghost, 退出卸载"
        fi

    fi
    removeNginx

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
        green "请选择SSL证书申请方式: 1 Soga内置的http方式, 2 通过acme.sh申请并放置证书文件"
        green "默认直接回车为 Soga内置的http自动申请模式"
        green "选否 则通过acme.sh申请证书并放置证书文件, 支持http和dns模式申请证书, 推荐此模式"
        echo
        green "注意: Soga SSL证书申请方式共有3种: 1 Soga内置的http方式, 2 Soga内置的dns方式, 3 手动放置证书文件 "
        green "如需要使用 Soga内置的dns方式 申请SSL证书方式, 请手动修改 soga.conf 配置文件"
        echo
        read -p "请选择SSL证书申请方式 ? 默认直接回车为http自动申请模式, 选否则通过acme.sh手动申请并放置证书, 请输入[Y/n]:" isSSLRequestHTTPInput
        isSSLRequestHTTPInput=${isSSLRequestHTTPInput:-Y}

        if [[ $isSSLRequestHTTPInput == [Yy] ]]; then
            echo
            green " ================================================== "
            yellow " 请输入绑定到本VPS的域名 例如www.xxx.com: (此步骤请关闭CDN后和nginx后安装 避免80端口占用导致申请证书失败)"
            green " ================================================== "

            read configSSLDomain

            sed -i 's/cert_mode=/cert_mode=http/g' ${configSogaConfigFilePath}
        else
            configSSLCertPath="${configSSLCertPathV2board}"
            getHTTPSCertificateStep1
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

    # https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh
    # https://raw.githubusercontent.com/Misaka-blog/XrayR-script/master/install.sh
    # https://raw.githubusercontent.com/long2k3pro/XrayR-release/master/install.sh

    wget -O xrayr_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/long2k3pro/XrayR-release/master/install.sh" && chmod +x xrayr_install.sh && ./xrayr_install.sh

    replaceXrayRConfig
}


function replaceXrayRConfig(){

    if test -s ${configXrayRConfigFilePath}; then

        echo
        green "请选择SSL证书申请方式: 1 XrayR内置的http 方式, 2 通过acme.sh 申请并放置证书文件, "
        green "默认直接回车为 XrayR内置的http自动申请模式"
        green "选否则通过acme.sh申请证书, 支持http 和 dns 等更多模式申请证书, 推荐使用"
        echo
        green "注意: XrayR 的SSL证书申请方式 共有4种: 1 XrayR内置的http 方式, 2 XrayR内置的 dns 方式, 3 file 手动放置证书文件, 4 none 不申请证书"
        green "如需要使用 XrayR内置的dns 申请SSL证书方式, 请手动修改 ${configXrayRConfigFilePath} 配置文件"
    
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
            configSSLCertPath="${configSSLCertPathV2board}"
            getHTTPSCertificateStep1
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




























function installAiruAndNginx(){
    isInstallNginx="true"
    configSSLCertPath="${configSSLCertPathV2board}"
    getHTTPSCertificateStep1
    configInstallNginxMode="airuniverse"
    installWebServerNginx


    sed -i 's/\"force_close_tls\": \?false/\"force_close_tls\": true/g' ${configAirUniverseConfigFilePath}

    systemctl restart xray.service
    airu restart

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
    echo
    green " 1. 不降级 使用最新版本"
    green " 2. 1.1.1 (不支持 Xray 1.5.0或更老版本)"
    green " 3. 1.0.0 (仅支持 Xray 1.5.0或更老版本)"
    green " 4. 0.9.2 (仅支持 Xray 1.5.0或更老版本)"
    echo
    read -p "请选择Air-Universe版本? 直接回车默认选1, 请输入纯数字:" isAirUniverseVersionInput
    isAirUniverseVersionInput=${isAirUniverseVersionInput:-1}


    downloadAirUniverseVersion=$(getGithubLatestReleaseVersion "crossfw/Air-Universe")
    downloadAirUniverseUrl="https://github.com/crossfw/Air-Universe/releases/download/v${downloadAirUniverseVersion}/Air-Universe-linux-64.zip"

    if [[ "${isAirUniverseVersionInput}" == "2" ]]; then
        downloadAirUniverseVersion="1.1.1"
    elif [[ "${isAirUniverseVersionInput}" == "3" ]]; then
        downloadAirUniverseVersion="1.0.0"
    elif [[ "${isAirUniverseVersionInput}" == "4" ]]; then
        downloadAirUniverseVersion="0.9.2"
    else
        echo
    fi

    if [[ "${isAirUniverseVersionInput}" == "1" ]]; then
        green " =================================================="
        green "  已选择不降级 使用最新版本 Air-Universe ${downloadAirUniverseVersion}"
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
    yellow " 请选择Xray降级到的版本, 默认直接回车为不降级"
    echo
    green " 1. 不降级 使用最新版本"

    if [[ "${isAirUniverseVersionInput}" == "1" || "${isAirUniverseVersionInput}" == "2" ]]; then
        green " 2. 1.7.3"
        green " 3. 1.6.1"
        green " 4. 1.6.0"
        green " 5. 1.5.5"
        green " 6. 1.5.4"
        green " 7. 1.5.3"
    else
        green " 8. 1.5.0"
        green " 9. 1.4.5"
        green " 10. 1.4.0"
        green " 11. 1.3.1"
    fi

    echo
    read -p "请选择Xray版本? 直接回车默认选1, 请输入纯数字:" isXrayVersionInput
    isXrayVersionInput=${isXrayVersionInput:-1}

    downloadXrayVersion=$(getGithubLatestReleaseVersion "XTLS/Xray-core")
    downloadXrayUrl="https://github.com/XTLS/Xray-core/releases/download/v${downloadXrayVersion}/Xray-linux-64.zip"

    if [[ "${isXrayVersionInput}" == "2" ]]; then
        downloadXrayVersion="1.7.3"

    elif [[ "${isXrayVersionInput}" == "3" ]]; then
        downloadXrayVersion="1.6.1"

    elif [[ "${isXrayVersionInput}" == "4" ]]; then
        downloadXrayVersion="1.6.0"

    elif [[ "${isXrayVersionInput}" == "5" ]]; then
        downloadXrayVersion="1.5.5"

    elif [[ "${isXrayVersionInput}" == "6" ]]; then
        downloadXrayVersion="1.5.4"

    elif [[ "${isXrayVersionInput}" == "7" ]]; then
        downloadXrayVersion="1.5.3"

    elif [[ "${isXrayVersionInput}" == "8" ]]; then
        downloadXrayVersion="1.5.0"

    elif [[ "${isXrayVersionInput}" == "9" ]]; then
        downloadXrayVersion="1.4.5"

    elif [[ "${isXrayVersionInput}" == "10" ]]; then
        downloadXrayVersion="1.4.0"

    elif [[ "${isXrayVersionInput}" == "11" ]]; then
        downloadXrayVersion="1.3.1"

    else
        echo
    fi

    if [[ "${isXrayVersionInput}" == "1" ]]; then
        green " =================================================="
        green "  已选择不降级 使用最新版本 Xray ${downloadXrayVersion}"
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
        
        airu stop
        systemctl stop xray.service

        chmod ugoa+rw ${configSSLCertPath}/*
        
        systemctl start xray.service
        echo
        airu start
        echo
        systemctl status xray.service
        echo
    fi    
}



configAirUniverseXrayAccessLogFilePath="${HOME}/xray_access.log"
configAirUniverseXrayErrorLogFilePath="${HOME}/xray_error.log"


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

    # sed -i '/User=nobody/d' "/etc/systemd/system/xray.service"
    # ${sudoCmd} systemctl daemon-reload
    # chown root "/var/log/au/xr.log"

    if test -s ${configAirUniverseConfigFilePath}; then

        echo
        green "请选择SSL证书申请方式: 1 通过acme.sh申请证书, 2 不申请证书"
        green "默认直接回车为通过acme.sh申请证书, 支持 http 和 dns 等更多方式申请证书, 推荐使用"
        green "注: Air-Universe 本身没有自动获取证书功能, 使用 acme.sh 申请证书"
        echo
        read -r -p "请选择SSL证书申请方式 ? 默认直接回车为申请证书, 选否则不申请证书, 请输入[Y/n]:" isSSLRequestHTTPInput
        isSSLRequestHTTPInput=${isSSLRequestHTTPInput:-Y}

        if [[ $isSSLRequestHTTPInput == [Yy] ]]; then
            echo
            configSSLCertPath="${configSSLCertPathV2board}"
            getHTTPSCertificateStep1

            airUniverseConfigNodeIdNumberInput=$(grep "nodes_type"  ${configAirUniverseConfigFilePath} | awk -F  ":" '{print $2}')

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

            # chown -R nobody:nogroup /var/log/v2ray

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
            read -r -p "Press enter to continue. 按回车继续运行 airu 命令"
            airu
        fi



        green " ================================================== "
        echo
        green "是否安装 Nginx web服务器, 安装Nginx可以提高安全性"
        echo
        read -r -p "是否安装 Nginx web服务器? 直接回车默认不安装, 请输入[y/N]:" isNginxAlistInstallInput
        isNginxAlistInstallInput=${isNginxAlistInstallInput:-n}

        if [[ "${isNginxAlistInstallInput}" == [Yy] ]]; then
            isInstallNginx="true"
            configSSLCertPath="${configSSLCertPathV2board}"
            configInstallNginxMode="airuniverse"
            installWebServerNginx

            sed -i 's/\"force_close_tls\": \?false/\"force_close_tls\": true/g' ${configAirUniverseConfigFilePath}

            systemctl restart xray.service
            airu restart
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

    V2rayDNSUnlockText="UseIPv4"
    v2rayConfigDNSInput=""

    if [[ "${isV2rayUnlockDNSInput}" == [Nn] ]]; then
        V2rayDNSUnlockText="UseIPv4"
    else
        V2rayDNSUnlockText="UseIP"
        read -r -d '' v2rayConfigDNSOutboundSettingsInput << EOM
            "settings": {
                "domainStrategy": "UseIP"
            }
EOM

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
        green " 7. 同时解锁 Netflix, Hulu, HBO, Disney, Spotify 和 Pornhub 限制"
        green " 8. 同时解锁 Netflix, Hulu, HBO, Disney, Spotify, Youtube 和 Pornhub 限制"
        green " 9. 解锁 全部流媒体 包括 Netflix, Youtube, Hulu, HBO, Disney, BBC, Fox, niconico, dmm, Spotify, Pornhub 等"
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
            V2rayUnlockVideoSiteRuleText="\"geosite:netflix\", \"geosite:disney\", \"geosite:spotify\", \"geosite:hulu\", \"geosite:hbo\", \"geosite:pornhub\""

        elif [[ $isV2rayUnlockVideoSiteInput == "8" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:netflix\", \"geosite:disney\", \"geosite:spotify\", \"geosite:youtube\", \"geosite:hulu\", \"geosite:hbo\", \"geosite:pornhub\""

        elif [[ $isV2rayUnlockVideoSiteInput == "9" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:netflix\", \"geosite:disney\", \"geosite:spotify\", \"geosite:youtube\", \"geosite:bahamut\", \"geosite:hulu\", \"geosite:hbo\", \"geosite:bbc\", \"geosite:4chan\", \"geosite:fox\", \"geosite:abema\", \"geosite:dmm\", \"geosite:niconico\", \"geosite:pixiv\", \"geosite:viu\", \"geosite:pornhub\""

        fi

    fi




    echo
    echo
    yellow " 某老姨子提供了可以解锁Netflix新加坡区的V2ray服务器, 已失效"
    read -p "是否通过老姨子解锁Netflix新加坡区? 直接回车默认不解锁, 请输入[y/N]:" isV2rayUnlockGoNetflixInput
    isV2rayUnlockGoNetflixInput=${isV2rayUnlockGoNetflixInput:-n}

    v2rayConfigRouteGoNetflixInput=""
    v2rayConfigOutboundV2rayGoNetflixServerInput=""
    if [[ "${isV2rayUnlockGoNetflixInput}" == [Nn] ]]; then
        echo
    else
        removeString="\"geosite:netflix\", "
        V2rayUnlockVideoSiteRuleText=${V2rayUnlockVideoSiteRuleText#"$removeString"}
        removeString2="\"geosite:disney\", "
        V2rayUnlockVideoSiteRuleText=${V2rayUnlockVideoSiteRuleText#"$removeString2"}
        read -r -d '' v2rayConfigRouteGoNetflixInput << EOM
            {
                "type": "field",
                "outboundTag": "GoNetflix",
                "domain": [ "geosite:netflix", "geosite:disney" ] 
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
                    "address": "free-sg-01.unblocknetflix.cf",
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
        {
            "tag": "blocked",
            "protocol": "blackhole",
            "settings": {
                "response": {
                    "type": "http"
                }
            }
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
        "domainStrategy": "IPOnDemand",
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
                "domain": [
                    "geosite:cn"
                ],
                "outboundTag": "IPv6_out"
            },
            {
                "type": "field",
                "ip": [
                    "geoip:cn"
                ],
                "outboundTag": "IPv6_out"
            },
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

    

    if [[ "${isV2rayUnlockWarpModeInput}" == "1" && "${isV2rayUnlockGoogleInput}" == "1"  && "${isV2rayUnlockGoNetflixInput}" == [Nn]  ]]; then
        if [[ "${isV2rayUnlockDNSInput}" == [Nn] ]]; then
            echo
        else
            TEST="${v2rayConfigDNSInput//\\/\\\\}"
            TEST="${TEST//\//\\/}"
            TEST="${TEST//&/\\&}"
            TEST="${TEST//$'\n'/\\n}"

            sed -i "/outbounds/i \    ${TEST}" ${configAirUniverseXrayConfigFilePath}

            TEST2="${v2rayConfigDNSOutboundSettingsInput//\\/\\\\}"
            TEST2="${TEST2//\//\\/}"
            TEST2="${TEST2//&/\\&}"
            TEST2="${TEST2//$'\n'/\\n}"

            # https://stackoverflow.com/questions/4396974/sed-or-awk-delete-n-lines-following-a-pattern

            sed -i -e '/freedom/{n;d}' ${configAirUniverseXrayConfigFilePath}
            sed -i "/freedom/a \      ${TEST2}" ${configAirUniverseXrayConfigFilePath}

        fi
    else
        
        # https://stackoverflow.com/questions/31091332/how-to-use-sed-to-delete-multiple-lines-when-the-pattern-is-matched-and-stop-unt/31091398
        sed -i '/outbounds/,/^&/d' ${configAirUniverseXrayConfigFilePath}
        cat >> ${configAirUniverseXrayConfigFilePath} <<-EOF

  ${xrayConfigProxyInput}

EOF
    fi


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










function updateGeoIp(){
    wget -O /usr/local/share/xray/geoip.dat https://github.com/v2fly/geoip/releases/latest/download/geoip.dat
    wget -O /usr/local/share/xray/geosite.dat https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat
    
    systemctl restart xray.service
    airu restart

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



function removeAirUniverse(){
    rm -rf /usr/local/etc/xray
    /root/airu_install.sh uninstall
    rm -f /usr/bin/airu 
    rm -f /usr/local/bin/au
    rm -f /usr/local/bin/xray
    
    rm -rf ${configSSLCertPathV2board}

    crontab -r 
    green " crontab 定时任务 已清除!"
    echo

    removeNginx
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





































openVPNSocksFolder="/root/openvpn_docker"
function runOpenVPNSocks(){
    mkdir -p ${openVPNSocksFolder}

    green "docker run -it --rm --device=/dev/net/tun --cap-add=NET_ADMIN  --name openvpn-client  --volume ${openVPNSocksFolder}/:/etc/openvpn/:ro -p 10808:1080  kizzx2/openvpn-client-socks"
    docker run -it --rm --device=/dev/net/tun --cap-add=NET_ADMIN  --name openvpn-client  --volume ${openVPNSocksFolder}/:/etc/openvpn/:ro -p 10808:1080  kizzx2/openvpn-client-socks
 
    curl --proxy socks5h://localhost:10808 ipinfo.io
    curl --proxy socks5h://localhost:10808 http://ip111.cn/
}







function startMenuOther(){
    clear

    if [[ ${configLanguage} == "cn" ]] ; then
    
        green " =================================================="
        echo
        green " 21. 安装 XrayR 服务器端"
        green " 22. 停止, 重启, 查看日志等, 管理 XrayR 服务器端"
        green " 23. 编辑 XrayR 配置文件 ${configXrayRConfigFilePath}"        
        echo
        green " 41. 安装 Soga 服务器端"
        green " 42. 停止, 重启, 查看日志等, 管理 Soga 服务器端"
        green " 43. 编辑 Soga 配置文件 ${configSogaConfigFilePath}"
        echo
        green " 62. 安装共享Netflix账号服务器端, 可以不用奈菲账号直接看奈菲"
        red " 63. 卸载共享Netflix账号服务器端"
        echo
        green " 71. 工具脚本合集 by BlueSkyXN "
        green " 72. 工具脚本合集 by jcnf "
        echo
        green " 9. 返回上级菜单"
        green " 0. 退出脚本"    

    else
        green " =================================================="
        echo
        green " 21. Install XrayR server side "
        green " 22. Stop, restart, show log, manage XrayR server side "
        green " 23. Using VI open XrayR config file ${configXrayRConfigFilePath}"        
        echo
        green " 41. Install Soga server side "
        green " 42. Stop, restart, show log, manage Soga server side "
        green " 43. Using VI open Soga config file ${configSogaConfigFilePath}"
        echo
        green " 62. Install Netflix account share service server, Play Netflix without Netflix account"
        red " 63. Remove Netflix account share service server"    
        echo
        green " 71. toolkit by BlueSkyXN "
        green " 72. toolkit by jcnf "
        echo
        green " 9. Back to main menu"
        green " 0. exit"

    fi


    echo
    read -p "Please input number:" menuNumberInput
    case "$menuNumberInput" in
        21 )
            setLinuxDateZone
            installXrayR
        ;;
        22 )
            manageXrayR
        ;;
        23 )
            editXrayRConfig
        ;;    
        41 )
            setLinuxDateZone
            installSoga 
        ;;
        42 )
            manageSoga
        ;;                                        
        43 )
            editSogaConfig
        ;;
        62 )
            installShareNetflixAccount
        ;;
        63 )
            removeShareNetflixAccount
        ;;
        71 )
            toolboxSkybox
        ;;
        72 )
            toolboxJcnf
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

    if [[ ${configLanguage} == "cn" ]] ; then
    green " =================================================="
    green " Linux 常用工具 一键安装脚本 | 2022-9-29 | 系统支持：centos7+ / debian9+ / ubuntu16.04+"
    green " =================================================="
    green " 1. 安装 linux 内核 BBR Plus, 安装 WireGuard, 用于解锁 Netflix 限制 和避免弹出 Google reCAPTCHA 人机验证"
    echo
    green " 3. 用 VI 编辑 authorized_keys 文件 填入公钥, 用于SSH免密码登录 增加安全性"
    green " 4. 修改 SSH 登陆端口号"
    green " 5. 设置时区为北京时间"
    green " 6. 用VI 编辑 /etc/hosts"
    echo
    green " 11. 安装 Vim Nano Micro 编辑器"
    green " 12. 安装 Nodejs 与 PM2"
    green " 13. 安装 Docker 与 Docker Compose"
    red " 14. 卸载 Docker 与 Docker Compose"
    green " 15. 设置 Docker Hub 镜像 "
    green " 16. 安装 Portainer "
    echo
    green " 21. 安装 Cloudreve 云盘系统 "
    red " 22. 卸载 Cloudreve 云盘系统 "
    green " 23. 安装/更新/删除 Alist 云盘文件列表系统 "
    echo
    green " 28. 安装 CasaOS 系统(包括 Nextcloud 云盘 和 AdGuard DNS 等)  "
    red " 29. 卸载 CasaOS 系统 " 
    echo
    green " 31. 安装 Grist 在线Excel表格(类似 Airtable)  "
    red " 32. 卸载 Grist 在线Excel表格 " 
    green " 33. 安装 NocoDB 在线Excel表格(类似 Airtable)  "
    red " 34. 卸载 NocoDB 在线Excel表格 " 
    green " 35. 安装 Etherpad 多人协作文档(类似 Word)  "
    red " 36. 卸载 Etherpad 多人协作文档 "     
    echo
    green " 41. 安装 Ghost Blog 博客系统 "
    red " 42. 卸载 Ghost Blog 博客系统 "     
    echo

    green " 47. 安装视频会议系统 Jitsi Meet "
    red " 48. 卸载 Jitsi Meet "
    green " 49. Jitsi Meet 发起会议是否需要密码验证"

    echo
    green " 51. 安装 Air-Universe 服务器端"
    red " 52. 卸载 Air-Universe"
    green " 53. 停止, 重启, 查看日志等, 管理 Air-Universe 服务器端"
    green " 54. 配合 WARP (Wireguard) 使用IPV6 解锁 google人机验证和 Netflix等流媒体网站"
    green " 55. 升级或降级 Air-Universe 到 1.0.0 or 0.9.2, 降级 Xray 到 1.5或1.4"
    green " 56. 重新申请证书 并修改 Air-Universe 配置文件 ${configAirUniverseConfigFilePath}"
    green " 58. 更新 geoip.dat 和 geosite.dat 文件"
    echo 
    green " 61. 单独申请域名SSL证书"
    echo
    green " 77. 子菜单 安装 V2board 服务器端 XrayR, V2Ray-Poseidon, Soga"
    echo
    green " 88. 升级脚本"
    green " 0. 退出脚本"

    else
    green " =================================================="
    green " Linux tools installation script | 2022-9-29 | OS support：centos7+ / debian9+ / ubuntu16.04+"
    green " =================================================="
    green " 1. Install linux kernel,  bbr plus kernel, WireGuard and Cloudflare WARP. Unlock Netflix geo restriction and avoid Google reCAPTCHA"
    echo
    green " 3. Using VI open authorized_keys file, enter your public key. Then save file. In order to login VPS without Password"
    green " 4. Modify SSH login port number. Secure your VPS"
    green " 5. Set timezone to Beijing time"
    green " 6. Using VI open /etc/hosts file"
    echo
    green " 11. Install Vim Nano Micro editor"
    green " 12. Install Nodejs and PM2"
    green " 13. Install Docker and Docker Compose"
    red " 14. Remove Docker and Docker Compose"
    green " 15. Set Docker Hub Registry"
    green " 16. Install Portainer "
    echo
    green " 21. Install Cloudreve cloud storage system"
    red " 22. Remove Cloudreve cloud storage system"
    green " 23. Install/Update/Remove Alist file list storage system "
    echo
    green " 28. Install CasaOS(Including Nextcloud, AdGuard DNS )  "
    red " 29. Remove CasaOS "     
    echo
    green " 31. Install Grist Online Spreadsheet (Airtable alternative)"
    red " 32. Remove Grist Online Spreadsheet (Airtable alternative)"
    green " 33. Install NocoDB Online Spreadsheet (Airtable alternative)"
    red " 34. Remove NocoDB Online Spreadsheet (Airtable alternative)"
    green " 35. Install Etherpad collaborative editor (Word alternative)"
    red " 36. Remove Etherpad collaborative editor (Word alternative)"
    echo
    green " 41. Install Ghost Blog "
    red " 42. Remove Ghost Blog "     
    echo    
    green " 47. Install Jitsi Meet video conference system"
    red " 48. Remove Jitsi Meet video conference system"
    green " 49. Modify Jitsi Meet whether to Start a meeting requires password authentication"

    echo
    green " 51. Install Air-Universe server side "
    red " 52. Remove Air-Universe"
    green " 53. Stop, restart, show log, manage Air-Universe server side "
    green " 54. Using WARP (Wireguard) and IPV6 Unlock Netflix geo restriction and avoid Google reCAPTCHA"
    green " 55. Upgrade or downgrade Air-Universe to 1.0.0 or 0.9.2, downgrade Xray to 1.5 / 1.4"
    green " 56. Redo to get a free SSL certificate for domain name and modify Air-Universe config file ${configAirUniverseConfigFilePath}"
    green " 58. Update geoip.dat and geosite.dat "
    echo 
    green " 61. Get a free SSL certificate for domain name only"
    echo
    green " 77. Submenu. install XrayR, V2Ray-Poseidon, Soga for V2board panel"
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
        3 )
            editLinuxLoginWithPublicKey
        ;;
        4 )
            changeLinuxSSHPort
            sleep 10s
            start_menu
        ;;
        5 )
            setLinuxDateZone
            sleep 4s
            start_menu
        ;;
        6 )
            DSMEditHosts
        ;;
        11 )
            installSoftEditor
        ;;
        12 )
            installPackage
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
        21 )
            installCloudreve
        ;;
        22 )
            removeCloudreve
        ;;
        23 )
            installAlist
        ;;
        28 )
            installCasaOS
        ;;
        29 )
            removeCasaOS
        ;;
        31 )
            installGrist
        ;;
        32 )
            removeGrist
        ;;
        33 )
            installNocoDB
        ;;
        34 )
            removeNocoDB
        ;;
        35 )
            installEtherpad
        ;;
        36 )
            removeEtherpad
        ;;
        41 )
            installCMSGhost
        ;;
        42 )
            removeCMSGhost
        ;;
        47 )
            installJitsiMeet
        ;;
        48 )
            removeJitsiMeet
        ;;
        49 )
            secureAddPasswordForJitsiMeet
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
            replaceAirUniverseConfigWARP
        ;;
        55 )
            downgradeXray
        ;;
        56 )
            installAirUniverse "ssl"
        ;;
        57 )
            installAiruAndNginx
        ;;
        58 )
            updateGeoIp
        ;;
        61 )
            getHTTPSCertificateStep1
        ;;
        77 )
            startMenuOther
        ;;
        88 )
            upgradeScript
        ;;
        89 )
                su - ghostsite << EOF
    echo "--------------------"
    echo "Current user: $(whoami)"
    whoami
    $(whoami)
    # ghost install --port 3468 --db=sqlite3 --no-prompt --dir ${configGhostSitePath} --url https://${configSSLDomain}
    echo "--------------------"
EOF
whoami
sudo -u ghostsite bash << EOF
echo "In"
whoami
EOF
echo "Out"
whoami
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
