#!/bin/sh



checkArchitecture(){
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


getLinuxOSRelease(){

    checkArchitecture

    # NAME="OpenWrt"
    # VERSION="SNAPSHOT"
    # ID="openwrt"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        osInfo=$NAME
        osID=$ID
        osReleaseVersionNo=$VERSION_ID
    fi

    echo "OS: ${osInfo}, ${ID}, ${VERSION_ID}   CPU: $osArchitecture"
}


getGithubLatestReleaseVersion(){
    # https://github.com/p4gefau1t/trojan-go/issues/63
    wget --no-check-certificate -qO- https://api.github.com/repos/$1/tags | grep 'name' | cut -d\" -f4 | head -1 | cut -b 1-
}



mosdnsDownloadPath="/tmp"
mosdnsLogFilePath="/tmp/mosdns.log"
mosdnsEtcPath="/etc/mosdns"

getIPDKdownloadFilename(){
    # mosdnsIPK_array=($(wget -qO- https://op.supes.top/packages/x86_64/ | grep -E "mosdns|v2ray" | awk -F'<a href=\"' '/ipk/{print $2}' | cut -d\" -f1 | sort -V))

    mosdnsFilename="mosdns_8bc1821-84_x86_64.ipk"
    mosdnsNeoFilename="mosdns-neo_abcb222-73_x86_64.ipk"
    mosdnsLuciFilename="luci-app-mosdns_git-22.189.25450-61bab3a_all.ipk"

    mosdnsUrl="https://op.supes.top/packages/x86_64/mosdns_8bc1821-84_x86_64.ipk"
    mosdnsNeoUrl="https://op.supes.top/packages/x86_64/mosdns_8bc1821-84_x86_64.ipk"
    mosdnsLuciUrl="https://op.supes.top/packages/x86_64/luci-app-mosdns_git-23.275.44892-e5a38e2_all.ipk"

    v2rayGeoSiteFilename="v2ray-geosite_20220425025949-4_all.ipk"
    v2rayGeoIpFilename="v2ray-geoip_202204210050-4_all.ipk"

    v2rayGeoSiteUrl="https://op.supes.top/packages/x86_64/v2ray-geosite_202203020836-6_all.ipk"
    v2rayGeoIpUrl="https://op.supes.top/packages/x86_64/v2ray-geoip_202203020834-6_all.ipk"


    mosdnsIPK_array=$(wget -qO- https://op.supes.top/packages/x86_64/ | grep -E "mosdns|v2ray" | awk -F'<a href=\"' '/ipk/{print $2}' | cut -d\" -f1 | sort -V)

    echo " 准备下载并安装以下文件"

    for filename in ${mosdnsIPK_array}; do

        if [ "${filename#*luci-app-mosdns}" != "$filename" ]; then
            mosdnsLuciFilename="${filename}"
            mosdnsLuciUrl="https://op.supes.top/packages/x86_64/${mosdnsLuciFilename}"
            echo "1 ${mosdnsLuciFilename}"

        elif [ "${filename#*mosdns-neo}" != "$filename" ]; then
            mosdnsNeoFilename="${filename}"
            mosdnsNeoUrl="https://op.supes.top/packages/x86_64/${mosdnsNeoFilename}"
            echo "2 ${mosdnsNeoFilename}"

        elif [ "${filename#*mosdns}" != "$filename" ]; then
            mosdnsFilename="${filename}"
            mosdnsUrl="https://op.supes.top/packages/x86_64/${mosdnsFilename}"
            echo "3 ${mosdnsFilename}"

        elif [ "${filename#*geosite}" != "$filename" ]; then
            v2rayGeoSiteFilename="${filename}"
            v2rayGeoSiteUrl="https://op.supes.top/packages/x86_64/${v2rayGeoSiteFilename}"
            echo "4 $v2rayGeoSiteFilename"

        elif [ "${filename#*geoip}" != "$filename" ]; then
            v2rayGeoIpFilename="${filename}"
            v2rayGeoIpUrl="https://op.supes.top/packages/x86_64/${v2rayGeoIpFilename}"
            echo "5 $v2rayGeoIpFilename"            
        else
            tempUrlXX=""
        fi
    done
}


installMosdns(){
    getLinuxOSRelease

    echo
    echo " ================================================== "

    if [ "${osInfo}" = "OpenWrt" ]; then
        if [ "${osArchitecture}" = "amd64" ]; then
            echo " Prepare to install Mosdns on OpenWrt X86"
            echo " 准备安装 OpenWrt X86 Mosdns, 通过 opkg 安装"
        else
            echo " Prepare to install Mosdns on OpenWrt Arm Openwrt ! "
            echo " 准备安装 OpenWrt Arm Mosdns, 如果安装失败 请在下面页面自行查找对应Arm版本进行安装 ! "
            echo " https://github.com/sbwml/luci-app-mosdns/releases ! "
            echo
            echo " 手动安装方法: "
            echo " 下载文件 v2ray-geoip_2022-07-04_all.ipk, v2ray-geosite_2022-07-04_all.ipk "
            echo " 下载文件 mosdns_4.1.5-1_arm_cortex-a7.ipk, luci-app-mosdns_1.4_all.ipk "
            echo " 把已下载文件 通过 ssh 或 ftp 上传到路由器上 例如上传到 /tmp 目录后 "
            echo " 运行命令 cd /tmp "
            echo " 运行命令 opkg install v2ray-geoip_2022-07-04_all.ipk v2ray-geosite_2022-07-04_all.ipk"
            echo " 运行命令 opkg install mosdns_4.1.5-1_arm_cortex-a7.ipk luci-app-mosdns_1.4_all.ipk "
            exit
        fi
    else
        echo " ================================================== "
        echo " For Other linux platform, please use the script below:  "
        echo " 针对非 OpenWrt 的 linux 系统, 请使用如下脚本安装: "
        echo " wget --no-check-certificate https://raw.githubusercontent.com/jinwyp/one_click_script/master/trojan_v2ray_install.sh && chmod +x ./trojan_v2ray_install.sh && ./trojan_v2ray_install.sh "
        echo
        exit
    fi

    echo
    echo " 请保证网络可以正常访问 github.com"
    echo " 如果不能正常访问 github.com 将会导致下载文件失败从而无法正常安装"
    echo " 请访问下面的链接 来检查是否可以正常访问 github.com"
    echo " https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt"
    echo


    cd "${mosdnsDownloadPath}" || exit



    getIPDKdownloadFilename


    geositeFilename="geosite.dat"
    geoipFilename="geoip.dat"
    # cnipFilename="cn.dat"

    # versionV2rayRulesDat=$(getGithubLatestReleaseVersion "Loyalsoldier/v2ray-rules-dat")
    # geositeUrl="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
    # geoipeUrl="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
    # cnipUrl="https://github.com/Loyalsoldier/geoip/releases/download/202205120123/cn.dat"

    geositeUrl="https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat"
    geoipeUrl="https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat"
    # cnipUrl="https://raw.githubusercontent.com/Loyalsoldier/geoip/release/cn.dat"



   
    echo
    echo " ================================================== "
    echo " 请填写mosdns运行的端口号 默认端口5335"
    echo
    read -r -p "请填写mosdns运行的端口号? 默认直接回车为5335, 请输入纯数字:" isMosDNSServerPortInput
    isMosDNSServerPortInput=${isMosDNSServerPortInput:-5335}

    mosDNSServerPort="5335"
    isNumberMosdnsPort=$(echo $mosDNSServerPort | grep -E '^[+-]?[0-9]+$')
    if [ -n "${isNumberMosdnsPort}" ] ; then
        mosDNSServerPort="${isMosDNSServerPortInput}"
    fi

    echo
    echo " ================================================== "
    echo " 是否添加自建的DNS服务器, 默认直接回车不添加"
    echo " 选是为添加DNS服务器, 建议先架设好DNS服务器后再运行此脚本"
    echo " 本脚本默认已经内置了多个DNS服务器地址"
    echo
    read -r -p "是否添加自建的DNS服务器? 默认直接回车为不添加, 请输入[y/N]:" isAddNewDNSServerInput
    isAddNewDNSServerInput=${isAddNewDNSServerInput:-n}

    addNewDNSServerIPText=""
    addNewDNSServerDomainText=""
    if [[ "$isAddNewDNSServerInput" == [Nn] ]]; then
        echo 
    else
        echo
        echo " ================================================== "
        echo " 请输入自建的DNS服务器IP 格式例如 1.1.1.1"
        echo " 请保证端口53 提供DNS解析服务, 如果是非53端口请填写端口号, 格式例如 1.1.1.1:8053"
        echo 
        read -r -p "请输入自建DNS服务器IP地址, 请输入:" isAddNewDNSServerIPInput

        if [ -n "${isAddNewDNSServerIPInput}" ]; then
        read -r -d '' addNewDNSServerIPText << EOM
        - addr: "udp://${isAddNewDNSServerIPInput}"
          idle_timeout: 500
          trusted: true
EOM

        fi

        echo
        echo " ================================================== "
        echo " 请输入自建的DNS服务器的域名 用于提供DOH服务, 格式例如 www.dns.com"
        echo " 请保证服务器在 /dns-query 提供DOH服务, 例如 https://www.dns.com/dns-query"
        echo 
        read -r -p "请输入自建DOH服务器的域名, 不要输入https://, 请直接输入域名:" isAddNewDNSServerDomainInput

        if [ -n "${isAddNewDNSServerDomainInput}" ]; then
        read -r -d '' addNewDNSServerDomainText << EOM
        - addr: "https://${isAddNewDNSServerDomainInput}/dns-query"       
          idle_timeout: 400
          trusted: true
EOM
        fi
    fi





    echo
    echo " ================================================== "
    echo " Downloading mosdns.  开始下载 mosdns.ipk 等相关文件"
    echo
    wget -O ${mosdnsDownloadPath}/${mosdnsFilename} ${mosdnsUrl}
    #wget -O ${mosdnsDownloadPath}/${mosdnsNeoFilename} ${mosdnsNeoUrl}
    wget -O ${mosdnsDownloadPath}/${mosdnsLuciFilename} ${mosdnsLuciUrl}

    wget -O ${mosdnsDownloadPath}/${v2rayGeoSiteFilename} ${v2rayGeoSiteUrl}
    wget -O ${mosdnsDownloadPath}/${v2rayGeoIpFilename} ${v2rayGeoIpUrl}


    echo
    echo " Downloading cn.dat, geosite.dat, geoip.dat.  开始下载 cn.dat geosite.dat geoip.dat  等相关文件"
    echo
    echo " 请保证网络可以正常访问 github.com"
    echo " 如果不能正常访问 github.com 将会导致下载文件失败从而无法正常安装"
    echo

    if [ ! -f "${mosdnsDownloadPath}/${geositeFilename}" ]; then
        wget -O ${mosdnsDownloadPath}/${geositeFilename} ${geositeUrl}
        wget -O ${mosdnsDownloadPath}/${geoipFilename} ${geoipeUrl}
    fi 

    if [ ! -f "${mosdnsDownloadPath}/${geositeFilename}" ]; then
        echo
        echo " ${geositeUrl}"
        echo " 下载失败, 请检查网络是否可以正常访问 gitHub.com"
    fi 

    if [ ! -f "${mosdnsDownloadPath}/${geoipFilename}" ]; then
        echo
        echo " ${geoipeUrl}"
        echo " 下载失败, 请检查网络是否可以正常访问 gitHub.com"
    fi


    echo
    echo " ================================================== "    
    echo " Install mosdns.ipk and luci-app-mosdns.ipk. 开始安装 mosdns.ipk luci-app-mosdns.ipk"
    echo

    rm -f /etc/config/mosdns
    rm -f /etc/config/mosdns-opkg

    rm -f "${mosdnsLogFilePath}"
    rm -rf "${mosdnsEtcPath}"

    opkg install ${v2rayGeoSiteFilename}
    opkg install ${v2rayGeoIpFilename}

    opkg install ${mosdnsFilename}
    opkg install ${mosdnsLuciFilename}


    mkdir -p ${mosdnsEtcPath}

    if [ -f "${mosdnsDownloadPath}/${geositeFilename}" ]; then
        cp -f ${mosdnsDownloadPath}/${geositeFilename} ${mosdnsEtcPath}
    else
        cp -f /usr/share/v2ray/${geositeFilename} ${mosdnsEtcPath}
    fi

    if [ -f "${mosdnsDownloadPath}/${geoipFilename}" ]; then
        cp -f ${mosdnsDownloadPath}/${geoipFilename} ${mosdnsEtcPath}
    else
        cp -f /usr/share/v2ray/${geoipFilename} ${mosdnsEtcPath}
    fi 


    cat > "${mosdnsEtcPath}/cus_config.yaml" <<-EOF    

log:
  level: info
  file: "${mosdnsLogFilePath}"

data_providers:
  - tag: geosite
    file: ./geosite.dat
    auto_reload: true
  - tag: geoip
    file: ./geoip.dat
    auto_reload: true

plugins:
  # 缓存
  - tag: cache
    type: cache
    args:
      size: 2048
      lazy_cache_ttl: 3600
      cache_everything: true

  # hosts map
  # - tag: map_hosts
  #   type: hosts
  #   args:
  #     hosts:
  #       - 'google.com 0.0.0.0'
  #       - 'api.miwifi.com 127.0.0.1'
  #       - 'www.baidu.com 0.0.0.0'

  # 转发至本地服务器的插件
  - tag: forward_local
    type: fast_forward
    args:
      upstream:
        - addr: "udp://223.5.5.5"
          trusted: true
        - addr: "udp://119.29.29.29"
          trusted: false


  # 转发至远程服务器的插件
  - tag: forward_remote
    type: fast_forward
    args:
      upstream:
${addNewDNSServerIPText}
${addNewDNSServerDomainText}
        - addr: "udp://208.67.222.222"
          trusted: true

        - addr: "udp://1.0.0.1"
          trusted: true
        - addr: "https://dns.cloudflare.com/dns-query"
          idle_timeout: 400
          trusted: true

        - addr: "udp://5.2.75.231"
          idle_timeout: 400
          trusted: true

        - addr: "udp://185.121.177.177"
          idle_timeout: 400
          trusted: true        

        - addr: "udp://94.130.180.225"
          idle_timeout: 400
          trusted: true     

        - addr: "udp://78.47.64.161"
          idle_timeout: 400
          trusted: true 

        - addr: "udp://51.38.83.141"          

        - addr: "udp://176.9.93.198"
        - addr: "udp://176.9.1.117"                  

        - addr: "udp://88.198.92.222"                  


  # 匹配本地域名的插件
  - tag: query_is_local_domain
    type: query_matcher
    args:
      domain:
        - 'provider:geosite:cn'

  - tag: query_is_gfw_domain
    type: query_matcher
    args:
      domain:
        - 'provider:geosite:gfw'

  # 匹配非本地域名的插件
  - tag: query_is_non_local_domain
    type: query_matcher
    args:
      domain:
        - 'provider:geosite:geolocation-!cn'

  # 匹配广告域名的插件
  - tag: query_is_ad_domain
    type: query_matcher
    args:
      domain:
        - 'provider:geosite:category-ads-all'

  # 匹配本地 IP 的插件
  - tag: response_has_local_ip
    type: response_matcher
    args:
      ip:
        - 'provider:geoip:cn'


  # 主要的运行逻辑插件
  # sequence 插件中调用的插件 tag 必须在 sequence 前定义，
  # 否则 sequence 找不到对应插件。
  - tag: main_sequence
    type: sequence
    args:
      exec:
        # hosts map
        # - map_hosts

        # 缓存
        - cache

        # 屏蔽广告域名 ad block
        - if: query_is_ad_domain
          exec:
            - _new_nxdomain_response
            - _return

        # 已知的本地域名用本地服务器解析
        - if: query_is_local_domain
          exec:
            - forward_local
            - _return

        - if: query_is_gfw_domain
          exec:
            - forward_remote
            - _return

        # 已知的非本地域名用远程服务器解析
        - if: query_is_non_local_domain
          exec:
            - _prefer_ipv4
            - forward_remote
            - _return

          # 剩下的未知域名用 IP 分流。
          # primary 从本地服务器获取应答，丢弃非本地 IP 的结果。
        - primary:
            - forward_local
            - if: "(! response_has_local_ip) && [_response_valid_answer]"
              exec:
                - _drop_response
          secondary:
            - _prefer_ipv4
            - forward_remote
          fast_fallback: 200
          always_standby: true

servers:
  - exec: main_sequence
    listeners:
      - protocol: udp
        addr: ":${mosDNSServerPort}"
      - protocol: tcp
        addr: ":${mosDNSServerPort}"


EOF


    echo
    echo " ================================================== "
    echo " Install mosdns success! 安装 mosdns 成功!"
    echo " mosdns running at port ${mosDNSServerPort}! 运行端口: ${mosDNSServerPort}!"
    echo " 查看访问日志: cat ${mosdnsLogFilePath}"

    echo " 请进入OpenWRT管理菜单: 服务-> MosDNS -> MosDNS 配置文件选择 下拉框选择 自定义配置 !"
    echo " 然后勾选 启用 复选框后, 点击 保存&应用 按钮 启动 MosDNS !"
    echo " ================================================== "
    echo
}



removeMosdns(){

    echo
    echo " =================================================="
    echo " 准备卸载 Mosdns on OpenWRT"
    echo " =================================================="
    echo

    opkg remove luci-app-mosdns
    opkg remove mosdns

    rm -f "${mosdnsLogFilePath}"
    rm -rf "${mosdnsEtcPath}"

    rm -f /etc/config/mosdns
    rm -f /etc/config/mosdns-opkg



    echo
    echo " ================================================== "
    echo "  Mosdns 卸载完毕 !"
    echo " ================================================== "

}


main(){

    if [ -z "$1" ]; then
        installMosdns
    else
        removeMosdns
    fi

}

main $1


