#!/bin/ash
# FixSynoboot() extracted from Jun 1.04b loader
# added hotplug-out event to gracefully clean up esata volumes 2020-Apr-18
# cleaned up share references in message log and root folder 2020-May-16

FixSynoboot()
{
if [ ! -e /dev/synoboot ]; then
  tail -n+3 /proc/partitions | while read major minor sz name
  do
    if echo $name | grep -q "^sd[[:alpha:]]*$";then
      basename=$name
      minor0=$minor
      synoboot1=""
      synoboot2=""
      continue
    fi
    if [ $name = "${basename}1" -a $sz -le 512000 ]; then
      synoboot1="$name"
      minor1=$minor
    elif [ $name = "${basename}2" -a $sz -le 512000 ]; then
      synoboot2="$name"
      minor2=$minor
    else
      continue
    fi
    if [ -n "$synoboot1" -a -n "$synoboot2" ]; then
      # begin hotplug event added
      if [ -e /sys/class/block/$basename ]; then
        port=$(synodiskport -portcheck $basename)
        df | grep "^/dev/$basename." | while read share; do
          share=$(echo $share | awk '{print $1,$NF}')
          sharedir=$(echo $share | awk '{print $2}')
          sharebase=$(echo $sharedir | awk -F\/ '{print $2}')
          sharedir=$(echo $sharedir | awk -F\/ '{print $3}')
          if ( synocheckshare --vol-unmounting $port $share ); then
            umount $(echo $share | awk '{print $1}')
            grep -v "^$share" /run/synostorage/volumetab >/tmp/volumetab
            mv /tmp/volumetab /run/synostorage/volumetab
            rm "/$sharebase/@eaDir/$sharedir/SYNO@.attr"
            find "/$sharebase" -empty -type d -delete 2>/dev/null
          fi
        done
        echo "remove" >/sys/class/block/$basename/uevent
      fi
      # end

      rm "/dev/$basename"
      rm "/dev/$synoboot1"
      rm "/dev/$synoboot2"
      rm "/dev/${basename}3"
      mknod /dev/synoboot b $major $minor0
      mknod /dev/synoboot1 b $major $minor1
      mknod /dev/synoboot2 b $major $minor2
      break
    fi
  done
fi
}

RUNAS="root"

case $1 in
    start)
	FixSynoboot
        exit 0
        ;;
    stop)
        exit 0
        ;;
    status)
        exit 0
        ;;
    log)
        exit 1
        ;;
    *)
        exit 1
        ;;
esac
