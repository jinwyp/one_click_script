#!/bin/bash

Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"

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





UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36";

configWARPPortFilePath="${HOME}/wireguard/warp-port"
configWARPPortLocalServerPort="40000"
warpPortInput="${1:-40000}"

isAutoRefreshWarp=""

function testWARPEnabled(){

    if [[ -f "${configWARPPortFilePath}" ]]; then
        configWARPPortLocalServerPort="$(cat ${configWARPPortFilePath})"
        yellow "检测到本机已安装 WARP Sock5, 端口号 ${configWARPPortLocalServerPort}"
        echo
    fi

    if [[  "$isAutoRefreshWarp" == "true" ]]; then
        warpPortInput="${configWARPPortLocalServerPort}"
    else
        read -p "请输入WARP Sock5 端口号? 直接回车默认${configWARPPortLocalServerPort}, 请输入纯数字:" warpPortInput
        warpPortInput=${warpPortInput:-$configWARPPortLocalServerPort}
    fi
    echo

}

isIPV6Enabled="false"
function testIPV6Enabled(){
    cmdCatIpv6=$(cat /sys/module/ipv6/parameters/disable)
    isIPV6Enabled="false"

    if [[ ${cmdCatIpv6} == "0" ]]; then
        isIPV6Enabled="true"
    fi

    cmd1SysCtlIpv6=$(sysctl -a 2>/dev/null | grep net.ipv6.conf.all.disable_ipv6 | awk -F  " " '{print $3}' )
    cmd2SysCtlIpv6=$(sysctl -a 2>/dev/null | grep net.ipv6.conf.default.disable_ipv6 | awk -F  " " '{print $3}' )

    if [[ ${cmd1SysCtlIpv6} == "0" && ${cmd2SysCtlIpv6} == "0" ]]; then
        isIPV6Enabled="true"
    fi
}


function testNetflixAll(){
    curlCommand="curl --connect-timeout 10 -sL"
    curlInfo="IPv4"

    if [[ $1 == "ipv4" ]]; then
        bold " 开始测试本机的IPv4 解锁 Netflix 情况"
        curlCommand="${curlCommand} -4"
        curlInfo="IPv4"

    elif [[ $1 == "ipv4warp" ]]; then

        read -r -p "是否测试本机 IPv4 WARP Sock5 代理? 直接回车默认不测试 请输入[y/N]:" isIpv4WARPContinueInput
        isIpv4WARPContinueInput=${isIpv4WARPContinueInput:-n}

        if [[ ${isIpv4WARPContinueInput} == [Nn] ]]; then
            red " 已退出本机 IPv4 WARP Sock5 代理测试"
            echo
            return
        else
            testWARPEnabled

            bold " 开始测试本机的IPv4 通过CloudFlare WARP 解锁 Netflix 情况"
            curlCommand="${curlCommand} -x socks5h://127.0.0.1:${warpPortInput}"
            curlInfo="IPv4 CloudFlare WARP"
        fi


    elif [[ $1 == "ipv6" ]]; then

        if [[ "${isIPV6Enabled}" == "false" ]]; then
            red " 本机IPv6 没有开启 是否继续测试IPv6 "
            read -r -p "是否继续测试IPv6? 直接回车默认不继续测试 请输入[y/N]:" isIpv6ContinueInput
            isIpv6ContinueInput=${isIpv6ContinueInput:-n}

            if [[ ${isIpv6ContinueInput} == [Nn] ]]; then
                red " 已退出 本机IPv6 测试 "
                echo
                return
            else
                echo
                bold " 开始测试本机的IPv6 解锁 Netflix 情况"
                curlCommand="${curlCommand} -6"
                curlInfo="IPv6"
            fi
        else
                bold " 开始测试本机的IPv6 解锁 Netflix 情况"
                curlCommand="${curlCommand} -6"
                curlInfo="IPv6"

        fi


    elif [[ $1 == "ipv6warp" ]]; then
        bold " 开始测试本机的IPv6 通过CloudFlare WARP 解锁 Netflix 情况"
        curlCommand="${curlCommand} -6"
        curlInfo="IPv6 CloudFlare WARP"

    else
        red " 没有选择要进行的测试 已退出! "
        return

    fi

    # curl 参数说明
    # --connect-timeout <seconds> Maximum time allowed for connection
    # -4, --ipv4          Resolve names to IPv4 addresses
    # -s, --silent        Silent mode
    # -S, --show-error    Show error even when -s is used
    # -L, --location      Follow redirects
    # -i, --include       Include protocol response headers in the output
    # -f, --fail          Fail silently (no output at all) on HTTP errors


    testNetflixOneMethod "${curlCommand}" "${curlInfo}"
    echo

}

function testNetflixOneMethod(){
    # https://stackoverflow.com/questions/3869072/test-for-non-zero-length-string-in-bash-n-var-or-var

    if [[ -n "$1" ]]; then

        netflixLinkIndex="https://www.netflix.com/"
        netflixLinkOwn="https://www.netflix.com/title/80018499"


        # green " Test Url: $1 -S ${netflixLinkIndex}"
        resultIndex=$($1 -S ${netflixLinkIndex} 2>&1)
        
        if [[ "${resultIndex}" == "curl"* ]];then
            red " 网络错误 无法打开 Netflix 网站"
            return
        fi
        
        if [[ -z "${resultIndex}" ]];then
            resultIndex2=$($1 -S ${netflixLinkIndex} 2>&1)
            if [[ -z "${resultIndex2}" ]];then
                red " 已被 Netflix 屏蔽, 403 访问错误 "
                return
            fi
        fi

        if [ "${resultIndex}" == "Not Available" ];then
            red " Netflix 不提供此地区服务 "
            if [[  "$isAutoRefreshWarp" == "true" ]]; then
                echo
            else
                return
            fi
            
        fi





        # green " Test Url: $1 -S ${netflixLinkOwn}"
        resultOwn=$($1 -S ${netflixLinkIndex} 2>&1)

        if [[ "${resultOwn}" == *"page-404"* ]] || [[ "${resultOwn}" == *"NSEZ-403"* ]];then
            red " 本机 $2 不能播放 Netflix 任何剧集"
            return
        fi


        # green " Test Url: $1 -fi https://www.netflix.com/title/80018499 2>&1 | sed -n '8p'"
        resultRegion=`tr [:lower:] [:upper:] <<< $($1 -fi "https://www.netflix.com/title/80018499" 2>&1 | sed -n '8p' | awk '{print $2}' | cut -d '/' -f4 | cut -d '-' -f1)`

        netflixRegion="${resultRegion}"
        # echo "x-robots-tag: ${netflixRegion}"

        if [[ "${resultRegion}" == *"INDEX"* ]] || [[ "${resultRegion}" == *"index"* ]];then
           netflixRegion="US"
        fi

        result1=$($1 -S "https://www.netflix.com/title/70143836" 2>&1)
        result2=$($1 -S "https://www.netflix.com/title/80027042" 2>&1)
        result3=$($1 -S "https://www.netflix.com/title/70140425" 2>&1)
        result4=$($1 -S "https://www.netflix.com/title/70283261" 2>&1)
        result5=$($1 -S "https://www.netflix.com/title/70143860" 2>&1)
        result6=$($1 -S "https://www.netflix.com/title/70202589" 2>&1)
        result7=$($1 -S "https://www.netflix.com/title/70305903" 2>&1)

        if [[ "$result1" == *"page-404"* ]] && [[ "$result2" == *"page-404"* ]] && [[ "$result3" == *"page-404"* ]] && [[ "$result4" == *"page-404"* ]] && [[ "$result5" == *"page-404"* ]] && [[ "$result6" == *"page-404"* ]]; then
            yellow " 本机 $2 仅解锁 Netflix 自制剧, 无法播放非自制剧. 区域: ${netflixRegion}"
            
            if [[ $2 == "IPv4 CloudFlare WARP Refresh" ]]; then
                echo
                green " 重启Warp 用于刷新能解锁IP, $2"
                warp_restart
                sleep 2
                
                autoRefreshWarpIP
            fi
            return
        fi

        green " 恭喜 本机 $2 解锁 Netflix 全部剧集 包括非自制剧. 区域: ${netflixRegion} "
        return

    else
        red " 要进行的测试 Url为空! "
    fi


}



function warp_restart(){
    if [ -f /etc/wireguard/wgcf.conf ]; then
        systemctl restart wg-quick@wgcf
        sleep 2
    fi

    if [ -f /usr/bin/warp-cli ]; then
        # systemctl restart warp-svc
        # sleep 3
        warp-cli --accept-tos delete 
        sleep 2
        warp-cli --accept-tos register 
        sleep 2
        warp-cli --accept-tos connect
        sleep 2

    fi
    green " 已经完成 重启Warp "
}


counter=1
function autoRefreshWarpIPStart(){

    if [[  "$isAutoRefreshWarp" == "true" ]]; then
        testWARPEnabled
        autoRefreshWarpIP
    fi

}

function autoRefreshWarpIP(){
    # https://stackoverflow.com/questions/13638670/adding-counter-in-shell-script

    if [[  "$isAutoRefreshWarp" == "true" ]]; then

        echo 
        time=$(date "+%Y-%m-%d %H:%M:%S")
        green " $time 开始自动刷新 WARP IP, 默认尝试20次 此次为第${counter}次"
        echo
        curlCommand="curl --connect-timeout 10 -sL"
        curlInfo="IPv4 CloudFlare WARP Refresh"

        

        if [ -f /usr/bin/warp-cli ]; then
            bold " 开始测试本机的IPv4 通过CloudFlare WARP sock5 解锁 Netflix 情况"
            curlCommand="${curlCommand} -x socks5h://127.0.0.1:${warpPortInput}"
        else
            bold " 开始测试本机的IPv6 通过CloudFlare WARP 解锁 Netflix 情况"
            curlCommand="${curlCommand} -6"
        fi
        

        if [[ "$counter" -gt 20 ]]; then
            exit 1
        else
            counter=$((counter+1))
            testNetflixOneMethod "${curlCommand}" "${curlInfo}"
        fi
        echo
    fi

}



















function testYoutubeAll(){
#    curlCommand="curl --connect-timeout 10 -s --user-agent ${UA_Browser}"
    curlCommand="curl --connect-timeout 10 -s"
    curlInfo="IPv4"

    if [[ $1 == "ipv4" ]]; then
        bold " 开始测试本机的IPv4 解锁 Youtube Premium 情况"
        curlCommand="${curlCommand} -4"
        curlInfo="IPv4"

    elif [[ $1 == "ipv4warp" ]]; then

        if [[ ${isIpv4WARPContinueInput} == [Nn] ]]; then
            red " 已退出本机 IPv4 WARP Sock5 代理测试"
            echo
            return
        else

            bold " 开始测试本机的IPv4 通过CloudFlare WARP 解锁 Youtube Premium 情况"
            curlCommand="${curlCommand} -x socks5h://127.0.0.1:${warpPortInput}"
            curlInfo="IPv4 CloudFlare WARP"
        fi

    elif [[ $1 == "ipv6" ]]; then

        if [[ "${isIPV6Enabled}" == "false" ]]; then

            if [[ ${isIpv6ContinueInput} == [Nn] ]]; then
                red " 已退出 本机IPv6 测试 "
                echo
                return
            else
                bold " 开始测试本机的IPv6 解锁 Youtube Premium 情况"
                curlCommand="${curlCommand} -6"
                curlInfo="IPv6"
            fi
        else
                bold " 开始测试本机的IPv6 解锁 Youtube Premium 情况"
                curlCommand="${curlCommand} -6"
                curlInfo="IPv6"

        fi

    elif [[ $1 == "ipv6warp" ]]; then
        bold " 开始测试本机的IPv6 通过CloudFlare WARP 解锁 Youtube Premium 情况"
        curlCommand="${curlCommand} -6"
        curlInfo="IPv6 CloudFlare WARP"

    else
        red " 没有选择要进行的测试 已退出! "
        return

    fi

    # curl 参数说明
    # --connect-timeout <seconds> Maximum time allowed for connection
    # -4, --ipv4          Resolve names to IPv4 addresses
    # -s, --silent        Silent mode
    # -S, --show-error    Show error even when -s is used
    # -L, --location      Follow redirects

    testYoutubeOneMethod "${curlCommand}" "${curlInfo}"
    echo

}

function testYoutubeOneMethod(){

    if [[ -n "$1" ]]; then

        youtubeLinkRed="https://www.youtube.com/red"

#        green " Test Url: $1 ${youtubeLinkRed}"

        resultYoutubeIndex=$($1 -S ${youtubeLinkRed} 2>&1)
  
        if [[ "${resultYoutubeIndex}" == "curl"* ]];then
            red " 网络错误 无法打开 YouTube 网站"
            return
        fi

        resultYoutube=$($1 ${youtubeLinkRed} | sed 's/,/\n/g' | grep countryCode | cut -d '"' -f4)

        if [ ! -n "${resultYoutube}" ]; then
            yellow " YouTube 角标不显示 可能不支持 YouTube Premium"
        else
            green " 本机 $2 支持 YouTube Premium, 角标: ${resultYoutube}"
        fi

    else
        red " 要进行的测试 Url为空! "
    fi

}


















function testDisneyPlusAll(){
    curlCommand="curl --connect-timeout 10 -s --user-agent ${UA_Browser}"
    # curlCommand="curl --connect-timeout 10 -s"
    curlInfo="IPv4"

    if [[ $1 == "ipv4" ]]; then
        bold " 开始测试本机的IPv4 解锁 Disney+ 情况"
        curlCommand="${curlCommand} -4"
        curlInfo="IPv4"

    elif [[ $1 == "ipv4warp" ]]; then

        if [[ ${isIpv4WARPContinueInput} == [Nn] ]]; then
            red " 已退出本机 IPv4 WARP Sock5 代理测试"
            echo
            return
        else

            bold " 开始测试本机的IPv4 通过CloudFlare WARP 解锁 Disney+ 情况"
            curlCommand="${curlCommand} -x socks5h://127.0.0.1:${warpPortInput}"
            curlInfo="IPv4 CloudFlare WARP"
        fi

    elif [[ $1 == "ipv6" ]]; then

        if [[ "${isIPV6Enabled}" == "false" ]]; then

            if [[ ${isIpv6ContinueInput} == [Nn] ]]; then
                red " 已退出 本机IPv6 测试 "
                echo
                return
            else
                bold " 开始测试本机的IPv6 解锁 Disney+ 情况"
                curlCommand="${curlCommand} -6"
                curlInfo="IPv6"
            fi
        else
                bold " 开始测试本机的IPv6 解锁 Disney+ 情况"
                curlCommand="${curlCommand} -6"
                curlInfo="IPv6"

        fi

    elif [[ $1 == "ipv6warp" ]]; then
        bold " 开始测试本机的IPv6 通过CloudFlare WARP 解锁 Disney+ 情况"
        curlCommand="${curlCommand} -6"
        curlInfo="IPv6 CloudFlare WARP"

    else
        red " 没有选择要进行的测试 已退出! "
        return

    fi

    # curl 参数说明
    # --connect-timeout <seconds> Maximum time allowed for connection
    # -4, --ipv4          Resolve names to IPv4 addresses
    # -s, --silent        Silent mode
    # -S, --show-error    Show error even when -s is used
    # -L, --location      Follow redirects

    testDisneyPlusOneMethod "${curlCommand}" "${curlInfo}"
    echo

}

function testDisneyPlusOneMethod(){

    if [[ -n "$1" ]]; then

        disneyLinkPrepare="https://disney.api.edge.bamgrid.com/devices"
        disneyLinkRed="https://www.disneyplus.com/movies/thor-the-dark-world/ZHk7aM5xTbW7"

#        green " Test Url: $1 ${disneyLinkRed}"

        resultDisneyPlusIndex=$($1 --max-time 10 -S -X POST "${disneyLinkPrepare}" -H "authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -H "content-type: application/json; charset=UTF-8" -d '{"deviceFamily":"browser","applicationRuntime":"chrome","deviceProfile":"windows","attributes":{}}' 2>&1)
  
        if [[ "${resultDisneyPlusIndex}" == "curl"* ]];then
            red " 网络错误 无法打开 Disney+ 网站"
            return
        fi

        local PreDisneyCookie=$(curl -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/cookies" | sed -n '1p')
        
        #resultYoutube=$(curl --connect-timeout 10 https://www.disneyplus.com/movies/thor-the-dark-world/ZHk7aM5xTbW7 | grep 'The Dark World' )
        resultYoutube=$($1 ${disneyLinkRed} | grep 'The Dark World' )

        if [  -z "${resultYoutube}" ]; then
            yellow " 无法打开 Disney Plus 影片"
        else
            green " 本机 $2 支持观看 Disney Plus 影片"
        fi

    else
        red " 要进行的测试 Url为空! "
    fi

}


function MediaUnlockTest_DisneyPlus() {
    echo -n -e " Disney+:\t\t\t\t->\c"
    local PreAssertion=$(curl $useNIC $xForward -${1} --user-agent "${UA_Browser}" -s --max-time 10 -X POST "https://disney.api.edge.bamgrid.com/devices" -H "authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -H "content-type: application/json; charset=UTF-8" -d '{"deviceFamily":"browser","applicationRuntime":"chrome","deviceProfile":"windows","attributes":{}}' 2>&1)
    if [[ "$PreAssertion" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$PreAssertion" == "curl"* ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local assertion=$(echo $PreAssertion | python -m json.tool 2>/dev/null | grep assertion | cut -f4 -d'"')
    local PreDisneyCookie=$(curl -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/cookies" | sed -n '1p')
    local disneycookie=$(echo $PreDisneyCookie | sed "s/DISNEYASSERTION/${assertion}/g")
    local TokenContent=$(curl $useNIC $xForward -${1} --user-agent "${UA_Browser}" -s --max-time 10 -X POST "https://disney.api.edge.bamgrid.com/token" -H "authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -d "$disneycookie")
    local isBanned=$(echo $TokenContent | python -m json.tool 2>/dev/null | grep 'forbidden-location')
    local is403=$(echo $TokenContent | grep '403 ERROR')

    if [ -n "$isBanned" ] || [ -n "$is403" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    local fakecontent=$(curl -s --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/cookies" | sed -n '8p')
    local refreshToken=$(echo $TokenContent | python -m json.tool 2>/dev/null | grep 'refresh_token' | awk '{print $2}' | cut -f2 -d'"')
    local disneycontent=$(echo $fakecontent | sed "s/ILOVEDISNEY/${refreshToken}/g")
    local tmpresult=$(curl $useNIC $xForward -${1} --user-agent "${UA_Browser}" -X POST -sSL --max-time 10 "https://disney.api.edge.bamgrid.com/graph/v1/device/graphql" -H "authorization: ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -d "$disneycontent" 2>&1)
    local previewcheck=$(curl $useNIC $xForward -${1} -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://disneyplus.com" | grep preview)
    local isUnabailable=$(echo $previewcheck | grep 'unavailable')
    local region=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'countryCode' | cut -f4 -d'"')
    local inSupportedLocation=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'inSupportedLocation' | awk '{print $2}' | cut -f1 -d',')

    if [[ "$region" == "JP" ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Green}Yes (Region: JP)${Font_Suffix}\n"
        return
    elif [ -n "$region" ] && [[ "$inSupportedLocation" == "false" ]] && [ -z "$isUnabailable" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Yellow}Available For [Disney+ $region] Soon${Font_Suffix}\n"
        return
    elif [ -n "$region" ] && [ -n "$isUnavailable" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -n "$region" ] && [[ "$inSupportedLocation" == "true" ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
        return
    elif [ -z "$region" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

}















function startNetflixTest(){

    echo
    green " =================================================="
    green " Netflix 非自制剧解锁 检测脚本 By JinWYP"
    red " 本脚本无法检测出使用 V2ray 服务器端路由规则解锁Netflix"
    red " 需要在 V2ray 客户端上运行本脚本才可以检测成功"
    green " =================================================="
    echo

    if [[ -n "$1" ]]; then
        isAutoRefreshWarp="true"
        autoRefreshWarpIPStart

    else

        testIPV6Enabled

        testNetflixAll "ipv4"
        testNetflixAll "ipv6"
        testNetflixAll "ipv4warp"

        green " ===== Youtube Premium 准备开始检测 ====="

        testYoutubeAll "ipv4"
        testYoutubeAll "ipv6"
        testYoutubeAll "ipv4warp"

        green " ===== Disney+ 准备开始检测 ====="

        testDisneyPlusAll "ipv4"
        testDisneyPlusAll "ipv6"
        testDisneyPlusAll "ipv4warp"

    fi    
}



startNetflixTest "$1"

