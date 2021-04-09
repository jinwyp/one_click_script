#!/bin/bash

# PVE WIKI
# https://pve.proxmox.com/wiki/Pci_passthrough
# https://pve.proxmox.com/wiki/PCI(e)_Passthrough
# https://pve.proxmox.com/wiki/Passthrough_Physical_Disk_to_Virtual_Machine_(VM)

# https://github.com/intel/gvt-linux/wiki/GVTg_Setup_Guide

# set -e
# set -o pipefail

export LC_ALL=C
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8


if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCmd="sudo"
else
  sudoCmd=""
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

function set_text_color(){
    COLOR_RED='\E[1;31m'
    COLOR_GREEN='\E[1;32m'
    COLOR_YELOW='\E[1;33m'
    COLOR_BLUE='\E[1;34m'
    COLOR_PINK='\E[1;35m'
    COLOR_PINKBACK_WHITEFONT='\033[45;37m'
    COLOR_GREEN_LIGHTNING='\033[32m \033[05m'
    COLOR_END='\E[0m'
}






function rebootSystem(){
	read -p "是否立即重启? 请输入[Y/n]:" isRebootInput
	isRebootInput=${isRebootInput:-Y}

	if [[ ${isRebootInput} == [Yy] ]]; then
		${sudoCmd} reboot
	else 
		exit
	fi
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




osCPU="intel"
osArchitecture="arm"
osRelease="dsm"
osReleaseVersionNo=""
osReleaseVersionCodeName="CodeName"
osSystemPackage="no"
osSystemMdPath="/lib/systemd/system/"


pveStatusIOMMU=""
pveStatusIOMMUDMAR=""
pveStatusVTX=""
pveStatusVTIntel=""
pveStatusVTAMD=""


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

# 检测系统发行版
function getLinuxOSRelease(){
	
    if [[ -f /etc/redhat-release ]]; then
        osRelease="centos"
        osSystemPackage="yum"
		osSystemMdPath="/usr/lib/systemd/system/"
    elif [[ -f /etc/redhat-release ]] && (cat /etc/issue | grep -Eqi "debian|raspbian|Proxmox"); then
        osRelease="debian"
        osSystemPackage="apt-get"
    elif [[ -f /etc/redhat-release ]] && (cat /etc/issue | grep -Eqi "ubuntu"); then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
    elif [[ -f /etc/redhat-release ]] && (cat /etc/issue | grep -Eqi "centos|red hat|redhat"); then
        osRelease="centos"
        osSystemPackage="yum"
		osSystemMdPath="/usr/lib/systemd/system/"
    elif cat /proc/version | grep -Eqi "debian|raspbian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
		osSystemMdPath="/usr/lib/systemd/system/"
    fi

	if [[  "${osRelease}" == "ubuntu" ]]; then
		osReleaseVersionNo=$(lsb_release -r --short)
		osReleaseVersionCodeName=$(lsb_release -c --short)

	elif [[ "${osRelease}" == "debian" || "${osRelease}" == "centos" ]]; then
        source /etc/os-release

        osReleaseVersionNo=$VERSION_ID

        if [ -n $VERSION_CODENAME ]; then
            osReleaseVersionCodeName=$VERSION_CODENAME
        fi
	fi



    [[ -z $(echo $SHELL|grep zsh) ]] && osSystemShell="bash" || osSystemShell="zsh"

	checkArchitecture
	checkCPU
    green " Status 系统信息:  ${osRelease}, ${osReleaseVersionNo}, ${osReleaseVersionCodeName}, ${osSystemShell}, ${osSystemPackage}, ${osCPU} CPU ${osArchitecture}"
}








function installSoft(){
	if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
		if ! dpkg -l | grep -qw wget; then
			${osSystemPackage} -y install wget curl
			
			# https://stackoverflow.com/questions/11116704/check-if-vt-x-is-activated-without-having-to-reboot-in-linux
			${osSystemPackage} -y install cpu-checker

			${osSystemPackage} install -y vim-gui-common vim-runtime vim 
		fi

	elif [[ "${osRelease}" == "centos" ]]; then
		if ! rpm -qa | grep -qw wget; then
			${osSystemPackage} -y install wget curl vim-minimal vim-enhanced vim-common
		fi
	fi


    if [[ ${osRelease} == "dsm" ]] ; then
		echo
    else
		sed -i "s/# alias l/alias l/g" ${HOME}/.bashrc

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

    fi

}

function installIperf3(){
    if [[ ${osRelease} == "dsm" ]] ; then
		${sudoCmd} wget -O /usr/lib/libiperf.so.0 https://iperf.fr/download/ubuntu/libiperf.so.0_3.1.3
		${sudoCmd} wget -O /usr/bin/iperf3 https://iperf.fr/download/ubuntu/iperf3_3.1.3
		${sudoCmd} chmod +x /usr/bin/iperf3
    else
		${osSystemPackage} -y install iperf3   
    fi

	green " ================================================== "
	green " 测网速软件iperf3 安装成功, 使用方法如下 "
	green " 启动服务器端 运行 iperf3 -s "
	green " 在另一台机器启动上传测速 运行 iperf3 -c 192.168.xx.xx, ip为服务端机器的ip即可"
	green " 在另一台机器启动下载测速 运行 iperf3 -R -c 192.168.xx.xx, ip为服务端机器的ip即可"
	green " ================================================== "
}


# Disable selinux
disableSelinux(){

	green " ================================================== "
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then

		read -p "是否关闭 安全系统 SELINUX, 直接回车默认关闭. 请输入[Y/n]:" isCloseSELinuxInput
		isCloseSELinuxInput=${isCloseSELinuxInput:-y}

		if [[ $isCloseSELinuxInput == [Yy] ]]; then
			sed -i 's/SELINUX=enforcing/SELinux=disabled/g' /etc/selinux/config
			${sudoCmd} setenforce 0

			green "     当前系统已成功关闭 SELinux, 需要重启生效 "
			green " ================================================== "
			rebootSystem
		fi

	else
		green "     当前系统没有开启 SELinux "
		green " ================================================== "
    fi
}

isFirewallRunningStatus="no"

checkFirewallStatus(){
	if [[ "${osRelease}" == "centos" ]]; then

		isFirewalldRunningStatusText=$(systemctl is-active firewalld)
		if [[ ${isFirewalldRunningStatusText} == "active" ]]; then
			isFirewallRunningStatus="yes"
		else	
			isFirewallRunningStatus="no"
		fi

	elif [[ "${osRelease}" == "debian" ]]; then
		echo ""
	elif [[ "${osRelease}" == "ubuntu" ]]; then
		isUfwRunningStatusText=$(ufw status | grep active | awk '{print $2}')
		if [[ ${isUfwRunningStatusText} == "active" ]]; then
			isFirewallRunningStatus="yes"
		else	
			isFirewallRunningStatus="no"
		fi
	fi

	echo
	green "     当前系统防火墙是否开启: ${isFirewallRunningStatus} "
	echo
}

addFirewallPort(){
	
	if [[ $1 -gt 1 && $1 -le 65535 ]]; then
		
		netstat -tulpn | grep [0-9]:$1 -q ; 
		if [ $? -eq 1 ]; then 
			green " 端口号 $1 没有被占用" 
			false 
		else 
			red " 端口号 $1 已被占用! " 
			true
		fi
	else
		red "输入的端口号错误! 必须是[1-65535] 纯数字!" 
	fi

	if [[ ${isFirewallRunningStatus} == "yes" ]]; then	
		if [[ "${osRelease}" == "centos" ]]; then

			${sudoCmd} firewall-cmd --permanent --zone=public --add-port=$1/tcp 
			${sudoCmd} firewall-cmd --permanent --zone=public --add-port=$1/udp 
            ${sudoCmd} firewall-cmd --reload

		elif [[ "${osRelease}" == "debian" ]]; then
			iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
			iptables -I INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT

		elif [[ "${osRelease}" == "ubuntu" ]]; then
			${sudoCmd} ufw allow $1/tcp
			${sudoCmd} ufw allow $1/udp
		fi
	
	else
		green "     当前系统防火墙没有开启, 不需要添加规则 "			
	fi

}


Del_iptables(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
}






















function updateYumAptSource(){
	if [[ "${osRelease}" == "centos" ]]; then

		echo

	elif [[ "${osRelease}" == "debian" ]]; then
		updatePVEAptSource

	elif [[ "${osRelease}" == "ubuntu" ]]; then
		updateUbuntuAptSource
	fi

}

function updateUbuntuAptSource(){
	green " ================================================== "
	green " 准备更新源 为阿里云 "

	${sudoCmd} cp /etc/apt/sources.list /etc/apt/sources.list.bak
	
	cat > /etc/apt/sources.list <<-EOF

deb http://mirrors.aliyun.com/ubuntu/ ${osReleaseVersionCodeName} main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${osReleaseVersionCodeName} main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ ${osReleaseVersionCodeName}-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${osReleaseVersionCodeName}-security main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ ${osReleaseVersionCodeName}-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${osReleaseVersionCodeName}-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ ${osReleaseVersionCodeName}-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${osReleaseVersionCodeName}-proposed main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ ${osReleaseVersionCodeName}-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${osReleaseVersionCodeName}-backports main restricted universe multiverse


EOF

	${sudoCmd} apt-get update

	green " ================================================== "
	green " 更新源成功 "
	green " ================================================== "

# deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
# deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse

# deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
# deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse

# deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
# deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse

# deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
# deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse

# deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
# deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
}



function updatePVEAptSource(){

	isPVESystem=$(cat /etc/issue | grep "Proxmox")

	green " ================================================== "

	if [[ -n "${isPVESystem}" ]]; then 
		green " 准备关闭企业更新源, 添加非订阅版更新源 "
		${sudoCmd} sed -i 's|deb https://enterprise.proxmox.com/debian/pve buster pve-enterprise|#deb https://enterprise.proxmox.com/debian/pve buster pve-enterprise|g' /etc/apt/sources.list.d/pve-enterprise.list

		#echo 'deb http://download.proxmox.com/debian/pve buster pve-no-subscription' > /etc/apt/sources.list.d/pve-no-subscription.list
		echo "deb https://mirrors.tuna.tsinghua.edu.cn/proxmox/debian buster pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list

		wget http://download.proxmox.com/debian/proxmox-ve-release-6.x.gpg -O /etc/apt/trusted.gpg.d/proxmox-ve-release-6.x.gpg
	fi



	cp /etc/apt/sources.list /etc/apt/sources.list.bak

	cat > /etc/apt/sources.list <<-EOF

deb http://mirrors.aliyun.com/debian/ buster main contrib non-free
deb-src http://mirrors.aliyun.com/debian/ buster main contrib non-free

deb http://mirrors.aliyun.com/debian/ buster-updates main contrib non-free
deb-src http://mirrors.aliyun.com/debian/ buster-updates main contrib non-free

deb http://mirrors.aliyun.com/debian/ buster-backports main contrib non-free
deb-src http://mirrors.aliyun.com/debian/ buster-backports main contrib non-free

deb http://mirrors.aliyun.com/debian-security buster/updates main contrib non-free
deb-src http://mirrors.aliyun.com/debian-security buster/updates main contrib non-free

EOF

	${sudoCmd} apt-get update

	green " ================================================== "
	green " 更新源成功 "
	green " ================================================== "


# deb http://deb.debian.org/debian buster main contrib non-free
# deb-src http://deb.debian.org/debian buster main contrib non-free

# deb http://deb.debian.org/debian buster-updates main contrib non-free
# deb-src http://deb.debian.org/debian buster-updates main contrib non-free

# deb http://deb.debian.org/debian buster-backports main contrib non-free
# deb-src http://deb.debian.org/debian buster-backports main contrib non-free

# deb http://deb.debian.org/debian-security/ buster/updates main contrib non-free
# deb-src http://deb.debian.org/debian-security/ buster/updates main contrib non-free

}




function setPVEIP(){
	# https://pve.proxmox.com/pve-docs/chapter-sysadmin.html#sysadmin_network_configuration

	green " ================================================== "

	green " 请选择使用静态IP模式还是DHCP自动获取IP模式, 直接回车默认静态IP模式 "
	read -p "Choose IP Mode: DHCP(y) or Static(n) ? (default: static ip) Pls Input [y/N]:" IPModeInput
	IPModeInput=${IPModeInput:-n}
	green " 请输入指定的IP地址, 如果已选择了DHCP模式 输入的IP不是实际的IP地址,仅作为在开机欢迎语中的IP显示"
	read -p "Please input IP address of your n3450 computer (default:192.168.7.200) :" IPInput

	if [[ $IPModeInput == [Yy] ]]; then
    cat > /etc/network/interfaces <<-EOF

# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback


# The primary network interface
iface enp1s0 inet manual

auto vmbr0
iface vmbr0 inet dhcp
    bridge_ports enp1s0
    bridge_stp off
    bridge_fd 0


# allow-hotplug wlp2s0
# iface wlp2s0 inet dhcp
# pre-up ip link set wlan0 up
# pre-up iwconfig wlan0 essid ssid
# wpa-ssid ssid
# wpa-psk password

EOF
	green " ================================================== "
	red "$IPInput is not the real ip. It only shows on the welcome message !"
	red "Please run command 'ifconfig' to show the real IP or check the real ip on the router !"
	red "$IPInput 不是实际的IP, 仅在开机欢迎语中显示, 实际的IP请运行命令 'ifconfig' 或通过路由器查看"

	green " ================================================== "
	else

		read -p "Please input IP netmask (default:255.255.255.0) :" netmaskInput
		read -p "Please input IP gateway (default:192.168.7.1) :" gatewayInput

		IPInput=${IPInput:-192.168.7.200}
		netmaskInput=${netmaskInput:-255.255.255.0}
		gatewayInput=${gatewayInput:-192.168.7.1}


    cat > /etc/network/interfaces <<-EOF

# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
iface enp1s0 inet manual

auto vmbr0
iface vmbr0 inet static
    address ${IPInput}
    netmask ${netmaskInput}
    gateway ${gatewayInput}
    bridge_ports enp1s0
    bridge_stp off
    bridge_fd 0
	

EOF
	
	fi


# https://unix.stackexchange.com/questions/340347/sed-replace-any-ip-address-with-127-0-0-1

sed -i -e "s/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/${IPInput}/g" /etc/issue

	green " ================================================== "
	green " IP修改成功, 已修改为 ${IPInput}"
	green " 请手工修改 /etc/hosts 文件, 确保 hostname 也改为新IP"
	green " ================================================== "
}





 
function lvextendDevRoot(){
	echo "准备把剩余空间扩容给 /dev/pve/root 或 /dev/pve/data"

	read -p "是否把剩余空间都扩容到/dev/pve/root 或 /dev/pve/data, 否为不处理扩容空间. 直接回车默认为是, 请输入[Y/n]:" isExtendDevRootInput
	isExtendDevRootInput=${isExtendDevRootInput:-Y}
	
	toExtendDevVolume="root"
	if [[ $isExtendDevRootInput == [Yy] ]]; then

		if [[ $1 == "/dev/pve/swap" ]]; then
			read -p "把剩余空间扩容到 /pve/root 还是 /pve/data?, 直接回车默认为是 /dev/root 盘, 否为/dev/data盘, 请输入[Y/n]:" isExtendDevDataInput
			isExtendDevDataInput=${isExtendDevDataInput:-Y}

			if [[ $isExtendDevDataInput == [Yy] ]]; then
				toExtendDevVolume="root"
			else
				toExtendDevVolume="data"
			fi
		fi

		echo "lvextend -l +100%FREE -f pve/${toExtendDevVolume}"
		lvextend -l +100%FREE -f "pve/${toExtendDevVolume}"  
		resize2fs "/dev/mapper/pve-${toExtendDevVolume}" 
		green " 已成功删除 $1 逻辑卷, 并扩容给 /dev/pve/${toExtendDevVolume}"
	else 
        green " 已成功删除 $1 逻辑卷, 剩余空间请自行处理扩容"
		exit
	fi
}

function deleteVGLVPVESwap(){
	green " ================================================== "
	green " 准备删除 /dev/pve/swap 逻辑卷, 得到的空间都会增加给/dev/pve/root 或 /dev/pve/data "

	${sudoCmd} sed -i 's|/dev/pve/swap none swap|#/dev/pve/swap none swap|g' /etc/fstab

	green " 请重启后 继续运行本脚本选择 第2项 继续完成删除"
	
	read -p "是否立即重启? 请输入[Y/n]:" isRebootInput
	isRebootInput=${isRebootInput:-Y}

	if [[ $isRebootInput == [Yy] ]]; then
		${sudoCmd} reboot
	fi

	echo
	echo "free"
	free
	
	green " 请查看上面信息 swap 分区的 total, used, free 是否为0, 表明系统不在使用swap分区" 
	echo ""

	green " 删除 /dev/pve/swap 逻辑卷"
	echo "lvremove /dev/pve/swap"
	lvremove /dev/pve/swap

	echo
	green " 请查看删除swap分区后 多出来的空间容量"
	vgdisplay pve | grep Free

	lvextendDevRoot "/dev/pve/swap"

	green " ================================================== "
}


function deleteVGLVPVEData(){
	green " ================================================== "
	green " 准备删除 /dev/pve/data 逻辑卷, 得到的空间都会增加给/dev/pve/root "

	cp /etc/pve/storage.cfg /etc/pve/storage.cfg.bak

	${sudoCmd} sed -i 's|content iso,vztmpl,backup|content backup,vztmpl,snippets,iso,images,rootdir|g' /etc/pve/storage.cfg

	${sudoCmd} sed -i '/lvmthin/d' /etc/pve/storage.cfg
	${sudoCmd} sed -i '/thinpool data/d' /etc/pve/storage.cfg
	${sudoCmd} sed -i '/vgname pve/d' /etc/pve/storage.cfg
	${sudoCmd} sed -i '/content rootdir,images/d' /etc/pve/storage.cfg


	green " 请重启后 继续运行本脚本选择 第2项 继续完成删除"
	lvremove /dev/pve/data

	echo "free"
	free
	
	green " 请查看上面信息 swap 分区的 total, used, free 是否为0, 表明系统不在使用swap分区" 
	echo ""

	green " 删除 /dev/pve/data 逻辑卷"
	echo "lvremove /dev/pve/data"
	lvremove /dev/pve/data

	echo
	green " 请查看删除 /dev/pve/data 逻辑卷后 多出来的空间容量"
	vgdisplay pve | grep Free 

	lvextendDevRoot "/dev/pve/data"

	green " ================================================== "
}



function checkIOMMU(){
	green " ================================================== "
	green " 准备检测当前系统是否开启IOMMU, 用于PCI直通. 需要先重启进入BIOS, 开启IOMMU. "
	green " 同时需要BIOS开启 CPU virtualization 虚拟化. Intel的CPU开启VT-d, AMD开启AMD-Vi "
	echo
	green " Checking IOMMU support ..."
	green " Restart your machine and boot into BIOS. Enable a feature called IOMMU"
	green " You'll also need to enable CPU virtualization. "
	green " For Intel processors, look for something called VT-d. For AMD, look for something called AMD-Vi."
	green " ================================================== "


	pveStatusVTXText=$(kvm-ok | grep "KVM acceleration can be used")

	if [[ $pveStatusVTXText == "KVM acceleration can be used" ]]; then
		pveStatusVTX="yes"
    else
        pveStatusVTX="no"
    fi

	echo
	green " 下面信息如果显示 KVM acceleration can be used 则已开启VT-x"
	green " 下面信息如果显示 INFO: /dev/kvm does not exist. KVM acceleration can NOT be used 则未开启VT-x"
	${sudoCmd} kvm-ok
	


	pveStatusIOMMUText=$(dmesg | grep IOMMU)
	pveStatusVTIntelText=$(dmesg | grep x2apic )
	pveStatusVTAMDText=$(dmesg | grep AMD-Vi)

	if [[ -z "$pveStatusIOMMUText" ]]; then
		pveStatusIOMMU="no"
	else
        pveStatusIOMMU="yes"
    fi

	echo
	green " 状态显示--当前是否开启VT-x: $pveStatusVTX "
	green " 状态显示--当前是否开启IOMMU: $pveStatusIOMMU "

	if [[ $osCPU == "intel" ]]; then
		if [[ -z "$pveStatusVTIntelText" ]]; then
			pveStatusVTIntel="no"
			green " 状态显示--当前是否开启Intel VT-d: $pveStatusVTIntel"
		else
			pveStatusVTIntel="yes"
			green " 状态显示--当前是否开启Intel VT-d: $pveStatusVTIntel "
			echo " dmesg | grep x2apic "
			echo "$pveStatusVTIntelText"
		fi
		
    else
		if [[ -z "$pveStatusVTAMDText" ]]; then
			pveStatusVTAMD="no"
			green " 状态显示--当前是否开启AMD-Vi: $pveStatusVTAMD"
		else
			pveStatusVTAMD="yes"
			green " 状态显示--当前是否开启AMD-Vi: $pveStatusVTAMD"
			echo " dmesg | grep AMD-Vi "
			echo "$pveStatusVTAMDText"
		fi
		
    fi

	green " ================================================== "

}


function checkIOMMUDMAR(){
	pveStatusIOMMUDMARText=$(dmesg | grep -e DMAR -e IOMMU)

	if [[ -z "$pveStatusIOMMUDMARText" ]]; then
		pveStatusIOMMUDMAR="no"
		green " 状态显示--当前是否开启IOMMU DMAR: $pveStatusIOMMUDMAR "
	else
        pveStatusIOMMUDMAR="yes"
		green " 状态显示--当前是否开启IOMMU DMAR: $pveStatusIOMMUDMAR "
		green " dmesg | grep -e DMAR -e IOMMU "
		echo "$pveStatusIOMMUDMARText"

    fi
}


function displayIOMMUInfo(){
	# https://pvecli.xuan2host.com/aa-angle-bios-vt-d-enable/

	green " ================================================== "
	green " 显示 IOMMU 信息, 用于查看是否开启IOMMU. "
	green " ================================================== "
	echo "iommu boot kernel flag"
	echo "cat /etc/default/grub | grep iommu"
	cat /etc/default/grub | grep iommu
	echo " "
	echo "dmesg | grep -e DMAR -e IOMMU"
	dmesg | grep -e DMAR -e IOMMU
	echo " "
	echo " "
	echo "lspci -vnn | grep -E \"Ethernet|VGA|Audio\""
	lspci -vnn | grep -E "Ethernet|VGA|Audio"
	echo " "
	echo " "
	echo "ls -al /sys/kernel/iommu_groups"
	ls -al /sys/kernel/iommu_groups
	echo " "
	echo " "
	echo "find /sys/kernel/iommu_groups/ -type l"
	find /sys/kernel/iommu_groups/ -type l
	echo " "
	green " ================================================== "
}


function checkVfio(){
	green " ================================================== "
	green " 准备检测当前系统是否开启显卡直通 "
	green " ================================================== "

	echo
	green " 显示 vfio 信息, 用于开启显卡直通 检查模块是否正常加载 "
	echo "lsmod | grep vfio"
	lsmod | grep vfio

	echo " "
	green " 显示显卡和声卡设备信息, 用于开启显卡直通 "
	echo "lspci -nn | grep -E \"VGA|Audio\" "
	lspci -nn | grep -E "VGA|Audio"

	echo " "
	echo "lspci -nn | grep -E \"0300|0403\" "
	lspci -nn | grep -E "0300|0403"

	echo " "
	green " 显示显卡信息, 请查看 Kernel driver in use 这一行"
	echo "lspci -vvv -s 00:02.0"
	lspci -vvv -s 00:02.0

	pveStatusVfioText=$(lspci -vvv -s 00:02.0 | grep "Kernel driver in use")

	if [[ $pveStatusVfioText == *"i915"* ]]; then
		pveStatusVifo="no"
    else
        pveStatusVifo="yes"
    fi

	green " 上面信息 Kernel driver in use 这一行如果是 vfio-pic, 则显卡设备被PVE屏蔽成功, 可以直通显卡 "
	green " 上面信息 Kernel driver in use 这一行如果是 i915, 则显卡设备没有被PVE屏蔽, 无法直通显卡"
	green " 状态显示--当前是否可以直通显卡: $pveStatusVifo "

	green " ================================================== "
	echo
	echo
}

function enableIOMMU(){
	checkIOMMU

	green " ================================================== "
	red " 警告: 不保证开启成功! 如有黑屏无法启动的风险, 后果自负!  "
	green " 准备开启IOMMU VT-d, 用于PCI设备直通.  "
	green " 如果开启IOMMU 遇到问题, 要直通的设备没有独立的IOMMU groups, 例如网卡的各个网口不能单独直通 可以添加 'pcie_acs_override=downstream' 参数开启 "
	echo
	green " PT模式 (pass-through using SR-IOV): PCIe设备只在需要时进行IOMMU转换, 开启可提高性能, 添加 'iommu=pt' 参数开启 "
	echo
	green " 如果AMD的CPU 例如Ryzen II 4750G 遇到 AMD-Vi: Unable to read/write to IOMMU perf counter. , 添加 'iommu=soft' 参数解决 "
	echo
	green " 开启显卡核显直通: 可以添加 'video=efifb:off,vesafb:off' 参数开启 "
	yellow " 注意: 开启显卡直通, 虚拟机不能设置自动随着宿主机开机自动启动, 否则宿主机会与虚拟机抢占显卡设备导致死机无法启动 "
	echo
	yellow " If you don't have dedicated IOMMU groups, you can try: "
	yellow " 1) moving the card to another pci slot "
	yellow " 2) adding 'pcie_acs_override=downstream' to kernel boot commandline which can help on some setup with bad ACS implementation"
	echo
	yellow " PT Mode (pass-through using SR-IOV):Enables the IOMMU translation only when necessary, and can thus improve performance for PCIe devices not used in VMs."
	green " ================================================== "
	
	# https://www.moenis.com/archives/103.html
	# https://pvecli.xuan2host.com/grub/
	# https://access.redhat.com/documentation/zh-cn/red_hat_virtualization/4.0/html/installation_guide/appe-configuring_a_hypervisor_host_for_pci_passthrough

	read -p "是否增加pcie_acs_override=downstream 参数? 默认否, 请输入[y/N]:" isAddPcieGroupsInput
	isAddPcieGroupsInput=${isAddPcieGroupsInput:-n}

	read -p "是否增加iommu=pt 参数? 默认否, 请输入[y/N]:" isAddPciePTInput
	isAddPciePTInput=${isAddPciePTInput:-n}

	read -p "是否增加iommu=soft 参数解决 AMD CPU的 Unable to read/write to IOMMU perf counter问题, 默认否, 请输入[y/N]:" isAddAMDCPUFixedPerfCounterInput
	isAddAMDCPUFixedPerfCounterInput=${isAddAMDCPUFixedPerfCounterInput:-n}

	read -p "是否增加acpi=off 参数解决 ACPI BIOS Error 问题, 默认否, 请输入[y/N]:" isAddAMDCPUFixedACPIInput
	isAddAMDCPUFixedACPIInput=${isAddAMDCPUFixedACPIInput:-n}
	
	isAddPcieText=""
	if [[ $isAddPciePTInput == [Yy] ]]; then
		isAddPcieText="iommu=pt"
	fi

	if [[ $isAddAMDCPUFixedACPIInput == [Yy] ]]; then
		isAddPcieText="${isAddPcieText} acpi=off"
	fi

	if [[ $isAddPcieGroupsInput == [Yy] ]]; then
		isAddPcieText="${isAddPcieText} pcie_acs_override=downstream,multifunction "
	fi

	# https://www.reddit.com/r/homelab/comments/b5xpua/the_ultimate_beginners_guide_to_gpu_passthrough/

	# https://www.proxmox.wiki/?thread-32.htm
	# http://www.dannysite.com/blog/257/
	# https://www.10bests.com/pve-libreelec-kodi-htpc/

	read -p "是否增加video=efifb:off 参数用于显卡直通? 默认否, 请输入[y/N]:" isAddPcieVideoInput
	isAddPcieVideoInput=${isAddPcieVideoInput:-n}

	if [[ $isAddPcieVideoInput == [Yy] ]]; then
		isAddPcieText="${isAddPcieText} video=efifb:off,vesafb:off"

		echo
		yellow " 添加模块黑名单，即让GPU设备在下次系统启动之后不使用这些驱动，把设备腾出来给vfio驱动用: "
		read -p "请输入直通的显卡是Intel核显, nVidia, AMD? 默认Intel, 请输入[I/n/a]:" isAddPcieVideoCardBrandInput
		isAddPcieVideoCardBrandInput=${isAddPcieVideoCardBrandInput:-i}

		# 添加模块（驱动）黑名单，即让GPU设备在下次系统启动之后不使用这些驱动，把设备腾出来给vfio驱动用：

		if [[ $isAddPcieVideoCardBrandInput == [Ii] ]]; then
			# Intel核显：
			echo "blacklist snd_hda_intel" >> /etc/modprobe.d/pve-blacklist.conf
			echo "blacklist snd_hda_codec_hdmi" >> /etc/modprobe.d/pve-blacklist.conf
			echo "blacklist i915" >> /etc/modprobe.d/pve-blacklist.conf

		elif [[ $isAddPcieVideoCardBrandInput == [Nn] ]]; then
			# N卡：
			echo "blacklist nvidia" >> /etc/modprobe.d/pve-blacklist.conf
			echo "blacklist nouveau" >> /etc/modprobe.d/pve-blacklist.conf
		else
			# /A卡：
			echo "blacklist radeon" >> /etc/modprobe.d/pve-blacklist.conf
		fi

		echo "options vfio_iommu_type1 allow_unsafe_interrupts=1" > /etc/modprobe.d/iommu_unsafe_interrupts.conf
		echo "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf

		echo
		yellow " 添加模块黑名单，是否添加直通显卡所带声卡和麦克风: "
		read -p "是否屏蔽显卡所带声卡和麦克风 用于直通, 直接回车默认是, 请输入[Y/n]:" isAddPcieVideoCardAudioInput
		isAddPcieVideoCardAudioInput=${isAddPcieVideoCardAudioInput:-y}
		
		if [[ $isAddPcieVideoCardAudioInput == [Yy] ]]; then
			echo "blacklist snd_soc_skl" >> /etc/modprobe.d/pve-blacklist.conf

			if [[ $isAddAMDCPUFixedPerfCounterInput == [Yy] ]]; then
				echo "blacklist snd_pci_acp3x" >> /etc/modprobe.d/pve-blacklist.conf
				echo "blacklist snd_rn_pci_acp3x" >> /etc/modprobe.d/pve-blacklist.conf
			fi

		fi

		pveVfioVideoId=$(lspci -n | grep -E "0300" | awk '{print $3}' )
		pveVfioVideoIdText=$(lspci -n | grep -E "0300" | awk '{print $1, $3}' )
		pveVfioAudioId=$(lspci -n | grep -E "0403" | awk '{print $3}' )

		echo
		echo
		green " 绑定显卡和声卡设备到vfio模块, 用于显卡直通 "
		green " 显卡设备ID为 ${pveVfioVideoId} "
		green " 声卡设备ID为 ${pveVfioAudioId} "

		read -p "是否同时绑定显卡和声卡设备, 输入n为仅绑定显卡. 直接回车默认是, 请输入[Y/n]:" isAddPcieVideoAudoVfioInput
		isAddPcieVideoAudoVfioInput=${isAddPcieVideoAudoVfioInput:-y}
		
		if [[ $isAddPcieVideoAudoVfioInput == [Yy] ]]; then
			echo "options vfio-pci ids=${pveVfioVideoId},${pveVfioAudioId} disable_vga=1" > /etc/modprobe.d/vfio.conf
		else 
			echo "options vfio-pci ids=${pveVfioVideoId} disable_vga=1" > /etc/modprobe.d/vfio.conf
		fi



		update-initramfs -u

	fi

    if [[ $osCPU == "intel" ]]; then
		${sudoCmd} sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet.*"/GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on '"${isAddPcieText}"'"/g' /etc/default/grub
	else

		if [[ $isAddAMDCPUFixedPerfCounterInput == [Yy] ]]; then
			${sudoCmd} sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet.*"/GRUB_CMDLINE_LINUX_DEFAULT="quiet iommu=soft '"${isAddPcieText}"'"/g' /etc/default/grub
		else
			${sudoCmd} sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet.*"/GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on '"${isAddPcieText}"'"/g' /etc/default/grub
		fi

	fi

	pveIsAddedVfioModule=$(cat /etc/modules | grep vfio )

	if [[ -z "$pveIsAddedVfioModule" ]]; then
		cat >> "/etc/modules" <<-EOF
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd

EOF

    fi


	update-grub
	green " ================================================== "
	green " 开启IOMMU成功 需要重启生效!"
	green " 重启后 在PVE 虚拟机添加PCI设备 ${pveVfioVideoIdText} 即可实现显卡直通!"
	checkIOMMUDMAR
	green " ================================================== "
	echo
	# displayIOMMUInfo

	rebootSystem

}


function disableIOMMU(){
	checkIOMMU

	green " ================================================== "
	green " 准备关闭IOMMU VT-d 关闭PCI直通功能. "
	green " ================================================== "
	
    if [[ $osCPU == "intel" ]]; then
		${sudoCmd} sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet.*"/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/g' /etc/default/grub
	else
		${sudoCmd} sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet.*"/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/g' /etc/default/grub
	fi

	${sudoCmd} sed -i '/vfio.*/d' /etc/modules


	# 恢复显卡直通文件
	rm /etc/modprobe.d/kvm.conf
	rm /etc/modprobe.d/iommu_unsafe_interrupts.conf
	rm /etc/modprobe.d/vfio.conf

	cat > "/etc/modprobe.d/pve-blacklist.conf" <<-EOF

# This file contains a list of modules which are not supported by Proxmox VE

# nidiafb see bugreport https://bugzilla.proxmox.com/show_bug.cgi?id=701
blacklist nvidiafb

EOF

	update-initramfs -u

	update-grub
	green "关闭IOMMU成功 需要重启生效!"
	checkIOMMUDMAR
	green " ================================================== "
	displayIOMMUInfo

	rebootSystem
}








function genPVEVMDiskWithQM(){
	
	img2kvmPath="./img2kvm"
	img2kvmRealPath="./img2kvm"

	if [ -z $1 ]; then
		green " ================================================== "
		green " 准备使用 qm importdisk 命令 导入群晖引导镜像文件 synoboot.img "
		red " 请先通过 PVE网页上传 群晖引导镜像文件syboboot.img 到local存储盘"
		red " 通过 PVE 网页上传成功后 文件路径一般为 /var/lib/vz/template/iso/synoboot.img"
		echo
		red " 或者通过SSH WinSCP等软件上传 群晖引导镜像文件syboboot.img 到 /root 目录或用户指定目录下"
		green " ================================================== "

		promptTextDefaultDsmBootImgFilePath="/var/lib/vz/template/iso"
		promptTextFailureCommand="img2kvm"
	else 
		green " ================================================== "
		green " 准备使用 img2kvm 命令 导入群晖引导镜像文件 synoboot.img "
		green " 可通过SSH WinSCP等软件上传 img2kvm 工具到当前目录下或/root目录下, 如果用户没有上传会自动从网上下载该命令 "
		echo
		red " 请先通过通过SSH WinSCP等软件上传 群晖引导镜像文件syboboot.img 到 /root 目录或用户指定目录下"
		echo
		red " 或者通过PVE 网页上传 群晖引导镜像文件syboboot.img 到local存储盘"
		red " 通过 PVE 网页上传成功后 文件路径一般为 /var/lib/vz/template/iso/synoboot.img"
		green " ================================================== "	

		promptTextDefaultDsmBootImgFilePath="/root"
		promptTextFailureCommand="qm importdisk"


		if [[ -f "/root/img2kvm" ]]; then
			img2kvmRealPath="/root/img2kvm"
		elif [[ -f "${img2kvmPath}" ]]; then
			img2kvmRealPath=${img2kvmPath}
		else 
			green " 没有找到 img2kvm 命令, 开始自动下载 img2kvm 命令到 ${HOME} 目录 "
			mkdir -p  ${HOME}/
			wget -P  ${HOME} http://dl.everun.top/softwares/utilities/img2kvm/img2kvm
			img2kvmRealPath="${HOME}/img2kvm"
		fi

		${sudoCmd} chmod +x ${img2kvmRealPath}

	fi



	read -p "请输入已上传的群晖引导镜像文件名, 直接回车默认为 synoboot.img :" dsmBootImgFilenameInput
	dsmBootImgFilenameInput=${dsmBootImgFilenameInput:-"synoboot.img"}

	read -p "请输入虚拟机ID, 直接回车默认为101 请输入:" dsmBootImgVMIdInput
	dsmBootImgVMIdInput=${dsmBootImgVMIdInput:-101}

	if [[ -f "/root/${dsmBootImgFilenameInput}" ]]; then
        dsmBootImgFileRealPath="/root/${dsmBootImgFilenameInput}"

	elif [[ -f "/var/lib/vz/template/iso/${dsmBootImgFilenameInput}" ]]; then
        dsmBootImgFileRealPath="/var/lib/vz/template/iso/${dsmBootImgFilenameInput}"

	else
		read -p "请输入已上传的群晖引导镜像的路径, 直接回车默认为${promptTextDefaultDsmBootImgFilePath} : (末尾不要有/)" dsmBootImgFilePathInput
		dsmBootImgFilePathInput=${dsmBootImgFilePathInput:-"${promptTextDefaultDsmBootImgFilePath}"}

		if [[ -f "${dsmBootImgFilePathInput}/${dsmBootImgFilenameInput}" ]]; then
			dsmBootImgFileRealPath="${dsmBootImgFilePathInput}/${dsmBootImgFilenameInput}"
		else
			green " ================================================== "
			red " 没有找到已上传的群晖引导镜像文件 ${dsmBootImgFilePathInput}/${dsmBootImgFilenameInput}"
			green " ================================================== "
			exit
		fi
    fi   


	green " 开始导入群晖引导镜像文件 ${dsmBootImgFileRealPath} "
	green " 引导镜像导入后, 默认储存在名称为local-lvm磁盘, 如果没有local-lvm盘 依次会导入到local盘储存, 也可储存在用户指定的磁盘 "

	isHaveStorageLocalLvm=$(cat /etc/pve/storage.cfg | grep local-lvm) 
	isHaveStorageLocal=$(cat /etc/pve/storage.cfg | grep local) 


	echo
	echo "cat /etc/pve/storage.cfg"
	cat /etc/pve/storage.cfg
	read -p "根据上面已有的磁盘信息, 输入要导入后储存到的磁盘名称, 直接回车默认为local-lvm,  请输入:" dsmBootImgStoragePathInput
	dsmBootImgStoragePathInput=${dsmBootImgStoragePathInput:-"local-lvm"}

	isHaveStorageUserInput=$(cat /etc/pve/storage.cfg | grep ${dsmBootImgStoragePathInput}) 

	if [[ -n "$isHaveStorageUserInput" ]]; then	
		green " 状态显示--系统有 储存盘 ${isHaveStorageUserInput}"

	elif [[ -n "$isHaveStorageLocalLvm" ]]; then	
		green " 状态显示--系统没有 储存盘 ${isHaveStorageUserInput} 使用储存盘 local-lvm 代替"
		dsmBootImgStoragePathInput="local-lvm"

	elif [[ -n "$isHaveStorageLocal" ]]; then	
		green " 状态显示--系统没有 储存盘 local-lvm, 使用储存盘 local 代替"
		dsmBootImgStoragePathInput="local"
	fi



	if [[ -f ${dsmBootImgFileRealPath} ]]; then
		
		dsmBootImgResult=""
		
		if [ -z $1 ]; then
			echo "qm importdisk ${dsmBootImgVMIdInput} ${dsmBootImgFileRealPath} ${dsmBootImgStoragePathInput}"
			dsmBootImgResult=$(qm importdisk ${dsmBootImgVMIdInput} ${dsmBootImgFileRealPath} ${dsmBootImgStoragePathInput})

		else
			echo " ${img2kvmRealPath} ${dsmBootImgFileRealPath} ${dsmBootImgVMIdInput} ${dsmBootImgStoragePathInput}"
			dsmBootImgResult=$(${img2kvmRealPath} ${dsmBootImgFileRealPath} ${dsmBootImgVMIdInput} ${dsmBootImgStoragePathInput})

		fi

		echo "${dsmBootImgResult}"

		isImportStorageSuccess=$(echo ${dsmBootImgResult} | grep "Successfully") 

		if [[ -n "$isImportStorageSuccess" ]]; then	
			green " 成功导入 群晖引导镜像文件! 请运行虚拟机继续安装群晖! "
		else 
			green " ================================================== "
			red " 导入失败 请重新导入群晖引导镜像文件 ${dsmBootImgFileRealPath}"
			red " 导入失败 或尝试用 ${promptTextFailureCommand} 命令重新导入"
			green " ================================================== "
			exit
		fi
	fi
	
}




function genPVEVMDiskPT(){
	green " ================================================== "
	green " 准备使用 qm set 命令 添加直通硬盘 Pass-through hard drive "
	red " 请先在 PVE 上添加好硬盘!"
	red " 请同时在bios 中开启VT-D, 可通过本工具选项1开启"
	green " 可以通过命令 lsblk 或 blkid 查看已挂载的硬盘"
	green " ================================================== "

	echo
	echo "Run Command : lsblk"
	echo
	lsblk
	echo

	green " ================================================== "
	echo
	echo "Run Command : blkid"
	echo
	blkid
	echo


	green " ================================================== "
	green " 请查看列出硬盘的ID.  Run Command : ls -l /dev/disk/by-id/"
	# echo "Run Command : ls -l /dev/disk/by-id/"


	# https://stackoverflow.com/questions/229551/how-to-check-if-a-string-contains-a-substring-in-bash

	COUNTER1=1
	COUNTER2=1

	for HDDfilename in $(ls /dev/disk/by-id/); do
		if [[ $HDDfilename == *"part"* ]]; then
			echo "          -->> 分区${COUNTER2}: $HDDfilename"
			COUNTER2=$[${COUNTER2} +1]
		else 
			echo
			echo "HDD硬盘${COUNTER1} : $HDDfilename"
			HDDArray[${COUNTER1}]="$HDDfilename"
			COUNTER1=$[${COUNTER1} +1]
			COUNTER2=1
		fi
	done

	echo
	# echo ${HDDArray[@]}  

	read -p "根据上面信息输入要选择的硬盘ID 编号, 直接回车默认为1:" dsmHDPTIdInput
	dsmHDPTIdInput=${dsmHDPTIdInput:-1}

	read -p "请输入虚拟机ID, 直接回车默认为101 请输入:" dsmHDPTVMIdInput
	dsmHDPTVMIdInput=${dsmHDPTVMIdInput:-101}

	read -p "请输入要给虚拟机的生成的硬盘设备编号, 直接回车默认为sata2 请输入sata1,sata3类似这种:" dsmHDPTVMHDIdInput
	dsmHDPTVMHDIdInput=${dsmHDPTVMHDIdInput:-sata2}

	green " 准备把硬盘 ${HDDArray[${dsmHDPTIdInput}]} 给虚拟机生成直通设备${dsmHDPTVMHDIdInput}  "

	dsmHDPTResult=""
		
	echo "qm set ${dsmHDPTVMIdInput} -${dsmHDPTVMHDIdInput} /dev/disk/by-id/${HDDArray[${dsmHDPTIdInput}]} "
	dsmHDPTResult=$(qm set ${dsmHDPTVMIdInput} -${dsmHDPTVMHDIdInput} /dev/disk/by-id/${HDDArray[${dsmHDPTIdInput}]})

	echo "${dsmHDPTResult}"

	isImportHDPTStorageSuccess=$(echo ${dsmHDPTResult} | grep "update VM") 

	if [[ -n "$isImportHDPTStorageSuccess" ]]; then	
		green " 成功生成直通设备 ! 请运行虚拟机继续安装群晖! "
	else 
		green " ================================================== "
		red " 导入直通设备失败 请检查设备ID是否正确 /dev/disk/by-id/${HDDArray[${dsmHDPTIdInput}]}"
		green " ================================================== "
		exit
	fi
}








function DSMOpenSSHRoot(){
	green " ================================================== "
	green " 准备开启群晖系统的 root 用户登陆SSH "
	red " 请先在群晖中 “控制面板” -> “终端机和SNMP” 开启“启动SSH功能”,打勾后点击“应用”按钮即可"
	red " 然后通过SSH工具使用admin或其他用户登录群晖系统,在运行此命令"
	green " ================================================== "

	read -p "是否继续操作? 请输入[Y/n]:" isContinueOpeartionInput
	isContinueOpeartionInput=${isContinueOpeartionInput:-Y}

	if [[ $isContinueOpeartionInput == [Yy] ]]; then


		currentUsername=$(whoami)
		echo
		green " 准备设置root用户的密码, 密码不能为空 "
		read -p " 请输入root用户的密码, 默认为123456 :" dsmRootUserPasswordInput
		dsmRootUserPasswordInput=${dsmRootUserPasswordInput:-123456}

		if [[ -z "$dsmRootUserPasswordInput" ]]; then
			green " ================================================== "
			red " 输入的 root 用户的密码为空, 设置root登录失败 !"
			green " ================================================== "
			exit
		else

			echo
			green " 请输入当前用户 ${currentUsername} 的密码: "
					sudo -i -u root sh << EOF

echo " 当前已切换到 \$(whoami) 用户"

synouser --setpw root ${dsmRootUserPasswordInput}
sed -i 's/#\?PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

EOF

			echo
			green " 设置root登录成功, 请用重启群晖后 使用root重新登录SSH"
			green " ================================================== "
			rebootSystem
		fi

	else
		exit
	fi

}

function DSMEditHosts(){
	green " ================================================== "
	green " 准备打开VI 编辑/etc/hosts"
	green " 请用root 用户登录群晖系统的SSH 运行本命令"
	green " ================================================== "

	vi /etc/hosts
}

function DSMFixSNAndMac(){
	green " ================================================== "
	green " 准备开始半洗白群晖 需要准备好SN 序列号和网卡Mac地址"
	green " 请用root 用户登录群晖系统的SSH 运行本命令"
	green " ================================================== "	

	echo
	echo "Run Command : blkid"
	echo
	blkid
	echo

	green " 请根据上面信息 查看已有的硬盘设备, 需要挂载群晖引导盘分区 一般为/dev/sda1"
	green " 如果通过本脚本14 修复过 /dev/synoboot 设备盘, 则为/dev/synoboot1:"

	read -p " 请输入群晖引导盘分区 直接回车默认为/dev/sda1: (末尾不要有/)" dsmDeviceIDInput
	dsmDeviceIDInput=${dsmDeviceIDInput:-"/dev/sda1"}

	if [ -b "/dev/sda1" ]; then
		green "/dev/sda1 is a block device. Mount to /mnt/disk3"
		mkdir -p /mnt/disk3
		mount -o rw "/dev/sda1" /mnt/disk3
	fi

	if [ -b "/dev/synoboot1" ]; then
		# https://xpenology.com/forum/topic/3461-how-to-hide-your-xpenoboot-usb-drive-from-dsm/

		green "/dev/synoboot1 is a block device. Mount to /mnt/disk2"
		mkdir -p /mnt/disk2
		cd /dev
		mount -t vfat "synoboot1" /mnt/disk2
	fi

	if [[ $dsmDeviceIDInput == *"/dev/sda1"* ]]; then
		echo ""
	elif [[ $dsmDeviceIDInput == *"/dev/synoboot1"* ]]; then
		echo ""
	else
		if [ -b "${dsmDeviceIDInput}" ]; then
			echo "${dsmDeviceIDInput} is a block device. . Mount to /mnt/disk1"
			mkdir -p /mnt/disk1
			mount -o rw ${dsmDeviceIDInput} /mnt/disk1
		fi	
	fi


	grubConfigFilePath="/mnt/disk1/grub/grub.cfg"
	if [[ -f "/mnt/disk1/grub/grub.cfg" ]]; then
		grubConfigFilePath="/mnt/disk1/grub/grub.cfg"
		green " 已找到群晖引导分区配置文件 grub.cfg, 位置为 /mnt/disk1/grub/grub.cfg"
	
	elif  [[ -f "/mnt/disk2/grub/grub.cfg" ]]; then
		grubConfigFilePath="/mnt/disk2/grub/grub.cfg"
		green " 已找到群晖引导分区配置文件 grub.cfg, 位置为 /mnt/disk2/grub/grub.cfg"

	elif  [[ -f "/mnt/disk3/grub/grub.cfg" ]]; then
		grubConfigFilePath="/mnt/disk3/grub/grub.cfg"
		green " 已找到群晖引导分区配置文件 grub.cfg, 位置为 /mnt/disk3/grub/grub.cfg"
				
	else
		green " ================================================== "
		red " 没有找到群晖引导分区配置文件 grub.cfg, 修改失败 !"
		green " ================================================== "
		exit		
	fi

    if [[ $1 == "vi" ]] ; then
		echo
		green " ================================================== "
		red " 注意: 编辑引导文件grub.cfg 如果为了隐藏引导盘 修改了 SataPortMap 和 DiskIdxMap 参数后"
		red " 会导致命令行下无法挂载引导分区 !"
		red " 从而无法再次使用本工具编辑该引导文件 grub.cfg !"
		echo
		red " 可以通过其他方法 例如 WinPE 下的 DiskGenius 修改 !"
		red " 或通过PVE 把引导盘sata5 顺序提前到sata1 不隐藏引导盘来修改 !"
		green " ================================================== "
		echo
		promptContinueOpeartion
        vi $grubConfigFilePath

	else

		read -p " 请输入群晖洗白的SN序列号: 直接回车默认为空:" dsmSNInput
		dsmSNInput=${dsmSNInput:-""}

		read -p " 请输入群晖洗白的网卡MAC地址: 直接回车默认为空: (中间不要有:或-)" dsmMACInput
		dsmMACInput=${dsmMACInput:-""}

		if [[ -z "$dsmSNInput" ]]; then
			green " ================================================== "
			red " 输入的群晖洗白的SN序列号为空, 修改失败 请重新运行"
			green " ================================================== "
			exit		
		fi

		if [[ -z "$dsmMACInput" ]]; then
			green " ================================================== "
			red " 输入的群晖洗白的网卡 MAC 地址 为空, 修改失败 请重新运行"
			green " ================================================== "
			exit		
		fi

		${sudoCmd} sed -i "s/set sn=.*/set sn=${dsmSNInput}/g" ${grubConfigFilePath}
		${sudoCmd} sed -i "s/set mac1=.*/set mac1=${dsmMACInput}/g" ${grubConfigFilePath}

		echo
		green " ================================================== "
		green " 群晖洗白成功, 请重启群晖!"
		green " ================================================== "

		rebootSystem

    fi
}


function DSMFixCPUInfo(){
	green " ================================================== "
	green " 准备开始修复 群晖系统信息中心 CPU型号显示错误"
	green " 请用root 用户登录群晖系统的SSH 运行本命令"
	echo
	green " 可通过群晖网页 共享文件夹上传 ch_cpuinfo 工具到共享目录/tools下, 实际路径一般为/volume1/tools/ch_cpuinfo "
	green " 通过群晖网页上传 ch_cpuinfo 成功后, 右键点击 ch_cpuinfo 文件“属性” -> “位置” 可查看到实际的储存路径, 一般为/volume1/tools/ch_cpuinfo "
	echo
	green " 或者通过SSH WinSCP等软件上传 ch_cpuinfo 工具到当前目录下或/root目录下 "
	echo
	green " 如果用户没有上传会自动从网上下载该命令 "
	green " ================================================== "


	if [[ -f "/root/ch_cpuinfo" ]]; then
		cpuInfoChangeRealPath="/root/ch_cpuinfo"

	elif [[ -f "${HOME}/download/ch_cpuinfo" ]]; then
		cpuInfoChangeRealPath="${HOME}/download/ch_cpuinfo"

	elif [[ -f "./ch_cpuinfo" ]]; then
		cpuInfoChangeRealPath="./ch_cpuinfo"

	elif [[ -f "/volume1/tools/ch_cpuinfo" ]]; then
		cpuInfoChangeRealPath="/volume1/tools/ch_cpuinfo"	

	else 
		echo
		green " 请输入已上传 ch_cpuinfo 的路径: 直接回车默认为/volume1/tools/ch_cpuinfo "
		green " 如果实际没有上传会自动从网上下载 ch_cpuinfo 命令, 直接回车即可 "
		echo
		read -p " 请输入已上传 ch_cpuinfo 的路径: (末尾不要有/)" dsmChangeCPUInfoPathInput
		dsmChangeCPUInfoPathInput=${dsmChangeCPUInfoPathInput:-"/volume1/tools/ch_cpuinfo"}

		if [[ -f "${dsmChangeCPUInfoPathInput}" ]]; then
			cpuInfoChangeRealPath="${dsmChangeCPUInfoPathInput}"
		else
			green " 没有找到 ch_cpuinfo 命令, 开始自动下载 ch_cpuinfo 命令到 ${HOME}/download 目录 "
			mkdir -p ${HOME}/download
			wget -P ${HOME}/download https://github.com/FOXBI/ch_cpuinfo/raw/master/ch_cpuinfo_2.2.1/ch_cpuinfo.tar

			tar xvf ${HOME}/download/ch_cpuinfo.tar
			cpuInfoChangeRealPath="${HOME}/download/ch_cpuinfo"
		fi
	fi

	${sudoCmd} chmod +x ${cpuInfoChangeRealPath}
	echo
	green " 随后的英文提示信息为: "
	echo
	green " 选择1 然后在输入y 修复CPU信息显示 "
	echo
	green " 选择2 恢复原始CPU信息后 再次修复CPU信息显示"
	echo
	green " 选择3 恢复到原始CPU信息"
	echo
	green " 请根据随后的英文提示 选择1-3: "
	echo
	promptContinueOpeartion
	${cpuInfoChangeRealPath}

	green " 修复CPU信息成功, 请重启群晖后在群晖“控制面板”->“信息中心” 查看"
	green " ================================================== "

	rebootSystem
}


function DSMFixDevSynoboot(){
	green " ================================================== "
	green " 准备开始修复 群晖 DSM 6.2.3 找不到 /dev/synoboot 引导盘问题 "
	red " 此问题在虚拟机 (例如PVE 或 ESXi) 安装 6.2.3 就会出现, 实体机安装也偶尔出现 "
	red " 由于/dev/synoboot 引导盘缺失, 导致 6.2.3-25426 Update 3 升级失败"
	green " ================================================== "

	# https://archive.synology.com/download/Os/DSM
	# https://xpenology.com/forum/topic/28183-running-623-on-esxi-synoboot-is-broken-fix-available/

	DSMStatusIsSynobootText=$(ls /dev/synoboot* | grep "synoboot")

	if [[ -z "$DSMStatusIsSynobootText" ]]; then
		DSMStatusSynoboot="no"
		green " 群晖状态显示--当前是否有 /dev/synoboot 引导盘: $DSMStatusSynoboot "
	else
        DSMStatusSynoboot="yes"
		green " 群晖状态显示--当前是否有 /dev/synoboot 引导盘: $DSMStatusSynoboot 无需修复" 
		green " ls /dev/synoboot* "
		echo "$DSMStatusIsSynobootText"
		echo
    fi
	
	if [[ -z "$DSMStatusIsSynobootText" ]]; then
		green " 准备开始修复 /dev/synoboot 引导盘 缺失问题 "

		dsmFixSynobootPathInput="${HOME}/FixSynoboot.sh"
		if [[ -f "${dsmFixSynobootPathInput}" ]]; then
			dsmFixSynobootPathInput="${dsmFixSynobootPathInput}"
			green " 本地已存在 FixSynoboot.sh 修复脚本, 位置在 ${dsmFixSynobootPathInput} "
		else
			green " 没有找到 FixSynoboot.sh, 开始自动下载 FixSynoboot.sh 脚本到 ${HOME} 目录 "
			mkdir -p  ${HOME}

			# https://github.com/vlombardino/Proxmox/raw/master/Xpenology/files/FixSynoboot.sh
			wget -P ${HOME} https://github.com/jinwyp/one_click_script/raw/master/dsm/FixSynoboot.sh
		fi

		
		${sudoCmd} chmod +x ${dsmFixSynobootPathInput}
		${sudoCmd} cp ${dsmFixSynobootPathInput} /usr/local/etc/rc.d
		${sudoCmd} chmod 0755 /usr/local/etc/rc.d/FixSynoboot.sh

		echo
		green " 修复成功! 请重启群晖后, 在群晖“控制面板”->“更新和还原” 即可正常更新!"
		green " ================================================== "
    fi

}


function DSMFixNvmeSSD(){
	green " ================================================== "
	green " 准备开始修复 群晖 识别 Nvme 固态硬盘问题"
	green " 请用root 用户登录群晖系统的SSH 运行本命令"
	red " 该补丁如果插两块NVMe SSD会出现问题, 请谨慎使用"
	echo
	green " 可通过群晖网页 共享文件夹上传 libsynonvme.so.1 到共享目录/tools下, 实际路径一般为/volume1/tools/libsynonvme.so.1 "
	green " 通过群晖网页上传 libsynonvme.so.1 成功后, 右键点击 libsynonvme.so.1 文件“属性” -> “位置” 可查看到实际的储存路径, 一般为/volume1/tools/libsynonvme.so.1 "
	echo
	green " 或者通过SSH WinSCP等软件上传 libsynonvme.so.1 到当前目录下或/root目录下 "
	echo
	green " 如果用户没有上传会自动从网上下载 libsynonvme.so.1 文件 "
	green " ================================================== "


	if [[ -f "/root/libsynonvme.so.1" ]]; then
		nvmeSSDPatchRealPath="/root/libsynonvme.so.1"

	elif [[ -f "./libsynonvme.so.1" ]]; then
		nvmeSSDPatchRealPath="./libsynonvme.so.1"

	elif [[ -f "/volume1/tools/libsynonvme.so.1" ]]; then
		nvmeSSDPatchRealPath="/volume1/tools/libsynonvme.so.1"	

	else 
		echo
		green " 请输入已上传 libsynonvme.so.1 的路径: 直接回车默认为/volume1/tools/libsynonvme.so.1 "
		green " 如果实际没有上传会自动从网上下载 libsynonvme.so.1, 直接回车即可 "
		echo
		read -p " 请输入已上传 libsynonvme.so.1 的路径: (末尾不要有/)" dsmNvmeSSDPatchPathInput
		dsmNvmeSSDPatchPathInput=${dsmNvmeSSDPatchPathInput:-"/volume1/tools/libsynonvme.so.1"}

		if [[ -f "${dsmNvmeSSDPatchPathInput}" ]]; then
			nvmeSSDPatchRealPath="${dsmNvmeSSDPatchPathInput}"
		else
			green " 没有找到 libsynonvme.so.1 , 开始自动下载 libsynonvme.so.1 到 ${HOME} 目录 "
			mkdir -p  ${HOME}
			wget -P  ${HOME} https://github.com/jinwyp/one_click_script/raw/master/dsm/libsynonvme.so.1

			nvmeSSDPatchRealPath="${HOME}/libsynonvme.so.1"
		fi
	fi


	echo

	if [[ -f "/usr/lib64/libsynonvme.so.1" ]]; then
		green " 原系统已存在 /usr/lib64/libsynonvme.so.1, 备份到 /usr/lib64/libsynonvme.so.1.bak "
		${sudoCmd}  mv -f /usr/lib64/libsynonvme.so.1 /usr/lib64/libsynonvme.so.1.bak
	fi
	${sudoCmd} cp ${nvmeSSDPatchRealPath} /usr/lib64	
	echo
	green " 修复识别 Nvme 固态硬盘成功, 请重启群晖!"
	green " ================================================== "

	rebootSystem

}


function DSMCheckVideoCardPassThrough(){
	green " ================================================== "
	green " 检测群晖系统中 是否有显卡或显卡直通是否开启成功"
	green " 请先在 PVE 控制台 添加PCI 显卡设备到群晖虚拟机"
	green " 请用root 用户登录群晖系统的SSH 运行本命令"
	red " Video station 软解检测 需要至少播放一次转码, 即在播放时选择[播放质量]为非[原始]例如选择[中]画质播放一次"
	green " ================================================== "

	DSMStatusVideoCardText=$(ls /dev/dri | grep "render")

	if [[ $DSMStatusVideoCardText == *"renderD128"* ]]; then
		DSMStatusVideoCard="yes"
		echo "ls /dev/dri"
		ls /dev/dri
    else
		DSMStatusVideoCard="no"
    fi
	

	DSMStatusVideoCardSoftDecodeText=$(cat /usr/syno/etc/codec/activation.conf | grep "\"success\":true")

	if [[ $DSMStatusVideoCardSoftDecodeText == *"true"* ]]; then
		DSMStatusVideoCardSoftDecode="yes"
		echo
		echo "cat /usr/syno/etc/codec/activation.conf"
		cat /usr/syno/etc/codec/activation.conf
    else
		DSMStatusVideoCardSoftDecode="no"
    fi


	DSMStatusVideoCardHardwareDecodeText=$(cat /sys/kernel/debug/dri/0/i915_frequency_info | grep "HW control enabled")

	if [[ $DSMStatusVideoCardHardwareDecodeText == *"yes"* ]]; then
		
		DSMStatusVideoCardHardwareDecode="yes"
		echo
		echo "cat /sys/kernel/debug/dri/0/i915_frequency_info"
		cat /sys/kernel/debug/dri/0/i915_frequency_info
    else
        DSMStatusVideoCardHardwareDecode="no"
    fi


	echo
	green " 群晖状态显示--当前显卡直通是否成功: $DSMStatusVideoCard "
	green " 群晖状态显示--Video station 软解是否支持: $DSMStatusVideoCardSoftDecode, 如不支持请洗白序列号 "
	green " 群晖状态显示--Video station 硬解是否支持: $DSMStatusVideoCardHardwareDecode, 如不支持请开启显卡直通 "
	green " ================================================== "
}























































function getGithubLatestReleaseVersion(){
    # https://github.com/p4gefau1t/trojan-go/issues/63
    wget --no-check-certificate -qO- https://api.github.com/repos/$1/tags | grep 'name' | cut -d\" -f4 | head -1 | cut -b 2-
}


function checkInvalidIp(){ 
	if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		green "输入的IP $1 地址格式正确, 继续安装..." 
		false 
	else
		red "输入的IP $1 地址格式不正确. 请重新输入" 
		inputFrpServerPort $2
	fi
}

function checkPortInUse(){ 

	if [[ $1 -gt 1 && $1 -le 65535 ]]; then
		
		netstat -tulpn | grep [0-9]:$1 -q ; 
		if [ $? -eq 1 ]; then 
			green "输入的端口号 $1 没有被占用, 继续安装..." 
			false 
		else 
			red "输入的端口号 $1 已被占用! 请检查端口是否已被占用, 然后重新运行脚本安装" 
			true
			exit
		fi
	else
		red "输入的端口号错误! 必须是[1-65535]. 请重新输入" 
		inputFrpServerPort $2
	fi
}


function inputFrpServerPort(){ 
	echo ""
	if [[ $1 == "text_FRP_bind_port" ]]; then
		read -p "请输入 Frps 服务器 通讯端口, 必须是纯数字 范围[1-65535], 默认7000. 请输入纯数字:" FRP_bind_port
		FRP_bind_port=${FRP_bind_port:-7000}
		checkPortInUse "${FRP_bind_port}" $1 
	fi

	if [[ $1 == "text_FRP_vhost_http_port" ]]; then
		read -p "请输入 Frps 服务器 Web Http 监听端口, 必须是纯数字 范围[1-65535], 默认80. 请输入纯数字:" FRP_vhost_http_port
		FRP_vhost_http_port=${FRP_vhost_http_port:-80}
		checkPortInUse "${FRP_vhost_http_port}" $1 
	fi

	if [[ $1 == "text_FRP_vhost_https_port" ]]; then
		read -p "请输入 Frps 服务器 Web Https 监听端口, 必须是纯数字 范围[1-65535], 默认443. 请输入纯数字:" FRP_vhost_https_port
		FRP_vhost_https_port=${FRP_vhost_https_port:-443}
		checkPortInUse "${FRP_vhost_https_port}" $1 
	fi

	if [[ $1 == "text_FRP_bind_udp_port" ]]; then
		FRP_bind_udp_port=7001
		let FRP_bind_udp_port=FRP_bind_port+1
		if [ $FRP_bind_udp_port -gt 65535 ]; then
			FRP_bind_udp_port=7001
		fi
		checkPortInUse "${FRP_bind_udp_port}" $1 
	fi


	if [[ $1 == "text_FRP_dashboard_port" ]]; then
		read -p "请输入 Frps 服务器 管理界面端口, 必须是纯数字 范围[1-65535], 默认7500. 请输入纯数字:" FRP_dashboard_port
		FRP_dashboard_port=${FRP_dashboard_port:-7500}
		checkPortInUse "${FRP_dashboard_port}" $1 
	fi

	if [[ $1 == "text_FRP_dashboard_user" ]]; then
		read -p "请输入 Frps 服务器 登录管理界面的用户名, 默认为 admin, 请输入用户名:" FRP_dashboard_user 
		FRP_dashboard_user=${FRP_dashboard_user:-admin}
	fi

	if [[ $1 == "text_FRP_dashboard_pwd" ]]; then
		read -p "请输入 Frps 服务器 登录管理界面的 ${FRP_dashboard_user} 用户的密码, 默认为 admin, 请输入密码:" FRP_dashboard_pwd
		FRP_dashboard_pwd=${FRP_dashboard_pwd:-admin}
	fi

	if [[ $1 == "text_FRP_token" ]]; then
		tempFrpToken=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
		read -p "请输入 Frps 服务器与客户端通讯的 token 密钥, 默认为8位随机数. 请输入密钥:" FRP_token
		FRP_token=${FRP_token:-$tempFrpToken}
	fi




	if [[ $1 == "text_FRP_server_addr" ]]; then
		read -p "请输入要连接的 Frps 服务器IP地址, 直接回车默认1.1.1.1, 该项为必填项 请输入:" FRP_server_addr
		FRP_server_addr=${FRP_server_addr:-1.1.1.1}
		checkInvalidIp "${FRP_server_addr}" $1 
	fi

	if [[ $1 == "text_FRP_server_port" ]]; then
		read -p "请输入要连接的 Frps 服务器端口, 必须是纯数字 范围[1-65535], 默认7000. 请输入纯数字:" FRP_server_port
		FRP_server_port=${FRP_server_port:-7000}
	fi

	if [[ $1 == "text_FRP_token_fprc" ]]; then
		read -p "请输入与 Frps 服务器一致的 token 密钥, 默认为123456. 该项为必填项. 请输入密钥:" FRP_token_fprc
		FRP_token_fprc=${FRP_token_fprc:-123456}
	fi

	if [[ $1 == "text_FRP_protocol" ]]; then
		read -p "是否开启kcp 用来降低延迟, 默认为tcp 不开启. 请输入[y/N]:" FRP_protocol_input
		FRP_protocol_input=${FRP_protocol_input:-n}

		if [[ ${FRP_protocol_input} == [Yy] ]]; then
			FRP_protocol="kcp"
		else 
			FRP_protocol="tcp"
		fi
	fi

	if [[ $1 == "text_FRP_admin_port" ]]; then
		read -p "请输入 Frpc 客户端 管理界面端口, 必须是纯数字 范围[1-65535], 默认为7400. 请输入纯数字:" FRP_admin_port
		FRP_admin_port=${FRP_admin_port:-7400}
		checkPortInUse "${FRP_admin_port}" $1 
	fi

	if [[ $1 == "text_FRP_admin_user" ]]; then
		read -p "请输入 Frpc 客户端 登录管理界面的用户名, 默认为 admin. 请输入用户名:" FRP_admin_user 
		FRP_admin_user=${FRP_admin_user:-admin}
	fi

	if [[ $1 == "text_FRP_admin_pwd" ]]; then
		read -p "请输入 Frpc 客户端 登录管理界面的 ${FRP_admin_user} 用户的密码, 默认为 admin. 请输入密码:" FRP_admin_pwd
		FRP_admin_pwd=${FRP_admin_pwd:-admin}
	fi

}


# https://github.com/stilleshan/frpc/blob/master/frpc_linux_install.sh

configFrpPath="${HOME}/frp"
configFrpPathBin="/usr/bin"
configFrpDSMPathBin="/var/packages/gofrpc/target/bin/arch"
configFrpDSMFilename="frpc_x64"
configFrpPathIni="/etc/frp"
configFrpLogFile="${HOME}/frp/frpc.log"

versionFRP="0.36.2"
downloadFilenameFRP="frp_${versionFRP}_linux_amd64.tar.gz"
downloadFilenameFRPFolder="frp_${versionFRP}_linux_amd64"

installFrpType="frpc"
installFrpPromptText="Frp 的 linux 客户端frpc"



function getVersionFRPFilename(){
	versionFRP=$(getGithubLatestReleaseVersion "fatedier/frp")

	# https://github.com/fatedier/frp/releases/download/v0.36.2/frp_0.36.2_linux_arm.tar.gz
	# https://github.com/fatedier/frp/releases/download/v0.36.2/frp_0.36.2_linux_arm64.tar.gz

	if [[ ${osArchitecture} == "arm64" ]] ; then
		downloadFilenameFRP="frp_${versionFRP}_linux_arm64.tar.gz"
		downloadFilenameFRPFolder="frp_${versionFRP}_linux_arm64"
		configFrpDSMFilename="frpc_arm64"
	elif [[ ${osArchitecture} == "arm" ]] ; then
		downloadFilenameFRP="frp_${versionFRP}_linux_arm.tar.gz"
		downloadFilenameFRPFolder="frp_${versionFRP}_linux_arm"
		configFrpDSMFilename="frpc_arm"
	else
		downloadFilenameFRP="frp_${versionFRP}_linux_amd64.tar.gz"
		downloadFilenameFRPFolder="frp_${versionFRP}_linux_amd64"
	fi
}

function installFRP(){

	if [[ $1 == "frps" ]] ; then
		installFrpType="frps"
		installFrpPromptText="Frp 的 linux 服务器端frps"

		configFrpLogFile="${HOME}/frp/frps.log"

	else
	    if [[ ${osRelease} == "dsm" ]] ; then
			green " =================================================="
			echo
			red "    如果要在群晖系统中安装 ${installFrpPromptText}, 建议直接通过frpc的SPK包文件安装, 而不要继续安装命令行版本的frpc客户端 "
			echo
			red "    frpc的SPK包文件 下载地址:  https://github.com/jinwyp/one_click_script/raw/master/dsm/frpc-noarch_v0.35.0.spk "
			echo
			red "    安装SPK包方法: 群晖系统中 打开 ‘套件中心’, 然后点击右上角的 ‘手动安装’, 上传安装上面下载的Frpc的SPK文件 即可 "
			echo
			green "    是否继续安装命令行版本的 ${installFrpPromptText} ?"
			echo
			promptContinueOpeartion
		fi	
	fi

   	if [ -f ${configFrpPathBin}/${installFrpType} ]; then
        green " =================================================="
   	 	red "    已安装过 ${installFrpPromptText}, 如需继续安装, 请卸载后重新安装 "
    	green " =================================================="
        exit
    fi

	disableSelinux

	getVersionFRPFilename
	

	FRP_SERVER_IP=$(wget -qO- ip.clang.cn | sed -r 's/\r//')
	FRP_Client_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

	green " =================================================="
    green "   开始安装 ${installFrpPromptText} ${versionFRP} "
	if [[ $1 == "frps" ]] ; then
		echo -e "   当前服务器IP: ${COLOR_GREEN} ${FRP_SERVER_IP} ${COLOR_END}"
	else
		echo -e "   当前主机IP (FRP 客户端): ${COLOR_GREEN} ${FRP_Client_IP} ${COLOR_END}"
	fi	
    
    green " =================================================="
	echo ""

	if [[ $1 == "frps" ]] ; then

		inputFrpServerPort "text_FRP_bind_port"

		inputFrpServerPort "text_FRP_token"

		inputFrpServerPort "text_FRP_bind_udp_port"

		inputFrpServerPort "text_FRP_vhost_http_port"
		inputFrpServerPort "text_FRP_vhost_https_port"

		inputFrpServerPort "text_FRP_dashboard_port"
		inputFrpServerPort "text_FRP_dashboard_user"
		inputFrpServerPort "text_FRP_dashboard_pwd"

	else
		inputFrpServerPort "text_FRP_server_addr"
		inputFrpServerPort "text_FRP_server_port"
		inputFrpServerPort "text_FRP_token_fprc"
		inputFrpServerPort "text_FRP_protocol"

		inputFrpServerPort "text_FRP_admin_port"
		inputFrpServerPort "text_FRP_admin_user"
		inputFrpServerPort "text_FRP_admin_pwd"

	fi


	mkdir -p ${configFrpPath} 
	mkdir -p ${configFrpPathBin} 
	mkdir -p ${configFrpPathIni} 

	cd ${configFrpPath} 

	# 下载并移动frp文件
	# https://github.com/fatedier/frp/releases/download/v0.36.2/frp_0.36.2_linux_amd64.tar.gz

	wget -P ${configFrpPath} https://github.com/fatedier/frp/releases/download/v${versionFRP}/${downloadFilenameFRP}
	tar -zxf ${configFrpPath}/${downloadFilenameFRP} -C ${configFrpPath}
	
	cd ${downloadFilenameFRPFolder}


	if [[ $1 == "frps" ]] ; then

		# 配置 frps.ini
	    cat > ${configFrpPathIni}/${installFrpType}.ini <<-EOF
[common]
bind_port = ${FRP_bind_port}
bind_udp_port = ${FRP_bind_udp_port}
kcp_bind_port = ${FRP_bind_port}

token = ${FRP_token}

vhost_http_port = ${FRP_vhost_http_port}
vhost_https_port = ${FRP_vhost_https_port}


dashboard_port = ${FRP_dashboard_port}
dashboard_user = ${FRP_dashboard_user}
dashboard_pwd = ${FRP_dashboard_pwd}

log_file = ${configFrpLogFile}
log_level = info
log_max_days = 7

max_pool_count = 20


EOF

	else

		# 配置 frpc.ini
	    cat > ${configFrpPathIni}/${installFrpType}.ini <<-EOF
[common]
server_addr = ${FRP_server_addr}
server_port = ${FRP_server_port}
protocol = ${FRP_protocol}

token = ${FRP_token_fprc}

log_file = ${configFrpLogFile}
log_level = info
log_max_days = 7


admin_port = ${FRP_admin_port}
admin_user = ${FRP_admin_user}
admin_pwd = ${FRP_admin_pwd}


# 请修改下面的配置信息 不需要的可以删除
[ssh]
type = tcp
local_ip = ${FRP_Client_IP}
local_port = 22
remote_port = 10022

[dns]
type = udp
local_ip = ${FRP_Client_IP}
local_port = 53
remote_port = 6000


# http 网站 本地运行在80端口  
[web-xxxx1]
type = http
local_ip = ${FRP_Client_IP}
local_port = 80
custom_domains = www.example.com


# https 网站 本地运行在443端口  
[web-xxxx2]
type = https
local_ip = ${FRP_Client_IP}
local_port = 443
custom_domains = www.example2.com


# 群晖nas 配置 远程访问群晖管理界面
[nas_dsm]
type = tcp
local_ip = ${FRP_Client_IP}
local_port = 5000
remote_port = 5000


# 群晖nas 配置 远程访问 qbittorrent 管理界面
[nas_qbittorrent]
type = tcp
local_ip = ${FRP_Client_IP}
local_port = 8085
remote_port = 8085




EOF

	fi

	# 增加启动脚本
	cat > ${osSystemMdPath}${installFrpType}.service <<-EOF
[Unit]
Description=Frp Server Service
After=network.target

[Service]
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=${configFrpPathBin}/${installFrpType} -c ${configFrpPathIni}/${installFrpType}.ini

[Install]
WantedBy=multi-user.target

EOF


	${sudoCmd} chown root:nobody ${configFrpPath}/${downloadFilenameFRPFolder}/frps
	${sudoCmd} chown root:nobody ${configFrpPath}/${downloadFilenameFRPFolder}/frpc
	${sudoCmd} chown root:nobody ${configFrpPathIni}/${installFrpType}.ini

	${sudoCmd} chmod +rx ${configFrpPath}/${downloadFilenameFRPFolder}/frps
	${sudoCmd} chmod +rx ${configFrpPath}/${downloadFilenameFRPFolder}/frpc
	${sudoCmd} chmod +rx ${configFrpPathIni}/${installFrpType}.ini

	${sudoCmd} chcon -t bin_t ${configFrpPath}/${downloadFilenameFRPFolder}/frps
	${sudoCmd} chcon -t bin_t ${configFrpPath}/${downloadFilenameFRPFolder}/frpc
	${sudoCmd} chcon -t etc_t ${configFrpPathIni}/${installFrpType}.ini



	mv ${configFrpPath}/${downloadFilenameFRPFolder}/frpc ${configFrpPathBin}
	mv ${configFrpPath}/${downloadFilenameFRPFolder}/frps ${configFrpPathBin}

	rm -rf ${configFrpPath}/${downloadFilenameFRPFolder}
	${sudoCmd} chmod +x ${osSystemMdPath}${installFrpType}.service
	${sudoCmd} systemctl daemon-reload
	${sudoCmd} systemctl enable ${installFrpType}.service 
	${sudoCmd} systemctl start ${installFrpType}.service
	${sudoCmd} systemctl status ${installFrpType}.service 

	echo
	green "======================================================================"
	green "    ${installFrpPromptText} ${versionFRP} 安装成功 !"
	green "    ${installFrpPromptText} 可执行文件路径 ${configFrpPathBin}/${installFrpType}"
	green "    ${installFrpPromptText} 配置路径 ${configFrpPathIni}/${installFrpType}.ini "
	green "    ${installFrpPromptText} 访问日志 ${configFrpLogFile} 或运行 journalctl -n 50 -u ${installFrpType}.service 查看 !"
	green "    ${installFrpPromptText} 停止命令: systemctl stop ${installFrpType}  启动命令: systemctl start ${installFrpType} "
	green "    ${installFrpPromptText} 重启命令: systemctl restart ${installFrpType}"
	green "======================================================================"
	echo

	if [[ $1 == "frps" ]] ; then

		green "    ${installFrpPromptText} 管理后台地址 http://${FRP_SERVER_IP}:${FRP_dashboard_port}"	
		echo
		green "    ${installFrpPromptText} 配置如下: "
		green "    bind_udp_port = ${FRP_bind_port} "
		green "    token = ${FRP_token} "
		green "    vhost_http_port = ${FRP_vhost_http_port} "
		green "    vhost_https_port = ${FRP_vhost_https_port} "
		green "    dashboard_port = ${FRP_dashboard_port} "
		green "    dashboard_user = ${FRP_dashboard_user} "
		green "    dashboard_pwd = ${FRP_dashboard_pwd} "
		green "    log_file = ${configFrpLogFile} "

	else

		green "    ${installFrpPromptText} 管理后台地址 http://${FRP_Client_IP}:${FRP_admin_port}"	
		echo
		green "    ${installFrpPromptText} 配置如下:  "
		green "    server_addr = ${FRP_server_addr} "
		green "    server_port = ${FRP_server_port} "
		green "    protocol = ${protocol} "
		green "    token = ${FRP_token_fprc} "
		green "    admin_port = ${FRP_admin_port} "
		green "    admin_user = ${FRP_admin_user} "
		green "    admin_pwd = ${FRP_admin_pwd} "
		green "    log_file = ${configFrpLogFile} "
		echo
		red "    请务必自行修改配置后 重启frpc生效 "

	fi

	echo
	green "======================================================================"


	# https://stackoverflow.com/questions/9381463/how-to-create-a-file-in-linux-from-terminal-window

	if [[ $1 == "frps" ]] ; then

    	cat > ${configFrpPath}/frp_readme.txt <<-EOF

${installFrpPromptText} ${versionFRP} 安装成功
${installFrpPromptText} 可执行文件路径 ${configFrpPathBin}/${installFrpType}
${installFrpPromptText} 配置路径 ${configFrpPathIni}/${installFrpType}.ini 

${installFrpPromptText} 访问日志 ${configFrpLogFile} 或运行 journalctl -n 50 -u ${installFrpType}.service 查看

${installFrpPromptText} 停止命令: systemctl stop ${installFrpType}  
${installFrpPromptText} 启动命令: systemctl start ${installFrpType}
${installFrpPromptText} 重启命令: systemctl restart ${installFrpType}

${installFrpPromptText} 管理后台地址 http://${FRP_SERVER_IP}:${FRP_dashboard_port}

${installFrpPromptText} 服务器端 配置如下:

[common]
bind_port = ${FRP_bind_port}
bind_udp_port = ${FRP_bind_udp_port}
kcp_bind_port = ${FRP_bind_port}

token: ${FRP_token}

vhost_http_port = ${FRP_vhost_http_port}
vhost_https_port = ${FRP_vhost_https_port}

dashboard_port = ${FRP_dashboard_port}
dashboard_user = ${FRP_dashboard_user}
dashboard_pwd = ${FRP_dashboard_pwd}

log_file = ${configFrpLogFile}
log_level = info
log_max_days = 7

max_pool_count = 20

EOF

	else
		cat > ${configFrpPath}/frp_readme.txt <<-EOF
	
${installFrpPromptText} ${versionFRP} 安装成功
${installFrpPromptText} 可执行文件路径 ${configFrpPathBin}/${installFrpType}
${installFrpPromptText} 配置路径 ${configFrpPathIni}/${installFrpType}.ini 

${installFrpPromptText} 访问日志 ${configFrpLogFile} 或运行 journalctl -n 50 -u ${installFrpType}.service 查看

${installFrpPromptText} 停止命令: systemctl stop ${installFrpType}  
${installFrpPromptText} 启动命令: systemctl start ${installFrpType}
${installFrpPromptText} 重启命令: systemctl restart ${installFrpType}

${installFrpPromptText} 管理后台地址 http://${FRP_Client_IP}:${FRP_admin_port}

${installFrpPromptText} 客户端 配置如下 请自行修改后 重启frpc生效:

[common]
server_addr = ${FRP_server_addr}
server_port = ${FRP_server_port}
protocol = ${FRP_protocol}

token = ${FRP_token_fprc}

log_file = ${configFrpLogFile}
log_level = info
log_max_days = 7

admin_port = ${FRP_admin_port}
admin_user = ${FRP_admin_user}
admin_pwd = ${FRP_admin_pwd}

EOF
	fi

}


function checkFRPInstalledStatus(){
   	if [ -f ${osSystemMdPath}frps.service ]; then
		installFrpType="frps"
		installFrpPromptText="Frp 的 linux 服务器端frps"

	elif [ -f ${osSystemMdPath}frpc.service ]; then
		echo ""
	elif [ -f ${configFrpDSMPathBin}/${configFrpDSMFilename} ]; then
		echo ""
	elif [ -f ${configFrpDSMPathBin}/frpc_arm64 ]; then
		echo ""
	else
		echo ""
		red " 当前系统中 没有安装 FRP ，请检查 ! "	
		echo ""
		exit 255
	fi
}



function removeFRP(){
	checkFRPInstalledStatus

    ${sudoCmd} systemctl stop ${installFrpType}.service
    ${sudoCmd} systemctl disable ${installFrpType}.service

    green " ================================================== "
    red " 准备卸载已安装的 ${installFrpPromptText}"
    green " ================================================== "

    rm -rf ${configFrpPath}
    rm -f ${osSystemMdPath}${installFrpType}.service
    rm -f ${configFrpPathBin}/frps
    rm -f ${configFrpPathBin}/frpc
    rm -f ${configFrpPathIni}/${installFrpType}.ini

    green " ================================================== "
    green "  ${installFrpPromptText} 已成功卸载 !"
    green " ================================================== "
}


function upgradeFRP(){
   	checkFRPInstalledStatus
	getVersionFRPFilename

   	if [ -f ${configFrpPath}/${downloadFilenameFRP} ]; then
		green " =================================================="
		red "    当前 ${installFrpPromptText} 已是最新版本 ${versionFRP}, 无需升级 "
		green " =================================================="
		exit
	fi

	green " =================================================="
    green "    开始升级 ${installFrpPromptText} ${versionFRP} "
    green " =================================================="

	if [ "$1" != "dsmspk" ] ; then
		${sudoCmd} systemctl stop ${installFrpType}.service
	fi
	
	
	mkdir -p ${configFrpPath} 
	cd ${configFrpPath} 

	# 下载并移动frpc文件
	# https://github.com/fatedier/frp/releases/download/v0.36.2/frp_0.36.2_linux_amd64.tar.gz

	wget -P ${configFrpPath} https://github.com/fatedier/frp/releases/download/v${versionFRP}/${downloadFilenameFRP}
	tar -zxf ${configFrpPath}/${downloadFilenameFRP} -C ${configFrpPath}
	
	cd ${downloadFilenameFRPFolder}

	${sudoCmd} chown root:nobody ${configFrpPath}/${downloadFilenameFRPFolder}/frps
	${sudoCmd} chown root:nobody ${configFrpPath}/${downloadFilenameFRPFolder}/frpc

	${sudoCmd} chmod 777 ${configFrpPath}/${downloadFilenameFRPFolder}/frps
	${sudoCmd} chmod 777 ${configFrpPath}/${downloadFilenameFRPFolder}/frpc


	if [[ $1 == "dsmspk" ]] ; then
		if [[ ${osRelease} == "dsm" ]] ; then
			green " ================================================== "
			green "     群晖系统中 开始升级通过SPK安装的 frpc 客户端"
			echo

			${sudoCmd} chown ufrpc:gofrpc ${configFrpPath}/${downloadFilenameFRPFolder}/frps
			${sudoCmd} chown ufrpc:gofrpc ${configFrpPath}/${downloadFilenameFRPFolder}/frpc

			mv -f ${configFrpPath}/${downloadFilenameFRPFolder}/frpc ${configFrpDSMPathBin}/${configFrpDSMFilename}
		else
			red "当前系统不是群晖系统, 升级失败! "
			exit 1
		fi
	else
		mv -f ${configFrpPath}/${downloadFilenameFRPFolder}/frpc ${configFrpPathBin}
		mv -f ${configFrpPath}/${downloadFilenameFRPFolder}/frps ${configFrpPathBin}

		${sudoCmd} systemctl start ${installFrpType}.service
	fi

	rm -rf ${configFrpPath}/${downloadFilenameFRPFolder}


    green " ================================================== "
    green "     ${installFrpPromptText} 升级成功 Version: ${versionFRP} !"
    green " ================================================== "

}

function systemRunFRP(){
	checkFRPInstalledStatus

	${sudoCmd} systemctl $1 ${installFrpType}.service

    green " ================================================== "
	echo " systemctl $1 ${installFrpType}.service"
    green "     ${installFrpPromptText} $1 运行成功 !"
    green " ================================================== "
}

function checkLogFRP(){
   	checkFRPInstalledStatus

	if [[ $1 == "ini" ]] ; then
		echo
		cat ${configFrpPath}/frp_readme.txt
		echo
		# cat ${configFrpPathIni}/${installFrpType}.ini

	elif [[ $1 == "edit" ]] ; then
		export LC_ALL=
		vi ${configFrpPathIni}/${installFrpType}.ini
	else
		echo ""
		green " 查看日志操作说明"
		echo ""
		red " 退出查看日志 请按 Ctrl+C 后, 再按 q 键" 
		echo ""
		red " 按 Ctrl+C 后, 通过'上下'键浏览, 'f,b' 键前后翻整页, 'd,u' 键翻半页 " 
		echo ""
		red " 更多用法请查看 less 命令 " 
		echo ""
		promptContinueOpeartion
		less +F ${configFrpLogFile}
	fi
}


function subMenuInstallFRP(){
    clear

    green " ===================================================================================================="
    green " 内网穿透工具 FRP 安装管理脚本 By jinwyp | 系统支持：centos7+ / ubuntu16+ / debian10 / 群晖DSM"
    green " ===================================================================================================="
    echo
	green " 1. 安装 Frp 服务器端版本 frps"
    green " 2. 安装 Frp 客户端版本 frpc"
	echo
    green " 3. 升级 Frp 到最新版本"
    green " 4. 群晖系统中 升级通过SPK安装的 Frpc 到最新版本"
    red " 5. 卸载 Frp "
    echo
	green " 6. 启动 Frp"
	green " 7. 停止 Frp"
	green " 8. 重启 Frp"
	echo
	green " 9. 查看 Frp 配置信息"
	green " 10. 编辑 Frp 配置信息"
	green " 11. 查看 Frp 日志"
    echo
    green " 20. 返回上级菜单"
    green " 0. 退出脚本"
    echo
    read -p "请输入数字:" menuNumberInput
    case "$menuNumberInput" in
        1 )
            installFRP "frps"
        ;;
        2 )
            installFRP
        ;;
        3 )
            upgradeFRP
        ;;
        4 )
            upgradeFRP "dsmspk"
        ;;
        5 )
            removeFRP
        ;;
        6 )
            systemRunFRP "start"
        ;;
        7 )
            systemRunFRP "stop"
        ;;
        8 )
            systemRunFRP "restart"
        ;;
        9 )
            checkLogFRP "ini"
        ;;
        10 )
            checkLogFRP "edit"
        ;;     		             
        11)
            checkLogFRP
        ;;
        20)
            start_menu
        ;;
        0 )
            exit 1
        ;;
        * )
            clear
            red "请输入正确数字 !"
            sleep 2s
            subMenuInstallFRP
        ;;
    esac
}
















































function start_menu(){
    clear
	set_text_color
	
    if [[ $1 == "first" ]] ; then
		getLinuxOSRelease
        installSoft
    fi
	
    green " ===================================================================================================="
    green " PVE 虚拟机 和 群晖 工具脚本 | 2021-04-15 | By jinwyp | 系统支持：PVE / debian10 "
    green " ===================================================================================================="
	green " 1. PVE 关闭企业更新源, 添加非订阅版更新源"
	green " 2. PVE 删除 swap 分区（/dev/pve/swap 逻辑卷) 并全部扩容给 /dev/pve/root 逻辑卷"
	green " 3. PVE 删除 local-lvm 储存盘 (/dev/pve/data 逻辑卷) 并全部扩容给 /dev/pve/root 逻辑卷"
	green " 4. PVE 修改IP地址 "
	echo
    green " 6. PVE 开启IOMMU 用于支持直通, 需要在BIOS先开启VT-d"
    green " 7. PVE 关闭IOMMU 关闭直通 恢复默认设置"
    green " 8. 检测系统是否支持 IOMMU, VT-d VT-d"
    green " 9. 检测系统是否开启显卡直通"
    green " 10. 显示系统信息 用于查看直通设备"
	echo
	green " 15. PVE安装群晖 使用 qm importdisk 命令导入引导文件synoboot.img, 生成硬盘设备"
	green " 16. PVE安装群晖 使用 img2kvm 命令导入引导文件synoboot.img, 生成硬盘设备"
	green " 17. PVE安装群晖 使用 qm set 命令添加整个硬盘(直通) 生成硬盘设备"
	echo
	green " 21. 群晖工具 开启ssh root登录"
	green " 22. 群晖工具 填入洗白的序列号和网卡Mac地址"
	green " 23. 群晖工具 使用vi 编辑/grub/grub.cfg 引导文件"
	green " 24. 群晖工具 使用vi 编辑/etc/host 文件"
	green " 25. 群晖补丁 修复DSM 6.2.3 找不到/dev/synoboot 从而升级失败问题"
	green " 26. 群晖补丁 修复CPU型号显示错误"
	green " 27. 群晖补丁 正确识别 Nvme 固态硬盘"	
	green " 28. 群晖检测 是否有显卡或是否显卡直通成功 支持硬解"	
	echo
	green " 51. 局域网测速工具 安装测速软件 iperf3"	
	green " 52. 子菜单 安装 FRP 内网穿透工具"	
	green " 70. 更换系统软件源为阿里云"	
	echo
    green " 0. 退出脚本"
    echo
    read -p "请输入数字:" menuNumberInput
    case "$menuNumberInput" in
        1 )
            updatePVEAptSource
        ;;	
        2 )
            deleteVGLVPVESwap
        ;;	
        3 )
            deleteVGLVPVEData
        ;;					
        4 )
            setPVEIP
        ;;					
        6 )
            enableIOMMU
        ;;
        7 )
            disableIOMMU
        ;;
        8 )
            checkIOMMU
			checkIOMMUDMAR
        ;;
        9 )
            checkVfio
        ;;
        10 )
            displayIOMMUInfo
        ;;
        15 )
            genPVEVMDiskWithQM
        ;;
        16 )
            genPVEVMDiskWithQM "Img2kvm"
        ;;
        17 )
            genPVEVMDiskPT
        ;;	
        21 )
            DSMOpenSSHRoot
        ;;				
        22 )
            DSMFixSNAndMac 
        ;;				
        23 )
            DSMFixSNAndMac "vi"
        ;;	
        24 )
            DSMEditHosts
        ;;				
        25 )
            DSMFixDevSynoboot  
        ;;	
        26 )
            DSMFixCPUInfo
        ;;						
        27 )
            DSMFixNvmeSSD
        ;;		
        28 )
            DSMCheckVideoCardPassThrough 
        ;;
        51 )
            installIperf3 
        ;;		
        52 )
            subMenuInstallFRP 
        ;;
        70 )
            updateYumAptSource
        ;;					
        88 )
            checkFirewallStatus
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



