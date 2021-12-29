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

function testWARPEnabled(){

    if [[ -f "${configWARPPortFilePath}" ]]; then
        configWARPPortLocalServerPort="$(cat ${configWARPPortFilePath})"
        configWARPPortLocalServerText="检测到本机已安装 WARP Sock5, 端口号 ${configWARPPortLocalServerPort}"
        yellow "${configWARPPortLocalServerText}"
        echo
    fi

    read -p "请输入WARP Sock5 端口号? 直接回车默认${configWARPPortLocalServerPort}, 请输入纯数字:" warpPortInput
    warpPortInput=${warpPortInput:-$configWARPPortLocalServerPort}
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
        yellow " 开始测试本机的IPv4 解锁 Netflix 情况"
        curlCommand="${curlCommand} -4"
        curlInfo="IPv4"

    elif [[ $1 == "ipv4warp" ]]; then

        read -p "是否测试本机 IPv4 WARP Sock5 代理? 直接回车默认不测试 请输入[y/N]:" isIpv4WARPContinueInput
        isIpv4WARPContinueInput=${isIpv4WARPContinueInput:-n}

        if [[ ${isIpv4WARPContinueInput} == [Nn] ]]; then
            red " 已退出本机 IPv4 WARP Sock5 代理测试"
            echo
            return
        else
            testWARPEnabled

            yellow " 开始测试本机的IPv4 通过CloudFlare WARP 解锁 Netflix 情况"
            curlCommand="${curlCommand} -x socks5://127.0.0.1:${warpPortInput}"
            curlInfo="IPv4 CloudFlare WARP"
        fi


    elif [[ $1 == "ipv6" ]]; then

        if [[ "${isIPV6Enabled}"=="false" ]]; then
            red " 本机IPv6 没有开启 是否继续测试IPv6 "
            read -p "是否继续测试IPv6? 直接回车默认不继续测试 请输入[y/N]:" isIpv6ContinueInput
            isIpv6ContinueInput=${isIpv6ContinueInput:-n}

            if [[ ${isIpv6ContinueInput} == [Nn] ]]; then
                red " 已退出 本机IPv6 测试 "
                echo
                return
            else
                echo
                yellow " 开始测试本机的IPv6 解锁 Netflix 情况"
                curlCommand="${curlCommand} -6"
                curlInfo="IPv6"
            fi
        else
                yellow " 开始测试本机的IPv6 解锁 Netflix 情况"
                curlCommand="${curlCommand} -6"
                curlInfo="IPv6"

        fi


    elif [[ $1 == "ipv6warp" ]]; then
        yellow " 开始测试本机的IPv6 通过CloudFlare WARP 解锁 Netflix 情况"
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


#        green " Test Url: $1 ${netflixLinkIndex}"
        resultIndex=$($1 ${netflixLinkIndex} 2>&1)

        if [[ -z "${resultIndex}" ]];then
            echo -e "${Font_Red}已被 Netflix 屏蔽, 403 访问错误 ${Font_Suffix}"
            return
        fi

        if [ "${resultIndex}" == "Not Available" ];then
            echo -e "${Font_Red}Netflix 不提供此地区服务 ${Font_Suffix}"
            return
        fi

        if [[ "${resultIndex}" == "curl"* ]];then
            echo -e "${Font_Red}网络错误 无法打开 Netflix 网站${Font_Suffix}"
            return
        fi



#        green " Test Url: $1 ${netflixLinkOwn}"
        resultOwn=$($1 ${netflixLinkIndex} 2>&1)

        if [[ "${resultOwn}" == *"page-404"* ]] || [[ "${resultOwn}" == *"NSEZ-403"* ]];then
            echo -e "${Font_Red} 本机 $2 不能看 Netflix 任何剧集 ${Font_Suffix}"
            return
        fi


#        green " Test Url: $1 -fi https://www.netflix.com/title/80018499 2>&1"
        resultRegion=`tr [:lower:] [:upper:] <<< $($1 -fi "https://www.netflix.com/title/80018499" 2>&1 | sed -n '8p' | awk '{print $2}' | cut -d '/' -f4 | cut -d '-' -f1)`

        netflixRegion="${resultRegion}"
#        echo "${netflixRegion}"

        if [[ "${resultRegion}" == *"INDEX"* ]] || [[ "${resultRegion}" == *"index"* ]];then
           netflixRegion="US"
        fi


        result1=$($1 "https://www.netflix.com/title/70143836" 2>&1)
        result2=$($1 "https://www.netflix.com/title/80027042" 2>&1)
        result3=$($1 "https://www.netflix.com/title/70140425" 2>&1)
        result4=$($1 "https://www.netflix.com/title/70283261" 2>&1)
        result5=$($1 "https://www.netflix.com/title/70143860" 2>&1)
        result6=$($1 "https://www.netflix.com/title/70202589" 2>&1)

        if [[ "$result1" == *"page-404"* ]] && [[ "$result2" == *"page-404"* ]] && [[ "$result3" == *"page-404"* ]] && [[ "$result4" == *"page-404"* ]] && [[ "$result5" == *"page-404"* ]] && [[ "$result6" == *"page-404"* ]]; then
            echo -e "${Font_Yellow}本机 $2 仅解锁 Netflix 自制剧${Font_Suffix}. 区域: ${netflixRegion}"
            return
        fi



        echo -e "${Font_Green}恭喜 本机 $2 解锁 Netflix 全部剧集 包括非自制剧. 区域: ${netflixRegion} ${Font_Suffix}"
        return

    else
        red " 要进行的测试 Url为空! "
    fi


}
























function testYoutubeAll(){
#    curlCommand="curl --connect-timeout 10 -s --user-agent ${UA_Browser}"
    curlCommand="curl --connect-timeout 10 -s"

    curlInfo="IPv4"


    if [[ $1 == "ipv4" ]]; then
        yellow " 开始测试本机的IPv4 解锁 Youtube Premium 情况"
        curlCommand="${curlCommand} -4"
        curlInfo="IPv4"

    elif [[ $1 == "ipv4warp" ]]; then

        if [[ ${isIpv4WARPContinueInput} == [Nn] ]]; then
            red " 已退出本机 IPv4 WARP Sock5 代理测试"
            echo
            return
        else

            yellow " 开始测试本机的IPv4 通过CloudFlare WARP 解锁 Youtube Premium 情况"
            curlCommand="${curlCommand} -x socks5://127.0.0.1:${warpPortInput}"
            curlInfo="IPv4 CloudFlare WARP"
        fi

    elif [[ $1 == "ipv6" ]]; then

        if [[ "${isIPV6Enabled}"=="false" ]]; then

            if [[ ${isIpv6ContinueInput} == [Nn] ]]; then
                red " 已退出 本机IPv6 测试 "
                echo
                return
            else
                yellow " 开始测试本机的IPv6 解锁 Youtube Premium 情况"
                curlCommand="${curlCommand} -6"
                curlInfo="IPv6"
            fi
        else
                yellow " 开始测试本机的IPv6 解锁 Youtube Premium 情况"
                curlCommand="${curlCommand} -6"
                curlInfo="IPv6"

        fi

    elif [[ $1 == "ipv6warp" ]]; then
        yellow " 开始测试本机的IPv6 通过CloudFlare WARP 解锁 Youtube Premium 情况"
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

        youtubeLinkRed="https://www.netflix.com/"

#        green " Test Url: $1 ${youtubeLinkRed}"
        resultYoutube=$($1 ${youtubeLinkRed} | sed 's/,/\n/g' | grep countryCode | cut -d '"' -f4)

        if [ ! -n "${resultYoutube}" ]; then
            echo -e "${Font_White}YouTube 角标不显示 可能不支持 YouTube Premium${Font_Suffix}"
        else
            echo -e "${Font_Green}本机 $2 支持 YouTube Premium, 角标: ${resultYoutube}${Font_Suffix}"
        fi

    else
        red " 要进行的测试 Url为空! "
    fi


}











function startNetflixTest(){

    testIPV6Enabled

    echo
    green " =================================================="
    green " Netflix 非自制剧解锁 检测脚本 By JinWYP"
    green " =================================================="

    testNetflixAll "ipv4"
    testNetflixAll "ipv4warp"
    testNetflixAll "ipv6"

    green " ===== Youtube Premium 准备开始检测 ====="

    testYoutubeAll "ipv4"
    testYoutubeAll "ipv4warp"
    testYoutubeAll "ipv6"
}



startNetflixTest

