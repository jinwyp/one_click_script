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
# ubuntu16 安装完成默认内核  linux-generic 4.4.0.210, linux-headers-4.4.0-210
# ubuntu18 安装完成默认内核  linux-generic 4.15.0.140, linux-headers-4.15.0-140
# ubuntu20 安装完成默认内核  linux-image-5.4.0-70-generic , linux-headers-5.4.0-70
# debian10 安装完成默认内核  4.19.0-16-amd64
# debian11 安装完成默认内核  linux-image-5.10.0-8-amd64

# UJX6N 编译的bbr plus 内核  5.10.27-bbrplus    5.9.16    5.4.86
# UJX6N 编译的bbr plus 内核  4.19.164   4.14.213    4.9.264-1.bbrplus
# https://github.com/cx9208/bbrplus/issues/27


# BBR 速度评测
# https://www.shopee6.com/web/web-tutorial/bbr-vs-plus-vs-bbr2.html
# https://hostloc.com/thread-644985-1-1.html

# https://dropbox.tech/infrastructure/evaluating-bbrv2-on-the-dropbox-edge-network



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

Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"





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
    virt_check

    [[ -z $(echo $SHELL|grep zsh) ]] && osSystemShell="bash" || osSystemShell="zsh"

    echo "OS info: ${osInfo}, ${osRelease}, ${osReleaseVersion}, ${osReleaseVersionNo}, ${osReleaseVersionCodeName}, ${osSystemShell}, ${osSystemPackage}, ${osSystemMdPath}"
}


virt_check(){
	# if hash ifconfig 2>/dev/null; then
		# eth=$(ifconfig)
	# fi

	virtualx=$(dmesg) 2>/dev/null


    if  [ "$(command -v dmidecode)" ]; then
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

        PACKAGE_LIST=( "wget" "curl" "git" "unzip" "apt-transport-https" "cpu-checker" "bc" "cron" )

        # 检查所有软件包是否已安装
        for package in "${PACKAGE_LIST[@]}"; do
            if ! dpkg -l | grep -qw "$package"; then
                # green "$package is not installed. ${osSystemPackage} Installing..."
                ${osSystemPackage} install -y "$package"
            fi
        done

		if ! dpkg -l | grep -qw curl; then
			${osSystemPackage} -y install wget curl git

            if [[ "${osRelease}" == "debian" ]]; then
                echo "deb http://deb.debian.org/debian buster-backports main contrib non-free" > /etc/apt/sources.list.d/buster-backports.list
                echo "deb-src http://deb.debian.org/debian buster-backports main contrib non-free" >> /etc/apt/sources.list.d/buster-backports.list
                ${sudoCmd} apt update -y
            fi

		fi

        if ! dpkg -l | grep -qw ca-certificates; then
			${osSystemPackage} -y install ca-certificates dmidecode
            update-ca-certificates
		fi

	elif [[ "${osRelease}" == "centos" ]]; then

        PACKAGE_LIST_Centos=( "wget" "curl" "git" "unzip" "bc" )

        # 检查所有软件包是否已安装
        for package in "${PACKAGE_LIST_Centos[@]}"; do
            if ! rpm -qa | grep -qw "$package"; then
                # green "$package is not installed. ${osSystemPackage} Installing..."
                ${osSystemPackage} install -y "$package"
            fi
        done

        # 处理ca证书
        if ! rpm -qa | grep -qw ca-certificates; then
			${osSystemPackage} -y install ca-certificates dmidecode
            update-ca-trust force-enable
		fi
	fi

}










# 更新本脚本
function upgradeScript(){
    wget -Nq --no-check-certificate -O ./install_kernel.sh "https://raw.githubusercontent.com/jinwyp/one_click_script/master/install_kernel.sh"
    green " Script upgrade successful. 本脚本升级成功! "
    chmod +x ./install_kernel.sh
    sleep 2s
    exec "./install_kernel.sh"
}









function rebootSystem(){

    if [ -z $1 ]; then

        red "请检查上面的信息 是否有新内核版本, 老内核版本 ${osKernelVersionBackup} 是否已经卸载!"
        echo
        red "请注意检查 是否把新内核也误删卸载了, 无新内核 ${linuxKernelToInstallVersionFull} 不要重启, 可重新安装内核后再重启! "

    fi

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
		exit 1
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
















osKernelVersionFull=$(uname -r)
osKernelVersionBackup=$(uname -r | awk -F "-" '{print $1}')
osKernelVersionShort=$(uname -r | cut -d- -f1 | awk -F "." '{print $1"."$2}')
osKernelBBRStatus=""
systemBBRRunningStatus="no"
systemBBRRunningStatusText=""

function listAvailableLinuxKernel(){
    echo
    green " =================================================="
    green " 状态显示--当前可以被安装的 Linux 内核: "
    if [[ "${osRelease}" == "centos" ]]; then
		${sudoCmd} yum --disablerepo="*" --enablerepo="elrepo-kernel" list available | grep kernel
	else
        if [ -z $1 ]; then
            ${sudoCmd} apt-cache search linux-image
        else
            ${sudoCmd} apt-cache search linux-image | grep $1
        fi
	fi

    green " =================================================="
    echo
}

function listInstalledLinuxKernel(){
    echo
    green " =================================================="
    green " 状态显示--当前已安装的 Linux 内核: "
    echo

	if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
        dpkg --get-selections | grep linux-
		# dpkg -l | grep linux-
        # dpkg-query -l | grep linux-
        # apt list --installed | grep linux-
        echo
        red " 如安装内核遇到kernel linux-image linux-headers 版本不一致问题, 请手动卸载已安装的kernel"
        red " 卸载内核命令1 apt remove -y --purge linux-xxx名称"
        red " 卸载内核命令2 apt autoremove -y --purge linux-xxx名称"

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

    if [[ ${osKernelVersionFull} == *"bbrplus"* ]]; then
        osKernelBBRStatus="BBR Plus"
    elif [[ ${osKernelVersionFull} == *"xanmod"* ]]; then
        osKernelBBRStatus="BBR 和 BBR2"
    fi

	net_congestion_control=`cat /proc/sys/net/ipv4/tcp_congestion_control | awk '{print $1}'`
	net_qdisc=`cat /proc/sys/net/core/default_qdisc | awk '{print $1}'`
	net_ecn=`cat /proc/sys/net/ipv4/tcp_ecn | awk '{print $1}'`

    if [[ ${osKernelVersionBackup} == *"4.14.129"* ]]; then
        # isBBREnabled=$(grep "net.ipv4.tcp_congestion_control" /etc/sysctl.conf | awk -F "=" '{print $2}')
        # isBBREnabled=$(sysctl net.ipv4.tcp_available_congestion_control | awk -F "=" '{print $2}')

        isBBRTcpEnabled=$(lsmod | grep "bbr" | awk '{print $1}')
        isBBRPlusTcpEnabled=$(lsmod | grep "bbrplus" | awk '{print $1}')
        isBBR2TcpEnabled=$(lsmod | grep "bbr2" | awk '{print $1}')
    else
        isBBRTcpEnabled=$(sysctl net.ipv4.tcp_congestion_control | grep "bbr" | awk -F "=" '{print $2}' | awk '{$1=$1;print}')
        isBBRPlusTcpEnabled=$(sysctl net.ipv4.tcp_congestion_control | grep "bbrplus" | awk -F "=" '{print $2}' | awk '{$1=$1;print}')
        isBBR2TcpEnabled=$(sysctl net.ipv4.tcp_congestion_control | grep "bbr2" | awk -F "=" '{print $2}' | awk '{$1=$1;print}')
    fi

    if [[ ${net_ecn} == "1" ]]; then
        systemECNStatusText="已开启"
    elif [[ ${net_ecn} == "0" ]]; then
        systemECNStatusText="已关闭"
    elif [[ ${net_ecn} == "2" ]]; then
        systemECNStatusText="只对入站请求开启(默认值)"
    else
        systemECNStatusText=""
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

    elif [[ ${net_congestion_control} == "bbr2" ]]; then

        if [[ ${isBBR2TcpEnabled} == *"bbr2"* ]]; then
            systemBBRRunningStatus="bbr2"
            systemBBRRunningStatusText="BBR2 已启动成功"
        else
            systemBBRRunningStatusText="BBR2 启动失败"
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
        green "           当前系统内核低于4.9, 不支持开启 BBR "
    else
        green "           当前系统内核高于4.9, 支持开启 BBR, ${systemBBRRunningStatusText}"
    fi

    if [[ ${osKernelVersionFull} == *"xanmod"* ]]; then
        green "           当前系统内核已支持开启 BBR2, ${systemBBRRunningStatusText}"
    else
        green "           当前系统内核不支持开启 BBR2"
    fi

    if [[ ${osKernelVersionFull} == *"bbrplus"* ]]; then
        green "           当前系统内核已支持开启 BBR Plus, ${systemBBRRunningStatusText}"
    else
        green "           当前系统内核不支持开启 BBR Plus"
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


function enableBBRSysctlConfig(){
    # https://hostloc.com/thread-644985-1-1.html
    # 优质线路用5.5+cake和原版bbr带宽跑的更足，不过cake的话就算高峰也不会像原版bbr那样跑不动，相比plus能慢些，但是区别不大，
    # bbr plus的话美西或者一些延迟高的，用起来更好，锐速针对丢包高的有奇效
    # 带宽大，并且延迟低不丢包的话5.5+cake在我这比较好，延迟高用plus更好，丢包多锐速最好. 一般130ms以下用cake不错，以上的话用plus更好些

    # https://github.com/xanmod/linux/issues/26
    # 说白了 bbrplus 就是改了点东西，然后那部分修改在 5.1 内核里合并进去了, 5.1 及以上的内核里自带的 bbr 已经包含了所谓的 bbrplus 的修改。
    # PS：bbr 是一直在修改的，比如说 5.0 内核的 bbr，4.15 内核的 bbr 和 4.9 内核的 bbr 其实都是不一样的

    # https://sysctl-explorer.net/net/ipv4/tcp_ecn/


    removeBbrSysctlConfig
    currentBBRText="bbr"
    currentQueueText="fq"
    currentECNValue="2"
    currentECNText=""

    if [ $1 = "bbrplus" ]; then
        currentBBRText="bbrplus"

    else
        echo
        echo " 请选择开启 (1) BBR 还是 (2) BBR2 网络加速 "
        red " 选择 1 BBR 需要内核在 4.9 以上"
        red " 选择 2 BBR2 需要内核为 XanMod "
        read -p "请选择? 直接回车默认选1 BBR, 请输入[1/2]:" BBRTcpInput
        BBRTcpInput=${BBRTcpInput:-1}
        if [[ $BBRTcpInput == [2] ]]; then
            if [[ ${osKernelVersionFull} == *"xanmod"* ]]; then
                currentBBRText="bbr2"

                echo
                echo " 请选择是否开启 ECN, (1) 关闭 (2) 开启 (3) 仅对入站请求开启 "
                red " 注意: 开启 ECN 可能会造成网络设备无法访问"
                read -p "请选择? 直接回车默认选1 关闭ECN, 请输入[1/2]:" ECNTcpInput
                ECNTcpInput=${ECNTcpInput:-1}
                if [[ $ECNTcpInput == [2] ]]; then
                    currentECNValue="1"
                    currentECNText="+ ECN"
                elif [[ $ECNTcpInput == [3] ]]; then
                    currentECNValue="2"
                else
                    currentECNValue="0"
                fi

            else
                echo
                red " 当前系统内核没有安装 XanMod 内核, 无法开启BBR2, 改为开启BBR"
                echo
                currentBBRText="bbr"
            fi

        else
            currentBBRText="bbr"
        fi
    fi

    echo
    echo " 请选择队列算法 (1) FQ,  (2) FQ-Codel,  (3) FQ-PIE,  (4) CAKE "
    red " 选择 2 FQ-Codel 队列算法 需要内核在 4.13 以上"
    red " 选择 3 FQ-PIE 队列算法 需要内核在 5.6 以上"
    red " 选择 4 CAKE 队列算法 需要内核在 5.5 以上"
    read -p "请选择队列算法? 直接回车默认选1 FQ, 请输入[1/2/3/4]:" BBRQueueInput
    BBRQueueInput=${BBRQueueInput:-1}

    if [[ $BBRQueueInput == [2] ]]; then
        currentQueueText="fq_codel"

    elif [[ $BBRQueueInput == [3] ]]; then
        currentQueueText="fq_pie"

    elif [[ $BBRQueueInput == [4] ]]; then
        currentQueueText="cake"

    else
        currentQueueText="fq"
    fi

    echo "net.core.default_qdisc=${currentQueueText}" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=${currentBBRText}" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_ecn=${currentECNValue}" >> /etc/sysctl.conf

    isSysctlText=$(sysctl -p 2>&1 | grep "No such file")

    echo
    if [[ -z "$isSysctlText" ]]; then
		green " 已成功开启 ${currentBBRText} + ${currentQueueText} ${currentECNText} "
	else
        green " 已成功开启 ${currentBBRText} ${currentECNText}"
        red " 但当前内核版本过低, 开启队列算法 ${currentQueueText} 失败! "
        red "请重新运行脚本, 选择'2 开启 BBR 加速'后, 务必再选择 (1)FQ 队列算法 !"
    fi
    echo


    read -p "是否优化系统网络配置? 直接回车默认优化, 请输入[Y/n]:" isOptimizingSystemInput
    isOptimizingSystemInput=${isOptimizingSystemInput:-Y}

    if [[ $isOptimizingSystemInput == [Yy] ]]; then
        addOptimizingSystemConfig "cancel"
    else
        echo
        echo "sysctl -p"
        echo
        sysctl -p
        echo
    fi

}

# 卸载 bbr+锐速 配置
function removeBbrSysctlConfig(){
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf

	sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf

	if [[ -e /appex/bin/lotServer.sh ]]; then
		bash <(wget --no-check-certificate -qO- https://git.io/lotServerInstall.sh) uninstall
	fi
}


function removeOptimizingSystemConfig(){
    removeBbrSysctlConfig

    sed -i '/fs.file-max/d' /etc/sysctl.conf
	sed -i '/fs.inotify.max_user_instances/d' /etc/sysctl.conf

	sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
	sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
	sed -i '/net.ipv4.route.gc_timeout/d' /etc/sysctl.conf

	sed -i '/net.ipv4.tcp_syn_retries/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_synack_retries/d' /etc/sysctl.conf
	sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
	sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_timestamps/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_max_orphans/d' /etc/sysctl.conf

	# sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf


    sed -i '/1000000/d' /etc/security/limits.conf
    sed -i '/1000000/d' /etc/profile

    echo
    green " 已删除当前系统的网络优化配置 "
    echo
}

function addOptimizingSystemConfig(){

    # https://ustack.io/2019-11-21-Linux%E5%87%A0%E4%B8%AA%E9%87%8D%E8%A6%81%E7%9A%84%E5%86%85%E6%A0%B8%E9%85%8D%E7%BD%AE.html
    # https://www.cnblogs.com/xkus/p/7463135.html

    # 优化系统配置

    if grep -q "1000000" "/etc/profile"; then
        echo
        green " 系统网络配置 已经优化过, 不需要再次优化 "
        echo
        sysctl -p
        echo
        exit
    fi

    if [ -z $1 ]; then
        removeOptimizingSystemConfig
    fi



    echo
    green " 开始准备 优化系统网络配置 "

    cat >> /etc/sysctl.conf <<-EOF

fs.file-max = 1000000
fs.inotify.max_user_instances = 8192

net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.route.gc_timeout = 100

net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 32768
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_max_orphans = 32768

# forward ipv4
#net.ipv4.ip_forward = 1


EOF



    cat >> /etc/security/limits.conf <<-EOF
*               soft    nofile          1000000
*               hard    nofile          1000000
EOF


	echo "ulimit -SHn 1000000" >> /etc/profile
    source /etc/profile


    echo
	sysctl -p

    echo
    green " 已完成 系统网络配置的优化 "
    echo
    rebootSystem "noinfo"

}



function startIpv4(){

    cat >> /etc/sysctl.conf <<-EOF
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_slow_start_after_idle = 0

# forward ipv4

net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0

net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

EOF

}




function Enable_IPv6_Support() {
    if [[ $(sysctl -a | grep 'disable_ipv6.*=.*1') || $(cat /etc/sysctl.{conf,d/*} | grep 'disable_ipv6.*=.*1') ]]; then
        sed -i '/disable_ipv6/d' /etc/sysctl.{conf,d/*}
        echo 'net.ipv6.conf.all.disable_ipv6 = 0' >/etc/sysctl.d/ipv6.conf
        sysctl -w net.ipv6.conf.all.disable_ipv6=0
    fi
}
































isInstallFromRepo="no"
userHomePath="${HOME}/download_linux_kernel"
linuxKernelByUser="elrepo"
linuxKernelToBBRType=""
linuxKernelToInstallVersion="5.15"
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
    preferIPV4

    if [ "${linuxKernelToBBRType}" = "bbrplus" ]; then
        getVersionBBRPlus
    fi

	if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
        installDebianUbuntuKernel

	elif [[ "${osRelease}" == "centos" ]]; then
        rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org

        if [ "${linuxKernelToBBRType}" = "xanmod" ]; then
            red " xanmod 内核不支持 Centos 系统安装"
            exit 255
        fi

        if [ "${isInstallFromRepo}" = "yes" ]; then
            getLatestCentosKernelVersion
            installCentosKernelFromRepo
        else
            if [ "${linuxKernelToBBRType}" = "bbrplus" ]; then
                echo
            else
                getLatestCentosKernelVersion "manual"
            fi

            installCentosKernelManual
        fi
	fi
}


function getVersionBBRPlus(){
    if [ "${linuxKernelToInstallVersion}" = "6.7" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus-6.x_stable")

    elif [ "${linuxKernelToInstallVersion}" = "6.6" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus-6.6")

    elif [ "${linuxKernelToInstallVersion}" = "6.1" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus-6.1")

    elif [ "${linuxKernelToInstallVersion}" = "5.19" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus-5.19")

    elif [ "${linuxKernelToInstallVersion}" = "5.15" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus-5.15")

    elif [ "${linuxKernelToInstallVersion}" = "5.10" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus-5.10")

    elif [ "${linuxKernelToInstallVersion}" = "5.4" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus-5.4")

    elif [ "${linuxKernelToInstallVersion}" = "4.19" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus-4.19")

    elif [ "${linuxKernelToInstallVersion}" = "4.14" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus")

    elif [ "${linuxKernelToInstallVersion}" = "4.9" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus-4.9")
    fi
    echo
    green "UJX6N 编译的 Linux bbrplus 内核版本号为 ${bbrplusKernelVersion}"
    echo

}

function getGithubLatestReleaseVersionBBRPlus(){
    wget --no-check-certificate -qO- https://api.github.com/repos/$1/tags | grep 'name' | cut -d\" -f4 | head -1 | cut -d- -f1
    # wget --no-check-certificate -qO- https://api.github.com/repos/UJX6N/bbrplus-5.14/tags | grep 'name' | cut -d\" -f4 | head -1 | cut -d- -f1
}


function getLatestCentosKernelVersion(){

    # https://stackoverflow.com/questions/4988155/is-there-a-bash-command-that-can-tell-the-size-of-a-shell-variable

    elrepo_kernel_version_lt_array=($(wget -qO- https://elrepo.org/linux/kernel/el8/x86_64/RPMS | awk -F'\"kernel-lt-' '/>kernel-lt-[4-9]./{print $2}' | cut -d- -f1 | sort -V))

    # echo ${elrepo_kernel_version_lt_array[@]}

    echo
    if [ ${#elrepo_kernel_version_lt_array[@]} -eq 0 ]; then
        red " 无法获取到 Centos elrepo 源的最新的Linux 内核 kernel-lt 版本号 "
    else
        # echo ${elrepo_kernel_version_lt_array[${#elrepo_kernel_version_lt_array[@]} - 1]}
        elrepo_kernel_version_lt=${elrepo_kernel_version_lt_array[${#elrepo_kernel_version_lt_array[@]} - 1]}
        green "Centos elrepo 源的最新的Linux 内核 kernel-lt 版本号为 ${elrepo_kernel_version_lt}"
    fi

    if [ -z $1 ]; then
        elrepo_kernel_version_ml_array=($(wget -qO- https://elrepo.org/linux/kernel/el8/x86_64/RPMS | awk -F'>kernel-ml-' '/>kernel-ml-[4-9]./{print $2}' | cut -d- -f1 | sort -V))

        if [ ${#elrepo_kernel_version_ml_array[@]} -eq 0 ]; then
            red " 无法获取到 Centos elrepo 源的最新的Linux 内核 kernel-ml 版本号 "
        else
            elrepo_kernel_version_ml=${elrepo_kernel_version_ml_array[-1]}
            green "Centos elrepo 源的最新的Linux 内核 kernel-ml 版本号为 ${elrepo_kernel_version_ml}"
        fi
    else
        elrepo_kernel_version_ml_teddysun_ftp_array=($(wget --no-check-certificate -qO- https://fr1.teddyvps.com/kernel/el8 | awk -F'>kernel-ml-' '/>kernel-ml-[4-9]./{print $2}' | cut -d- -f1 | sort -V))
        elrepo_kernel_version_ml_teddysun_ftp_array_lts=($(wget --no-check-certificate -qO- https://fr1.teddyvps.com/kernel/el8 | awk -F'>kernel-ml-' '/>kernel-ml-[4-9]./{print $2}'  | grep -v "elrepo" | cut -d- -f1 | sort -V))

        if [ ${#elrepo_kernel_version_ml_teddysun_ftp_array_lts[@]} -eq 0 ]; then
            red " 无法获取到由 Teddysun 编译的 Centos 最新的Linux 5.10 内核 kernel-ml 版本号 "
        else
            elrepo_kernel_version_ml=${elrepo_kernel_version_ml_teddysun_ftp_array[-1]}
            elrepo_kernel_version_ml_Teddysun_number_temp=$(echo ${elrepo_kernel_version_ml} | grep -oe "\.[0-9]*\." | grep -oe "[0-9]*" )
            elrepo_kernel_version_ml_Teddysun_number_temp_first=${elrepo_kernel_version_ml:0:1}

            if [[ ${elrepo_kernel_version_ml_Teddysun_number_temp_first} == "5" ]]; then
                elrepo_kernel_version_ml_Teddysun_latest_version_middle="19"
                elrepo_kernel_version_ml_Teddysun_latest_version="5.${elrepo_kernel_version_ml_Teddysun_latest_version_middle}"
            else
                elrepo_kernel_version_ml_Teddysun_latest_version_middle=$((elrepo_kernel_version_ml_Teddysun_number_temp-1))
                elrepo_kernel_version_ml_Teddysun_latest_version="6.${elrepo_kernel_version_ml_Teddysun_latest_version_middle}"
            fi




            # https://stackoverflow.com/questions/229551/how-to-check-if-a-string-contains-a-substring-in-bash
            for ver in "${elrepo_kernel_version_ml_teddysun_ftp_array_lts[@]}"; do

                if [[ ${ver} == *"5.10"* ]]; then
                    # echo "符合所选版本的Linux 5.10 内核版本: ${ver}"
                    elrepo_kernel_version_ml_Teddysun510=${ver}
                fi

                if [[ ${ver} == *"5.15"* ]]; then
                    # echo "符合所选版本的Linux 5.15 内核版本: ${ver}"
                    elrepo_kernel_version_ml_Teddysun515=${ver}
                fi

                if [[ ${ver} == *"6.1"* ]]; then
                    # echo "符合所选版本的Linux 6.1 内核版本: ${ver}"
                    elrepo_kernel_version_ml_Teddysun61=${ver}
                fi

                if [[ ${ver} == *"${elrepo_kernel_version_ml_Teddysun_latest_version}"* ]]; then
                    # echo "符合所选版本的Linux 内核版本: ${ver}, ${elrepo_kernel_version_ml_Teddysun_latest_version}"
                    elrepo_kernel_version_ml_Teddysun_latest=${ver}
                fi

            done

            green "Centos elrepo 源的最新的Linux 内核 kernel-ml 版本号为 ${elrepo_kernel_version_ml}"
            green "由 Teddysun 编译的 Centos 最新的Linux 5.15 LTS 内核 kernel-ml 版本号为 ${elrepo_kernel_version_ml_Teddysun515}"
            green "由 Teddysun 编译的 Centos 最新的Linux 6.1 LTS 内核 kernel-ml 版本号为 ${elrepo_kernel_version_ml_Teddysun61}"
            green "由 Teddysun 编译的 Centos 最新的Linux 6.xx 内核 kernel-ml 版本号为 ${elrepo_kernel_version_ml_Teddysun_latest}"

        fi
    fi
    echo
}


function installCentosKernelFromRepo(){

    green " =================================================="
    green "    开始通过 elrepo 源安装 linux 内核, 不支持Centos6 "
    green " =================================================="

    if [ -n "${osReleaseVersionNoShort}" ]; then

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

        if [ "${osReleaseVersionNoShort}" -eq 7 ]; then
            # https://computingforgeeks.com/install-linux-kernel-5-on-centos-7/

            # https://elrepo.org/linux/kernel/
            # https://elrepo.org/linux/kernel/el7/x86_64/RPMS/

            ${sudoCmd} yum install -y yum-plugin-fastestmirror
            ${sudoCmd} yum install -y https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm

        elif [ "${osReleaseVersionNoShort}" -eq 8 ]; then
            # https://elrepo.org/linux/kernel/el8/x86_64/RPMS/

            ${sudoCmd} yum install -y yum-plugin-fastestmirror
            ${sudoCmd} yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm

        elif [ "${osReleaseVersionNoShort}" -eq 9 ]; then
            # https://elrepo.org/linux/kernel/el8/x86_64/RPMS/

            ${sudoCmd} yum install -y yum-plugin-fastestmirror
            ${sudoCmd} yum install -y https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm

        else
            green " =================================================="
            red "    不支持 Centos 7, 8, 9 以外的其他版本 安装 linux 内核"
            green " =================================================="
            exit 255
        fi

        removeCentosKernelMulti
        listAvailableLinuxKernel
        echo
        green " =================================================="
        green " 开始安装 linux 内核版本: ${linuxKernelToInstallVersionFull}"
        echo
        ${sudoCmd} yum -y --enablerepo=elrepo-kernel install ${elrepo_kernel_name}
        ${sudoCmd} yum -y --enablerepo=elrepo-kernel install ${elrepo_kernel_name}-{devel,headers,tools,tools-libs}

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
        green " 准备从 ${linuxKernelByUser} github 网站下载 bbrplus ${linuxKernelToInstallVersion} 的linux内核并安装 "
    else
        linuxKernelByUserTeddysun=""

        if [[ "${kernelVersionFirstletter}" == "5" || "${kernelVersionFirstletter}" == "6" ]]; then
            linuxKernelByUser="elrepo"

            if [[ "${linuxKernelToInstallVersion}" == "5.10" || "${linuxKernelToInstallVersion}" == "5.15" || "${linuxKernelToInstallVersion}" == "5.19" ]]; then
                linuxKernelByUserTeddysun="Teddysun"
            fi
        else
            linuxKernelByUser="altarch"
        fi

        if [ "${linuxKernelByUserTeddysun}" = "Teddysun" ]; then
            green " 准备从 Teddysun 网站下载 linux ${linuxKernelByUser} 内核并安装 "
        else
            green " 准备从 ${linuxKernelByUser} 网站下载linux内核并安装 "
        fi

    fi
    echo

    if [ "${linuxKernelByUser}" = "elrepo" ]; then
        # elrepo

        if [ "${linuxKernelToInstallVersion}" = "5.4" ]; then
            elrepo_kernel_name="kernel-lt"
            elrepo_kernel_version=${elrepo_kernel_version_lt}
            elrepo_kernel_filename="elrepo."
            ELREPODownloadUrl="https://elrepo.org/linux/kernel/el${osReleaseVersionNoShort}/x86_64/RPMS"

            # https://elrepo.org/linux/kernel/el7/x86_64/RPMS/
            # https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-lt-5.4.105-1.el7.elrepo.x86_64.rpm
            # https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-lt-tools-5.4.109-1.el7.elrepo.x86_64.rpm
            # https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-lt-tools-libs-5.4.109-1.el7.elrepo.x86_64.rpm

        elif [ "${linuxKernelToInstallVersion}" = "5.10" ]; then
            elrepo_kernel_name="kernel-ml"
            elrepo_kernel_version=${elrepo_kernel_version_ml_Teddysun510}
            elrepo_kernel_filename=""
            ELREPODownloadUrl="https://dl.lamp.sh/kernel/el${osReleaseVersionNoShort}"

            # https://dl.lamp.sh/kernel/el7/kernel-ml-5.10.37-1.el7.x86_64.rpm
            # https://dl.lamp.sh/kernel/el8/kernel-ml-5.10.27-1.el8.x86_64.rpm

        elif [ "${linuxKernelToInstallVersion}" = "5.15" ]; then
            elrepo_kernel_name="kernel-ml"
            elrepo_kernel_version=${elrepo_kernel_version_ml_Teddysun515}
            elrepo_kernel_filename=""
            ELREPODownloadUrl="https://dl.lamp.sh/kernel/el${osReleaseVersionNoShort}"

        elif [ "${linuxKernelToInstallVersion}" = "6.1" ]; then
            elrepo_kernel_name="kernel-ml"
            elrepo_kernel_version=${elrepo_kernel_version_ml_Teddysun61}
            elrepo_kernel_filename=""
            ELREPODownloadUrl="https://dl.lamp.sh/kernel/el${osReleaseVersionNoShort}"

        elif [ "${linuxKernelToInstallVersion}" = "${elrepo_kernel_version_ml_Teddysun_latest_version}" ]; then
            elrepo_kernel_name="kernel-ml"
            elrepo_kernel_version=${elrepo_kernel_version_ml_Teddysun_latest}
            elrepo_kernel_filename=""
            ELREPODownloadUrl="https://fr1.teddyvps.com/kernel/el${osReleaseVersionNoShort}"

            # https://fr1.teddyvps.com/kernel/el7/kernel-ml-5.12.14-1.el7.x86_64.rpm

        else
            elrepo_kernel_name="kernel-ml"
            elrepo_kernel_version=${elrepo_kernel_version_ml}
            elrepo_kernel_filename="elrepo."
            ELREPODownloadUrl="https://fr1.teddyvps.com/kernel/el${osReleaseVersionNoShort}"

            # https://fr1.teddyvps.com/kernel/el7/kernel-ml-5.13.0-1.el7.elrepo.x86_64.rpm
        fi

        linuxKernelToInstallVersionFull=${elrepo_kernel_version}

        mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
        cd ${userHomePath}/${linuxKernelToInstallVersionFull}

        echo
        echo "+++++++++++ elrepo_kernel_version ${elrepo_kernel_version}"
        echo

        if [ "${osReleaseVersionNoShort}" -eq 7 ]; then
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-${elrepo_kernel_version}-1.el7.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-devel-${elrepo_kernel_version}-1.el7.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-headers-${elrepo_kernel_version}-1.el7.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-tools-${elrepo_kernel_version}-1.el7.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-tools-libs-${elrepo_kernel_version}-1.el7.${elrepo_kernel_filename}x86_64.rpm

        elif [ "${osReleaseVersionNoShort}" -eq 8 ]; then

            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-devel-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-headers-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-core-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-modules-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-tools-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-tools-libs-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm

        elif [ "${osReleaseVersionNoShort}" -eq 9 ]; then
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-${elrepo_kernel_version}-1.el9.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-devel-${elrepo_kernel_version}-1.el9.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-headers-${elrepo_kernel_version}-1.el9.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-core-${elrepo_kernel_version}-1.el9.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-modules-${elrepo_kernel_version}-1.el9.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-modules-extra-${elrepo_kernel_version}-1.el9.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-tools-${elrepo_kernel_version}-1.el9.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-tools-libs-${elrepo_kernel_version}-1.el9.${elrepo_kernel_filename}x86_64.rpm

            # https://fr1.teddyvps.com/kernel/el9/kernel-ml-6.1.0-1.el9.elrepo.x86_64.rpm
            # https://fr1.teddyvps.com/kernel/el9/kernel-ml-modules-extra-6.1.0-1.el9.elrepo.x86_64.rpm
            # https://fr1.teddyvps.com/kernel/el9/kernel-ml-tools-libs-devel-6.1.0-1.el9.elrepo.x86_64.rpm
        fi


        removeCentosKernelMulti
        echo
        green " =================================================="
        green " 开始安装 linux 内核版本: ${linuxKernelToInstallVersionFull}"
        echo

        if [ "${osReleaseVersionNoShort}" -eq 8 ]; then
            rpm -ivh --force --nodeps ${elrepo_kernel_name}-core-${elrepo_kernel_version}-*.rpm
        fi

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

        if [ "${osReleaseVersionNoShort}" -eq 7 ]; then

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
        echo
        green " =================================================="
        green " 开始安装 linux 内核版本: ${linuxKernelToInstallVersionFull}"
        echo
        rpm -ivh --force --nodeps ${altarch_kernel_name}-core-${altarch_kernel_version}*
        rpm -ivh --force --nodeps ${altarch_kernel_name}-*
        # yum install -y kernel-*


    elif [ "${linuxKernelByUser}" = "cx9208" ]; then

        linuxKernelToInstallVersionFull="4.14.129-bbrplus"

        if [ "${osReleaseVersionNoShort}" -eq 7 ]; then
            mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
            cd ${userHomePath}/${linuxKernelToInstallVersionFull}

            # https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/bbrplus/centos/7/kernel-4.14.129-bbrplus.rpm
            # https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/bbrplus/centos/7/kernel-headers-4.14.129-bbrplus.rpm

            bbrplusDownloadUrl="https://raw.githubusercontent.com/cx9208/Linux-NetSpeed/master/bbrplus/centos/7"

            downloadFile ${bbrplusDownloadUrl}/kernel-${linuxKernelToInstallVersionFull}.rpm
            downloadFile ${bbrplusDownloadUrl}/kernel-headers-${linuxKernelToInstallVersionFull}.rpm

            removeCentosKernelMulti
            echo
            green " =================================================="
            green " 开始安装 linux 内核版本: ${linuxKernelToInstallVersionFull}"
            echo
            rpm -ivh --force --nodeps kernel-${linuxKernelToInstallVersionFull}.rpm
            rpm -ivh --force --nodeps kernel-headers-${linuxKernelToInstallVersionFull}.rpm
        else
            red "从 cx9208 的 github 网站没有找到 Centos 8 的 ${linuxKernelToInstallVersion} Kernel "
            exit 255
        fi

    elif [ "${linuxKernelByUser}" = "UJX6N" ]; then

        linuxKernelToInstallVersionFull="${bbrplusKernelVersion}-bbrplus"

        mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
        cd ${userHomePath}/${linuxKernelToInstallVersionFull}


        if [ "${linuxKernelToInstallVersion}" = "6.7" ]; then
            bbrplusDownloadUrl="https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/${linuxKernelToInstallVersionFull}"

        elif [ "${linuxKernelToInstallVersion}" = "4.14" ]; then
            bbrplusDownloadUrl="https://github.com/UJX6N/bbrplus/releases/download/${linuxKernelToInstallVersionFull}"

        else
            bbrplusDownloadUrl="https://github.com/UJX6N/bbrplus-${linuxKernelToInstallVersion}/releases/download/${linuxKernelToInstallVersionFull}"
        fi



        if [ "${osReleaseVersionNoShort}" -eq 7 ]; then

            # https://github.com/UJX6N/bbrplus-5.14/releases/download/5.14.15-bbrplus/CentOS-7_Required_kernel-bbrplus-5.14.15-1.bbrplus.el7.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.15/releases/download/5.15.86-bbrplus/CentOS-7_Required_kernel-5.15.86-bbrplus.el7.x86_64.rpm

            # https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/6.7.4-bbrplus/CentOS-7_Required_kernel-6.7.4-bbrplus.el7.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-6.1/releases/download/6.1.28-bbrplus/CentOS-7_Required_kernel-6.1.28-bbrplus.el7.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.76-bbrplus/CentOS-7_Required_kernel-bbrplus-5.10.76-1.bbrplus.el7.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.27-bbrplus/CentOS-7_Optional_kernel-bbrplus-devel-5.10.27-1.bbrplus.el7.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.27-bbrplus/CentOS-7_Optional_kernel-bbrplus-headers-5.10.27-1.bbrplus.el7.x86_64.rpm

            if [[ "${linuxKernelToInstallVersion}" == "5.10" || "${linuxKernelToInstallVersion}" == "5.15" || "${linuxKernelToInstallVersion}" == "6.1" || "${linuxKernelToInstallVersion}" == "6.6" || "${linuxKernelToInstallVersion}" == "6.7" ]]; then
                # https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/6.7.4-bbrplus/CentOS-7_Required_kernel-6.7.4-bbrplus.el7.x86_64.rpm
                # https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/6.7.4-bbrplus/CentOS-7_Optional_kernel-headers-6.7.4-bbrplus.el7.x86_64.rpm
                # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.16-bbrplus/CentOS-7_Required_kernel-5.10.162-bbrplus.el7.x86_64.rpm
                # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.162-bbrplus/CentOS-7_Optional_kernel-headers-5.10.162-bbrplus.el7.x86_64.rpm

                downloadFile ${bbrplusDownloadUrl}/CentOS-7_Required_kernel-${bbrplusKernelVersion}-bbrplus.el7.x86_64.rpm
                downloadFile ${bbrplusDownloadUrl}/CentOS-7_Optional_kernel-headers-${bbrplusKernelVersion}-bbrplus.el7.x86_64.rpm
            else
                # https://github.com/UJX6N/bbrplus-4.9/releases/download/4.9.337-bbrplus/CentOS-7_Optional_kernel-bbrplus-devel-4.9.337-1.bbrplus.el7.x86_64.rpm

                downloadFile ${bbrplusDownloadUrl}/CentOS-7_Required_kernel-bbrplus-${bbrplusKernelVersion}-1.bbrplus.el7.x86_64.rpm
                downloadFile ${bbrplusDownloadUrl}/CentOS-7_Optional_kernel-bbrplus-devel-${bbrplusKernelVersion}-1.bbrplus.el7.x86_64.rpm
                downloadFile ${bbrplusDownloadUrl}/CentOS-7_Optional_kernel-bbrplus-headers-${bbrplusKernelVersion}-1.bbrplus.el7.x86_64.rpm
            fi




            removeCentosKernelMulti
            echo
            green " =================================================="
            green " 开始安装 linux 内核版本: ${linuxKernelToInstallVersionFull}"
            echo
            rpm -ivh --force --nodeps CentOS-7_Required_kernel-bbrplus-${bbrplusKernelVersion}-1.bbrplus.el7.x86_64.rpm
            rpm -ivh --force --nodeps *.rpm
        else

            if [[ "${kernelVersionFirstletter}" == "5" || "${kernelVersionFirstletter}" == "6" ]]; then
                echo
            else
                red "从 UJX6N 的 github 网站没有找到 Centos 8 的 ${linuxKernelToInstallVersion} Kernel "
                exit 255
            fi

            # https://github.com/UJX6N/bbrplus-5.14/releases/download/5.14.18-bbrplus/CentOS-8_Required_kernel-bbrplus-core-5.14.18-1.bbrplus.el8.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.14/releases/download/5.14.18-bbrplus/CentOS-8_Required_kernel-bbrplus-modules-5.14.18-1.bbrplus.el8.x86_64.rpm


            # https://github.com/UJX6N/bbrplus-5.14/releases/download/5.14.18-bbrplus/CentOS-8_Optional_kernel-bbrplus-5.14.18-1.bbrplus.el8.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.14/releases/download/5.14.18-bbrplus/CentOS-8_Optional_kernel-bbrplus-devel-5.14.18-1.bbrplus.el8.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.14/releases/download/5.14.18-bbrplus/CentOS-8_Optional_kernel-bbrplus-headers-5.14.18-1.bbrplus.el8.x86_64.rpm

            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.27-bbrplus/CentOS-8_Optional_kernel-bbrplus-modules-5.10.27-1.bbrplus.el8.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.14/releases/download/5.14.18-bbrplus/CentOS-8_Optional_kernel-bbrplus-modules-extra-5.14.18-1.bbrplus.el8.x86_64.rpm


            if [[ "${linuxKernelToInstallVersion}" == "5.10" || "${linuxKernelToInstallVersion}" == "5.15" || "${linuxKernelToInstallVersion}" == "6.1" || "${linuxKernelToInstallVersion}" == "6.6" || "${linuxKernelToInstallVersion}" == "6.7" ]]; then
                # https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/6.7.4-bbrplus/CentOS-Stream-8_Required_kernel-6.7.4-bbrplus.el8.x86_64.rpm
                # https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/6.6.1-bbrplus/CentOS-Stream-8_Required_kernel-6.6.1-bbrplus.el8.x86_64.rpm
                # https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/6.4.3-bbrplus/CentOS-Stream-8_Required_kernel-6.4.3-bbrplus.el8.x86_64.rpm
                # https://github.com/UJX6N/bbrplus-6.1/releases/download/6.1.28-bbrplus/CentOS-Stream-8_Required_kernel-6.1.28-bbrplus.el8.x86_64.rpm
                # https://github.com/UJX6N/bbrplus-5.15/releases/download/5.15.86-bbrplus/CentOS-Stream-8_Required_kernel-5.15.86-bbrplus.el8.x86_64.rpm
                # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.162-bbrplus/CentOS-Stream-8_Optional_kernel-headers-5.10.162-bbrplus.el8.x86_64.rpm

                downloadFile ${bbrplusDownloadUrl}/CentOS-Stream-8_Required_kernel-${bbrplusKernelVersion}-bbrplus.el8.x86_64.rpm
                downloadFile ${bbrplusDownloadUrl}/CentOS-Stream-8_Optional_kernel-headers-${bbrplusKernelVersion}-bbrplus.el8.x86_64.rpm

            else
                # https://github.com/UJX6N/bbrplus-5.19/releases/download/5.19.17-bbrplus/CentOS-8_Required_kernel-bbrplus-core-5.19.17-1.bbrplus.el8.x86_64.rpm


                downloadFile ${bbrplusDownloadUrl}/CentOS-8_Required_kernel-bbrplus-core-${bbrplusKernelVersion}-1.bbrplus.el8.x86_64.rpm
                downloadFile ${bbrplusDownloadUrl}/CentOS-8_Required_kernel-bbrplus-modules-${bbrplusKernelVersion}-1.bbrplus.el8.x86_64.rpm

                downloadFile ${bbrplusDownloadUrl}/CentOS-8_Optional_kernel-bbrplus-${bbrplusKernelVersion}-1.bbrplus.el8.x86_64.rpm
                downloadFile ${bbrplusDownloadUrl}/CentOS-8_Optional_kernel-bbrplus-devel-${bbrplusKernelVersion}-1.bbrplus.el8.x86_64.rpm
                downloadFile ${bbrplusDownloadUrl}/CentOS-8_Optional_kernel-bbrplus-headers-${bbrplusKernelVersion}-1.bbrplus.el8.x86_64.rpm
                # downloadFile ${bbrplusDownloadUrl}/CentOS-8_Optional_kernel-bbrplus-modules-${bbrplusKernelVersion}-1.bbrplus.el8.x86_64.rpm
                downloadFile ${bbrplusDownloadUrl}/CentOS-8_Optional_kernel-bbrplus-modules-extra-${bbrplusKernelVersion}-1.bbrplus.el8.x86_64.rpm
            fi


            removeCentosKernelMulti
            echo
            green " =================================================="
            green " 开始安装 linux 内核版本: ${linuxKernelToInstallVersionFull}"
            echo
            rpm -ivh --force --nodeps CentOS-8_Required_kernel-bbrplus-core-${bbrplusKernelVersion}-1.bbrplus.el8.x86_64.rpm
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
    removeCentosKernelMulti "kernel"
    listInstalledLinuxKernel
    rebootSystem
}



function removeCentosKernelMulti(){
    listInstalledLinuxKernel

    if [ -z $1 ]; then
        red " 开始准备删除 kernel-header kernel-devel kernel-tools kernel-tools-libs 内核, 建议删除 "
    else
        red " 开始准备删除 kernel 内核, 建议删除 "
    fi

    red " 注意: 删除内核有风险, 可能会导致VPS无法启动, 请先做好备份! "
    read -p "是否删除内核? 直接回车默认删除内核, 请输入[Y/n]:" isContinueDelKernelInput
	isContinueDelKernelInput=${isContinueDelKernelInput:-Y}

    echo

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
    echo
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


    # echo "rpm -qa | grep ${removeKernelNameText} | grep -v ${grepExcludelinuxKernelVersion} | grep -v noarch | wc -l"
    rpmOldKernelNumber=$(rpm -qa | grep "${removeKernelNameText}" | grep -v "${grepExcludelinuxKernelVersion}" | grep -v "noarch" | wc -l)
    rpmOLdKernelNameList=$(rpm -qa | grep "${removeKernelNameText}" | grep -v "${grepExcludelinuxKernelVersion}" | grep -v "noarch")
    # echo "${rpmOLdKernelNameList}"

    # https://stackoverflow.com/questions/29269259/extract-value-of-column-from-a-line-variable


    if [ "${rpmOldKernelNumber}" -gt "0" ]; then

        yellow "========== 准备开始删除旧内核 ${removeKernelNameText} ${osKernelVersionBackup}, 当前要安装新内核版本为: ${grepExcludelinuxKernelVersion}"
        red " 当前系统的旧内核 ${removeKernelNameText} ${osKernelVersionBackup} 有 ${rpmOldKernelNumber} 个需要删除"
        echo
        for((integer = 1; integer <= ${rpmOldKernelNumber}; integer++)); do
            rpmOLdKernelName=$(awk "NR==${integer}" <<< "${rpmOLdKernelNameList}")
            green "+++++ 开始卸载第 ${integer} 个内核: ${rpmOLdKernelName}. 命令: rpm --nodeps -e ${rpmOLdKernelName}"
            rpm --nodeps -e ${rpmOLdKernelName}
            green "+++++ 已卸载第 ${integer} 个内核 ${rpmOLdKernelName} +++++"
            echo
        done
        yellow "========== 共 ${rpmOldKernelNumber} 个旧内核 ${removeKernelNameText} ${osKernelVersionBackup} 已经卸载完成"
        echo
    else
        red " 当前需要卸载的系统旧内核 ${removeKernelNameText} ${osKernelVersionBackup} 数量为0 !"
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

        if [[ ${osReleaseVersionNoShort} = "6" ]]; then
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

    for ver in "${ubuntuKernelLatestVersionArray[@]}"; do

        if [[ ${ver} == *"${linuxKernelToInstallVersion}"* ]]; then
            # echo "符合所选版本的Linux 内核版本: ${ver}, 选择的版本为 ${linuxKernelToInstallVersion}"
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

    ${sudoCmd} apt-get clean
    ${sudoCmd} apt-get update
    ${sudoCmd} apt-get install -y dpkg

    # https://kernel.ubuntu.com/~kernel-ppa/mainline/

    # https://unix.stackexchange.com/questions/545601/how-to-upgrade-the-debian-10-kernel-from-backports-without-recompiling-it-from-s

    # https://askubuntu.com/questions/119080/how-to-update-kernel-to-the-latest-mainline-version-without-any-distro-upgrade

    # https://sypalo.com/how-to-upgrade-ubuntu

    if [ "${isInstallFromRepo}" = "yes" ]; then

        if [ "${linuxKernelToBBRType}" = "xanmod" ]; then

            green " =================================================="
            green "    开始准备从 XanMod 官方源安装 linux 内核 ${linuxKernelToInstallVersion}"
            green " =================================================="

            # https://xanmod.org/


            # echo 'deb http://deb.xanmod.org releases main' > /etc/apt/sources.list.d/xanmod-kernel.list
            # wget -qO - https://dl.xanmod.org/gpg.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/xanmod-kernel.gpg add -

            wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
            echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list

            ${sudoCmd} apt update -y

            listAvailableLinuxKernel "xanmod"

            linuxKernelToInstallVersionFull=${linuxKernelToInstallVersion}
            echo
            green " =================================================="
            green " 开始安装 linux 内核版本: XanMod ${linuxKernelToInstallVersionFull}"
            echo

            if [ "${linuxKernelToInstallVersion}" = "5.15" ]; then
                ${sudoCmd} apt install -y linux-xanmod-lts
            elif [ "${linuxKernelToInstallVersion}" = "6.2" ]; then
                ${sudoCmd} apt install -y linux-xanmod-x64v3
            elif [ "${linuxKernelToInstallVersion}" = "6.1" ]; then
                ${sudoCmd} apt install -y linux-xanmod-lts-x64v3
            else
                ${sudoCmd} apt install -y linux-xanmod
            fi


            listInstalledLinuxKernel
            rebootSystem
        else

            if [ "${linuxKernelToInstallVersion}" = "5.10" ]; then
                debianKernelVersion="5.10.0-0"
                # linux-image-5.10.0-0.bpo.15-amd64
            elif [ "${linuxKernelToInstallVersion}" = "5.19" ]; then
                debianKernelVersion="5.16.0-0"
                if [ "${osReleaseVersionNo}" = "11" ]; then
                    debianKernelVersion="5.19.0-0"
                fi

            elif [ "${linuxKernelToInstallVersion}" = "4.19" ]; then
                debianKernelVersion="4.19.0-21"
            else
                debianKernelVersion="6.1.0-0"
                if [ "${osReleaseVersionNo}" = "11" ]; then
                    debianKernelVersion="6.1.0-0"
                fi
            fi



            green " =================================================="
            green "    开始通过 Debian 官方源安装 linux 内核 ${debianKernelVersion}"
            green " =================================================="

            if [ "${osKernelVersionBackup}" = "${debianKernelVersion}" ]; then
                red "当前系统内核版本已经是 ${osKernelVersionBackup} 无需安装! "
                promptContinueOpeartion
            fi

            linuxKernelToInstallVersionFull=${debianKernelVersion}

            echo "deb http://deb.debian.org/debian $osReleaseVersionCodeName-backports main contrib non-free" > /etc/apt/sources.list.d/$osReleaseVersionCodeName-backports.list
            echo "deb-src http://deb.debian.org/debian $osReleaseVersionCodeName-backports main contrib non-free" >> /etc/apt/sources.list.d/$osReleaseVersionCodeName-backports.list
            ${sudoCmd} apt update -y

            listAvailableLinuxKernel

            echo
            green " apt --fix-broken install"
            ${sudoCmd} apt --fix-broken install

            #green " apt install -y -t $osReleaseVersionCodeName-backports linux-image-amd64"
            #${sudoCmd} apt install -y -t $osReleaseVersionCodeName-backports linux-image-amd64

            #green " apt install -y -t $osReleaseVersionCodeName-backports firmware-linux firmware-linux-nonfree"
            #${sudoCmd} apt install -y -t $osReleaseVersionCodeName-backports firmware-linux firmware-linux-nonfree

            echo
            echo "dpkg --get-selections | grep linux-image-${debianKernelVersion} | awk '/linux-image-[4-9]./{print \$1}' | awk -F'linux-image-' '{print \$2}' "
            #debianKernelVersionPackageName=$(dpkg --get-selections | grep "${debianKernelVersion}" | awk '/linux-image-[4-9]./{print $1}' | awk -F'linux-image-' '{print $2}')
            debianKernelVersionPackageName=$(apt-cache search linux-image | grep "${debianKernelVersion}" | awk '/linux-image-[4-9]./{print $1}' | awk '/[0-9]-amd64$/{print $1}' | awk -F'linux-image-' '{print $2}' | tail -1)


            echo
            green " Debian 官方源安装 linux 内核版本: ${debianKernelVersionPackageName}"
            echo

            green " 开始安装 linux-image  命令为:  apt install -y linux-image-${debianKernelVersionPackageName}"
            ${sudoCmd} apt install -y linux-image-${debianKernelVersionPackageName}
            echo
            green " 开始安装 linux-headers  命令为:  apt install -y linux-headers-${debianKernelVersionPackageName}"
            ${sudoCmd} apt install -y linux-headers-${debianKernelVersionPackageName}
            # ${sudoCmd} apt-get -y dist-upgrade

        fi

    else
        echo
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

            if [ -f "${userHomePath}/libssl1.1_1.1.0g-2ubuntu4_amd64.deb" ]; then
                green "文件已存在, 不需要下载, 文件原下载地址: http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb "
            else
                green "文件下载中... 下载地址: http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb "
                wget -P ${userHomePath} http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb
            fi

            ${sudoCmd} dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb
        fi

        if [[ "${linuxKernelToInstallVersion}" == "5.19" || "${linuxKernelToInstallVersion}" == "5.10.118" || "${linuxKernelToInstallVersion}" == "5.15" ]]; then
            if [ -f "${userHomePath}/libssl3_3.0.2-0ubuntu1_amd64.deb" ]; then
                green "文件已存在, 不需要下载, 文件原下载地址: http://mirrors.kernel.org/ubuntu/pool/main/o/openssl/libssl3_3.0.2-0ubuntu1_amd64.deb "
            else
                green "文件下载中... 下载地址: http://mirrors.kernel.org/ubuntu/pool/main/o/openssl/libssl3_3.0.2-0ubuntu1_amd64.deb "
                wget -P ${userHomePath} http://mirrors.kernel.org/ubuntu/pool/main/o/openssl/libssl3_3.0.2-0ubuntu1_amd64.deb
            fi

            if [ -f "${userHomePath}/libc6_2.35-0ubuntu3_amd64.deb" ]; then
                green "文件已存在, 不需要下载, 文件原下载地址: http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/libc6_2.35-0ubuntu3_amd64.deb "
            else
                green "文件下载中... 下载地址: http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/libc6_2.35-0ubuntu3_amd64.deb "
                wget -P ${userHomePath} http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/libc6_2.35-0ubuntu3_amd64.deb
            fi

            if [ -f "${userHomePath}/locales_2.35-0ubuntu3_all.deb" ]; then
                green "文件已存在, 不需要下载, 文件原下载地址: http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/locales_2.35-0ubuntu3_all.deb "
            else
                green "文件下载中... 下载地址: http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/locales_2.35-0ubuntu3_all.deb "
                wget -P ${userHomePath} http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/locales_2.35-0ubuntu3_all.deb
            fi

            if [ -f "${userHomePath}/libc-bin_2.35-0ubuntu3_amd64.deb" ]; then
                green "文件已存在, 不需要下载, 文件原下载地址: http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/libc-bin_2.35-0ubuntu3_amd64.deb "
            else
                green "文件下载中... 下载地址: http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/libc-bin_2.35-0ubuntu3_amd64.deb "
                wget -P ${userHomePath} http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/libc-bin_2.35-0ubuntu3_amd64.deb
            fi

            ${sudoCmd} dpkg -i locales_2.35-0ubuntu3_all.deb
            ${sudoCmd} dpkg -i libc-bin_2.35-0ubuntu3_amd64.deb
            ${sudoCmd} dpkg -i libssl3_3.0.2-0ubuntu1_amd64.deb
            ${sudoCmd} dpkg -i libc6_2.35-0ubuntu3_amd64.deb

        fi



        if [ "${linuxKernelByUser}" = "" ]; then

            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.11.12/amd64/
            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.11.12/amd64/linux-image-unsigned-5.11.12-051112-generic_5.11.12-051112.202104071432_amd64.deb
            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.11.12/amd64/linux-modules-5.11.12-051112-generic_5.11.12-051112.202104071432_amd64.deb

            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.19.17/
            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.19.17/amd64/linux-image-unsigned-5.19.17-051917-generic_5.19.17-051917.202210240939_amd64.deb
            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.19.17/amd64/linux-headers-5.19.17-051917-generic_5.19.17-051917.202210240939_amd64.deb
            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.19.17/amd64/linux-modules-5.19.17-051917-generic_5.19.17-051917.202210240939_amd64.deb

            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.19.17/arm64/linux-image-unsigned-5.19.17-051917-generic_5.19.17-051917.202210240939_arm64.deb
            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.19.17/arm64/linux-headers-5.19.17-051917-generic_5.19.17-051917.202210240939_arm64.deb
            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.19.17/arm64/linux-modules-5.19.17-051917-generic_5.19.17-051917.202210240939_arm64.deb


            getLatestUbuntuKernelVersion

            linuxKernelToInstallVersionFull=${ubuntuKernelVersion}

            mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
            cd ${userHomePath}/${linuxKernelToInstallVersionFull}


            for file in "${ubuntuKernelDownloadUrlArray[@]}"; do
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

            linuxKernelToInstallVersionFull="${bbrplusKernelVersion}-bbrplus"

            mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
            cd ${userHomePath}/${linuxKernelToInstallVersionFull}

            if [ "${linuxKernelToInstallVersion}" = "6.6" ]; then
                bbrplusDownloadUrl="https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/${linuxKernelToInstallVersionFull}"

            elif [ "${linuxKernelToInstallVersion}" = "4.14" ]; then
                bbrplusDownloadUrl="https://github.com/UJX6N/bbrplus/releases/download/${linuxKernelToInstallVersionFull}"

            else
                bbrplusDownloadUrl="https://github.com/UJX6N/bbrplus-${linuxKernelToInstallVersion}/releases/download/${linuxKernelToInstallVersionFull}"
            fi


            # https://github.com/UJX6N/bbrplus-5.9/releases/download/5.9.16-bbrplus/Debian-Ubuntu_Required_linux-image-5.9.16-bbrplus_5.9.16-bbrplus-1_amd64.deb
            # https://github.com/UJX6N/bbrplus-5.4/releases/download/5.4.228-bbrplus/Debian-Ubuntu_Required_linux-headers-5.4.228-bbrplus_5.4.228-bbrplus-1_amd64.deb
            # https://github.com/UJX6N/bbrplus-5.4/releases/download/5.4.228-bbrplus/Debian-Ubuntu_Required_linux-image-5.4.228-bbrplus_5.4.228-bbrplus-1_amd64.deb

            # https://github.com/UJX6N/bbrplus-4.19/releases/download/4.19.269-bbrplus/Debian-Ubuntu_Required_linux-image-4.19.269-bbrplus_4.19.269-bbrplus-1_amd64.deb
            # https://github.com/UJX6N/bbrplus/releases/download/4.14.302-bbrplus/Debian-Ubuntu_Required_linux-headers-4.14.302-bbrplus_4.14.302-bbrplus-1_amd64.deb
            # https://github.com/UJX6N/bbrplus-4.9/releases/download/4.9.337-bbrplus/Debian-Ubuntu_Required_linux-image-4.9.337-bbrplus_4.9.337-bbrplus-1_amd64.deb


            if [[ "${linuxKernelToInstallVersion}" == "5.10" || "${linuxKernelToInstallVersion}" == "5.15" || "${linuxKernelToInstallVersion}" == "6.1" || "${linuxKernelToInstallVersion}" == "6.6" || "${linuxKernelToInstallVersion}" == "6.7" ]]; then
            # https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/6.4.3-bbrplus/Debian-Ubuntu_Required_linux-image-6.4.3-bbrplus_6.4.3-1_amd64.deb
            # https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/6.4.3-bbrplus/Debian-Ubuntu_Optional_linux-headers-6.4.3-bbrplus_6.4.3-1_amd64.deb

            # https://github.com/UJX6N/bbrplus-6.1/releases/download/6.1.38-bbrplus/Debian-Ubuntu_Required_linux-image-6.1.38-bbrplus_6.1.38-bbrplus-1_amd64.deb

            # https://github.com/UJX6N/bbrplus-5.15/releases/download/5.15.120-bbrplus/Debian-Ubuntu_Required_linux-image-5.15.120-bbrplus_5.15.120-bbrplus-1_amd64.deb

            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.162-bbrplus/Debian-Ubuntu_Required_linux-image-5.10.162-bbrplus_5.10.162-bbrplus-1_amd64.deb
            # https://github.com/UJX6N/bbrplus-5.15/releases/download/5.15.86-bbrplus/Debian-Ubuntu_Optional_linux-headers-5.15.86-bbrplus_5.15.86-bbrplus-1_amd64.deb

                downloadFile ${bbrplusDownloadUrl}/Debian-Ubuntu_Required_linux-image-${bbrplusKernelVersion}-bbrplus_${bbrplusKernelVersion}-bbrplus-1_amd64.deb
                downloadFile ${bbrplusDownloadUrl}/Debian-Ubuntu_Optional_linux-headers-${bbrplusKernelVersion}-bbrplus_${bbrplusKernelVersion}-bbrplus-1_amd64.deb
            else
                downloadFile ${bbrplusDownloadUrl}/Debian-Ubuntu_Required_linux-image-${bbrplusKernelVersion}-bbrplus_${bbrplusKernelVersion}-1_amd64.deb
                downloadFile ${bbrplusDownloadUrl}/Debian-Ubuntu_Optional_linux-headers-${bbrplusKernelVersion}-bbrplus_${bbrplusKernelVersion}-1_amd64.deb
            fi

        fi


        removeDebianKernelMulti
        echo
        green " =================================================="
        green " 开始安装 linux 内核版本: ${linuxKernelToInstallVersionFull}"
        echo
        ${sudoCmd} dpkg -i ./*.deb

        updateGrubConfig

    fi

    echo
    green " =================================================="
    green "    安装 linux 内核 ${linuxKernelToInstallVersionFull} 成功! "
    red "    请根据以下信息 检查新内核是否安装成功，无新内核不要重启! "
    green " =================================================="
    echo

    showLinuxKernelInfo
    removeDebianKernelMulti "linux-image"
    listInstalledLinuxKernel
    rebootSystem

}




function removeDebianKernelMulti(){
    listInstalledLinuxKernel

    echo
    if [ -z $1 ]; then
        red "===== 开始准备删除 linux-headers linux-modules 内核, 建议删除 "
    else
        red "===== 开始准备删除 linux-image 内核, 建议删除 "
    fi

    red " 注意: 删除内核有风险, 可能会导致VPS无法启动, 请先做好备份! "
    read -p "是否删除内核? 直接回车默认删除内核, 请输入[Y/n]:" isContinueDelKernelInput
	isContinueDelKernelInput=${isContinueDelKernelInput:-Y}
    echo

	if [[ $isContinueDelKernelInput == [Yy] ]]; then

        if [ -z $1 ]; then
            removeDebianKernel "linux-modules-extra"
            removeDebianKernel "linux-modules"
            removeDebianKernel "linux-headers"
            removeDebianKernel "linux-image"
            # removeDebianKernel "linux-kbuild"
            # removeDebianKernel "linux-compiler"
            # removeDebianKernel "linux-libc"
        else
            removeDebianKernel "linux-image"
            removeDebianKernel "linux-modules-extra"
            removeDebianKernel "linux-modules"
            removeDebianKernel "linux-headers"
            # ${sudoCmd} apt -y --purge autoremove
        fi

    fi
    echo
}

function removeDebianKernel(){

    removeKernelNameText="linux-image"
    removeKernelNameText=$1
    grepExcludelinuxKernelVersion=$(echo ${linuxKernelToInstallVersionFull} | cut -d- -f1)


    # echo "dpkg --get-selections | grep ${removeKernelNameText} | grep -Ev '${grepExcludelinuxKernelVersion}|${removeKernelNameText}-amd64' | awk '{print \$1}' "
    rpmOldKernelNumber=$(dpkg --get-selections | grep "${removeKernelNameText}" | grep -Ev "${grepExcludelinuxKernelVersion}|${removeKernelNameText}-amd64" | wc -l)
    rpmOLdKernelNameList=$(dpkg --get-selections | grep "${removeKernelNameText}" | grep -Ev "${grepExcludelinuxKernelVersion}|${removeKernelNameText}-amd64" | awk '{print $1}' )
    # echo "$rpmOLdKernelNameList"

    # https://stackoverflow.com/questions/16212656/grep-exclude-multiple-strings
    # https://stackoverflow.com/questions/29269259/extract-value-of-column-from-a-line-variable

    # https://askubuntu.com/questions/187888/what-is-the-correct-way-to-completely-remove-an-application

    if [ "${rpmOldKernelNumber}" -gt "0" ]; then
        yellow "========== 准备开始删除旧内核 ${removeKernelNameText} ${osKernelVersionBackup}, 当前要安装新内核版本为: ${grepExcludelinuxKernelVersion}"
        red " 当前系统的旧内核 ${removeKernelNameText} ${osKernelVersionBackup} 有 ${rpmOldKernelNumber} 个需要删除"
        echo
        for((integer = 1; integer <= ${rpmOldKernelNumber}; integer++)); do
            rpmOLdKernelName=$(awk "NR==${integer}" <<< "${rpmOLdKernelNameList}")
            green "+++++ 开始卸载第 ${integer} 个内核: ${rpmOLdKernelName}. 命令: apt remove --purge ${rpmOLdKernelName}"
            ${sudoCmd} apt remove -y --purge ${rpmOLdKernelName}
            ${sudoCmd} apt autoremove -y ${rpmOLdKernelName}
            green "+++++ 已卸载第 ${integer} 个内核 ${rpmOLdKernelName} +++++"
            echo
        done
        yellow "========== 共 ${rpmOldKernelNumber} 个旧内核 ${removeKernelNameText} ${osKernelVersionBackup} 已经卸载完成"
        echo
    else
        red " 当前需要卸载的系统旧内核 ${removeKernelNameText} ${osKernelVersionBackup} 数量为0 !"
    fi

    echo
}






























function installWARP(){
    # wget -qN --no-check-certificate -O ./nf.sh https://raw.githubusercontent.com/jinwyp/SimpleNetflix/dev/nf.sh && chmod +x ./nf.sh
	# wget -qN --no-check-certificate -O ./warp-go.sh https://raw.githubusercontent.com/fscarmen/warp/main/warp-go.sh && chmod +x ./warp-go.sh && ./warp-go.sh
    # wget -qN --no-check-certificate -O ./warp-go.sh https://gitlab.com/fscarmen/warp/-/raw/main/warp-go.sh && chmod +x ./warp-go.sh && ./warp-go.sh
    wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh
}

function installWARPGO(){
    # wget -qN --no-check-certificate -O ./nf.sh https://raw.githubusercontent.com/jinwyp/SimpleNetflix/dev/nf.sh && chmod +x ./nf.sh
	# wget -qN --no-check-certificate -O ./warp-go.sh https://raw.githubusercontent.com/fscarmen/warp/main/warp-go.sh && chmod +x ./warp-go.sh && ./warp-go.sh
    wget -qN --no-check-certificate -O ./warp-go.sh https://gitlab.com/fscarmen/warp/-/raw/main/warp-go.sh && chmod +x ./warp-go.sh && ./warp-go.sh
}

function vps_netflix_auto(){
    # wget -qN --no-check-certificate -O ./nf.sh https://raw.githubusercontent.com/jinwyp/SimpleNetflix/dev/nf.sh && chmod +x ./nf.sh
	# bash <(curl -sSL https://raw.githubusercontent.com/fscarmen/warp_unlock/main/unlock.sh)
    bash <(curl -sSL https://gitlab.com/fscarmen/warp_unlock/-/raw/main/unlock.sh)
}

function vps_netflix_jin(){
    # wget -qN --no-check-certificate -O ./nf.sh https://raw.githubusercontent.com/jinwyp/SimpleNetflix/dev/nf.sh && chmod +x ./nf.sh
	wget -qN --no-check-certificate -O ./nf.sh https://raw.githubusercontent.com/jinwyp/one_click_script/master/netflix_check.sh && chmod +x ./nf.sh && ./nf.sh
}

function vps_netflix_jin_auto(){
    # wget -qN --no-check-certificate -O ./nf.sh https://raw.githubusercontent.com/jinwyp/SimpleNetflix/dev/nf.sh && chmod +x ./nf.sh
    cd ${HOME}
	wget -qN --no-check-certificate -O ./nf.sh https://raw.githubusercontent.com/jinwyp/one_click_script/master/netflix_check.sh && chmod +x ./nf.sh

    echo
    green " =================================================="
    green " 通过Cron定时任务 每天自动检测Netflix是否解锁非自制剧"
    green " 如果检测到Netflix没有解锁 会自动刷新 WARP IP, 默认尝试刷新20次"
    green " 刷新日志 log 在 /root/warp_refresh.log"
    green " Auto refresh Cloudflare WARP IP to unlock Netflix non-self produced drama"
    green " =================================================="
    echo
    (crontab -l ; echo "10 5 * * 0,1,2,3,4,5,6 /root/nf.sh auto >> /root/warp_refresh.log ") | sort - | uniq - | crontab -
    echo

    ./nf.sh auto
}







































function getGithubLatestReleaseVersion(){
    # https://github.com/p4gefau1t/trojan-go/issues/63
    wget --no-check-certificate -qO- https://api.github.com/repos/$1/tags | grep 'name' | cut -d\" -f4 | head -1 | cut -b 2-
}









# https://unix.stackexchange.com/questions/8656/usr-bin-vs-usr-local-bin-on-linux

versionWgcf="2.2.11"
downloadFilenameWgcf="wgcf_${versionWgcf}_linux_amd64"
configWgcfBinPath="/usr/local/bin"
configWgcfConfigFolderPath="${HOME}/wireguard"
configWgcfAccountFilePath="${configWgcfConfigFolderPath}/wgcf-account.toml"
configWgcfProfileFilePath="${configWgcfConfigFolderPath}/wgcf-profile.conf"
configWARPPortFilePath="${configWgcfConfigFolderPath}/warp-port"
configWireGuardConfigFileFolder="/etc/wireguard"
configWireGuardConfigFilePath="/etc/wireguard/wgcf.conf"
configWireGuardDNSBackupFilePath="/etc/resolv_warp_bak.conf"


configWarpPort="40000"



function installWARPClient(){

    # https://developers.cloudflare.com/warp-client/setting-up/linux

    echo
    green " =================================================="
    green " Prepare to install Cloudflare WARP Official client "
    green " Cloudflare WARP Official client only support Debian 10/11、Ubuntu 20.04/16.04、CentOS 8"
    green " =================================================="
    echo

    if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
        ${sudoCmd} apt-key del 835b8acb
        ${sudoCmd} apt-key del 8e5f9a5d

        ${sudoCmd} apt install -y gnupg
        ${sudoCmd} apt install -y apt-transport-https

        # Add cloudflare gpg key
        sudo mkdir -p --mode=0755 /usr/share/keyrings
        curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

        # Add this repo to your apt repositories
        echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $osReleaseVersionCodeName main" | ${sudoCmd} tee /etc/apt/sources.list.d/cloudflared.list

        # install cloudflared

        ${sudoCmd} apt-get update
        ${sudoCmd} apt install -y cloudflare-warp
        ${sudoCmd} apt-get install cloudflared

    elif [[ "${osRelease}" == "centos" ]]; then
        ${sudoCmd} rpm -e gpg-pubkey-835b8acb-*
        ${sudoCmd} rpm -e gpg-pubkey-8e5f9a5d-*

        if [ "${osReleaseVersionNoShort}" -eq 7 ]; then
            # red "Cloudflare WARP Official client is not supported on Centos 7"

            # This requires yum config-manager
            ${sudoCmd} yum install yum-utils

            # Add cloudflared.repo to config-manager
            ${sudoCmd} yum-config-manager --add-repo https://pkg.cloudflare.com/cloudflared-ascii.repo

            # install cloudflared
            ${sudoCmd} yum install cloudflared
        else
            # This requires dnf config-manager
            # Add cloudflared.repo to config-manager
            ${sudoCmd} dnf config-manager --add-repo https://pkg.cloudflare.com/cloudflared-ascii.repo

            # install cloudflared
            ${sudoCmd} dnf install cloudflared
        fi

        ${sudoCmd} yum install -y cloudflare-warp
    fi

    if [[ ! -f "/bin/warp-cli" ]]; then
        green " =================================================="
        red "  ${osInfo}${osReleaseVersionNoShort} ${osReleaseVersionCodeName} is not supported ! "
        green " =================================================="
        exit
    fi

    echo
    echo
    read -p "是否生成随机的WARP SOCKS5 端口号? 默认随机端口, 输入N为设置固定端口号40000, 请输入[Y/n]:" isWarpPortInput
    isWarpPortInput=${isWarpPortInput:-y}

    if [[ $isWarpPortInput == [Nn] ]]; then
        echo
    else
        configWarpPort="$(($RANDOM + 10000))"
    fi

    mkdir -p ${configWgcfConfigFolderPath}
    echo "${configWarpPort}" > "${configWARPPortFilePath}"

    ${sudoCmd} systemctl enable warp-svc

    yes | warp-cli register
    echo
    echo "warp-cli set-mode proxy"
    warp-cli set-mode proxy
    echo
    echo "warp-cli --accept-tos set-proxy-port ${configWarpPort}"
    warp-cli --accept-tos set-proxy-port ${configWarpPort}
    echo
    echo "warp-cli --accept-tos connect"
    warp-cli --accept-tos connect
    echo
    echo "warp-cli --accept-tos enable-always-on"
    warp-cli --accept-tos enable-always-on

    echo
    checkWarpClientStatus


    # (crontab -l ; echo "10 6 * * 0,1,2,3,4,5,6 warp-cli disable-always-on ") | sort - | uniq - | crontab -
    # (crontab -l ; echo "11 6 * * 0,1,2,3,4,5,6 warp-cli disconnect ") | sort - | uniq - | crontab -
    (crontab -l ; echo "12 6 * * 1,4 systemctl restart warp-svc ") | sort - | uniq - | crontab -
    # (crontab -l ; echo "16 6 * * 0,1,2,3,4,5,6 warp-cli connect ") | sort - | uniq - | crontab -
    # (crontab -l ; echo "17 6 * * 0,1,2,3,4,5,6 warp-cli enable-always-on ") | sort - | uniq - | crontab -



    echo
    green " ================================================== "
    green "  Cloudflare 官方 WARP Client 安装成功 !"
    green "  WARP SOCKS5 端口号 ${configWarpPort} "
    echo
    green "  WARP 停止命令: warp-cli disconnect , 停止Always-On命令: warp-cli disable-always-on "
    green "  WARP 启动命令: warp-cli connect , 开启Always-On命令(保持一直连接WARP): warp-cli enable-always-on "
    green "  WARP 查看日志: journalctl -n 100 -u warp-svc"
    green "  WARP 查看运行状态: warp-cli status"
    green "  WARP 查看连接信息: warp-cli warp-stats"
    green "  WARP 查看设置信息: warp-cli settings"
    green "  WARP 查看账户信息: warp-cli account"
    echo
    green "  用本脚本安装v2ray或xray 可以选择是否 解锁 Netflix 限制 和 避免弹出 Google reCAPTCHA 人机验证 !"
    echo
    green "  其他脚本安装的v2ray或xray 请自行替换 v2ray或xray 配置文件!"
    green " ================================================== "

}

function installWireguard(){



    if [[ -f "${configWireGuardConfigFilePath}" ]]; then
        green " =================================================="
        green "  已安装过 Wireguard, 如需重装 可以选择卸载 Wireguard 后重新安装! "
        green " =================================================="
        exit
    fi


    green " =================================================="
    green " 准备安装 WireGuard "
    echo
    red " 安装前建议用本脚本升级linux内核到5.6以上 例如5.10 LTS内核. 也可以不升级内核, 具体请看下面说明"
    red " 如果是新的干净的没有换过内核的系统(例如没有安装过BBR Plus内核), 可以不用退出安装其他内核, 直接继续安装 WireGuard"
    red " 如果安装过其他内核(例如安装过BBR Plus内核), 建议先安装高于5.6以上的内核, 低于5.6的内核也可以继续安装, 但有几率无法启动 WireGuard"
    red " 如遇到 WireGuard 启动失败, 建议重做新系统后, 升级系统到5.10内核, 然后安装WireGuard. 或者重做新系统后不要更换其他内核, 直接安装WireGuard"
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
		echo
        green " =================================================="
        green " 开始安装 WireGuard "
        green " =================================================="
	else
        green " 建议请先用本脚本安装 linux kernel 5.6 以上的内核 !"
		exit
	fi

    echo
    echo

    if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
        ${sudoCmd} apt --fix-broken install -y
        ${sudoCmd} apt-get update
        ${sudoCmd} apt install -y openresolv
        # ${sudoCmd} apt install -y resolvconf
        ${sudoCmd} apt install -y net-tools iproute2 dnsutils
        echo
        if [[ ${isKernelBuildInWireGuardModule} == "yes" ]]; then
            green " 当前系统内核版本高于5.6, 直接安装 wireguard-tools "
            echo
            ${sudoCmd} apt install -y wireguard-tools
        else
            # 安装 wireguard-dkms 后 ubuntu 20 系统 会同时安装 5.4.0-71   内核
            green " 当前系统内核版本低于5.6,  直接安装 wireguard wireguard"
            echo
            ${sudoCmd} apt install -y wireguard
            # ${sudoCmd} apt install -y wireguard-tools
        fi

        # if [[ ! -L "/usr/local/bin/resolvconf" ]]; then
        #     ln -s /usr/bin/resolvectl /usr/local/bin/resolvconf
        # fi

        ${sudoCmd} systemctl enable systemd-resolved.service
        ${sudoCmd} systemctl start systemd-resolved.service

    elif [[ "${osRelease}" == "centos" ]]; then
        ${sudoCmd} yum install -y epel-release elrepo-release
        ${sudoCmd} yum install -y net-tools
        ${sudoCmd} yum install -y iproute

        echo
        if [[ ${isKernelBuildInWireGuardModule} == "yes" ]]; then

            green " 当前系统内核版本高于5.6, 直接安装 wireguard-tools "
            echo
            if [ "${osReleaseVersionNoShort}" -eq 7 ]; then
                ${sudoCmd} yum install -y yum-plugin-elrepo
            fi

            ${sudoCmd} yum install -y wireguard-tools
        else

            if [ "${osReleaseVersionNoShort}" -eq 7 ]; then
                if [[ ${osKernelVersionBackup} == *"3.10."* ]]; then
                    green " 当前系统内核版本为原版Centos 7 ${osKernelVersionBackup} , 直接安装 kmod-wireguard "
                    ${sudoCmd} yum install -y yum-plugin-elrepo
                    ${sudoCmd} yum install -y kmod-wireguard wireguard-tools
                else
                    green " 当前系统内核版本低于5.6, 安装 wireguard-dkms "
                    ${sudoCmd} yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
                    ${sudoCmd} curl -o /etc/yum.repos.d/jdoss-wireguard-epel-7.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
                    ${sudoCmd} yum install -y wireguard-dkms wireguard-tools
                fi
            else
                if [[ ${osKernelVersionBackup} == *"4.18."* ]]; then
                    green " 当前系统内核版本为原版Centos 8 ${osKernelVersionBackup} , 直接安装 kmod-wireguard "
                    ${sudoCmd} yum install -y kmod-wireguard wireguard-tools
                else
                    green " 当前系统内核版本低于5.6, 安装 wireguard-dkms "
                    ${sudoCmd} yum config-manager --set-enabled PowerTools
                    ${sudoCmd} yum copr enable jdoss/wireguard
                    ${sudoCmd} yum install -y wireguard-dkms wireguard-tools
                fi

            fi
        fi
    fi

    green " ================================================== "
    green "  Wireguard 安装成功 !"
    green " ================================================== "

    installWGCF
}

function installWGCF(){

    versionWgcf=$(getGithubLatestReleaseVersion "ViRb3/wgcf")
    downloadFilenameWgcf="wgcf_${versionWgcf}_linux_amd64"

    echo
    green " =================================================="
    green " 开始安装 Cloudflare WARP 命令行工具 Wgcf ${versionWgcf}"
    green " =================================================="
    echo

    mkdir -p ${configWgcfConfigFolderPath}
    mkdir -p ${configWgcfBinPath}
    mkdir -p ${configWireGuardConfigFileFolder}

    cd ${configWgcfConfigFolderPath}

    # https://github.com/ViRb3/wgcf/releases/download/v2.2.10/wgcf_2.2.10_linux_amd64
    wget -O ${configWgcfConfigFolderPath}/wgcf --no-check-certificate "https://github.com/ViRb3/wgcf/releases/download/v${versionWgcf}/${downloadFilenameWgcf}"


    if [[ -f ${configWgcfConfigFolderPath}/wgcf ]]; then
        green " Cloudflare WARP 命令行工具 Wgcf ${versionWgcf} 下载成功!"
        echo
    else
        red "  Wgcf ${versionWgcf} 下载失败!"
        exit 255
    fi

    ${sudoCmd} chmod +x ${configWgcfConfigFolderPath}/wgcf
    cp ${configWgcfConfigFolderPath}/wgcf ${configWgcfBinPath}

    # ${configWgcfConfigFolderPath}/wgcf register --config "${configWgcfAccountFilePath}"

    if [[ -f ${configWgcfAccountFilePath} ]]; then
        echo
    else
        yes | ${configWgcfConfigFolderPath}/wgcf register
    fi

    echo
    echo
    green " =================================================="
    yellow " 没有购买过WARP+ 订阅请直接按回车跳过此步, Press enter to continue without WARP+"
    echo
    yellow " 如已购买过 WARP+ subscription 订阅, 可以填入 license key 启用WARP+"
    green " 查看方法: 手机打开 open Cloudflare 1.1.1.1 app, 点击右上菜单 click hamburger menu button on the top-right corner "
    green " Navigate to: Account > Key, 选择 Account 菜单里的key 就是 license key"
    echo

    read -p "请填写 license key?  直接回车默认跳过此步, 请输入:" isWARPLicenseKeyInput
    isWARPLicenseKeyInput=${isWARPLicenseKeyInput:-n}

    if [[ ${isWARPLicenseKeyInput} == [Nn] ]]; then
        echo
    else
        sed -i "s/license_key =.*/license_key = \"${isWARPLicenseKeyInput}\"/g" ${configWgcfAccountFilePath}
        WGCF_LICENSE_KEY="${isWARPLicenseKeyInput}" wgcf update
    fi

    if [[ -f ${configWgcfProfileFilePath} ]]; then
        echo
    else
        yes | ${configWgcfConfigFolderPath}/wgcf generate
    fi


    cp ${configWgcfProfileFilePath} ${configWireGuardConfigFilePath}

    enableWireguardIPV6OrIPV4

    echo
    green " 开始临时启动 Wireguard, 用于测试是否启动正常, 运行命令: wg-quick up wgcf"
    ${sudoCmd} wg-quick up wgcf

    echo
    green " 开始验证 Wireguard 是否启动正常, 检测是否使用 Cloudflare 的 ipv6 访问 !"
    echo
    echo "curl -6 ip.p3terx.com"
    curl -6 ip.p3terx.com
    echo
    isWireguardIpv6Working=$(curl -6 ip.p3terx.com | grep CLOUDFLARENET )
    echo

    if [[ -n "$isWireguardIpv6Working" ]]; then
        green " Wireguard 启动正常, 已成功通过 Cloudflare WARP 提供的 IPv6 访问网络! "
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

    echo
    green " 关闭临时启动用于测试的 Wireguard, 运行命令: wg-quick down wgcf "
    ${sudoCmd} wg-quick down wgcf
    echo

    ${sudoCmd} systemctl daemon-reload

    # 设置开机启动
    ${sudoCmd} systemctl enable wg-quick@wgcf

    # 启用守护进程
    ${sudoCmd} systemctl start wg-quick@wgcf

    # (crontab -l ; echo "12 6 * * 1 systemctl restart wg-quick@wgcf ") | sort - | uniq - | crontab -

    checkWireguardBootStatus

    echo
    green " ================================================== "
    green "  Wireguard 和 Cloudflare WARP 命令行工具 Wgcf ${versionWgcf} 安装成功 !"
    green "  Cloudflare WARP 申请的账户配置文件路径: ${configWgcfAccountFilePath} "
    green "  Cloudflare WARP 生成的 Wireguard 配置文件路径: ${configWireGuardConfigFilePath} "
    echo
    green "  Wireguard 停止命令: systemctl stop wg-quick@wgcf  启动命令: systemctl start wg-quick@wgcf  重启命令: systemctl restart wg-quick@wgcf"
    green "  Wireguard 查看日志: journalctl -n 50 -u wg-quick@wgcf"
    green "  Wireguard 查看运行状态: systemctl status wg-quick@wgcf"
    echo
    green "  用本脚本安装v2ray或xray 可以选择是否 解锁 Netflix 限制 和 避免弹出 Google reCAPTCHA 人机验证 !"
    echo
    green "  其他脚本安装的v2ray或xray 请自行替换 v2ray或xray 配置文件!"
    green "  可参考 如何使用 IPv6 访问 Netflix 的教程 https://ybfl.xyz/111.html 或 https://toutyrater.github.io/app/netflix.html"
    green " ================================================== "

}




function enableWireguardIPV6OrIPV4(){
    # https://p3terx.com/archives/use-cloudflare-warp-to-add-extra-ipv4-or-ipv6-network-support-to-vps-servers-for-free.html


    ${sudoCmd} systemctl stop wg-quick@wgcf

    cp /etc/resolv.conf ${configWireGuardDNSBackupFilePath}

    sed -i '/nameserver 2a00\:1098\:2b\:\:1/d' /etc/resolv.conf

    sed -i '/nameserver 8\.8/d' /etc/resolv.conf
    sed -i '/nameserver 9\.9/d' /etc/resolv.conf
    sed -i '/nameserver 1\.1\.1\.1/d' /etc/resolv.conf

    echo
    green " ================================================== "
    yellow " 请选择为服务器添加 IPv6 网络 还是 IPv4 网络支持: "
    echo
    green " 1 添加 IPv6 网络 (用于解锁 Netflix 限制 和避免弹出 Google reCAPTCHA 人机验证)"
    green " 2 添加 IPv4 网络 (用于给只有 IPv6 的 VPS主机添加 IPv4 网络支持)"
    echo
    read -p "请选择添加 IPv6 还是 IPv4 网络支持? 直接回车默认选1 , 请输入[1/2]:" isAddNetworkIPv6Input
	isAddNetworkIPv6Input=${isAddNetworkIPv6Input:-1}

	if [[ ${isAddNetworkIPv6Input} == [2] ]]; then

        # 为 IPv6 Only 服务器添加 IPv4 网络支持

        sed -i 's/^AllowedIPs = \:\:\/0/# AllowedIPs = \:\:\/0/g' ${configWireGuardConfigFilePath}
        sed -i 's/# AllowedIPs = 0\.0\.0\.0/AllowedIPs = 0\.0\.0\.0/g' ${configWireGuardConfigFilePath}

        sed -i 's/engage\.cloudflareclient\.com/\[2606\:4700\:d0\:\:a29f\:c001\]/g' ${configWireGuardConfigFilePath}
        sed -i 's/162\.159\.192\.1/\[2606\:4700\:d0\:\:a29f\:c001\]/g' ${configWireGuardConfigFilePath}

        sed -i 's/^DNS = 1\.1\.1\.1/DNS = 2620:fe\:\:10,2001\:4860\:4860\:\:8888,2606\:4700\:4700\:\:1111/g'  ${configWireGuardConfigFilePath}
        sed -i 's/^DNS = 8\.8\.8\.8,8\.8\.4\.4,1\.1\.1\.1,9\.9\.9\.10/DNS = 2620:fe\:\:10,2001\:4860\:4860\:\:8888,2606\:4700\:4700\:\:1111/g'  ${configWireGuardConfigFilePath}

        echo "nameserver 2a00:1098:2b::1" >> /etc/resolv.conf

        echo
        green " Wireguard 已成功切换到 对VPS服务器的 IPv4 网络支持"

    else

        # 为 IPv4 Only 服务器添加 IPv6 网络支持
        sed -i 's/^AllowedIPs = 0\.0\.0\.0/# AllowedIPs = 0\.0\.0\.0/g' ${configWireGuardConfigFilePath}
        sed -i 's/# AllowedIPs = \:\:\/0/AllowedIPs = \:\:\/0/g' ${configWireGuardConfigFilePath}

        sed -i 's/engage\.cloudflareclient\.com/162\.159\.192\.1/g' ${configWireGuardConfigFilePath}
        sed -i 's/\[2606\:4700\:d0\:\:a29f\:c001\]/162\.159\.192\.1/g' ${configWireGuardConfigFilePath}

        sed -i 's/^DNS = 1\.1\.1\.1/DNS = 8\.8\.8\.8,8\.8\.4\.4,1\.1\.1\.1,9\.9\.9\.10/g' ${configWireGuardConfigFilePath}
        sed -i 's/^DNS = 2620:fe\:\:10,2001\:4860\:4860\:\:8888,2606\:4700\:4700\:\:1111/DNS = 8\.8\.8\.8,1\.1\.1\.1,9\.9\.9\.10/g' ${configWireGuardConfigFilePath}

        echo "nameserver 8.8.8.8" >> /etc/resolv.conf
        echo "nameserver 8.8.4.4" >> /etc/resolv.conf
        echo "nameserver 1.1.1.1" >> /etc/resolv.conf
        #echo "nameserver 9.9.9.9" >> /etc/resolv.conf
        echo "nameserver 9.9.9.10" >> /etc/resolv.conf

        echo
        green " Wireguard 已成功切换到 对VPS服务器的 IPv6 网络支持"
    fi

    green " ================================================== "
    echo
    green " Wireguard 配置信息如下 配置文件路径: ${configWireGuardConfigFilePath} "
    cat ${configWireGuardConfigFilePath}
    green " ================================================== "
    echo

    # -n 不为空
    if [[ -n $1 ]]; then
        ${sudoCmd} systemctl start wg-quick@wgcf
    else
        preferIPV4
    fi
}




function preferIPV4(){

    if [[ -f "/etc/gai.conf" ]]; then
        sed -i '/^precedence \:\:ffff\:0\:0/d' /etc/gai.conf
        sed -i '/^label 2002\:\:\/16/d' /etc/gai.conf
    fi

    # -z 为空
    if [[ -z $1 ]]; then

        echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf

        echo
        green " VPS服务器已成功设置为 IPv4 优先访问网络"

    else

        green " ================================================== "
        yellow " 请为服务器设置 IPv4 还是 IPv6 优先访问: "
        echo
        green " 1 优先 IPv4 访问网络 (用于 给只有 IPv6 的 VPS主机添加 IPv4 网络支持)"
        green " 2 优先 IPv6 访问网络 (用于 解锁 Netflix 限制 和避免弹出 Google reCAPTCHA 人机验证)"
        green " 3 删除 IPv4 或 IPv6 优先访问的设置, 还原为系统默认配置"
        echo
        red " 注意: 选2后 优先使用 IPv6 访问网络 可能造成无法访问某些不支持IPv6的网站! "
        red " 注意: 解锁Netflix限制和避免弹出Google人机验证 一般不需要选择2设置IPv6优先访问, 可以在V2ray的配置中单独设置对Netfile和Google使用IPv6访问 "
        red " 注意: 由于 trojan 或 trojan-go 不支持配置 使用IPv6优先访问Netfile和Google, 可以选择2 开启服务器优先IPv6访问, 解决 trojan-go 解锁Netfile和Google人机验证问题"
        echo
        read -p "请选择 IPv4 还是 IPv6 优先访问? 直接回车默认选1, 请输入[1/2/3]:" isPreferIPv4Input
        isPreferIPv4Input=${isPreferIPv4Input:-1}

        if [[ ${isPreferIPv4Input} == [2] ]]; then

            # 设置 IPv6 优先
            echo "label 2002::/16   2" >> /etc/gai.conf

            echo
            green " VPS服务器已成功设置为 IPv6 优先访问网络 "
        elif [[ ${isPreferIPv4Input} == [3] ]]; then

            echo
            green " VPS服务器 已删除 IPv4 或 IPv6 优先访问的设置, 还原为系统默认配置 "
        else
            # 设置 IPv4 优先
            echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf

            echo
            green " VPS服务器已成功设置为 IPv4 优先访问网络 "
        fi

        green " ================================================== "
        echo
        yellow " 验证 IPv4 或 IPv6 访问网络优先级测试, 命令: curl ip.p3terx.com "
        echo
        curl ip.p3terx.com
        echo
        green " 上面信息显示 如果是IPv4地址 则VPS服务器已设置为 IPv4优先访问. 如果是IPv6地址则已设置为 IPv6优先访问 "
        green " ================================================== "

    fi
    echo

}

function removeWireguard(){
    green " ================================================== "
    red " 准备卸载 Wireguard 和 Cloudflare WARP 命令行工具 Wgcf "
    green " ================================================== "

    if [[ -f "${configWgcfBinPath}/wgcf" || -f "${configWgcfConfigFolderPath}/wgcf" || -f "/wgcf" ]]; then
        ${sudoCmd} systemctl stop wg-quick@wgcf.service
        ${sudoCmd} systemctl disable wg-quick@wgcf.service

        ${sudoCmd} wg-quick down wgcf
        ${sudoCmd} wg-quick disable wgcf


        if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then

            $osSystemPackage -y remove wireguard-tools
            $osSystemPackage -y remove wireguard

        elif [[ "${osRelease}" == "centos" ]]; then
            $osSystemPackage -y remove kmod-wireguard
            $osSystemPackage -y remove wireguard-dkms
            $osSystemPackage -y remove wireguard-tools
        fi

        echo
        read -p "是否删除Wgcf申请的账号文件, 默认不删除, 方便以后不用在重新注册, 请输入[y/N]:" isWgcfAccountFileRemoveInput
        isWgcfAccountFileRemoveInput=${isWgcfAccountFileRemoveInput:-n}

        echo
        if [[ $isWgcfAccountFileRemoveInput == [Yy] ]]; then
            rm -rf "${configWgcfConfigFolderPath}"
            green " Wgcf申请的账号信息文件 ${configWgcfAccountFilePath} 已删除!"

        else
            rm -f "${configWgcfProfileFilePath}"
            green " Wgcf申请的账号信息文件 ${configWgcfAccountFilePath} 已保留! "
        fi


        rm -f ${configWgcfBinPath}/wgcf
        rm -rf ${configWireGuardConfigFileFolder}
        rm -f ${osSystemMdPath}wg-quick@wgcf.service

        rm -f /usr/bin/wg
        rm -f /usr/bin/wg-quick
        rm -f /usr/share/man/man8/wg.8
        rm -f /usr/share/man/man8/wg-quick.8

        [ -d "/etc/wireguard" ] && ("rm -rf /etc/wireguard")


        sleep 2
        modprobe -r wireguard

        cp -f ${configWireGuardDNSBackupFilePath} /etc/resolv.conf

        green " ================================================== "
        green "  Wireguard 和 Cloudflare WARP 命令行工具 Wgcf 卸载完毕 !"
        green " ================================================== "

    else
        red " 系统没有安装 Wireguard 和 Wgcf, 退出卸载"
        echo
    fi



}

function removeWARP(){
    green " ================================================== "
    red " 准备卸载 Cloudflare WARP 官方 linux client "
    green " ================================================== "

    if [[ -f "/usr/bin/warp-cli" ]]; then
        ${sudoCmd} warp-cli disable-always-on
        ${sudoCmd} warp-cli disconnect
        ${sudoCmd} systemctl stop warp-svc
        sleep 5s

        if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then

            ${sudoCmd} apt purge -y cloudflare-warp
            rm -f /etc/apt/sources.list.d/cloudflare-client.list

        elif [[ "${osRelease}" == "centos" ]]; then
            yum remove -y cloudflare-warp
        fi

        rm -f ${configWARPPortFilePath}

        crontab -l | grep -v 'warp-cli'  | crontab -
        crontab -l | grep -v 'warp-svc'  | crontab -

        green " ================================================== "
        green "  Cloudflare WARP linux client 卸载完毕 !"
        green " ================================================== "
    else
        red " 系统没有安装 Cloudflare WARP linux client, 退出卸载"
        echo
    fi

}

function checkWireguardBootStatus(){
    echo
    green " ================================================== "
    isWireguardBootSuccess=$(systemctl status wg-quick@wgcf | grep -E "Active: active")
    if [[ -z "${isWireguardBootSuccess}" ]]; then
        green " 状态显示-- Wireguard 已启动${Red_font_prefix}失败${Green_font_prefix}! 请查看 Wireguard 运行日志, 寻找错误后重启 Wireguard "
    else
        green " 状态显示-- Wireguard 已启动成功! "
        echo
        echo "wgcf trace"
        echo
        wgcf trace
        echo
    fi
    green " ================================================== "
    echo
}

cloudflare_Trace_URL='https://www.cloudflare.com/cdn-cgi/trace'
function checkWarpClientStatus(){

    if [[ -f "${configWARPPortFilePath}" ]]; then
        configWarpPort=$(cat ${configWARPPortFilePath})
    fi

    echo
    green " ================================================== "
    sleep 2s
    isWarpClientBootSuccess=$(systemctl is-active warp-svc | grep -E "inactive")
    if [[ -z "${isWarpClientBootSuccess}" ]]; then
        green " 状态显示-- WARP 已启动成功! "
        echo

        isWarpClientMode=$(curl -sx "socks5h://127.0.0.1:${configWarpPort}" ${cloudflare_Trace_URL} --connect-timeout 20 | grep warp | cut -d= -f2)
        sleep 3s
        case ${isWarpClientMode} in
        on)
            green " 状态显示-- WARP SOCKS5 代理已启动成功, 端口号 ${configWarpPort} ! "
            ;;
        plus)
            green " 状态显示-- WARP+ SOCKS5 代理已启动成功, 端口号 ${configWarpPort} ! "
            ;;
        *)
            green " 状态显示-- WARP SOCKS5 代理启动${Red_font_prefix}失败${Green_font_prefix}! "
            ;;
        esac

        green " ================================================== "
        echo
        echo "curl -x 'socks5h://127.0.0.1:${configWarpPort}' ${cloudflare_Trace_URL}"
        echo
        curl -x "socks5h://127.0.0.1:${configWarpPort}" ${cloudflare_Trace_URL}
    else
        green " 状态显示-- WARP 已启动${Red_font_prefix}失败${Green_font_prefix}! 请查看 WARP 运行日志, 寻找错误后重启 WARP "
    fi
    green " ================================================== "
    echo
}


function restartWireguard(){
    echo
    echo "systemctl restart wg-quick@wgcf"
    systemctl restart wg-quick@wgcf
    green " Wireguard 已重启 !"
    echo
}
function startWARP(){
    echo
    echo "systemctl start warp-svc"
    systemctl start warp-svc
    echo
    echo "warp-cli connect"
    warp-cli connect
    echo
    echo "warp-cli enable-always-on"
    warp-cli enable-always-on
    green " WARP SOCKS5 代理 已启动 !"
}
function stopWARP(){
    echo
    echo "warp-cli disable-always-on"
    warp-cli disable-always-on
    echo
    echo "warp-cli disconnect"
    warp-cli disconnect
    echo
    echo "systemctl stop warp-svc"
    systemctl stop warp-svc
    green " WARP SOCKS5 代理 已停止 !"
}
function restartWARP(){
    echo
    echo "warp-cli disable-always-on"
    warp-cli disable-always-on
    echo
    echo "warp-cli disconnect"
    warp-cli disconnect
    echo
    echo "systemctl restart warp-svc"
    systemctl restart warp-svc
    sleep 5s
    echo
    read -p "Press enter to continue"
    echo
    echo "warp-cli connect"
    warp-cli connect
    echo
    echo "warp-cli enable-always-on"
    warp-cli enable-always-on
    echo
    green " WARP SOCKS5 代理 已重启 !"
    echo
}

function checkWireguard(){
    echo
    green " =================================================="
    echo
    green " 1. 查看当前系统内核版本, 检查是否因为装了多个版本内核导致 Wireguard 启动失败"
    echo
    green " 2. 查看 Wireguard 和 WARP SOCKS5 代理运行状态"
    echo
    green " 3. 查看 Wireguard 运行日志, 如果 Wireguard 启动失败 请用此项查找问题"
    green " 4. 启动 Wireguard "
    green " 5. 停止 Wireguard "
    green " 6. 重启 Wireguard "
    green " 7. 查看 Wireguard 和 WARP 运行状态 wgcf status "
    green " 8. 查看 Wireguard 配置文件 ${configWireGuardConfigFilePath} "
    green " 9. 用VI 编辑 Wireguard 配置文件 ${configWireGuardConfigFilePath} "
    echo
    green " 11. 查看 WARP SOCKS5 运行日志, 如果 WARP 启动失败 请用此项查找问题"
    green " 12. 启动 WARP SOCKS5 代理"
    green " 13. 停止 WARP SOCKS5 代理"
    green " 14. 重启 WARP SOCKS5 代理"
    echo
    green " 15. 查看 WARP SOCKS5 运行状态 warp-cli status"
    green " 16. 查看 WARP SOCKS5 连接信息 warp-cli warp-stats"
    green " 17. 查看 WARP SOCKS5 设置信息 warp-cli settings"
    green " 18. 查看 WARP SOCKS5 账户信息 warp-cli account"

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
            echo
            #echo "systemctl status wg-quick@wgcf"
            #systemctl status wg-quick@wgcf
            #red " 请查看上面 Active: 一行信息, 如果文字是绿色 active 则为启动正常, 否则启动失败"
            checkWireguardBootStatus
            checkWarpClientStatus
        ;;
        3 )
            echo
            echo "journalctl -n 100 -u wg-quick@wgcf"
            journalctl -n 100 -u wg-quick@wgcf
            red " 请查看上面包含 Error 的信息行, 查找启动失败的原因 "
        ;;
        4 )
            echo
            echo "systemctl start wg-quick@wgcf"
            systemctl start wg-quick@wgcf
            echo
            green " Wireguard 已启动 !"
            checkWireguardBootStatus
        ;;
        5 )
            echo
            echo "systemctl stop wg-quick@wgcf"
            systemctl stop wg-quick@wgcf
            echo
            green " Wireguard 已停止 !"
            checkWireguardBootStatus
        ;;
        6 )
            restartWireguard
            checkWireguardBootStatus
        ;;
        7 )
            echo
            green "Running command 'wgcf status' to check device status :"
            echo
            wgcf status
            echo
            echo
            green "Running command 'wgcf trace' to verify WARP/WARP+ works :"
            echo
            wgcf trace
            echo
        ;;
        8 )
            echo
            echo "cat ${configWireGuardConfigFilePath}"
            cat ${configWireGuardConfigFilePath}
        ;;
        9 )
            echo
            echo "vi ${configWireGuardConfigFilePath}"
            vi ${configWireGuardConfigFilePath}
        ;;
        11 )
            echo
            echo "journalctl --no-pager -u warp-svc "
            journalctl --no-pager -u warp-svc
            red " 请查看上面包含 Error 的信息行, 查找启动失败的原因 "
        ;;
        12 )
            startWARP
            checkWarpClientStatus
        ;;
        13 )
            stopWARP
            checkWarpClientStatus
        ;;
        14 )
            restartWARP
            checkWarpClientStatus
        ;;
        15 )
            echo
            echo "warp-cli status"
            warp-cli status
        ;;
        16 )
            echo
            echo "warp-cli warp-stats"
            warp-cli warp-stats
        ;;
        17 )
            echo
            echo "warp-cli settings"
            warp-cli settings
        ;;
        18 )
            echo
            echo "warp-cli account"
            warp-cli account
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











































function start_menu(){
    clear

    if [[ $1 == "first" ]] ; then
        getLinuxOSRelease
        installSoftDownload
    fi
    showLinuxKernelInfoNoDisplay

    if [[ ${configLanguage} == "cn" ]] ; then
    green " =================================================="
    green " Linux 内核 一键安装脚本 | 2024-03-13 | 系统支持：centos7+ / debian10+ / ubuntu16.04+"
    green " Linux 内核 4.9 以上都支持开启BBR, 如要开启BBR Plus 则需要安装支持BBR Plus的内核 "
    red " 在任何生产环境中请谨慎使用此脚本, 升级内核有风险, 请做好备份！在某些VPS会导致无法启动! "
    green " =================================================="
    if [[ -z ${osKernelBBRStatus} ]]; then
        echo -e " 当前系统内核: ${osKernelVersionBackup} (${virtual})   ${Red_font_prefix}未安装 BBR 或 BBR Plus ${Font_color_suffix} 加速内核, 请先安装4.9以上内核 "
    else
        if [ ${systemBBRRunningStatus} = "no" ]; then
            echo -e " 当前系统内核: ${osKernelVersionBackup} (${virtual})   ${Green_font_prefix}已安装 ${osKernelBBRStatus}${Font_color_suffix} 加速内核, ${Red_font_prefix}${systemBBRRunningStatusText}${Font_color_suffix} "
        else
            echo -e " 当前系统内核: ${osKernelVersionBackup} (${virtual})   ${Green_font_prefix}已安装 ${osKernelBBRStatus}${Font_color_suffix} 加速内核, ${Green_font_prefix}${systemBBRRunningStatusText}${Font_color_suffix} "
        fi
    fi
    echo -e " 当前拥塞控制算法: ${Green_font_prefix}${net_congestion_control}${Font_color_suffix}    ECN: ${Green_font_prefix}${systemECNStatusText}${Font_color_suffix}   当前队列算法: ${Green_font_prefix}${net_qdisc}${Font_color_suffix} "

    echo
    green " 1. 查看当前系统内核版本, 检查是否支持BBR / BBR2 / BBR Plus"
    green " 2. 开启 BBR 或 BBR2 加速, 开启 BBR2 需要安装 XanMod 内核"
    green " 3. 开启 BBR Plus 加速"
    green " 4. 优化 系统网络配置"
    red " 5. 删除 系统网络优化配置"
    echo
    green " 6. 查看 Wireguard 运行状态"
    green " 7. 重启 Wireguard "
    green " 8. 查看 WARP SOCKS5 代理运行状态"
    green " 9. 重启 WARP SOCKS5"
    green " 10. 查看 WireGuard 和 WARP SOCKS5 运行状态, 错误日志, 如果WireGuard启动失败 请选该项排查错误"
    echo
    green " 11. 安装官方 Cloudflare WARP Client 启动SOCKS5代理, 用于解锁 Netflix 限制"
    green " 12. 安装 WireGuard 和 Cloudflare WARP 工具 Wgcf, 启动 IPv4或IPv6, 用于避免弹出Google人机验证"
    green " 13. 同时安装 官方 Cloudflare WARP Client, WireGuard 和 命令行工具 Wgcf, 不推荐 "
    red " 14. 卸载 WireGuard 和 Cloudflare WARP linux client"
    green " 15. 切换 WireGuard 对VPS服务器的 IPv6 和 IPv4 的网络支持"
    green " 16. 设置 VPS 服务器 IPv4 还是 IPv6 网络优先访问"

    green " 21. 安装 warp 脚本 by fscarmen"
    green " 22. 安装 warp-go 脚本 by fscarmen"
    green " 23. 自动刷新WARP IP 直到支持 Netflix 非自制剧解锁 "
    # green " 22. 测试 VPS 是否支持 Netflix 非自制剧解锁 支持 WARP SOCKS5 测试 强烈推荐使用 "

    echo

    if [[ "${osRelease}" == "centos" ]]; then
    green " 31. 安装 最新版本内核 6.1, 通过elrepo源安装"
    green " 32. 安装 LTS内核 5.4 LTS, 通过elrepo源安装"
    green " 33. 安装 内核 4.14 LTS, 从 altarch网站 下载安装"
    green " 34. 安装 内核 4.19 LTS, 从 altarch网站 下载安装"
    green " 35. 安装 内核 5.4 LTS, 从 elrepo网站 下载安装"
    echo
    green " 36. 安装 内核 5.10 LTS, Teddysun 编译 推荐安装"
    green " 37. 安装 内核 5.15 LTS, Teddysun 编译 推荐安装"
    green " 38. 安装 内核 6.1 LTS, Teddysun 编译 下载安装. "
    green " 39. 安装 内核 6.3, elrepo 官方编译. "

    else
        if [[ "${osRelease}" == "debian" ]]; then

            if [[ "${osReleaseVersion}" == "10" ]]; then
                green " 41. 安装 LTS内核 5.10 LTS, 通过 Debian 官方源安装"
            fi
            if [[ "${osReleaseVersion}" == "11" ]]; then
                green " 41. 安装 LTS内核 5.10 LTS, 通过 Debian 官方源安装"
                green " 42. 安装 内核 5.19, 通过 Debian 官方源安装"
                green " 43. 安装 最新版本内核 6.1 或更高, 通过 Debian 官方源安装"
            fi
            echo
        fi

        green " 44. 安装 内核 4.19 LTS, 通过 Ubuntu kernel mainline 安装"
        green " 45. 安装 内核 5.4 LTS, 通过 Ubuntu kernel mainline 安装"
        green " 46. 安装 内核 5.10 LTS, 通过 Ubuntu kernel mainline 安装"
        green " 47. 安装 内核 5.15, 通过 Ubuntu kernel mainline 安装"
        green " 48. 安装 内核 5.19, 通过 Ubuntu kernel mainline 安装"
        green " 49. 安装 最新版本内核 6.1, 通过 Ubuntu kernel mainline 安装"
        echo
        green " 51. 安装 XanMod Kernel 内核 6.1 LTS, 官方源安装 "
        green " 52. 安装 XanMod Kernel 内核 6.2, 官方源安装 "

    fi

    echo
    green " 61. 安装 BBR Plus 内核 4.14.129 LTS, cx9208 编译的 dog250 原版, 推荐使用"
    green " 62. 安装 BBR Plus 内核 4.14 LTS, UJX6N 编译"
    green " 63. 安装 BBR Plus 内核 4.19 LTS, UJX6N 编译"
    green " 64. 安装 BBR Plus 内核 5.10 LTS, UJX6N 编译"
    green " 65. 安装 BBR Plus 内核 5.15 LTS, UJX6N 编译"
    green " 66. 安装 BBR Plus 内核 6.1 LTS, UJX6N 编译"
    green " 67. 安装 BBR Plus 内核 6.6 LTS, UJX6N 编译"
    green " 68. 安装 BBR Plus 最新版内核 6.7或更高版本, UJX6N 编译"

    echo
    green " 0. 退出脚本"


    else

    green " =================================================="
    green " Linux kernel install script | 2024-03-13 | OS support：centos7+ / debian10+ / ubuntu16.04+"
    green " Enable bbr require linux kernel higher than 4.9. Enable bbr plus require special bbr plus kernel "
    red " Please use this script with caution in production. Backup your data first! Upgrade linux kernel will cause VPS unable to boot sometimes."
    green " =================================================="
    if [[ -z ${osKernelBBRStatus} ]]; then
        echo -e " Current Kernel: ${osKernelVersionBackup} (${virtual})   ${Red_font_prefix}Not install BBR / BBR Plus ${Font_color_suffix} , Please install kernel which is higher than 4.9"
    else
        if [ ${systemBBRRunningStatus} = "no" ]; then
            echo -e " Current Kernel: ${osKernelVersionBackup} (${virtual})   ${Green_font_prefix}installed ${osKernelBBRStatus}${Font_color_suffix} kernel, ${Red_font_prefix}${systemBBRRunningStatusText}${Font_color_suffix} "
        else
            echo -e " Current Kernel: ${osKernelVersionBackup} (${virtual})   ${Green_font_prefix}installed ${osKernelBBRStatus}${Font_color_suffix} kernel, ${Green_font_prefix}${systemBBRRunningStatusText}${Font_color_suffix} "
        fi
    fi
    echo -e " Congestion Control Algorithm: ${Green_font_prefix}${net_congestion_control}${Font_color_suffix}    ECN: ${Green_font_prefix}${systemECNStatusText}${Font_color_suffix}   Network Queue Algorithm: ${Green_font_prefix}${net_qdisc}${Font_color_suffix} "

    echo
    green " 1. Show current linux kernel version, check supoort BBR / BBR2 / BBR Plus or not"
    green " 2. enable bbr / bbr2 acceleration, (bbr2 require XanMod kernel)"
    green " 3. enable bbr plus acceleration"
    green " 4. Optimize system network configuration"
    red " 5. Remove system network optimization configuration"
    echo
    green " 6. Show Wireguard working status"
    green " 7. restart Wireguard "
    green " 8. Show WARP SOCKS5 proxy working status"
    green " 9. restart WARP SOCKS5 proxy"
    green " 10. Show WireGuard and WARP SOCKS5 working status, error log, etc."
    echo
    green " 11. Install official Cloudflare WARP linux client SOCKS5 proxy, in order to unlock Netflix geo restriction "
    green " 12. Install WireGuard and Cloudflare WARP tool Wgcf, enable IPv4 or IPv6, avoid Google reCAPTCHA"
    green " 13. Install official Cloudflare WARP linux client, WireGuard and WARP toll Wgcf, not recommended "
    red " 14. Remove WireGuard 和 Cloudflare WARP linux client"
    green " 15. Switch WireGuard using IPv6 or IPv4 for your VPS"
    green " 16. Set VPS using IPv4 or IPv6 firstly to access network"

    green " 21. Install warp by fscarmen. Enable IPv6, avoid Google reCAPTCHA and unlock Netflix geo restriction "
    green " 22. Install warp-go by fscarmen. Enable IPv6, avoid Google reCAPTCHA and unlock Netflix geo restriction "
    green " 23. Auto refresh Cloudflare WARP IP to unlock Netflix non-self produced drama"
    echo

    if [[ "${osRelease}" == "centos" ]]; then
    green " 31. Install latest linux kernel, 6.1, from elrepo yum repository"
    green " 32. Install LTS linux kernel, 5.4 LTS, from elrepo yum repository"
    green " 33. Install linux kernel 4.14 LTS, download and install from altarch website"
    green " 34. Install linux kernel 4.19 LTS, download and install from altarch website"
    green " 35. Install linux kernel 5.4 LTS, download and install from elrepo website"
    echo
    green " 36. Install linux kernel 5.10 LTS, compile by Teddysun. Recommended"
    green " 37. Install linux kernel 5.15 LTS, compile by Teddysun. Recommended"
    green " 38. Install linux kernel 6.1 LTS compile by Teddysun. Recommended"
    green " 39. Install linux kernel 6.3, compile by elrepo "
    else
        if [[ "${osRelease}" == "debian" ]]; then
            if [[ "${osReleaseVersion}" == "10" ]]; then
                green " 41. Install LTS linux kernel, 5.10 LTS, from Debian repository source"
            fi

            if [[ "${osReleaseVersion}" == "11" ]]; then
                green " 41. Install LTS linux kernel, 5.10 LTS, from Debian repository source"
                green " 42. Install linux kernel, 5.19, from Debian repository source"
                green " 43. Install latest linux kernel, 6.1 or higher, from Debian repository source"
            fi
            echo
        fi

    green " 44. Install linux kernel 4.19 LTS, download and install from Ubuntu kernel mainline"
    green " 45. Install linux kernel 5.4 LTS, download and install from Ubuntu kernel mainline"
    green " 46. Install linux kernel 5.10 LTS, download and install from Ubuntu kernel mainline"
    green " 47. Install linux kernel 5.15, download and install from Ubuntu kernel mainline"
    green " 48. Install linux kernel 5.19, download and install from Ubuntu kernel mainline"
    green " 49. Install latest linux kernel 6.1, download and install from Ubuntu kernel mainline"
    echo
    green " 51. Install XanMod kernel 6.1 LTS, from XanMod repository source "
    green " 52. Install XanMod kernel 6.2, from XanMod repository source "
    fi

    echo
    green " 61. Install BBR Plus kernel 4.14.129 LTS, compile by cx9208 from original dog250 source code. Recommended"
    green " 62. Install BBR Plus kernel 4.14 LTS, compile by UJX6N"
    green " 63. Install BBR Plus kernel 4.19 LTS, compile by UJX6N"
    green " 64. Install BBR Plus kernel 5.10 LTS, compile by UJX6N"
    green " 65. Install BBR Plus kernel 5.15 LTS, compile by UJX6N"
    green " 66. Install BBR Plus kernel 6.1 LTS, compile by UJX6N"
    green " 67. Install BBR Plus kernel 6.6 LTS, compile by UJX6N"
    green " 68. Install BBR Plus latest kernel 6.7 or higher, compile by UJX6N"
    echo
    green " 0. exit"

    fi

    echo
    read -r -p "Please input number:" menuNumberInput
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
        4 )
            addOptimizingSystemConfig
        ;;
        5 )
            removeOptimizingSystemConfig
            sysctl -p
        ;;
        6 )
            checkWireguardBootStatus
        ;;
        7 )
            restartWireguard
            checkWireguardBootStatus
        ;;
        8 )
            checkWarpClientStatus
        ;;
        9 )
            restartWARP
            checkWarpClientStatus
        ;;
        10 )
           checkWireguard
        ;;
        11 )
           installWARPClient
        ;;
        12 )
           installWireguard
        ;;
        13 )
           installWireguard
           installWARPClient
        ;;
        14 )
           removeWireguard
           removeWARP
        ;;
        15 )
           enableWireguardIPV6OrIPV4 "redo"
        ;;
        16 )
           preferIPV4 "redo"
        ;;

        21 )
           installWARP
        ;;
        22 )
           installWARPGO
        ;;
        23 )
           vps_netflix_auto
        ;;
        24 )
           vps_netflix_jin
        ;;
        25 )
           vps_netflix_jin_auto
        ;;
        31 )
            linuxKernelToInstallVersion="5.19"
            isInstallFromRepo="yes"
            installKernel
        ;;
        32 )
            linuxKernelToInstallVersion="5.4"
            isInstallFromRepo="yes"
            installKernel
        ;;
        33 )
            linuxKernelToInstallVersion="4.14"
            installKernel
        ;;
        34 )
            linuxKernelToInstallVersion="4.19"
            installKernel
        ;;
        35 )
            linuxKernelToInstallVersion="5.4"
            installKernel
        ;;
        36 )
            linuxKernelToInstallVersion="5.10"
            installKernel
        ;;
        37 )
            linuxKernelToInstallVersion="5.15"
            installKernel
        ;;
        38 )
            linuxKernelToInstallVersion="6.1"
            installKernel
        ;;
        39 )
            linuxKernelToInstallVersion="6.3"
            installKernel
        ;;
        41 )
            linuxKernelToInstallVersion="5.10"
            isInstallFromRepo="yes"
            installKernel
        ;;
        42 )
            linuxKernelToInstallVersion="5.19"
            isInstallFromRepo="yes"
            installKernel
        ;;
        43 )
            linuxKernelToInstallVersion="6.1"
            isInstallFromRepo="yes"
            installKernel
        ;;
        44 )
            linuxKernelToInstallVersion="4.19"
            installKernel
        ;;
        45 )
            linuxKernelToInstallVersion="5.4"
            installKernel
        ;;
        46 )
            linuxKernelToInstallVersion="5.10.118"
            installKernel
        ;;
        47 )
            linuxKernelToInstallVersion="5.15"
            installKernel
        ;;
        48 )
            linuxKernelToInstallVersion="5.19"
            installKernel
        ;;
        49 )
            linuxKernelToInstallVersion="6.1"
            installKernel
        ;;
        51 )
            linuxKernelToInstallVersion="6.1"
            linuxKernelToBBRType="xanmod"
            isInstallFromRepo="yes"
            installKernel
        ;;
        52 )
            linuxKernelToInstallVersion="6.2"
            linuxKernelToBBRType="xanmod"
            isInstallFromRepo="yes"
            installKernel
        ;;
        61 )
            linuxKernelToInstallVersion="4.14.129"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        62 )
            linuxKernelToInstallVersion="4.14"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        63 )
            linuxKernelToInstallVersion="4.19"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        64 )
            linuxKernelToInstallVersion="5.10"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        65 )
            linuxKernelToInstallVersion="5.15"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        66 )
            linuxKernelToInstallVersion="6.1"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        67 )
            linuxKernelToInstallVersion="6.6"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        68 )
            linuxKernelToInstallVersion="6.7"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        87 )
            getLatestUbuntuKernelVersion
            getLatestCentosKernelVersion
            getLatestCentosKernelVersion "manual"
        ;;
        88 )
            upgradeScript
        ;;
        89 )
            virt_check
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
    green " 1. English"
    green " 2. 中文"
    echo
    read -r -p "Please input your language:" languageInput

    case "${languageInput}" in
        1 )
            echo "en" > ${configLanguageFilePath}
            showMenu
        ;;
        2 )
            echo "cn" > ${configLanguageFilePath}
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
