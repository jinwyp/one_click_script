#!/bin/bash

#
# Install linux kernel for TCP BBR and BBR Plus
#
# Copyright (C) 2021-2023 JinWYP
#


# 4.4 LTS 4.9 LTS 4.14 LTS 4.19 LTS
# 5.4 LTS 5.10 LTS


# 4.x版本内核最新的longterm版本是4.19.113,安装的话只能找个4.19的rpm包来安装了

# 从 Linux 4.9 版本开始，TCP BBR 就已经成为了 Linux 系统内核的一部分。因此，开启 BBR 的首要前提就是当前系统内核版本大于等于 4.9

# Linux 内核 5.6 正式发布了，内置了 wireguard module
# Linux 5.6 引入 FQ-PIE 数据包调度程序以帮助应对 Bufferbloat
# 5.5内核支持cake队列
# 自来光大佬： xamod内核5.8默认队列算法已经改为 fq_pie 之前是cake


# centos8 安装完成默认内核  kernel-core-4.18.0-240.15.1.el8_3.x86_64, kernel-modules-4.18.0-240.15.1.el8_3.x86_64
# ubuntu20 安装完成默认内核  linux-generic 4.15.0.140, linux-headers-4.15.0-140
# debian10 安装完成默认内核  4.19.0-16-amd64

# UJX6N 编译的bbr plus 内核  5.10.27-bbrplus    5.9.16    5.4.86  
# UJX6N 编译的bbr plus 内核  4.19.164   4.14.213    4.9.264-1.bbrplus
# https://github.com/cx9208/bbrplus/issues/27


# BBR 速度评测 
# https://www.shopee6.com/web/web-tutorial/bbr-vs-plus-vs-bbr2.html
# https://hostloc.com/thread-644985-1-1.html



export LC_ALL=C
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

Green_font_prefix="\033[32m" 
Red_font_prefix="\033[31m" 
Green_background_prefix="\033[42;37m" 
Red_background_prefix="\033[41;37m" 
Font_color_suffix="\033[0m"



osInfo=""
osRelease=""
osReleaseVersion=""
osReleaseVersionNo=""
osReleaseVersionCodeName="CodeName"
osSystemPackage=""
osSystemMdPath=""
osSystemShell="bash"

osKernelVersionFull=$(uname -r)
osKernelVersionBackup=$(uname -r | awk -F "-" '{print $1}')
osKernelVersionShort=$(uname -r | cut -d- -f1 | awk -F "." '{print $1"."$2}')
osKernelBBRStatus=""
systemBBRRunningStatus="no"
systemBBRRunningStatusText=""


# 检测系统版本号
getLinuxOSVersion(){
    if [[ -s /etc/redhat-release ]]; then
        osReleaseVersion=$(grep -oE '[0-9.]+' /etc/redhat-release)
    else
        osReleaseVersion=$(grep -oE '[0-9.]+' /etc/issue)
    fi

    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
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
    virt_check

    [[ -z $(echo $SHELL|grep zsh) ]] && osSystemShell="bash" || osSystemShell="zsh"

    echo "OS info: ${osInfo}, ${osRelease}, ${osReleaseVersion}, ${osReleaseVersionNo}, ${osReleaseVersionCodeName}, ${osSystemShell}, ${osSystemPackage}, ${osSystemMdPath}"
}


virt_check(){
	# if hash ifconfig 2>/dev/null; then
		# eth=$(ifconfig)
	# fi

	virtualx=$(dmesg) 2>/dev/null

    if  [ $(which dmidecode) ]; then
		sys_manu=$(dmidecode -s system-manufacturer) 2>/dev/null
		sys_product=$(dmidecode -s system-product-name) 2>/dev/null
		sys_ver=$(dmidecode -s system-version) 2>/dev/null
	else
		sys_manu=""
		sys_product=""
		sys_ver=""
	fi
	
	if grep docker /proc/1/cgroup -qa; then
	    virtual="Docker"
	elif grep lxc /proc/1/cgroup -qa; then
		virtual="Lxc"
	elif grep -qa container=lxc /proc/1/environ; then
		virtual="Lxc"
	elif [[ -f /proc/user_beancounters ]]; then
		virtual="OpenVZ"
	elif [[ "$virtualx" == *kvm-clock* ]]; then
		virtual="KVM"
	elif [[ "$cname" == *KVM* ]]; then
		virtual="KVM"
	elif [[ "$cname" == *QEMU* ]]; then
		virtual="KVM"
	elif [[ "$virtualx" == *"VMware Virtual Platform"* ]]; then
		virtual="VMware"
	elif [[ "$virtualx" == *"Parallels Software International"* ]]; then
		virtual="Parallels"
	elif [[ "$virtualx" == *VirtualBox* ]]; then
		virtual="VirtualBox"
	elif [[ -e /proc/xen ]]; then
		virtual="Xen"
	elif [[ "$sys_manu" == *"Microsoft Corporation"* ]]; then
		if [[ "$sys_product" == *"Virtual Machine"* ]]; then
			if [[ "$sys_ver" == *"7.0"* || "$sys_ver" == *"Hyper-V" ]]; then
				virtual="Hyper-V"
			else
				virtual="Microsoft Virtual Machine"
			fi
		fi
	else
		virtual="Dedicated母鸡"
	fi
}




function installSoftDownload(){
	if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
		if ! dpkg -l | grep -qw wget; then
			${osSystemPackage} -y install wget curl git
		fi

        if ! dpkg -l | grep -qw bc; then
			${osSystemPackage} -y install bc
            # https://stackoverflow.com/questions/11116704/check-if-vt-x-is-activated-without-having-to-reboot-in-linux
            ${osSystemPackage} -y install cpu-checker
		fi

	elif [[ "${osRelease}" == "centos" ]]; then
		if ! rpm -qa | grep -qw wget; then
			${osSystemPackage} -y install wget curl git bc
		fi

        if ! rpm -qa | grep -qw bc; then
			${osSystemPackage} -y install bc
		fi
	fi

}


function rebootSystem(){
   
    red "请检查上面的信息 是否有新内核版本, 老内核版本 ${osKernelVersionBackup} 是否已经卸载!"
    echo
    red "请注意检查 是否把新内核也误删卸载了, 无新内核 ${linuxKernelToInstallVersionFull} 不要重启, 可重新安装内核后再重启! "
    echo
	read -p "是否立即重启? 请输入[Y/n]?" isRebootInput
	isRebootInput=${isRebootInput:-Y}

	if [[ $isRebootInput == [Yy] ]]; then
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

# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash
versionCompare () {
    if [[ $1 == $2 ]]; then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

versionCompareWithOp () {
    versionCompare $1 $2
    case $? in
        0) op='=';;
        1) op='>';;
        2) op='<';;
    esac
    if [[ $op != $3 ]]; then
        # echo "Version Number Compare Fail: Expected '$3', Actual '$op', Arg1 '$1', Arg2 '$2'"
        return 1
    else
        # echo "Version Number Compare Pass: '$1 $op $2'"
        return 0
    fi
}


function listAvailableLinuxKernel(){
    echo
    green " =================================================="
    green " 状态显示--当前可以被安装的 Linux 内核: "
    if [[ "${osRelease}" == "centos" ]]; then
		${sudoCmd} yum --disablerepo="*" --enablerepo="elrepo-kernel" list available | grep kernel
	else
        ${sudoCmd} apt-cache search linux-image
	fi
    
    green " =================================================="
    echo
}

function listInstalledLinuxKernel(){
    green " =================================================="
    green " 状态显示--当前已安装的 Linux 内核: "
    echo

	if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
        dpkg --get-selections | grep linux-
		# dpkg -l | grep linux-
        # dpkg-query -l | grep linux-
        # apt list --installed | grep linux-

	elif [[ "${osRelease}" == "centos" ]]; then
        ${sudoCmd} rpm -qa | grep kernel
        echo
        red " 如安装内核遇到kernel kernel-headers kernel-devel版本不一致问题, 请手动卸载已安装的kernel" 
        red " 卸载内核命令 rpm --nodeps -e kernel-xxx名称" 
	fi
    green " =================================================="
    echo
}

function showLinuxKernelInfoNoDisplay(){

    isKernelSupportBBRVersion="4.9"

    if versionCompareWithOp "${isKernelSupportBBRVersion}" "${osKernelVersionShort}" ">"; then
        echo
    else 
        osKernelBBRStatus="BBR"
    fi

    if [[ ${osKernelVersionFull} == *bbrplus* ]]; then
        osKernelBBRStatus="BBR Plus"
    fi

	net_congestion_control=`cat /proc/sys/net/ipv4/tcp_congestion_control | awk '{print $1}'`
	net_qdisc=`cat /proc/sys/net/core/default_qdisc | awk '{print $1}'`

    if [[ ${osKernelVersionBackup} == *4.14.129* ]]; then
        # isBBREnabled=$(grep "net.ipv4.tcp_congestion_control" /etc/sysctl.conf | awk -F "=" '{print $2}')
        # isBBREnabled=$(sysctl net.ipv4.tcp_available_congestion_control | awk -F "=" '{print $2}')

        isBBRTcpEnabled=$(lsmod | grep "bbr" | awk '{print $1}')
        isBBRPlusTcpEnabled=$(lsmod | grep "bbrplus" | awk '{print $1}')
    else
        isBBRTcpEnabled=$(sysctl net.ipv4.tcp_congestion_control | grep "bbr" | awk -F "=" '{print $2}' | awk '{$1=$1;print}')
        isBBRPlusTcpEnabled=$(sysctl net.ipv4.tcp_congestion_control | grep "bbrplus" | awk -F "=" '{print $2}' | awk '{$1=$1;print}')
    fi



    if [[ ${net_congestion_control} == "bbr" ]]; then
        
        if [[ ${isBBRTcpEnabled} == *"bbr"* ]]; then
            systemBBRRunningStatus="bbr"
            systemBBRRunningStatusText="BBR 已启动成功"            
        else 
            systemBBRRunningStatusText="BBR 启动失败"
        fi

    elif [[ ${net_congestion_control} == "bbrplus" ]]; then

        if [[ ${isBBRPlusTcpEnabled} == *"bbrplus"* ]]; then
            systemBBRRunningStatus="bbrplus"
            systemBBRRunningStatusText="BBR Plus 已启动成功"            
        else 
            systemBBRRunningStatusText="BBR Plus 启动失败"
        fi
    else 
        systemBBRRunningStatusText="未启动加速模块"
    fi

}

function showLinuxKernelInfo(){
    
    # https://stackoverflow.com/questions/8654051/how-to-compare-two-floating-point-numbers-in-bash
    # https://stackoverflow.com/questions/229551/how-to-check-if-a-string-contains-a-substring-in-bash

    isKernelSupportBBRVersion="4.9"

    green " =================================================="
    green " 状态显示--当前Linux 内核版本: ${osKernelVersionShort} , $(uname -r) "

    if versionCompareWithOp "${isKernelSupportBBRVersion}" "${osKernelVersionShort}" ">"; then
        green " 状态显示--当前系统内核低于4.9, 不支持开启 BBR "   
    else
        green " 状态显示--当前系统内核高于4.9, 支持开启 BBR, ${systemBBRRunningStatusText}"
        osKernelBBRStatus="BBR"
    fi

    if [[ ${osKernelVersionFull} == *bbrplus* ]]; then
        green " 状态显示--当前系统内核已支持开启 BBR Plus, ${systemBBRRunningStatusText}"
        osKernelBBRStatus="BBR Plus"
    else
        green " 状态显示--当前系统内核不支持开启 BBR Plus"
    fi


    # sysctl net.ipv4.tcp_available_congestion_control 返回值 net.ipv4.tcp_available_congestion_control = bbr cubic reno 或 reno cubic bbr
    # sysctl net.ipv4.tcp_congestion_control 返回值 net.ipv4.tcp_congestion_control = bbr
    # sysctl net.core.default_qdisc 返回值 net.core.default_qdisc = fq
    # lsmod | grep bbr 返回值 tcp_bbr     20480  3  或 tcp_bbr                20480  1   注意：并不是所有的 VPS 都会有此返回值，若没有也属正常。

    # isFlagBbr=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')

    # if [[ (${isFlagBbr} == *"bbr"*)  &&  (${isFlagBbr} != *"bbrplus"*) && (${isFlagBbr} != *"bbr2"*) ]]; then
    #     green " 状态显示--是否开启BBR: 已开启 "
    # else
    #     green " 状态显示--是否开启BBR: 未开启 "
    # fi

    # if [[ ${isFlagBbr} == *"bbrplus"* ]]; then
    #     green " 状态显示--是否开启BBR Plus: 已开启 "
    # else
    #     green " 状态显示--是否开启BBR Plus: 未开启 "
    # fi
    
    # if [[ ${isFlagBbr} == *"bbr2"* ]]; then
    #     green " 状态显示--是否开启BBR2: 已开启 "
    # else
    #     green " 状态显示--是否开启BBR2: 未开启 "
    # fi

    green " =================================================="
    echo
}


enableBBRSysctlConfig() {
    # https://hostloc.com/thread-644985-1-1.html
    # 优质线路用5.5+cake和原版bbr带宽跑的更足，不过cake的话就算高峰也不会像原版bbr那样跑不动，相比plus能慢些，但是区别不大，
    # bbr plus的话美西或者一些延迟高的，用起来更好，锐速针对丢包高的有奇效
    # 带宽大，并且延迟低不丢包的话5.5+cake在我这比较好，延迟高用plus更好，丢包多锐速最好. 一般130ms以下用cake不错，以上的话用plus更好些

    removeBbrSysctlConfig
    currentBBRText="bbr"
    currentQueueText="fq"

    if [ $1 = "bbrplus" ]; then
        currentBBRText="bbrplus"
    elif [ $1 = "bbr2" ]; then
        currentBBRText="bbr2"
    else
        currentBBRText="bbr"
        
        echo
        echo " 请选择队列算法 (1) FQ,  (2) FQ-PIE,  (3) CAKE "
        red " 选择 2 FQ-PIE 队列算法 需要内核在 5.6 以上"
        red " 选择 3 CAKE 队列算法 需要内核在 5.5 以上"
        read -p "请选择队列算法? 直接回车默认选1 FQ, 请输入[1/2/3]:" BBRQueueInput
        BBRQueueInput=${BBRQueueInput:-i}

        if [[ $BBRQueueInput == [2] ]]; then
            currentQueueText="fq_pie"

        elif [[ $BBRQueueInput == [3] ]]; then
            currentQueueText="cake"

        else
            currentQueueText="fq"
        fi

    fi

    echo "net.core.default_qdisc=${currentQueueText}" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=${currentBBRText}" >> /etc/sysctl.conf

    isSysctlText=$(sysctl -p 2>&1 | grep "No such file") 

    echo
    if [[ -z "$isSysctlText" ]]; then
		green " 已成功开启 ${currentBBRText} + ${currentQueueText}"
	else
        green " 已成功开启 ${currentBBRText}"
        red " 但当前内核版本过低, 开启队列算法 ${currentQueueText} 失败! " 
        red "请重新运行脚本, 选择'2 开启 BBR 加速'后, 务必再选择 (1)FQ 队列算法 !"
    fi
    echo

    # rebootSystem
}

# 卸载 bbr+锐速 配置
removeBbrSysctlConfig(){
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf

	sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf

    echo
	sysctl -p
		
	if [[ -e /appex/bin/lotServer.sh ]]; then
		bash <(wget --no-check-certificate -qO- https://git.io/lotServerInstall.sh) uninstall
	fi

	# echo -e "${Info}:清除bbr/lotserver加速完成。"
}











































isInstallFromRepo="no"
userHomePath="${HOME}/linux_kernel"
linuxKernelByUser="elrepo"
linuxKernelToBBRType=""
linuxKernelToInstallVersion="5.10"
linuxKernelToInstallVersionFull=""

elrepo_kernel_name="kernel-ml"
elrepo_kernel_version="5.4.110"

altarch_kernel_name="kernel"
altarch_kernel_version="5.4.105"



function downloadFile(){

    tempUrl=$1
    tempFilename=$(echo "${tempUrl##*/}")

    echo "${userHomePath}/${linuxKernelToInstallVersionFull}/${tempFilename}"
    if [ -f "${userHomePath}/${linuxKernelToInstallVersionFull}/${tempFilename}" ]; then
        green "文件已存在, 不需要下载, 文件原下载地址: $1 "
    else 
        green "文件下载中... 下载地址: $1 "
        wget -N --no-check-certificate -P ${userHomePath}/${linuxKernelToInstallVersionFull} $1 
    fi 
    echo
}


function installKernel(){

    if [ "${linuxKernelToInstallVersion}" = "5.10" ]; then 
        bbrplusKernelVersion="5.10.27-1"
        
    elif [ "${linuxKernelToInstallVersion}" = "5.9" ]; then 
        bbrplusKernelVersion="5.9.16-5"
        
    elif [ "${linuxKernelToInstallVersion}" = "5.4" ]; then 
        bbrplusKernelVersion="5.4.109-1"

    elif [ "${linuxKernelToInstallVersion}" = "4.19" ]; then 
        bbrplusKernelVersion="4.19.184-1"

    elif [ "${linuxKernelToInstallVersion}" = "4.14" ]; then 
        bbrplusKernelVersion="4.14.228-1"

    elif [ "${linuxKernelToInstallVersion}" = "4.9" ]; then 
        bbrplusKernelVersion="4.9.264-1"
    fi    



	if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
		
        installDebianUbuntuKernel

	elif [[ "${osRelease}" == "centos" ]]; then
        if [ "${linuxKernelToBBRType}" != "bbrplus" ]; then 
            getLatestCentosKernelVersion
        fi
        
        if [ "${isInstallFromRepo}" = "yes" ]; then 
            installCentosKernelFromRepo
        else
            installCentosKernelManual
        fi
	fi
}


function getLatestCentosKernelVersion(){

    # https://stackoverflow.com/questions/4988155/is-there-a-bash-command-that-can-tell-the-size-of-a-shell-variable

    elrepo_kernel_version_lt_array=($(wget -qO- https://elrepo.org/linux/kernel/el8/x86_64/RPMS/ | awk -F'\"kernel-lt-' '/kernel-lt-[4-9]./{print $2}' | cut -d- -f1 | sort -V))
    elrepo_kernel_version_ml_array=($(wget -qO- https://elrepo.org/linux/kernel/el8/x86_64/RPMS/ | awk -F'\"kernel-ml-' '/kernel-ml-[4-9]./{print $2}' | cut -d- -f1 | sort -V))

    # echo ${elrepo_kernel_version_lt_array[@]}

    echo
    if [ ${#elrepo_kernel_version_lt_array[@]} -eq 0 ]; then
        red " 无法获取到 Centos elrepo 源的最新的Linux 内核 kernel-lt 版本号 "
    else
        # echo ${elrepo_kernel_version_lt_array[${#elrepo_kernel_version_lt_array[@]} - 1]}
        elrepo_kernel_version_lt=${elrepo_kernel_version_lt_array[${#elrepo_kernel_version_lt_array[@]} - 1]}
        green "Centos elrepo 源的最新的Linux 内核 kernel-lt 版本号为 ${elrepo_kernel_version_lt}" 
    fi

    if [ ${#elrepo_kernel_version_ml_array[@]} -eq 0 ]; then
        red " 无法获取到 Centos elrepo 源的最新的Linux 内核 kernel-ml 版本号 "
    else
        elrepo_kernel_version_ml=${elrepo_kernel_version_ml_array[-1]}
        green "Centos elrepo 源的最新的Linux 内核 kernel-ml 版本号为 ${elrepo_kernel_version_ml}" 
    fi
    echo
}


function installCentosKernelFromRepo(){

    green " =================================================="
    green "    开始通过 elrepo 源安装 linux 内核, 不支持Centos6 "
    green " =================================================="

    if [ -n "${osReleaseVersionNo}" ]; then 
    
        if [ "${linuxKernelToInstallVersion}" = "5.4" ]; then 
            elrepo_kernel_name="kernel-lt"
            elrepo_kernel_version=${elrepo_kernel_version_lt}

        else
            elrepo_kernel_name="kernel-ml"
            elrepo_kernel_version=${elrepo_kernel_version_ml}
        fi

        if [ "${osKernelVersionBackup}" = "${elrepo_kernel_version}" ]; then 
            red "当前系统内核版本已经是 ${osKernelVersionBackup} 无需安装! "
            promptContinueOpeartion
        fi
        
        linuxKernelToInstallVersionFull=${elrepo_kernel_version}

        if [ "${osReleaseVersionNo}" -eq 7 ]; then
            # https://computingforgeeks.com/install-linux-kernel-5-on-centos-7/

            # https://elrepo.org/linux/kernel/
            # https://elrepo.org/linux/kernel/el7/x86_64/RPMS/
            
            rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
            ${sudoCmd} yum install -y yum-plugin-fastestmirror 
            ${sudoCmd} yum install -y https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm

            removeCentosKernelMulti
            listAvailableLinuxKernel

            ${sudoCmd} yum -y --enablerepo=elrepo-kernel install ${elrepo_kernel_name}
            ${sudoCmd} yum -y --enablerepo=elrepo-kernel install ${elrepo_kernel_name}-{devel,headers,tools,tools-libs}
            
        elif [ "${osReleaseVersionNo}" -eq 8 ]; then
            # https://elrepo.org/linux/kernel/el8/x86_64/RPMS/
            rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
            ${sudoCmd} yum install -y yum-plugin-fastestmirror 
            ${sudoCmd} yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm

            removeCentosKernelMulti
            listAvailableLinuxKernel

            ${sudoCmd} yum -y --enablerepo=elrepo-kernel install ${elrepo_kernel_name}
            ${sudoCmd} yum -y --enablerepo=elrepo-kernel install ${elrepo_kernel_name}-{devel,headers,tools,tools-libs}
        else
            green " =================================================="
            red "    不支持 Centos 7和8 以外的其他版本 安装 linux 内核"
            green " =================================================="
        fi

        green " =================================================="
        green "    安装 linux 内核 ${linuxKernelToInstallVersionFull} 成功! "
        red "    请根据以下信息 检查新内核是否安装成功，无新内核不要重启! "
        green " =================================================="
        echo

        showLinuxKernelInfo
        listInstalledLinuxKernel
        removeCentosKernelMulti "kernel"
        listInstalledLinuxKernel
        rebootSystem
    fi

}




function installCentosKernelManual(){

    green " =================================================="
    green "    开始手动安装 linux 内核, 不支持Centos6 "
    green " =================================================="
    echo

    yum install -y linux-firmware
    
    mkdir -p ${userHomePath}
    cd ${userHomePath}

    kernelVersionFirstletter=${linuxKernelToInstallVersion:0:1}

    echo
    if [ "${linuxKernelToBBRType}" = "bbrplus" ]; then 
        linuxKernelByUser="UJX6N"
        if [ "${linuxKernelToInstallVersion}" = "4.14.129" ]; then 
            linuxKernelByUser="cx9208"
        fi
        green " 准备从 ${linuxKernelByUser} github 网站下载 bbr plus 的linux内核并安装 "
    else
        if [ "${kernelVersionFirstletter}" = "5" ]; then 
            linuxKernelByUser="elrepo"
        else
            linuxKernelByUser="altarch"
        fi
        green " 准备从 ${linuxKernelByUser} 网站下载linux内核并安装 "
    fi
    echo

    if [ "${linuxKernelByUser}" = "elrepo" ]; then 
        # elrepo 

        if [ "${linuxKernelToInstallVersion}" = "5.4" ]; then 
            elrepo_kernel_name="kernel-lt"
            elrepo_kernel_version=${elrepo_kernel_version_lt}
            elrepo_kernel_filename="elrepo."
            ELREPODownloadUrl="https://elrepo.org/linux/kernel/el${osReleaseVersionNo}/x86_64/RPMS"

            # https://elrepo.org/linux/kernel/el7/x86_64/RPMS/
            # https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-lt-5.4.105-1.el7.elrepo.x86_64.rpm
            # https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-lt-tools-5.4.109-1.el7.elrepo.x86_64.rpm
            # https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-lt-tools-libs-5.4.109-1.el7.elrepo.x86_64.rpm
        else
            elrepo_kernel_name="kernel-ml"
            elrepo_kernel_version="5.10.28"
            elrepo_kernel_filename=""
            ELREPODownloadUrl="https://dl.lamp.sh/kernel/el${osReleaseVersionNo}"

             # https://dl.lamp.sh/kernel/el7/kernel-ml-5.10.23-1.el7.x86_64.rpm
             # https://dl.lamp.sh/kernel/el8/kernel-ml-5.10.27-1.el8.x86_64.rpm
             # https://dl.lamp.sh/kernel/el8/kernel-ml-5.10.27-1.el8.x86_64.rpm

        fi

        linuxKernelToInstallVersionFull=${elrepo_kernel_version}

        mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
        cd ${userHomePath}/${linuxKernelToInstallVersionFull}

        if [ "${osReleaseVersionNo}" -eq 7 ]; then
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-${elrepo_kernel_version}-1.el7.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-devel-${elrepo_kernel_version}-1.el7.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-headers-${elrepo_kernel_version}-1.el7.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-tools-${elrepo_kernel_version}-1.el7.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-tools-libs-${elrepo_kernel_version}-1.el7.${elrepo_kernel_filename}x86_64.rpm
        else 
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-devel-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-headers-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-core-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-modules-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-tools-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-tools-libs-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
        fi

        removeCentosKernelMulti
        rpm -ivh --force --nodeps ${elrepo_kernel_name}-core-${elrepo_kernel_version}-*.rpm
        rpm -ivh --force --nodeps ${elrepo_kernel_name}-${elrepo_kernel_version}-*.rpm
        rpm -ivh --force --nodeps ${elrepo_kernel_name}-*.rpm


    elif [ "${linuxKernelByUser}" = "altarch" ]; then 
        # altarch

        if [ "${linuxKernelToInstallVersion}" = "4.14" ]; then 
            altarch_kernel_version="4.14.119-200"
            altarchDownloadUrl="https://vault.centos.org/altarch/7.6.1810/kernel/x86_64/Packages"

            # https://vault.centos.org/altarch/7.6.1810/kernel/x86_64/Packages/kernel-4.14.119-200.el7.x86_64.rpm
        elif [ "${linuxKernelToInstallVersion}" = "4.19" ]; then 
            altarch_kernel_version="4.19.113-300"
            altarchDownloadUrl="https://vault.centos.org/altarch/7.8.2003/kernel/x86_64/Packages"

            # https://vault.centos.org/altarch/7.8.2003/kernel/x86_64/Packages/kernel-4.19.113-300.el7.x86_64.rpm
        else
            altarch_kernel_version="5.4.105"
            altarchDownloadUrl="http://mirror.centos.org/altarch/7/kernel/x86_64/Packages"

            # http://mirror.centos.org/altarch/7/kernel/x86_64/Packages/kernel-5.4.96-200.el7.x86_64.rpm
        fi

        linuxKernelToInstallVersionFull=$(echo ${altarch_kernel_version} | cut -d- -f1)

        mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
        cd ${userHomePath}/${linuxKernelToInstallVersionFull}

        if [ "${osReleaseVersionNo}" -eq 7 ]; then
            
            if [ "$kernelVersionFirstletter" = "5" ]; then 
                # http://mirror.centos.org/altarch/7/kernel/x86_64/Packages/

                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-${altarch_kernel_version}-200.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-core-${altarch_kernel_version}-200.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-devel-${altarch_kernel_version}-200.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-headers-${altarch_kernel_version}-200.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-modules-${altarch_kernel_version}-200.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-tools-${altarch_kernel_version}-200.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-tools-libs-${altarch_kernel_version}-200.el7.x86_64.rpm

            else 
                # https://vault.centos.org/altarch/7.6.1810/kernel/x86_64/Packages/
                # https://vault.centos.org/altarch/7.6.1810/kernel/x86_64/Packages/kernel-4.14.119-200.el7.x86_64.rpm

                # https://vault.centos.org/altarch/7.8.2003/kernel/x86_64/Packages/
                # https://vault.centos.org/altarch/7.8.2003/kernel/i386/Packages/kernel-4.19.113-300.el7.i686.rpm
                # https://vault.centos.org/altarch/7.8.2003/kernel/x86_64/Packages/kernel-4.19.113-300.el7.x86_64.rpm
                # http://ftp.iij.ad.jp/pub/linux/centos-vault/altarch/7.8.2003/kernel/i386/Packages/kernel-4.19.113-300.el7.i686.rpm

                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-${altarch_kernel_version}.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-core-${altarch_kernel_version}.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-devel-${altarch_kernel_version}.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-headers-${altarch_kernel_version}.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-modules-${altarch_kernel_version}.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-tools-${altarch_kernel_version}.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-tools-libs-${altarch_kernel_version}.el7.x86_64.rpm

            fi

        else 
            red "从 altarch 源没有找到 Centos 8 的 ${linuxKernelToInstallVersion} Kernel "
            exit 255
        fi

        removeCentosKernelMulti
        rpm -ivh --force --nodeps ${altarch_kernel_name}-core-${altarch_kernel_version}*
        rpm -ivh --force --nodeps ${altarch_kernel_name}-*
        # yum install -y kernel-*


    elif [ "${linuxKernelByUser}" = "cx9208" ]; then 

        linuxKernelToInstallVersionFull="4.14.129-bbrplus"

        if [ "${osReleaseVersionNo}" -eq 7 ]; then
            mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
            cd ${userHomePath}/${linuxKernelToInstallVersionFull}

            # https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/bbrplus/centos/7/kernel-4.14.129-bbrplus.rpm
            # https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/bbrplus/centos/7/kernel-headers-4.14.129-bbrplus.rpm

            bbrplusDownloadUrl="https://raw.githubusercontent.com/cx9208/Linux-NetSpeed/master/bbrplus/centos/7"

            downloadFile ${bbrplusDownloadUrl}/kernel-${linuxKernelToInstallVersionFull}.rpm
            downloadFile ${bbrplusDownloadUrl}/kernel-headers-${linuxKernelToInstallVersionFull}.rpm

            removeCentosKernelMulti
            rpm -ivh --force --nodeps kernel-${linuxKernelToInstallVersionFull}.rpm
            rpm -ivh --force --nodeps kernel-headers-${linuxKernelToInstallVersionFull}.rpm
        else 
            red "从 cx9208 的 github 网站没有找到 Centos 8 的 ${linuxKernelToInstallVersion} Kernel "
            exit 255
        fi

    elif [ "${linuxKernelByUser}" = "UJX6N" ]; then 
        
        linuxKernelToInstallSubVersion=$(echo ${bbrplusKernelVersion} | cut -d- -f1)
        linuxKernelToInstallVersionFull="${linuxKernelToInstallSubVersion}-bbrplus"

        mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
        cd ${userHomePath}/${linuxKernelToInstallVersionFull}

        if [ "${linuxKernelToInstallVersion}" = "5.9" ]; then 
            bbrplusDownloadUrl="https://github.com/UJX6N/bbrplus-${linuxKernelToInstallVersion}/releases/download/5.9.16-bbrplus-final-update-for-5.9"

        elif [ "${linuxKernelToInstallVersion}" = "4.14" ]; then 
            bbrplusDownloadUrl="https://github.com/UJX6N/bbrplus/releases/download/${linuxKernelToInstallVersionFull}"

        else
            bbrplusDownloadUrl="https://github.com/UJX6N/bbrplus-${linuxKernelToInstallVersion}/releases/download/${linuxKernelToInstallVersionFull}"
        fi
        


        if [ "${osReleaseVersionNo}" -eq 7 ]; then

            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.27-bbrplus/CentOS-7_Required_kernel-bbrplus-5.10.27-1.bbrplus.el7.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.27-bbrplus/CentOS-7_Optional_kernel-bbrplus-devel-5.10.27-1.bbrplus.el7.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.27-bbrplus/CentOS-7_Optional_kernel-bbrplus-headers-5.10.27-1.bbrplus.el7.x86_64.rpm
            

            # https://github.com/UJX6N/bbrplus-5.9/releases/download/5.9.16-bbrplus-final-update-for-5.9/CentOS-7_Required_kernel-bbrplus-5.9.16-5.bbrplus.el7.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.4/releases/download/5.4.109-bbrplus/CentOS-7_Required_kernel-bbrplus-5.4.109-1.bbrplus.el7.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-4.19/releases/download/4.19.184-bbrplus/CentOS-7_Required_kernel-bbrplus-4.19.184-1.bbrplus.el7.x86_64.rpm
            # https://github.com/UJX6N/bbrplus/releases/download/4.14.228-bbrplus/CentOS-7_Required_kernel-bbrplus-4.14.228-1.bbrplus.el7.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-4.9/releases/download/4.9.264-bbrplus/CentOS-7_Required_kernel-bbrplus-4.9.264-1.bbrplus.el7.x86_64.rpm

            downloadFile ${bbrplusDownloadUrl}/CentOS-7_Required_kernel-bbrplus-${bbrplusKernelVersion}.bbrplus.el7.x86_64.rpm
            downloadFile ${bbrplusDownloadUrl}/CentOS-7_Optional_kernel-bbrplus-devel-${bbrplusKernelVersion}.bbrplus.el7.x86_64.rpm
            downloadFile ${bbrplusDownloadUrl}/CentOS-7_Optional_kernel-bbrplus-headers-${bbrplusKernelVersion}.bbrplus.el7.x86_64.rpm

            removeCentosKernelMulti
            rpm -ivh --force --nodeps CentOS-7_Required_kernel-bbrplus-${bbrplusKernelVersion}.bbrplus.el7.x86_64.rpm
            rpm -ivh --force --nodeps *.rpm
        else 
            
            if [ "${kernelVersionFirstletter}" = "5" ]; then 
                echo
            else
                red "从 UJX6N 的 github 网站没有找到 Centos 8 的 ${linuxKernelToInstallVersion} Kernel "
                exit 255
            fi

            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.27-bbrplus/CentOS-8_Required_kernel-bbrplus-core-5.10.27-1.bbrplus.el8.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.27-bbrplus/CentOS-8_Optional_kernel-bbrplus-5.10.27-1.bbrplus.el8.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.27-bbrplus/CentOS-8_Optional_kernel-bbrplus-devel-5.10.27-1.bbrplus.el8.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.27-bbrplus/CentOS-8_Optional_kernel-bbrplus-headers-5.10.27-1.bbrplus.el8.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.27-bbrplus/CentOS-8_Optional_kernel-bbrplus-modules-5.10.27-1.bbrplus.el8.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.27-bbrplus/CentOS-8_Optional_kernel-bbrplus-modules-extra-5.10.27-1.bbrplus.el8.x86_64.rpm

            
            downloadFile ${bbrplusDownloadUrl}/CentOS-8_Required_kernel-bbrplus-core-${bbrplusKernelVersion}.bbrplus.el8.x86_64.rpm
            downloadFile ${bbrplusDownloadUrl}/CentOS-8_Optional_kernel-bbrplus-${bbrplusKernelVersion}.bbrplus.el8.x86_64.rpm
            downloadFile ${bbrplusDownloadUrl}/CentOS-8_Optional_kernel-bbrplus-devel-${bbrplusKernelVersion}.bbrplus.el8.x86_64.rpm
            downloadFile ${bbrplusDownloadUrl}/CentOS-8_Optional_kernel-bbrplus-headers-${bbrplusKernelVersion}.bbrplus.el8.x86_64.rpm
            downloadFile ${bbrplusDownloadUrl}/CentOS-8_Optional_kernel-bbrplus-modules-${bbrplusKernelVersion}.bbrplus.el8.x86_64.rpm
            downloadFile ${bbrplusDownloadUrl}/CentOS-8_Optional_kernel-bbrplus-modules-extra-${bbrplusKernelVersion}.bbrplus.el8.x86_64.rpm

            removeCentosKernelMulti
            rpm -ivh --force --nodeps CentOS-8_Required_kernel-bbrplus-core-${bbrplusKernelVersion}.bbrplus.el8.x86_64.rpm
            rpm -ivh --force --nodeps *.rpm

        fi

    fi;



    updateGrubConfig

    green " =================================================="
    green "    安装 linux 内核 ${linuxKernelToInstallVersionFull} 成功! "
    red "    请根据以下信息 检查新内核是否安装成功，无新内核不要重启! "
    green " =================================================="
    echo

    showLinuxKernelInfo
    listInstalledLinuxKernel
    removeCentosKernelMulti "kernel"
    listInstalledLinuxKernel
    rebootSystem
}



function removeCentosKernelMulti(){
    echo

    if [ -z $1 ]; then
        red " 开始准备删除 kernel-header kernel-devel kernel-tools kernel-tools-libs 内核, 建议删除 "
    else
        red " 开始准备删除 kernel 内核, 建议删除 "
    fi

    red " 注意: 删除内核有风险, 可能会导致VPS无法启动, 请先做好备份! "
    read -p "是否删除内核? 直接回车默认删除内核, 请输入[Y/n]:" isContinueDelKernelInput
	isContinueDelKernelInput=${isContinueDelKernelInput:-Y}

	if [[ $isContinueDelKernelInput == [Yy] ]]; then

        if [ -z $1 ]; then
            removeCentosKernel "kernel-devel"
            removeCentosKernel "kernel-header"
            removeCentosKernel "kernel-tools"

            removeCentosKernel "kernel-ml-devel"
            removeCentosKernel "kernel-ml-header"
            removeCentosKernel "kernel-ml-tools"

            removeCentosKernel "kernel-lt-devel"
            removeCentosKernel "kernel-lt-header"
            removeCentosKernel "kernel-lt-tools"

            removeCentosKernel "kernel-bbrplus-devel"  
            removeCentosKernel "kernel-bbrplus-headers" 
            removeCentosKernel "kernel-bbrplus-modules" 
        else
            removeCentosKernel "kernel"  
        fi 
	fi

}

function removeCentosKernel(){

    # 嗯嗯，用的yum localinstall kernel-ml-* 后，再指定顺序， 用那个 rpm -ivh 包名不行，提示kernel-headers冲突，
    # 输入rpm -e --nodeps kernel-headers 提示无法加载到此包，

    # 此时需要指定已安装的完整的 rpm 包名。
    # rpm -qa | grep kernel
    # 可以查看。比如：kernel-ml-headers-5.10.16-1.el7.elrepo.x86_64
    # 那么强制删除，则命令为：rpm -e --nodeps kernel-ml-headers-5.10.16-1.el7.elrepo.x86_64

    # ${sudoCmd} yum remove kernel-ml kernel-ml-{devel,headers,perf}
    # ${sudoCmd} rpm -e --nodeps kernel-headers
    # ${sudoCmd} rpm -e --nodeps kernel-ml-headers-${elrepo_kernel_version}-1.el7.elrepo.x86_64

    removeKernelNameText="kernel"
    removeKernelNameText=$1
    grepExcludelinuxKernelVersion=$(echo ${linuxKernelToInstallVersionFull} | cut -d- -f1)

    echo
    green "===== 准备开始删除旧内核 ${removeKernelNameText} ${osKernelVersionBackup}, 当前要安装新内核版本为: ${grepExcludelinuxKernelVersion}"

    echo "rpm -qa | grep ${removeKernelNameText} | grep -v ${grepExcludelinuxKernelVersion} | grep -v noarch | wc -l"
    rpmOldKernelNumber=$(rpm -qa | grep "${removeKernelNameText}" | grep -v "${grepExcludelinuxKernelVersion}" | grep -v "noarch" | wc -l)
    rpmOLdKernelNameList=$(rpm -qa | grep "${removeKernelNameText}" | grep -v "${grepExcludelinuxKernelVersion}" | grep -v "noarch")
    # echo "${rpmOLdKernelNameList}"

    # https://stackoverflow.com/questions/29269259/extract-value-of-column-from-a-line-variable


    if [ "${rpmOldKernelNumber}" -gt "0" ]; then
        
        red " 当前系统的旧内核 ${removeKernelNameText} ${osKernelVersionBackup} 有 ${rpmOldKernelNumber} 个需要删除"
        echo
        for((integer = 1; integer <= ${rpmOldKernelNumber}; integer++)); do   
            rpmOLdKernelName=$(awk "NR==${integer}" <<< "${rpmOLdKernelNameList}")
            green " 开始卸载第 ${integer} 个内核: ${rpmOLdKernelName}. 命令: rpm --nodeps -e ${rpmOLdKernelName}"
            rpm --nodeps -e ${rpmOLdKernelName}
            green " 已卸载第 ${integer} 个内核 ${rpmOLdKernelName}"
            echo
        done
        green "===== 共 ${rpmOldKernelNumber} 个旧内核 ${removeKernelNameText} ${osKernelVersionBackup} 已经卸载完成"
    else
        red " 当前需要卸载的系统旧内核 ${removeKernelNameText} 数量为0 !" 
    fi

    echo
}



# 更新引导文件 grub.conf
updateGrubConfig(){
	if [[ "${osRelease}" == "centos" ]]; then

        # if [ ! -f "/boot/grub/grub.conf" ]; then
        #     red "File '/boot/grub/grub.conf' not found, 没找到该文件"  
        # else 
        #     sed -i 's/^default=.*/default=0/g' /boot/grub/grub.conf
        #     grub2-set-default 0

        #     awk -F\' '$1=="menuentry " {print i++ " : " $2}' /boot/grub2/grub.cfg
        #     egrep ^menuentry /etc/grub2.cfg | cut -f 2 -d \'

        #     grub2-editenv list
        # fi
        
        # https://blog.51cto.com/foxhound/2551477
        # 看看最新的 5.10.16 是否排在第一，也就是第 0 位。 如果是，执行：grub2-set-default 0,  然后再看看：grub2-editenv list

        green " =================================================="
        echo

        if [[ ${osReleaseVersionNo} = "6" ]]; then
            red " 不支持 Centos 6"
            exit 255
        else
			if [ -f "/boot/grub2/grub.cfg" ]; then
				grub2-mkconfig -o /boot/grub2/grub.cfg
				grub2-set-default 0
			elif [ -f "/boot/efi/EFI/centos/grub.cfg" ]; then
				grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
				grub2-set-default 0
			elif [ -f "/boot/efi/EFI/redhat/grub.cfg" ]; then
				grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
				grub2-set-default 0	
			else
				red " /boot/grub2/grub.cfg 没找到该文件，请检查."
				exit
			fi

            echo
            green "    查看当前 grub 菜单启动项列表, 确保新安装的内核 ${linuxKernelToInstallVersionFull} 是否在第一项 "
            # grubby --info=ALL|awk -F= '$1=="kernel" {print i++ " : " $2}'
            awk -F\' '$1=="menuentry " {print i++ " : " $2}' /boot/grub2/grub.cfg

            echo
            green "    查看当前 grub 启动顺序是否已设置为第一项 "
            echo "grub2-editenv list" 
            grub2-editenv list
            green " =================================================="
            echo    
        fi

    elif [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
        echo
        echo "/usr/sbin/update-grub" 
        /usr/sbin/update-grub
    fi
}
































function getLatestUbuntuKernelVersion(){
    ubuntuKernelLatestVersionArray=($(wget -qO- https://kernel.ubuntu.com/~kernel-ppa/mainline/ | awk -F'\"v' '/v[4-9]\./{print $2}' | cut -d/ -f1 | grep -v - | sort -V))
    ubuntuKernelLatestVersion=${ubuntuKernelLatestVersionArray[${#ubuntuKernelLatestVersionArray[@]} - 1]}
    echo
    green "Ubuntu mainline 最新的Linux 内核 kernel 版本号为 ${ubuntuKernelLatestVersion}" 
    

    for ver in ${ubuntuKernelLatestVersionArray[@]}; do
        
        if [[ ${ver} == *"${linuxKernelToInstallVersion}"* ]]; then
            # echo "符合所选版本的Linux 内核版本: ${ver}"
            ubuntuKernelVersion=${ver}
        fi
    done
    
    green "即将安装的内核版本: ${ubuntuKernelVersion}"
    ubuntuDownloadUrl="https://kernel.ubuntu.com/~kernel-ppa/mainline/v${ubuntuKernelVersion}/amd64"
    echo
    echo "wget -qO- ${ubuntuDownloadUrl} | awk -F'>' '/-[4-9]\./{print \$7}' | cut -d'<' -f1 | grep -v lowlatency"
    ubuntuKernelDownloadUrlArray=($(wget -qO- ${ubuntuDownloadUrl} | awk -F'>' '/-[4-9]\./{print $7}' | cut -d'<' -f1 | grep -v lowlatency ))

    # echo "${ubuntuKernelDownloadUrlArray[*]}" 
    echo

}

function installDebianUbuntuKernel(){


    # https://kernel.ubuntu.com/~kernel-ppa/mainline/

    # https://unix.stackexchange.com/questions/545601/how-to-upgrade-the-debian-10-kernel-from-backports-without-recompiling-it-from-s

    # https://askubuntu.com/questions/119080/how-to-update-kernel-to-the-latest-mainline-version-without-any-distro-upgrade

    # https://sypalo.com/how-to-upgrade-ubuntu
    
    if [ "${isInstallFromRepo}" = "yes" ]; then 

        debianKernelVersion="5.10.0"

        green " =================================================="
        green "    开始通过 Debian 官方源安装 linux 内核 ${debianKernelVersion}"
        green " =================================================="

        if [ "${osKernelVersionBackup}" = "${debianKernelVersion}" ]; then 
            red "当前系统内核版本已经是 ${osKernelVersionBackup} 无需安装! "
            promptContinueOpeartion
        fi

        linuxKernelToInstallVersionFull=${debianKernelVersion}

        echo "deb http://deb.debian.org/debian buster-backports main contrib non-free" > /etc/apt/sources.list.d/buster-backports.list
        echo "deb-src http://deb.debian.org/debian buster-backports main contrib non-free" > /etc/apt/sources.list.d/buster-backports.list
        ${sudoCmd} apt update


        listAvailableLinuxKernel
        
        ${sudoCmd} apt install -y -t buster-backports linux-image-amd64
        ${sudoCmd} apt install -y -t buster-backports firmware-linux firmware-linux-nonfree

        echo
        echo "dpkg --get-selections | grep linux-image-${debianKernelVersion} | awk '/linux-image-[4-9]./{print \$1}' | awk -F'linux-image-' '{print \$2}' "
        debianKernelVersionPackageName=$(dpkg --get-selections | grep "${debianKernelVersion}" | awk '/linux-image-[4-9]./{print $1}' | awk -F'linux-image-' '{print $2}')
        
        echo
        green " Debian 官方源安装 linux 内核版本: ${debianKernelVersionPackageName}"
        green " 开始安装 linux-headers  命令为:  apt install -y linux-headers-${debianKernelVersionPackageName}"
        echo
        ${sudoCmd} apt install -y linux-headers-${debianKernelVersionPackageName}
        # ${sudoCmd} apt-get -y dist-upgrade
        

    else

        green " =================================================="
        green "    开始手动安装 linux 内核 "
        green " =================================================="
        echo

        mkdir -p ${userHomePath}
        cd ${userHomePath}

        linuxKernelByUser=""

        if [ "${linuxKernelToBBRType}" = "bbrplus" ]; then 
            linuxKernelByUser="UJX6N"
            if [ "${linuxKernelToInstallVersion}" = "4.14.129" ]; then 
                linuxKernelByUser="cx9208"
            fi
            green " 准备从 ${linuxKernelByUser} github 网站下载 bbr plus 的linux内核并安装 "
        else
            green " 准备从 Ubuntu kernel-ppa mainline 网站下载linux内核并安装 "
        fi
        echo

        if [[ "${osRelease}" == "ubuntu" && ${osReleaseVersionNo} == "16.04" ]]; then 
            wget -P ${userHomePath} http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb
            ${sudoCmd} dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb 
        fi



        if [ "${linuxKernelByUser}" = "" ]; then 

            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.11.12/amd64/
            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.11.12/amd64/linux-image-unsigned-5.11.12-051112-generic_5.11.12-051112.202104071432_amd64.deb
            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.11.12/amd64/linux-modules-5.11.12-051112-generic_5.11.12-051112.202104071432_amd64.deb

            getLatestUbuntuKernelVersion

            linuxKernelToInstallVersionFull=${ubuntuKernelVersion}

            mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
            cd ${userHomePath}/${linuxKernelToInstallVersionFull}


            for file in ${ubuntuKernelDownloadUrlArray[@]}; do
                downloadFile ${ubuntuDownloadUrl}/${file}
            done

        elif [ "${linuxKernelByUser}" = "cx9208" ]; then 

            linuxKernelToInstallVersionFull="4.14.129-bbrplus"

            mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
            cd ${userHomePath}/${linuxKernelToInstallVersionFull}

            # https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/bbrplus/debian-ubuntu/x64/linux-headers-4.14.129-bbrplus.deb
            # https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/bbrplus/debian-ubuntu/x64/linux-image-4.14.129-bbrplus.deb

            # https://github.com/cx9208/Linux-NetSpeed/raw/master/bbrplus/debian-ubuntu/x64/linux-headers-4.14.129-bbrplus.deb
            # https://github.com/cx9208/Linux-NetSpeed/raw/master/bbrplus/debian-ubuntu/x64/linux-image-4.14.129-bbrplus.deb

            # https://raw.githubusercontent.com/cx9208/Linux-NetSpeed/master/bbrplus/debian-ubuntu/x64/linux-headers-4.14.129-bbrplus.deb
            # https://raw.githubusercontent.com/cx9208/Linux-NetSpeed/master/bbrplus/debian-ubuntu/x64/linux-image-4.14.129-bbrplus.deb

            bbrplusDownloadUrl="https://raw.githubusercontent.com/cx9208/Linux-NetSpeed/master/bbrplus/debian-ubuntu/x64"

            downloadFile ${bbrplusDownloadUrl}/linux-image-${linuxKernelToInstallVersionFull}.deb
            downloadFile ${bbrplusDownloadUrl}/linux-headers-${linuxKernelToInstallVersionFull}.deb

        elif [ "${linuxKernelByUser}" = "UJX6N" ]; then 
        
            linuxKernelToInstallSubVersion=$(echo ${bbrplusKernelVersion} | cut -d- -f1)
            linuxKernelToInstallVersionFull="${linuxKernelToInstallSubVersion}-bbrplus"

            mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
            cd ${userHomePath}/${linuxKernelToInstallVersionFull}

            if [ "${linuxKernelToInstallVersion}" = "5.9" ]; then 
                bbrplusDownloadUrl="https://github.com/UJX6N/bbrplus-${linuxKernelToInstallVersion}/releases/download/5.9.16-bbrplus-final-update-for-5.9"
                downloadFile ${bbrplusDownloadUrl}/Debian-Ubuntu_Required_linux-image-${linuxKernelToInstallSubVersion}-bbrplus_5_amd64.deb
                downloadFile ${bbrplusDownloadUrl}/Debian-Ubuntu_Required_linux-headers-${linuxKernelToInstallSubVersion}-bbrplus_5_amd64.deb    

            elif [ "${linuxKernelToInstallVersion}" = "4.14" ]; then 
                bbrplusDownloadUrl="https://github.com/UJX6N/bbrplus/releases/download/${linuxKernelToInstallVersionFull}"
                downloadFile ${bbrplusDownloadUrl}/Debian-Ubuntu_Required_linux-image-${linuxKernelToInstallSubVersion}-bbrplus_${linuxKernelToInstallSubVersion}-bbrplus-1_amd64.deb
                downloadFile ${bbrplusDownloadUrl}/Debian-Ubuntu_Required_linux-headers-${linuxKernelToInstallSubVersion}-bbrplus_${linuxKernelToInstallSubVersion}-bbrplus-1_amd64.deb
            else
                bbrplusDownloadUrl="https://github.com/UJX6N/bbrplus-${linuxKernelToInstallVersion}/releases/download/${linuxKernelToInstallVersionFull}"

                downloadFile ${bbrplusDownloadUrl}/Debian-Ubuntu_Required_linux-image-${linuxKernelToInstallSubVersion}-bbrplus_${linuxKernelToInstallSubVersion}-bbrplus-1_amd64.deb
                downloadFile ${bbrplusDownloadUrl}/Debian-Ubuntu_Required_linux-headers-${linuxKernelToInstallSubVersion}-bbrplus_${linuxKernelToInstallSubVersion}-bbrplus-1_amd64.deb

            fi
    
            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.27-bbrplus/Debian-Ubuntu_Required_linux-image-5.10.27-bbrplus_5.10.27-bbrplus-1_amd64.deb
            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.27-bbrplus/Debian-Ubuntu_Required_linux-headers-5.10.27-bbrplus_5.10.27-bbrplus-1_amd64.deb

            # https://github.com/UJX6N/bbrplus-5.9/releases/download/5.9.16-bbrplus-final-update-for-5.9/Debian-Ubuntu_Required_linux-image-5.9.16-bbrplus_5_amd64.deb
            # https://github.com/UJX6N/bbrplus-5.4/releases/download/5.4.109-bbrplus/Debian-Ubuntu_Required_linux-image-5.4.109-bbrplus_5.4.109-bbrplus-1_amd64.deb
            # https://github.com/UJX6N/bbrplus-4.19/releases/download/4.19.184-bbrplus/Debian-Ubuntu_Required_linux-image-4.19.184-bbrplus_4.19.184-bbrplus-1_amd64.deb

        fi


         
        green " 开始安装 linux 内核版本: ${linuxKernelToInstallVersionFull}"
        echo

        removeDebianKernelMulti
        ${sudoCmd} dpkg -i *.deb 

        updateGrubConfig

    fi

    echo
    green " =================================================="
    green "    安装 linux 内核 ${linuxKernelToInstallVersionFull} 成功! "
    red "    请根据以下信息 检查新内核是否安装成功，无新内核不要重启! "
    green " =================================================="
    echo

    showLinuxKernelInfo
    listInstalledLinuxKernel
    removeDebianKernelMulti "linux-image"
    listInstalledLinuxKernel
    rebootSystem

}




function removeDebianKernelMulti(){

    echo
    if [ -z $1 ]; then
        red " 开始准备删除 linux-headers linux-modules 内核, 建议删除 "
    else
        red " 开始准备删除 linux-image 内核, 建议删除 "
    fi

    red " 注意: 删除内核有风险, 可能会导致VPS无法启动, 请先做好备份! "
    read -p "是否删除内核? 直接回车默认删除内核, 请输入[Y/n]:" isContinueDelKernelInput
	isContinueDelKernelInput=${isContinueDelKernelInput:-Y}

	if [[ $isContinueDelKernelInput == [Yy] ]]; then

        if [ -z $1 ]; then
            removeDebianKernel "linux-headers"
            removeDebianKernel "linux-modules"
            # removeDebianKernel "linux-kbuild"
            # removeDebianKernel "linux-compiler"
            # removeDebianKernel "linux-libc"
        else
            removeDebianKernel "linux-image"
        fi

    fi
}

function removeDebianKernel(){

    removeKernelNameText="linux-image"
    removeKernelNameText=$1
    grepExcludelinuxKernelVersion=$(echo ${linuxKernelToInstallVersionFull} | cut -d- -f1)

    echo
    green "===== 准备开始删除旧内核 ${removeKernelNameText} ${osKernelVersionBackup}, 当前要安装新内核版本为: ${grepExcludelinuxKernelVersion}"

    echo "dpkg --get-selections | grep ${removeKernelNameText} | grep -Ev '${grepExcludelinuxKernelVersion}|${removeKernelNameText}-amd64' | awk '{print \$1}' "
    rpmOldKernelNumber=$(dpkg --get-selections | grep "${removeKernelNameText}" | grep -Ev "${grepExcludelinuxKernelVersion}|${removeKernelNameText}-amd64" | wc -l)
    rpmOLdKernelNameList=$(dpkg --get-selections | grep "${removeKernelNameText}" | grep -Ev "${grepExcludelinuxKernelVersion}|${removeKernelNameText}-amd64" | awk '{print $1}' )
    # echo "$rpmOLdKernelNameList"

    # https://stackoverflow.com/questions/16212656/grep-exclude-multiple-strings
    # https://stackoverflow.com/questions/29269259/extract-value-of-column-from-a-line-variable

    
    if [ "${rpmOldKernelNumber}" -gt "0" ]; then
    
        red " 当前系统的旧内核 ${removeKernelNameText} ${osKernelVersionBackup} 有 ${rpmOldKernelNumber} 个需要删除"
        echo
        for((integer = 1; integer <= ${rpmOldKernelNumber}; integer++)); do   
            rpmOLdKernelName=$(awk "NR==${integer}" <<< "${rpmOLdKernelNameList}")
            green " 开始卸载第 ${integer} 个内核: ${rpmOLdKernelName}. 命令: apt remove --purge ${rpmOLdKernelName}"
            ${sudoCmd} apt remove -y --purge ${rpmOLdKernelName}
            green " 已卸载第 ${integer} 个内核 ${rpmOLdKernelName}"
            echo
        done
        green "===== 共 ${rpmOldKernelNumber} 个旧内核 ${removeKernelNameText} ${osKernelVersionBackup} 已经卸载完成"
    else
        red " 当前需要卸载的系统旧内核 ${removeKernelNameText} 数量为0 !" 
    fi

    echo

    ${sudoCmd} apt -y --purge autoremove
}






































function getGithubLatestReleaseVersion(){
    # https://github.com/p4gefau1t/trojan-go/issues/63
    wget --no-check-certificate -qO- https://api.github.com/repos/$1/tags | grep 'name' | cut -d\" -f4 | head -1 | cut -b 2-
}






# https://unix.stackexchange.com/questions/8656/usr-bin-vs-usr-local-bin-on-linux

versionWgcf="2.2.3"
downloadFilenameWgcf="wgcf_${versionWgcf}_linux_amd64"
configWgcfBinPath="/usr/local/bin"
configWgcfConfigFilePath="${HOME}/wireguard"
configWgcfAccountFilePath="${configWgcfConfigFilePath}/wgcf-account.toml"
configWgcfProfileFilePath="${configWgcfConfigFilePath}/wgcf-profile.conf"
configWireGuardConfigFileFolder="/etc/wireguard"
configWireGuardConfigFilePath="/etc/wireguard/wgcf.conf"

function installWireguard(){

    versionWgcf=$(getGithubLatestReleaseVersion "ViRb3/wgcf")
    downloadFilenameWgcf="wgcf_${versionWgcf}_linux_amd64"

    green " =================================================="
    green "    开始安装 WireGuard 和 Cloudflare Warp 命令行工具 Wgcf ${versionWgcf} !"
    echo
    red " 如果是新的干净的没有换过内核的系统(例如没有安装过BBR Plus内核), 不要退出安装其他内核, 直接继续安装 WireGuard"
    red " 如果安装过其他内核(例如安装过BBR Plus内核), 建议先安装高于5.6以上的内核, 低于5.6的内核也可以继续安装, 但有几率无法启动 WireGuard"
    red " 如遇到 WireGuard 启动失败, 建议重做新系统后, 不要更换其他内核, 直接安装WireGuard"
    green " =================================================="
    echo

    isKernelSupportWireGuardVersion="5.6"
    isKernelBuildInWireGuardModule="no"

    if versionCompareWithOp "${isKernelSupportWireGuardVersion}" "${osKernelVersionShort}" ">"; then
        red " 当前系统内核为 ${osKernelVersionShort}, 低于5.6的系统内核没有内置 WireGuard Module !"
        isKernelBuildInWireGuardModule="no"
    else
        green " 当前系统内核为 ${osKernelVersionShort}, 系统内核已内置 WireGuard Module"
        isKernelBuildInWireGuardModule="yes"
    fi

    
	read -p "是否继续操作? 请确认linux内核已正确安装 直接回车默认继续操作, 请输入[Y/n]:" isContinueInput
	isContinueInput=${isContinueInput:-Y}

	if [[ ${isContinueInput} == [Yy] ]]; then
		echo ""
        green " 开始安装 WireGuard Tools "
	else 
        green " 建议请先用本脚本安装 linux kernel 5.6 以上的内核 !"
		exit
	fi
    echo

    if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
            ${sudoCmd} apt-get update
            ${sudoCmd} apt install -y wireguard

            ln -s /usr/bin/resolvectl /usr/local/bin/resolvconf

            ${sudoCmd} systemctl enable systemd-resolved.service
            ${sudoCmd} systemctl start systemd-resolved.service

    elif [[ "${osRelease}" == "centos" ]]; then
    
        if [[ ${isKernelBuildInWireGuardModule} == "yes" ]]; then

            green " 当前系统内核版本高于5.6, 直接安装 kmod-wireguard "

            if [ "${osReleaseVersionNo}" -eq 7 ]; then
                ${sudoCmd} yum install -y yum-plugin-elrepo
            fi

            ${sudoCmd} yum install -y epel-release elrepo-release 
            ${sudoCmd} yum install -y kmod-wireguard wireguard-tools
        else 
            
            if [ "${osReleaseVersionNo}" -eq 7 ]; then
                if [[ ${osKernelVersionBackup} == *"3.10."* ]]; then
                    green " 当前系统内核版本为原版Centos 7 ${osKernelVersionBackup} , 直接安装 kmod-wireguard "
                    ${sudoCmd} yum install -y yum-plugin-elrepo
                    ${sudoCmd} yum install -y epel-release elrepo-release 
                    ${sudoCmd} yum install -y kmod-wireguard wireguard-tools
                else
                    green " 当前系统内核版本低于5.6 , 安装 wireguard-dkms "
                    ${sudoCmd} yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
                    ${sudoCmd} curl -o /etc/yum.repos.d/jdoss-wireguard-epel-7.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
                    ${sudoCmd} yum install -y wireguard-dkms wireguard-tools
                fi
            else
                if [[ ${osKernelVersionBackup} == *"4.18."* ]]; then
                    green " 当前系统内核版本为原版Centos 8 ${osKernelVersionBackup} , 直接安装 kmod-wireguard "
                    ${sudoCmd} yum install -y epel-release elrepo-release 
                    ${sudoCmd} yum install -y kmod-wireguard wireguard-tools
                else
                    green " 当前系统内核版本低于5.6 , 安装 wireguard-dkms "
                    ${sudoCmd} yum install -y epel-release
                    ${sudoCmd} yum config-manager --set-enabled PowerTools
                    ${sudoCmd} yum copr enable jdoss/wireguard
                    ${sudoCmd} yum install -y wireguard-dkms wireguard-tools
                fi

            fi
        fi
    fi


    echo
    green " =================================================="
    green " 开始安装 Cloudflare Warp 命令行工具 Wgcf "
    echo

    mkdir -p ${configWgcfConfigFilePath}
    mkdir -p ${configWgcfBinPath}
    mkdir -p ${configWireGuardConfigFileFolder}

    cd ${configWgcfConfigFilePath}

    # https://github.com/ViRb3/wgcf/releases/download/v2.2.2/wgcf_2.2.2_linux_amd64
    wget -O ${configWgcfConfigFilePath}/wgcf --no-check-certificate "https://github.com/ViRb3/wgcf/releases/download/v${versionWgcf}/${downloadFilenameWgcf}"
    

    if [[ -f ${configWgcfConfigFilePath}/wgcf ]]; then
        ${sudoCmd} chmod +x ${configWgcfConfigFilePath}/wgcf
        cp ${configWgcfConfigFilePath}/wgcf ${configWgcfBinPath}

        green " Cloudflare Warp 命令行工具 Wgcf ${versionWgcf} 下载成功!"
        echo
        # ${configWgcfConfigFilePath}/wgcf register --config "${configWgcfAccountFilePath}"

        ${configWgcfConfigFilePath}/wgcf register 
        ${configWgcfConfigFilePath}/wgcf generate 

        sed -i '/AllowedIPs = 0\.0\.0\.0/d' ${configWgcfProfileFilePath}
        sed -i 's/engage\.cloudflareclient\.com/162\.159\.192\.1/g'  ${configWgcfProfileFilePath}

    else
        red "  Wgcf ${versionWgcf} 下载失败!"
        exit 255
    fi


    echo "nameserver 8.8.8.8" >>  /etc/resolv.conf
    # echo "nameserver 8.8.4.4" >>  /etc/resolv.conf
    # echo "nameserver 1.1.1.1" >>  /etc/resolv.conf
    # echo "nameserver 9.9.9.9" >>  /etc/resolv.conf
    # echo "nameserver 9.9.9.10" >>  /etc/resolv.conf


    cp ${configWgcfProfileFilePath} ${configWireGuardConfigFilePath}

    echo 
    green "  开始启动 Wireguard, 运行命令: wg-quick up wgcf"
    ${sudoCmd} wg-quick up wgcf

    echo 
    green "  开始验证 Wireguard 是否启动正常 检测是否使用 CLOUDFLARE 的 ipv6 访问 !"
    echo
    echo "curl -6 ip.p3terx.com"
    curl -6 ip.p3terx.com 
    echo
    
    isWireguardIpv6Working=$(curl -6 ip.p3terx.com | grep CLOUDFLARENET )
    sleep 3
    ${sudoCmd} wg-quick down wgcf

    
	if [[ -n "$isWireguardIpv6Working" ]]; then	
		green " Wireguard 启动正常! "
        echo
	else 
		green " ================================================== "
		red " Wireguard 通过 curl -6 ip.p3terx.com, 检测使用CLOUDFLARENET的IPV6 访问失败"
        red " 请检查linux 内核安装是否正确"
        red " 安装会继续运行, 也有可能安装成功, 只是IPV6 没有使用"
        red " 检查 WireGuard 是否启动成功, 可运行查看运行状态命令: systemctl status wg-quick@wgcf"
        red " 如果 WireGuard 启动失败, 可运行查看日志命令 寻找原因: journalctl -n 50 -u wg-quick@wgcf"
        red " 如遇到 WireGuard 启动失败, 建议重做新系统后, 不要更换其他内核, 直接安装WireGuard"
		green " ================================================== "
	fi


    ${sudoCmd} systemctl daemon-reload
    
    # 设置开机启动
    ${sudoCmd} systemctl enable wg-quick@wgcf

    # 启用守护进程
    ${sudoCmd} systemctl start wg-quick@wgcf


    green " ================================================== "
    green "  Wireguard 和 Cloudflare Warp 命令行工具 Wgcf ${versionWgcf} 安装成功 !"
    green "  Wireguard 停止命令: systemctl stop wg-quick@wgcf  启动命令: systemctl start wg-quick@wgcf  重启命令: systemctl restart wg-quick@wgcf"
    green "  Wireguard 查看日志: journalctl -n 50 -u wg-quick@wgcf 查看运行状态: systemctl status wg-quick@wgcf"
    
    green "  用本脚本安装v2ray或xray 可以选择是否解除 google 验证码 和 Netflix 的限制 !"
    green "  其他脚本安装的v2ray或xray 请自行替换 v2ray或xray 配置文件!"
    green " ================================================== "
    
}


function removeWireguard(){
    green " ================================================== "
    red " 准备卸载已安装 Wireguard 和 Cloudflare Warp 命令行工具 Wgcf "
    green " ================================================== "

    if [[ -f "${configWgcfBinPath}/wgcf" || -f "${configWgcfConfigFilePath}/wgcf" || -f "/wgcf" ]]; then
        ${sudoCmd} systemctl stop wg-quick@wgcf.service
        ${sudoCmd} systemctl disable wg-quick@wgcf.service
    else 
        red " 系统没有安装 Wireguard 和 Wgcf, 退出卸载"
        echo
        exit
    fi

    $osSystemPackage -y remove kmod-wireguard
    $osSystemPackage -y remove wireguard-dkms
    $osSystemPackage -y remove wireguard-tools
    $osSystemPackage -y remove wireguard

    rm -f ${configWgcfBinPath}/wgcf
    rm -rf ${configWgcfConfigFilePath}
    rm -rf ${configWireGuardConfigFileFolder}

    rm -f ${osSystemMdPath}wg-quick@wgcf.service

    rm -f /usr/bin/wg
    rm -f /usr/bin/wg-quick
    rm -f /usr/share/man/man8/wg.8
    rm -f /usr/share/man/man8/wg-quick.8

    [ -d "/etc/wireguard" ] && ("rm -rf /etc/wireguard")

    sed -i '/nameserver 8.8.8.8/d' /etc/resolv.conf


    modprobe -r wireguard

    green " ================================================== "
    green "  Wireguard 和 Cloudflare Warp 命令行工具 Wgcf 卸载完毕 !"
    green " ================================================== "

  
}

































function start_menu(){
    clear
    
    if [[ $1 == "first" ]] ; then
        getLinuxOSRelease
        installSoftDownload
    fi
    showLinuxKernelInfoNoDisplay

    green " =================================================="
    green " Linux 内核 一键安装脚本 | 2021-04-15 | By jinwyp | 系统支持：centos7+ / debian10+ / ubuntu16.04+"
    green " Linux 内核 4.9 以上都支持开启BBR, 如要开启BBR Plus 则需要安装支持BBR Plus的内核 "
    red " *在任何生产环境中请谨慎使用此脚本, 升级内核有风险, 请做好备份！在某些VPS会导致无法启动! "
    green " =================================================="
    if [ -z $1 ]; then
        echo -e " 当前系统内核: ${osKernelVersionBackup} (${virtual})   ${Red_font_prefix}未安装 BBR 或 BBR Plus ${Font_color_suffix} 加速内核, 请先安装4.9以上内核 "
    else
        if [ ${systemBBRRunningStatus} = "no" ]; then
            echo -e " 当前系统内核: ${osKernelVersionBackup} (${virtual})   ${Green_font_prefix}已安装 ${osKernelBBRStatus}${Font_color_suffix} 加速内核, ${Red_font_prefix}${systemBBRRunningStatusText}${Font_color_suffix} "
        else
            echo -e " 当前系统内核: ${osKernelVersionBackup} (${virtual})   ${Green_font_prefix}已安装 ${osKernelBBRStatus}${Font_color_suffix} 加速内核, ${Green_font_prefix}${systemBBRRunningStatusText}${Font_color_suffix} "
        fi
        
    fi  
    echo -e " 当前拥塞控制算法: ${Green_font_prefix}${net_congestion_control}${Font_color_suffix}   当前队列算法: ${Green_font_prefix}${net_qdisc}${Font_color_suffix} "

    echo
    green " 1. 查看当前系统内核版本, 检查是否支持BBR"
    green " 2. 开启 BBR 加速"
    green " 3. 开启 BBR Plus 加速"
    echo
    green " 6. 安装 WireGuard 和 Cloudflare Warp, 用于解锁 google 验证码 和 Netflix 限制"
    red " 7. 卸载 WireGuard" 
    echo

    if [[ "${osRelease}" == "centos" ]]; then
    green " 11. 安装 最新版本内核 5.11, 通过elrepo源安装"
    green " 12. 安装 最新版本LTS内核 5.4 LTS, 通过elrepo源安装"
    echo
    green " 13. 安装 内核 4.14 LTS"
    green " 14. 安装 内核 4.19 LTS"
    green " 15. 安装 内核 5.4 LTS"
    green " 16. 安装 内核 5.10 LTS, Teddysun 编译 推荐安装此内核"

    elif [[ "${osRelease}" == "debian" ]]; then
    green " 21. 安装 最新版本LTS内核 5.10 LTS, 通过 Debian 官方源安装"
    echo
    green " 22. 安装 最新版本内核 5.11, 通过 Ubuntu kernel mainline 安装"
    green " 23. 安装 内核 4.19 LTS, 通过 Ubuntu kernel mainline 安装"
    green " 24. 安装 内核 5.4 LTS, 通过 Ubuntu kernel mainline 安装"
    green " 25. 安装 内核 5.10 LTS, 通过 Ubuntu kernel mainline 安装"

    elif [[ "${osRelease}" == "ubuntu" ]]; then
    green " 22. 安装 最新版本内核 5.11, 通过 Ubuntu kernel mainline 安装"
    green " 23. 安装 内核 4.19 LTS, 通过 Ubuntu kernel mainline 安装"
    green " 24. 安装 内核 5.4 LTS, 通过 Ubuntu kernel mainline 安装"
    green " 25. 安装 内核 5.10 LTS, 通过 Ubuntu kernel mainline 安装"
    fi

    echo
    green " 31. 安装 BBR Plus 内核 4.14.129 LTS, cx9208 编译的 dog250 原版, 推荐使用"
    green " 32. 安装 BBR Plus 内核 4.9 LTS, UJX6N 编译"
    green " 33. 安装 BBR Plus 内核 4.14 LTS, UJX6N 编译"
    green " 34. 安装 BBR Plus 内核 4.19 LTS, UJX6N 编译"
    green " 35. 安装 BBR Plus 内核 5.4 LTS, UJX6N 编译"
    green " 36. 安装 BBR Plus 内核 5.9, UJX6N 编译"
    green " 37. 安装 BBR Plus 内核 5.10 LTS, UJX6N 编译"    
    echo
    green " =================================================="
    green " 0. 退出脚本"
    echo
    read -p "请输入数字:" menuNumberInput
    case "$menuNumberInput" in
        1 )
            showLinuxKernelInfo
            listInstalledLinuxKernel
        ;;   
        2 )
           enableBBRSysctlConfig "bbr"
        ;;
        3 )
           enableBBRSysctlConfig "bbrplus"
        ;;        
        6 )
           installWireguard
        ;;
        7 )
           removeWireguard
        ;;    
        11 )
            linuxKernelToInstallVersion="5.11"
            isInstallFromRepo="yes"
            installKernel
        ;;
        12 )
            linuxKernelToInstallVersion="5.4"
            isInstallFromRepo="yes"
            installKernel
        ;;
        13 )
            linuxKernelToInstallVersion="4.14"
            installKernel
        ;;
        14 ) 
            linuxKernelToInstallVersion="4.19"
            installKernel
        ;;
        15 )
            linuxKernelToInstallVersion="5.4"
            installKernel
        ;;
        16 )
            linuxKernelToInstallVersion="5.10"
            installKernel
        ;;
        21 )
            linuxKernelToInstallVersion="5.10"
            isInstallFromRepo="yes"
            installKernel
        ;;
        22 )
            linuxKernelToInstallVersion="5.11"
            installKernel
        ;;
        23 ) 
            linuxKernelToInstallVersion="4.19"
            installKernel
        ;;
        24 )
            linuxKernelToInstallVersion="5.4"
            installKernel
        ;;
        25 )
            linuxKernelToInstallVersion="5.10"
            installKernel
        ;;                
        31 )
            linuxKernelToInstallVersion="4.14.129"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        32 )
            linuxKernelToInstallVersion="4.9"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        33 )
            linuxKernelToInstallVersion="4.14"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        34 )
            linuxKernelToInstallVersion="4.19"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        35 )
            linuxKernelToInstallVersion="5.4"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        36 )
            linuxKernelToInstallVersion="5.9"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        37 )
            linuxKernelToInstallVersion="5.10"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        88 )
            getLatestUbuntuKernelVersion
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
