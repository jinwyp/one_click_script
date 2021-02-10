#!/bin/bash


# source https://gist.github.com/saltlakeryan/e12aafd09528ff77c346

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



function main() {
	echo $1
	if [[ -n $1 ]]; then
		saveDateToFile

		if [[ $1 == "firstrun" ]]; then
			setCrontab
			setIP

			cp /mnt/usb1/date.sh /root/date.sh 
			chmod +x /root/date.sh 
			apt-get install ifupdown2
		fi	
	else
		setDateFromFile
	fi
}




dateFilePath="/root/date.log"
function saveDateToFile(){
	green " ================================================== "
	echo "Save system date to file $dateFilePath "
	date +'%Y-%m-%d %H:%M:%S' > $dateFilePath
	cat $dateFilePath
}

function setDateFromFile(){
	green " ================================================== "
	echo "Set system date from file $dateFilePath "
	currentDate=`cat $dateFilePath`
	echo "$currentDate"
	date -s "$currentDate"

	hwclock --set --date "$currentDate"
	hwclock --hctosys
}



function setCrontab(){
	# 设置 cron 定时任务
    # https://stackoverflow.com/questions/610839/how-can-i-programmatically-create-a-new-cron-job

    # (crontab -l 2>/dev/null | grep -v '^[a-zA-Z]'; echo "15 4 * * 0,1,2,3,4,5,6 systemctl restart trojan.service") | sort - | uniq - | crontab -
    (crontab -l ; echo "@reboot /root/date.sh") | sort - | uniq - | crontab -
    (crontab -l ; echo "10 4 * * 0,1,2,3,4,5,6 /root/date.sh savedate") | sort - | uniq - | crontab -

}

function setIP(){
	# https://pve.proxmox.com/pve-docs/chapter-sysadmin.html#sysadmin_network_configuration


	read -p "Please input IP address (default:192.168.7.200) ?" IPInput
	read -p "Please input IP netmask (default:255.255.255.0) ?" netmaskInput
	read -p "Please input IP gateway (default:192.168.7.1) ?" gatewayInput

	IPInput=${IPInput:-192.168.7.200}
	netmaskInput=${netmaskInput:-255.255.255.0}
	gatewayInput=${gatewayInput:-192.168.7.1}


    cat > /etc/network/interfaces <<-EOF

source /etc/network/interfaces.d/*


auto lo
iface lo inet loopback


allow-hotplug enp1s0
iface enp1s0 inet static
    address ${IPInput}
    netmask ${netmaskInput}
    gateway ${gatewayInput}
    bridge_ports eno1
    bridge_stp off
    bridge_fd 0
EOF

sed -i "s/10\.100\.99\.1/${IPInput}/g" /etc/issue
sed -i "s/10\.100\.99\.1/${IPInput}/g" /etc/hosts

}





function mount_usb() {
	green " ================================================== "
	echo "Run Command : lsblk"
	lsblk
	echo
	green " ================================================== "
	echo "Run Command : blkid"
	blkid
	echo
	green " ================================================== "
	echo "  Starting mount usb drive "

	deviceUSB1="/dev/sda1"
	deviceUSB2="/dev/sdb1"

	MountDIR1="/mnt/usb1"
	MountDIR2="/mnt/usb2"

	if [ -b "$deviceUSB1" ]; then
		green "$deviceUSB1 is a block device. Mount to ${MountDIR1}"
		mkdir -p $MountDIR1
		mount -o rw $deviceUSB1 $MountDIR1
	fi

	if [ -b "$deviceUSB2" ]; then
		echo "$deviceUSB2 is a block device. . Mount to ${MountDIR2}"
		mkdir -p $MountDIR2
		mount -o rw $deviceUSB2 $MountDIR2
	fi

}


main $1