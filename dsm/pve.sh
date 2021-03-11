#!/bin/bash

# PVE WIKI
# https://pve.proxmox.com/wiki/Pci_passthrough
# https://pve.proxmox.com/wiki/PCI(e)_Passthrough
# https://pve.proxmox.com/wiki/Passthrough_Physical_Disk_to_Virtual_Machine_(VM)

# https://github.com/intel/gvt-linux/wiki/GVTg_Setup_Guide

# set -e
# set -o pipefail

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



if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCmd="sudo"
else
  sudoCmd=""
fi




osSystemPackage="apt-get"
osCPU="intel"

pveStatusIOMMU=""
pveStatusIOMMUDMAR=""
pveStatusVTX=""
pveStatusVTIntel=""
pveStatusVTAMD=""

function checkCPU(){

	osCPUText=$(cat /proc/cpuinfo | grep vendor_id | uniq)
	if [[ $osCPUText =~ "GenuineIntel" ]]; then
		osCPU="intel"
    else
        osCPU="amd"
    fi

	green " Status 状态显示--当前CPU是: $osCPU"
}


function installSoft(){
	${osSystemPackage} -y install wget curl 

	# https://stackoverflow.com/questions/11116704/check-if-vt-x-is-activated-without-having-to-reboot-in-linux
	${osSystemPackage} -y install cpu-checker

	# ${osSystemPackage} -y install git
	
}

function rebootSystem(){
	read -p "是否立即重启? 请输入[Y/n]?" isRebootInput
	isRebootInput=${isRebootInput:-Y}

	if [[ $isRebootInput == [Yy] ]]; then
		${sudoCmd} reboot
	else 
		exit
	fi
}

function promptContinueOpeartion(){
	read -p "是否继续操作? 直接回车默认继续操作, 请输入[Y/n]?" isContinueInput
	isContinueInput=${isContinueInput:-Y}

	if [[ $isContinueInput == [Yy] ]]; then
		echo ""
	else 
		exit
	fi
}




function updatePVEAptSource(){
	green " ================================================== "
	green " 准备关闭企业更新源, 添加非订阅版更新源 "
	${sudoCmd} sed -i 's|deb https://enterprise.proxmox.com/debian/pve buster pve-enterprise|#deb https://enterprise.proxmox.com/debian/pve buster pve-enterprise|g' /etc/apt/sources.list.d/pve-enterprise.list

	#echo 'deb http://download.proxmox.com/debian/pve buster pve-no-subscription' > /etc/apt/sources.list.d/pve-no-subscription.list
	echo "deb https://mirrors.tuna.tsinghua.edu.cn/proxmox/debian buster pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list

	wget http://download.proxmox.com/debian/proxmox-ve-release-6.x.gpg -O /etc/apt/trusted.gpg.d/proxmox-ve-release-6.x.gpg

	green " 更新源成功 "
	green " ================================================== "

	cat > /etc/apt/sources.list <<-EOF

deb http://mirrors.aliyun.com/debian/ buster main contrib non-free
deb-src http://mirrors.aliyun.com/debian/ buster main contrib non-free

deb http://mirrors.aliyun.com/debian/ buster-updates main contrib non-free
deb-src http://mirrors.aliyun.com/debian/ buster-updates main contrib non-free

deb http://mirrors.aliyun.com/debian/ buster-backports main contrib non-free
deb-src http://mirrors.aliyun.com/debian/ buster-backports main contrib non-free

deb http://mirrors.aliyun.com/debian-security buster/updates main contrib non-free
deb-src http://mirrors.aliyun.com/debian-security buster/updates main contrib non-free



deb http://deb.debian.org/debian buster main contrib non-free
deb-src http://deb.debian.org/debian buster main contrib non-free

deb http://deb.debian.org/debian buster-updates main contrib non-free
deb-src http://deb.debian.org/debian buster-updates main contrib non-free

deb http://deb.debian.org/debian buster-backports main contrib non-free
deb-src http://deb.debian.org/debian buster-backports main contrib non-free

deb http://deb.debian.org/debian-security/ buster/updates main contrib non-free
deb-src http://deb.debian.org/debian-security/ buster/updates main contrib non-free


EOF

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
	pveStatusVTIntelText=$(dmesg | grep VT-d)
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
			echo " dmesg | grep VT-d "
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

	green " 上面信息 Kernel driver in use 这一行是 vfio-pic, 则显卡设备被PVE屏蔽成功, 可以直通显卡 "
	green " 上面信息 Kernel driver in use 这一行是  i915 则显卡设备没有被PVE屏蔽, 无法直通显卡"
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

	read -p "是否增加pcie_acs_override=downstream 参数? 默认否, 请输入[y/N]?" isAddPcieGroupsInput
	isAddPcieGroupsInput=${isAddPcieGroupsInput:-n}

	read -p "是否增加iommu=pt 参数? 默认否, 请输入[y/N]?" isAddPciePTInput
	isAddPciePTInput=${isAddPciePTInput:-n}

	isAddPcieText=""
	if [[ $isAddPciePTInput == [Yy] ]]; then
		isAddPcieText="iommu=pt"
	fi

	if [[ $isAddPcieGroupsInput == [Yy] ]]; then
		isAddPcieText="${isAddPcieText} pcie_acs_override=downstream"
	fi


	# https://www.proxmox.wiki/?thread-32.htm
	# http://www.dannysite.com/blog/257/
	# https://www.10bests.com/pve-libreelec-kodi-htpc/

	read -p "是否增加video=efifb:off 参数用于显卡直通? 默认否, 请输入[y/N]?" isAddPcieVideoInput
	isAddPcieVideoInput=${isAddPcieVideoInput:-n}

	if [[ $isAddPcieVideoInput == [Yy] ]]; then
		isAddPcieText="${isAddPcieText} video=efifb:off,vesafb:off"

		echo
		yellow " 添加模块黑名单，即让GPU设备在下次系统启动之后不使用这些驱动，把设备腾出来给vfio驱动用: "
		read -p "请输入直通的显卡是Intel核显, nVidia, AMD? 默认Intel, 请输入[I/n/a]?" isAddPcieVideoCardBrandInput
		isAddPcieVideoCardBrandInput=${isAddPcieVideoCardBrandInput:-i}

		# 添加模块（驱动）黑名单，即让GPU设备在下次系统启动之后不使用这些驱动，把设备腾出来给vfio驱动用：

		if [[ $isAddPcieVideoCardBrandInput == [Ii] ]]; then
			# Intel核显：
			echo "blacklist snd_hda_intel" >> /etc/modprobe.d/pve-blacklist.conf
			echo "blacklist snd_hda_codec_hdmi" >> /etc/modprobe.d/pve-blacklist.conf
			echo "blacklist i915" >> /etc/modprobe.d/pve-blacklist.conf

		elif [[ $isAddPcieVideoCardBrandInput == [Nn] ]]; then
			# N卡/A卡：
			echo "blacklist nouveau" >> /etc/modprobe.d/pve-blacklist.conf
			echo "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf
		else
			# /A卡：
			echo "blacklist radeon" >> /etc/modprobe.d/pve-blacklist.conf
		fi

		echo
		yellow " 添加模块黑名单，是否添加直通显卡所带声卡和麦克风: "
		read -p "是否直通显卡所带声卡和麦克风, 直接回车默认是, 请输入[Y/n]?" isAddPcieVideoCardAudioInput
		isAddPcieVideoCardAudioInput=${isAddPcieVideoCardAudioInput:-y}
		
		if [[ $isAddPcieVideoCardAudioInput == [Yy] ]]; then
			echo "blacklist snd_soc_skl" >> /etc/modprobe.d/pve-blacklist.conf
		fi

		pveVfioVideoId=$(lspci -n | grep -E "0300" | awk '{print $3}' )
		pveVfioVideoIdText=$(lspci -n | grep -E "0300" | awk '{print $1, $3}' )
		pveVfioAudioId=$(lspci -n | grep -E "0403" | awk '{print $3}' )

		echo
		echo
		green " 绑定显卡和声卡设备到vfio模块, 用于显卡直通 "
		green " 显卡设备ID为 ${pveVfioVideoId} "
		green " 声卡设备ID为 ${pveVfioAudioId} "

		read -p "是否同时绑定显卡和声卡设备, 输入n为仅绑定显卡. 直接回车默认是, 请输入[Y/n]?" isAddPcieVideoAudoVfioInput
		isAddPcieVideoAudoVfioInput=${isAddPcieVideoAudoVfioInput:-y}
		
		if [[ $isAddPcieVideoAudoVfioInput == [Yy] ]]; then
			echo "options vfio-pci ids=${pveVfioVideoId},${pveVfioAudioId}" > /etc/modprobe.d/vfio.conf
		else 
			echo "options vfio-pci ids=${pveVfioVideoId}" > /etc/modprobe.d/vfio.conf
		fi

		update-initramfs -u

	fi

    if [[ $osCPU == "intel" ]]; then
		${sudoCmd} sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet.*"/GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on '"${isAddPcieText}"'"/g' /etc/default/grub
	else
		${sudoCmd} sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet.*"/GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on '"${isAddPcieText}"'"/g' /etc/default/grub
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
	displayIOMMUInfo

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

	${sudoCmd} sed -i 's/vfio.*/ /g' /etc/modules


	# 恢复显卡直通文件
	rm /etc/modprobe.d/kvm.conf
	rm /etc/modprobe.d/vfio.conf

	cat > "/etc/modprobe.d/pve-blacklist.conf" <<-EOF

# This file contains a list of modules which are not supported by Proxmox VE

# nidiafb see bugreport https://bugzilla.proxmox.com/show_bug.cgi?id=701
blacklist nvidiafb

EOF


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
	green " 请查看列出硬盘的ID"
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

	read -p "根据上面信息输入要选择的硬盘ID 编号, 直接回车默认为1: " dsmHDPTIdInput
	dsmHDPTIdInput=${dsmHDPTIdInput:-1}

	read -p "请输入虚拟机ID, 直接回车默认为101 请输入: " dsmHDPTVMIdInput
	dsmHDPTVMIdInput=${dsmHDPTVMIdInput:-101}

	read -p "请输入要给虚拟机的生成的硬盘设备编号, 直接回车默认为sata2 请输入sata1,sata3类似这种: " dsmHDPTVMHDIdInput
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

	read -p "是否继续操作? 请输入[Y/n]?" isContinueOpeartionInput
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
			green " 没有找到 ch_cpuinfo 命令, 开始自动下载 ch_cpuinfo 命令到 ${HOME} 目录 "
			mkdir -p ${HOME}
			wget -P ${HOME} https://github.com/FOXBI/ch_cpuinfo/raw/master/ch_cpuinfo_2.2.1/ch_cpuinfo.tar

			tar xvf ${HOME}/ch_cpuinfo.tar
			cpuInfoChangeRealPath="${HOME}/ch_cpuinfo"
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
	green " 请用root 用户登录群晖系统的SSH 运行本命令"
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





function start_menu(){
    clear

    if [[ $1 == "first" ]] ; then
        installSoft
    fi
	checkCPU

    green " =================================================="
    green " PVE 虚拟机 和 群晖 工具脚本 2021-03-08 更新. By jinwyp. 系统支持：PVE / debian10"
    green " =================================================="
	green " 1. PVE 关闭企业更新源, 添加非订阅版更新源"
    green " 2. PVE 开启IOMMU 用于支持直通, 需要在BIOS先开启VT-d"
    green " 3. PVE 关闭IOMMU 关闭直通 恢复默认设置"
    green " 4. 检测系统是否支持 IOMMU, VT-d VT-d"
    green " 5. 检测系统是否开启显卡直通"

	echo
	green " 6. PVE安装群晖 使用 qm importdisk 命令导入引导文件synoboot.img, 生成硬盘设备"
	green " 7. PVE安装群晖 使用 img2kvm 命令导入引导文件synoboot.img, 生成硬盘设备"
	green " 8. PVE安装群晖 使用 qm set 命令添加整个硬盘(直通) 生成硬盘设备"
	echo
	green " 11. 群晖补丁 开启ssh root登录"
	green " 12. 群晖补丁 填入洗白的序列号和网卡Mac地址"
	green " 13. 群晖补丁 使用vi 编辑/grub/grub.cfg 引导文件"
	green " 14. 群晖补丁 使用vi 编辑/etc/host 文件"
	green " 15. 群晖补丁 修复DSM 6.2.3 找不到/dev/synoboot 从而升级失败问题"
	green " 16. 群晖补丁 修复CPU型号显示错误"
	green " 17. 群晖补丁 正确识别 Nvme 固态硬盘"	
	green " 18. 群晖检测 是否有显卡或是否显卡直通成功 支持硬解"	
	echo
    green " 0. 退出脚本"
    echo
    read -p "请输入数字:" menuNumberInput
    case "$menuNumberInput" in
        1 )
            updatePVEAptSource
        ;;	
        2 )
            enableIOMMU
        ;;
        3 )
            disableIOMMU
        ;;
        4 )
            checkIOMMU
			checkIOMMUDMAR
        ;;
        5 )
            checkVfio
        ;;
        6 )
            genPVEVMDiskWithQM
        ;;
        7 )
            genPVEVMDiskWithQM "Img2kvm"
        ;;
        8 )
            genPVEVMDiskPT
        ;;	
        11 )
            DSMOpenSSHRoot
        ;;				
        12 )
            DSMFixSNAndMac 
        ;;				
        13 )
            DSMFixSNAndMac "vi"
        ;;	
        14 )
            DSMEditHosts
        ;;				
        15 )
            DSMFixDevSynoboot  
        ;;	
        16 )
            DSMFixCPUInfo
        ;;						
        17 )
            DSMFixNvmeSSD
        ;;		
        18 )
            DSMCheckVideoCardPassThrough 
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

