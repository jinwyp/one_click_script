#!/bin/bash

export LC_ALL=C
export LANG=C
export LANGUAGE=en_US.UTF-8


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



sudoCommand=""


if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCommand="sudo"
fi



osCPU="intel"
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

    osReleaseVersionNoShort=$(echo $osReleaseVersionNo | sed 's/\..*//')
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








function installSoftDownload(){
	if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
		if ! dpkg -l | grep -qw wget; then
			${osSystemPackage} -y install wget curl git unzip
			
			# https://stackoverflow.com/questions/11116704/check-if-vt-x-is-activated-without-having-to-reboot-in-linux
			${osSystemPackage} -y install cpu-checker
		fi

	elif [[ "${osRelease}" == "centos" ]]; then
		if ! rpm -qa | grep -qw wget; then
			${osSystemPackage} -y install wget curl git unzip
		fi
	fi 
}



function installPackage(){
    if [ "$osRelease" == "centos" ]; then
       
        # rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm

        cat > "/etc/yum.repos.d/nginx.repo" <<-EOF
[nginx]
name=nginx repo
baseurl=https://nginx.org/packages/centos/$osReleaseVersionNoShort/\$basearch/
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













# 安装 BBR 加速网络软件
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
        green "===== 下载并解压tar文件: $3 "
        wget -O ${configDownloadTempPath}/$3 $1
        tar xf ${configDownloadTempPath}/$3 -C ${configDownloadTempPath}
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












function installNodejs(){

    if [ "$osRelease" == "centos" ] ; then

        if [ "$osReleaseVersion" == "8" ]; then
            ${sudoCommand} dnf module list nodejs
            ${sudoCommand} dnf module enable nodejs:14
            ${sudoCommand} dnf install nodejs
        fi

        if [ "$osReleaseVersion" == "7" ]; then
            curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
            ${sudoCommand} yum install -y nodejs
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
        # curl -fsSL https://get.docker.com -o get-docker.sh  
        curl -sSL https://get.daocloud.io/docker -o get-docker.sh  
        chmod +x ./get-docker.sh
        sh get-docker.sh
        
        systemctl start docker
        systemctl enable docker.service
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

        ${sudoCommand} wget -O /usr/local/bin/docker-compose ${dockerComposeUrl}
        ${sudoCommand} chmod a+x /usr/local/bin/docker-compose

        rm -f `which dc` 
        rm -f "/usr/bin/docker-compose"
        ${sudoCommand} ln -s /usr/local/bin/docker-compose /usr/bin/dc
        ${sudoCommand} ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
        
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

            echo
            green " =================================================="
            systemctl restart xray.service
            airu restart
            echo
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
    if [[ $isV2rayUnlockDNSInput == [Nn] ]]; then
        v2rayConfigDNSInput=""
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
    yellow " 是否使用 Cloudflare WARP 解锁 流媒体 Netflix 等网站和避免弹出 Google reCAPTCHA 人机验证"
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
        green " 5. 同时解锁 2, 4项, 即为 解锁 Netflix 和 Pornhub 限制"
        green " 6. 同时解锁 2, 3, 4项, 即为 解锁 Netflix, Youtube 和 Pornhub 限制"
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
            V2rayUnlockVideoSiteRuleText="\"geosite:youtube\", \"geosite:netflix\", \"geosite:pornhub\""

        elif [[ $isV2rayUnlockVideoSiteInput == "7" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:netflix\", \"geosite:hulu\", \"geosite:hbo\", \"geosite:disney\", \"geosite:pornhub\""

        elif [[ $isV2rayUnlockVideoSiteInput == "8" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:youtube\", \"geosite:netflix\", \"geosite:hulu\", \"geosite:hbo\", \"geosite:disney\", \"geosite:pornhub\""

        elif [[ $isV2rayUnlockVideoSiteInput == "9" ]]; then
            V2rayUnlockVideoSiteRuleText="\"geosite:youtube\", \"geosite:netflix\", \"geosite:bahamut\", \"geosite:hulu\", \"geosite:hbo\", \"geosite:disney\", \"geosite:bbc\", \"geosite:4chan\", \"geosite:fox\", \"geosite:abema\", \"geosite:dmm\", \"geosite:niconico\", \"geosite:pixiv\", \"geosite:viu\", \"geosite:pornhub\""

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

    if [[ $isV2rayUnlockWarpModeInput == "1" ]]; then
        echo
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
        systemctl restart xray.service
        airu restart
        green " =================================================="

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
    green " 是否检测域名指向的IP正确 (默认检测，如果域名指向的IP不是本机器IP则无法继续. 如果已开启CDN不方便关闭可以选择否)"
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











# 更新本脚本
function upgradeScript(){
    wget -Nq --no-check-certificate -O ./linux_install_software.sh "https://raw.githubusercontent.com/jinwyp/one_click_script/master/linux_install_software.sh"
    green " 本脚本升级成功! "
    chmod +x ./linux_install_software.sh
    sleep 2s
    exec "./linux_install_software.sh"
}






































function start_menu(){
    clear

    if [[ $1 == "first" ]] ; then
        getLinuxOSRelease
        installSoftDownload
    fi

    green " =================================================="
    green " Linux 常用工具 一键安装脚本 | 2021-11-29 | By jinwyp | 系统支持：centos7+ / debian9+ / ubuntu16.04+"
    red " *请不要在任何生产环境使用此脚本 请不要有其他程序占用80和443端口"
    red " *若是已安装trojan 或第二次使用脚本，请先执行卸载trojan"
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
    echo 
    green " 71. 单独申请域名SSL证书"
    echo
    green " 81. 工具脚本合集 by BlueSkyXN "
    green " 82. 工具脚本合集 by jcnf "
    echo
    green " 88. 升级脚本"
    green " 0. 退出脚本"
    echo
    read -p "请输入数字:" menuNumberInput
    case "$menuNumberInput" in
        1 )
            installWireguard
        ;;    
        2 )
            installBBR
        ;;
        3 )
            installBBR2
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
        71 )
            getHTTPS
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



start_menu "first"

