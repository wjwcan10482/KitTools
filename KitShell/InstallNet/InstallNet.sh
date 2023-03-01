#!/bin/bash
export tmpVER=''
export tmpDIST=''
export tmpURL=''
export tmpWORD=''
export tmpMirror=''
export tmpSSL=''
export tmpINS=''
export tmpFW=''
export ipAddr=''
export ipMask=''
export ipGate=''
export linuxdists=''
export ddMode='0'
export setNet='0'
export isMirror='0'
export FindDists='0'

while [[ $# -ge 1 ]]; do
    case $1 in
    -v | --ver)
        shift
        tmpVER="$1"
        shift
        ;;
    -d | --debian)
        shift
        linuxdists='debian'
        tmpDIST="$1"
        shift
        ;;
    -k | --kylin)
        shift
        linuxdists='kylin'
        tmpDIST="$1"
        shift
        ;;
    -u | --ubuntu)
        shift
        linuxdists='ubuntu'
        tmpDIST="$1"
        shift
        ;;
    -dd | --image)
        shift
        ddMode='1'
        tmpURL="$1"
        shift
        ;;
    -p | --password)
        shift
        tmpWORD="$1"
        shift
        ;;
    --ip-addr)
        shift
        ipAddr="$1"
        shift
        ;;
    --ip-mask)
        shift
        ipMask="$1"
        shift
        ;;
    --ip-gate)
        shift
        ipGate="$1"
        shift
        ;;
    -a | --auto)
        shift
        tmpINS='auto'
        ;;
    -m | --manual)
        shift
        tmpINS='manual'
        ;;
    -apt | --mirror)
        shift
        isMirror='1'
        tmpMirror="$1"
        shift
        ;;
    -ssl)
        shift
        tmpSSL="$1"
        shift
        ;;
    --firmware)
        shift
        tmpFW='1'
        ;;
    *)
        echo -ne " Usage:\n\t$0\t-d/--debian [\033[33m\033[04mdists-name\n\t\t\t\t-u/--ubuntu [\033[04mdists-name\n\t\t\t\t-v/--ver [32/\033[33m\033[04mi386\033[0m|64/amd64]\n\t\t\t\t--ip-addr/--ip-gate/--ip-mask\n\t\t\t\t-apt/--mirror\n\t\t\t\t-dd/--image\n\t\t\t\t-a/--auto\n\t\t\t\t-m/--manual\n"
        exit 1
        ;;
    esac
done

[[ "$EUID" -ne '0' ]] && echo "Error:This script must be run as root!" && exit 1

function CheckDependence() {
    FullDependence='0'
    for BIN_DEP in $(echo "$1" | sed 's/,/\n/g'); do
        if [[ -n "$BIN_DEP" ]]; then
            Founded='0'
            for BIN_PATH in $(echo "$PATH" | sed 's/:/\n/g'); do
                ls $BIN_PATH/$BIN_DEP >/dev/null 2>&1
                if [ $? == '0' ]; then
                    Founded='1'
                    break
                fi
            done
            if [ "$Founded" == '1' ]; then
                echo -en "$BIN_DEP\t\tok\n"
            else
                FullDependence='1'
                echo -en "$BIN_DEP\t\tfail\n"
            fi
        fi
    done
    if [ "$FullDependence" == '1' ]; then
        exit 1
    fi
}

clear && echo -e " 安装依赖包"
CheckDependence wget,awk,grep,sed,cut,cat,cpio,gzip,sshpass

[ "$ddMode" == '1' ] && {
    CheckDependence iconv
}

[[ "$linuxdists" != 'kylin' ]] && {
    clear && echo -e " 确认grub.cfg路径"
    [[ -f '/boot/grub/grub.cfg' ]] && GRUBOLD='0' && GRUBDIR='/boot/grub' && GRUBFILE='grub.cfg'
    [[ -z "$GRUBDIR" ]] && [[ -f '/boot/grub2/grub.cfg' ]] && GRUBOLD='0' && GRUBDIR='/boot/grub2' && GRUBFILE='grub.cfg'
    [[ -z "$GRUBDIR" ]] && [[ -f '/boot/grub/grub.conf' ]] && GRUBOLD='1' && GRUBDIR='/boot/grub' && GRUBFILE='grub.conf'
    [ -z "$GRUBDIR" -o -z "$GRUBFILE" ] && echo -ne "Error! \nNot Found grub path.\n" && exit 1
}

[[ "$linuxdists" == 'kylin' ]] && {
    clear && echo -e " 确认grub.cfg路径"
    [[ -f '/boot/efi/boot/grub/grub.cfg' ]] && GRUBOLD='0' && GRUBDIR='/boot/efi/boot/grub' && GRUBFILE='grub.cfg'
    [[ -z "$GRUBDIR" ]] && [[ -f '/boot/efi/boot/grub/grub.cfg' ]] && GRUBOLD='0' && GRUBDIR='/boot/grub' && GRUBFILE='grub.cfg'
    [ -z "$GRUBDIR" -o -z "$GRUBFILE" ] && echo -ne "Error! \nNot Found grub path.\n" && exit 1
}

clear && echo -e " 确认操作系统版本 "
[[ -n "$tmpVER" ]] && {
    [ "$tmpVER" == '32' -o "$tmpVER" == 'i386' ] && VER='i386'
    [ "$tmpVER" == '64' -o "$tmpVER" == 'amd64' ] && VER='amd64'
    [ "$tmpVER" == 'aarch64' ] && VER='aarch64'
}
[[ -z "$VER" ]] && VER='aarch64'

[[ -z "$linuxdists" ]] && linuxdists='kylin'

clear && echo -e " 确认镜像路径 "
[[ "$isMirror" == '1' ]] && [[ -n "$tmpMirror" ]] && {
    tmpDebianMirror="$(echo -n "$tmpMirror" | grep -Eo '.*\.(\w+)')"
    echo -n "$tmpDebianMirror" | grep -q '://'
    [[ $? -eq '0' ]] && {
        DebianMirror="$(echo -n "$tmpDebianMirror" | awk -F'://' '{print $2}')"
    } || {
        DebianMirror="$(echo -n "$tmpDebianMirror")"
    }
} || {
    [[ "$linuxdists" == 'debian' ]] && DebianMirror='httpredir.debian.org'
    [[ "$linuxdists" == 'ubuntu' ]] && DebianMirror='archive.ubuntu.com'
    [[ "$linuxdists" == 'kylin' ]] && DebianMirror='172.16.81.82'
}

[[ -z "$DebianMirrorDirectory" ]] && [[ -n "$DebianMirror" ]] && [[ -n "$tmpMirror" ]] && {
    DebianMirrorDirectory="$(echo -n "$tmpMirror" | awk -F''${DebianMirror}'' '{print $2}' | sed 's/\/$//g')"
}

[[ -n "$DebianMirror" ]] && {
    [[ "$DebianMirrorDirectory" == '/' ]] && {
        [[ "$linuxdists" == 'debian' ]] && DebianMirrorDirectory='/debian'
        [[ "$linuxdists" == 'ubuntu' ]] && DebianMirrorDirectory='/ubuntu'
        [[ "$linuxdists" == 'kylin' ]] && DebianMirrorDirectory='/kylin'
    }
    [[ -z "$DebianMirrorDirectory" ]] && {
        [[ "$linuxdists" == 'debian' ]] && DebianMirrorDirectory='/debian'
        [[ "$linuxdists" == 'ubuntu' ]] && DebianMirrorDirectory='/ubuntu'
        [[ "$linuxdists" == 'kylin' ]] && DebianMirrorDirectory='/kylin'
    }
}

[[ -z "$tmpDIST" ]] && {
    [[ "$linuxdists" == 'debian' ]] && DIST='wheezy'
    [[ "$linuxdists" == 'ubuntu' ]] && DIST='trusty'
    [[ "$linuxdists" == 'kylin' ]] && DIST='juniper'
}

[[ -z "$DIST" ]] && {
    DIST="$(echo "$tmpDIST" | sed -r 's/(.*)/\L\1/')"
    echo "$DIST" | grep -q '[0-9]'
    [[ $? -eq '0' ]] && {
        isDigital="$(echo "$DIST" | grep -o '[0-9\.]\{1,\}' | sed -n '1h;1!H;$g;s/\n//g;$p' | cut -d'.' -f1)"
        [[ -n $isDigital ]] && {
            [[ "$isDigital" == '7' ]] && DIST='wheezy'
            [[ "$isDigital" == '8' ]] && DIST='jessie'
            [[ "$isDigital" == '9' ]] && DIST='stretch'
            [[ "$isDigital" == '10' ]] && DIST='buster'
            [[ "$isDigital" == '4' ]] && DIST='juniper'
        }
    }
}
echo "http://$DebianMirror$DebianMirrorDirectory/dists/$DIST"

[[ "$ddMode" == '1' ]] && {
    [[ -n "$tmpURL" ]] && {
        linuxdists='debian'
        DIST='jessie'
        VER='amd64'
        tmpINS='auto'
        DDURL="$tmpURL"
        echo "$DDURL" | grep -q '^http://\|^ftp://\|^https://'
        [[ $? -ne '0' ]] && echo 'Please input vaild URL,Only support http://, ftp:// and https:// !' && exit 1
        [[ -n "$tmpSSL" ]] && SSL_SUPPORT="$tmpSSL"
        [[ -z "$SSL_SUPPORT" ]] && SSL_SUPPORT='https://moeclub.org/get-wget_udeb_amd64'
    } || {
        echo 'Please input vaild URL! '
        exit 1
    }
}

clear && echo -e " 查找dists是否存在 "
DistsList="$(wget --no-check-certificate -qO- "http://$DebianMirror$DebianMirrorDirectory/dists/" | grep -o 'href=.*/"' | cut -d'"' -f2 | sed '/-\|old\|Debian\|experimental\|stable\|test\|sid\|devel/d' | grep '^[^/]' | sed -n '1h;1!H;$g;s/\n//g;s/\//\;/g;$p')"
echo "http://$DebianMirror$DebianMirrorDirectory/dists/"
for CheckDEB in $(echo "$DistsList" | sed 's/;/\n/g'); do
    [[ "$CheckDEB" == "$DIST" ]] && FindDists='1'
    [[ "$FindDists" == '1' ]] && break
done
[[ "$FindDists" == '0' ]] && {
    echo -ne '\nThe dists version not found, Please check it! \n\n'
    bash $0 error
    exit 1
}

[[ -n "$tmpINS" ]] && {
    [[ "$tmpINS" == 'auto' ]] && inVNC='n'
    [[ "$tmpINS" == 'manual' ]] && inVNC='y'
}

[ -n "$ipAddr" ] && [ -n "$ipMask" ] && [ -n "$ipGate" ] && setNet='1'
[[ -n "$tmpWORD" ]] && myPASSWORD="$tmpWORD"
[[ -n "$tmpFW" ]] && INCFW="$tmpFW"
[[ -z "$myPASSWORD" ]] && myPASSWORD='Vicer'
[[ -z "$INCFW" ]] && INCFW='0'

clear && echo -e " Install"

ASKVNC() {
    inVNC='y'
    [[ "$ddMode" == '0' ]] && {
        echo -ne "\033[34mCan you login VNC?\033[0m\e[33m[\e[32my\e[33m/n]\e[0m "
        read tmpinVNC
        [[ -n "$tmpinVNC" ]] && inVNCtmp="$tmpinVNC"
    }
    [ "$inVNCtmp" == 'y' -o "$inVNCtmp" == 'Y' ] && inVNC='y'
    [ "$inVNCtmp" == 'n' -o "$inVNCtmp" == 'N' ] && inVNC='n'
}

[ "$inVNC" == 'y' -o "$inVNC" == 'n' ] || ASKVNC
[[ "$linuxdists" == 'debian' ]] && LinuxName='Debian'
[[ "$linuxdists" == 'ubuntu' ]] && LinuxName='Ubuntu'
[[ "$linuxdists" == 'kylin' ]] && LinuxName='Kylin'
[[ "$ddMode" == '0' ]] && {
    [[ "$inVNC" == 'y' ]] && echo -e "\033[34mManual Mode\033[0m insatll \033[33m$LinuxName\033[0m [\033[33m$DIST [\033[33m$VER in VNC. "
    [[ "$inVNC" == 'n' ]] && echo -e "\033[34mAuto Mode\033[0m insatll \033[33m$LinuxName\033[0m [\033[33m$DIST [\033[33m$VER. "
}
[[ "$ddMode" == '1' ]] && {
    echo -ne "\033[34mAuto Mode\033[0m insatll \033[33mWindows[\033[33m$DDURL\n"
}

echo -e "\n[\033[33m$LinuxName [\033[33m$DIST [\033[33m$VER Downloading linux and initrd"

[[ "$linuxdists" != 'kylin' ]] && {
    [[ -z "$DebianMirror" ]] && echo -ne "\033[31mError! \033[0mGet debian mirror fail! \n" && exit 1
    [[ -z "$DebianMirrorDirectory" ]] && echo -ne "\033[31mError! \033[0mGet debian mirror directory fail! \n" && exit 1
    wget --no-check-certificate -qO '/boot/initrd.gz' "http://$DebianMirror$DebianMirrorDirectory/dists/$DIST/main/installer-$VER/current/images/netboot/$linuxdists-installer/$VER/initrd.gz"
    [[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'initrd.gz' failed! \n" && exit 1
    wget --no-check-certificate -qO '/boot/linux' "http://$DebianMirror$DebianMirrorDirectory/dists/$DIST/main/installer-$VER/current/images/netboot/$linuxdists-installer/$VER/linux"
    [[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'linux' failed! \n" && exit 1
    [[ "$INCFW" == '1' ]] && [[ "$linuxdists" == 'debian' ]] && {
        wget --no-check-certificate -qO '/boot/firmware.cpio.gz' "http://cdimage.debian.org/cdimage/unofficial/non-free/firmware/$DIST/current/firmware.cpio.gz"
        [[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'firmware' failed! \n" && exit 1
    }
}

[[ "$linuxdists" == 'kylin' ]] && {
    clear && echo -e " 下载并重新命名.new到/boot "
    [[ -z "$DebianMirror" ]] && echo -ne "\033[31mError! \033[0mGet debian mirror fail! \n" && exit 1
    [[ -z "$DebianMirrorDirectory" ]] && echo -ne "\033[31mError! \033[0mGet debian mirror directory fail! \n" && exit 1
    wget --no-check-certificate -qO '/boot/Image.new' "http://$DebianMirror$DebianMirrorDirectory/casper/Image"
    [[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'initrd.gz' failed! \n" && exit 1
    wget --no-check-certificate -qO '/boot/initrd.img.new' "http://$DebianMirror$DebianMirrorDirectory/netboot/initrd.img"
    [[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'linux' failed! \n" && exit 1
    # [[ "$INCFW" == '1' ]] && [[ "$linuxdists" == 'debian' ]] && {
    #     wget --no-check-certificate -qO '/boot/firmware.cpio.gz' "http://cdimage.debian.org/cdimage/unofficial/non-free/firmware/$DIST/current/firmware.cpio.gz"
    #     [[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'firmware' failed! \n" && exit 1
    # }
}



clear && echo -e " 获取本地网络信息IP/NETMASK/GATEWAY "
[[ "$setNet" == '1' ]] && {
    IPv4="$ipAddr"
    MASK="$ipMask"
    GATE="$ipGate"
} || {
    DEFAULTNET="$(ip route show | grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.*' | head -n1 | sed 's/proto.*\|onlink.*//g' | awk '{print $NF}')"
    [[ -n "$DEFAULTNET" ]] && IPSUB="$(ip addr | grep ''${DEFAULTNET}'' | grep 'global' | grep 'brd' | head -n1 | grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}/[0-9]\{1,2\}')"
    IPv4="$(echo -n "$IPSUB" | cut -d'/' -f1)"
    NETSUB="$(echo -n "$IPSUB" | grep -o '/[0-9]\{1,2\}')"
    GATE="$(ip route show | grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}' | head -n1 | grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}')"
    [[ -n "$NETSUB" ]] && MASK="$(echo -n '128.0.0.0/1,192.0.0.0/2,224.0.0.0/3,240.0.0.0/4,248.0.0.0/5,252.0.0.0/6,254.0.0.0/7,255.0.0.0/8,255.128.0.0/9,255.192.0.0/10,255.224.0.0/11,255.240.0.0/12,255.248.0.0/13,255.252.0.0/14,255.254.0.0/15,255.255.0.0/16,255.255.128.0/17,255.255.192.0/18,255.255.224.0/19,255.255.240.0/20,255.255.248.0/21,255.255.252.0/22,255.255.254.0/23,255.255.255.0/24,255.255.255.128/25,255.255.255.192/26,255.255.255.224/27,255.255.255.240/28,255.255.255.248/29,255.255.255.252/30,255.255.255.254/31,255.255.255.255/32' | grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'${NETSUB}'' | cut -d'/' -f1)"
}

[[ -n "$GATE" ]] && [[ -n "$MASK" ]] && [[ -n "$IPv4" ]] || {
    echo "Not found $(ip command), It will use $(route command)."
    ipNum() {
        local IFS='.'
        read ip1 ip2 ip3 ip4 <<<"$1"
        echo $((ip1 * (1 << 24) + ip2 * (1 << 16) + ip3 * (1 << 8) + ip4))
    }

    SelectMax() {
        ii=0
        for IPITEM in $(route -n | awk -v OUT=$1 '{print $OUT}' | grep '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'); do
            NumTMP="$(ipNum $IPITEM)"
            eval "arrayNum[$ii]='$NumTMP,$IPITEM'"
            ii=$(($ii + 1))
        done
        echo ${arrayNum[@]} | sed 's/\s/\n/g' | sort -n -k 1 -t ',' | tail -n1 | cut -d',' -f2
    }

    [[ -z $IPv4 ]] && IPv4="$(ifconfig | grep 'Bcast' | head -n1 | grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}' | head -n1)"
    [[ -z $GATE ]] && GATE="$(SelectMax 2)"
    [[ -z $MASK ]] && MASK="$(SelectMax 3)"

    [[ -n "$GATE" ]] && [[ -n "$MASK" ]] && [[ -n "$IPv4" ]] || {
        echo "Error! Not configure network. "
        exit 1
    }
}

[[ "$setNet" != '1' ]] && [[ -f '/etc/network/interfaces' ]] && {
    [[ -z "$(sed -n '/iface.*inet static/p' /etc/network/interfaces)" ]] && AutoNet='1' || AutoNet='0'
    [[ -d /etc/network/interfaces.d ]] && {
        ICFGN="$(find /etc/network/interfaces.d -name '*.cfg' | wc -l)" || ICFGN='0'
        [[ "$ICFGN" -ne '0' ]] && {
            for NetCFG in $(ls -1 /etc/network/interfaces.d/*.cfg); do
                [[ -z "$(cat $NetCFG | sed -n '/iface.*inet static/p')" ]] && AutoNet='1' || AutoNet='0'
                [[ "$AutoNet" -eq '0' ]] && break
            done
        }
    }
}

[[ "$setNet" != '1' ]] && [[ -d '/etc/sysconfig/network-scripts' ]] && {
    ICFGN="$(find /etc/sysconfig/network-scripts -name 'ifcfg-*' | grep -v 'lo' | wc -l)" || ICFGN='0'
    [[ "$ICFGN" -ne '0' ]] && {
        for NetCFG in $(ls -1 /etc/sysconfig/network-scripts/ifcfg-* | grep -v 'lo$' | grep -v ':[0-9]\{1,\}'); do
            [[ -n "$(cat $NetCFG | sed -n '/BOOTPROTO.*[dD][hH][cC][pP]/p')" ]] && AutoNet='1' || {
                AutoNet='0' && . $NetCFG
                [[ -n $NETMASK ]] && MASK="$NETMASK"
                [[ -n $GATEWAY ]] && GATE="$GATEWAY"
            }
            [[ "$AutoNet" -eq '0' ]] && break
        done
    }
}


clear && echo -e " grub.cfg对比生成/tmp/grub.new "
[[ ! -f $GRUBDIR/$GRUBFILE ]] && echo "Error! Not Found $GRUBFILE. " && exit 1

[[ ! -f $GRUBDIR/$GRUBFILE.old ]] && [[ -f $GRUBDIR/$GRUBFILE.bak ]] && mv -f $GRUBDIR/$GRUBFILE.bak $GRUBDIR/$GRUBFILE.old
mv -f $GRUBDIR/$GRUBFILE $GRUBDIR/$GRUBFILE.bak
[[ -f $GRUBDIR/$GRUBFILE.old ]] && cat $GRUBDIR/$GRUBFILE.old >$GRUBDIR/$GRUBFILE || cat $GRUBDIR/$GRUBFILE.bak >$GRUBDIR/$GRUBFILE

[[ "$GRUBOLD" == '0' ]] && {
    READGRUB='/tmp/grub.read'
    cat $GRUBDIR/$GRUBFILE | sed -n '1h;1!H;$g;s/\n/+++/g;$p' | grep -oPm 1 'menuentry\ .*\{.*\}\+\+\+' | sed 's/\+\+\+/\n/g' >$READGRUB
    LoadNum="$(cat $READGRUB | grep -c 'menuentry ')"
    if [[ "$LoadNum" -eq '1' ]]; then
        cat $READGRUB | sed '/^$/d' >/tmp/grub.new
    elif [[ "$LoadNum" -gt '1' ]]; then
        CFG0="$(awk '/menuentry /{print NR}' $READGRUB | head -n 1)"
        CFG2="$(awk '/menuentry /{print NR}' $READGRUB | head -n 2 | tail -n 1)"
        CFG1=""
        for tmpCFG in $(awk '/}/{print NR}' $READGRUB); do
            [ "$tmpCFG" -gt "$CFG0" -a "$tmpCFG" -lt "$CFG2" ] && CFG1="$tmpCFG"
        done
        [[ -z "$CFG1" ]] && {
            echo "Error! read $GRUBFILE. "
            exit 1
        }

        sed -n "$CFG0,$CFG1"p $READGRUB >/tmp/grub.new
        [[ -f /tmp/grub.new ]] && [[ "$(grep -c '{' /tmp/grub.new)" -eq "$(grep -c '}' /tmp/grub.new)" ]] || {
            echo -ne "\033[31mError! \033[0mNot configure $GRUBFILE. \n"
            exit 1
        }
    fi
    [ ! -f /tmp/grub.new ] && echo "Error! $GRUBFILE. " && exit 1
    sed -i "/menuentry.*/c\menuentry\ \'Install OS \[$DIST\ $VER\]\'\ --class debian\ --class\ gnu-linux\ --class\ gnu\ --class\ os\ \{" /tmp/grub.new
    sed -i "/echo.*Loading/d" /tmp/grub.new
}

[[ "$GRUBOLD" == '1' ]] && {
    CFG0="$(awk '/title /{print NR}' $GRUBDIR/$GRUBFILE | head -n 1)"
    CFG1="$(awk '/title /{print NR}' $GRUBDIR/$GRUBFILE | head -n 2 | tail -n 1)"
    [[ -n $CFG0 ]] && [ -z $CFG1 -o $CFG1 == $CFG0 ] && sed -n "$CFG0,$"p $GRUBDIR/$GRUBFILE >/tmp/grub.new
    [[ -n $CFG0 ]] && [ -z $CFG1 -o $CFG1 != $CFG0 ] && sed -n "$CFG0,$CFG1"p $GRUBDIR/$GRUBFILE >/tmp/grub.new
    [[ ! -f /tmp/grub.new ]] && echo "Error! configure append $GRUBFILE. " && exit 1
    sed -i "/title.*/c\title\ \'Install OS \[$DIST\ $VER\]\'" /tmp/grub.new
    sed -i '/^#/d' /tmp/grub.new
}

[[ -n "$(grep 'linux.*/\|kernel.*/' /tmp/grub.new | awk '{print $2}' | tail -n 1 | grep '^/boot/')" ]] && Type='InBoot' || Type='NoBoot'

LinuxKernel="$(grep 'linux.*/\|kernel.*/' /tmp/grub.new | awk '{print $1}' | head -n 1)"
[[ -z "$LinuxKernel" ]] && echo "Error! read grub config! " && exit 1
LinuxIMG="$(grep 'initrd.*/' /tmp/grub.new | awk '{print $1}' | tail -n 1)"
[ -z "$LinuxIMG" ] && sed -i "/$LinuxKernel.*\//a\\\tinitrd\ \/" /tmp/grub.new && LinuxIMG='initrd'

[[ "$Type" == 'InBoot' ]] && {
    sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/boot\/linux auto=true hostname=$linuxdists domain= -- quiet" /tmp/grub.new
    sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/boot\/initrd.gz" /tmp/grub.new
}

[[ "$Type" == 'NoBoot' ]] && {
    sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/Image.new url=http://172.16.81.81:8000/${IPv4}.preseed.cfg quiet splash console=tty1 pcie_aspm=off $vt_handoff console=tty1  rw  KEYBOARDTYPE=pc KEYTABLE=us language=zh_CN" /tmp/grub.new
    sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/initrd.img.gz" /tmp/grub.new
}

sed -i '$a\\n' /tmp/grub.new

[[ "$inVNC" == 'n' ]] && {
    GRUBPATCH='0'

    [ -f '/etc/network/interfaces' -o -d '/etc/sysconfig/network-scripts' ] || {
        echo "Error, Not found interfaces config."
        exit 1
    }

    INSERTGRUB="$(awk '/menuentry /{print NR}' $GRUBDIR/$GRUBFILE | head -n 1)"
    sed -i ''${INSERTGRUB}'i\\n' $GRUBDIR/$GRUBFILE
    sed -i ''${INSERTGRUB}'r /tmp/grub.new' $GRUBDIR/$GRUBFILE
    [[ -f $GRUBDIR/grubenv ]] && sed -i 's/saved_entry/#saved_entry/g' $GRUBDIR/grubenv

    [[ -d /boot/tmp ]] && [[ "$linuxdists" == 'kylin' ]] && rm -rf /boot/tmp
    {
        mkdir -p /boot/tmp
        cd /boot/tmp
        # gzip -d < ../initrd.gz | cpio --extract --verbose --make-directories --no-absolute-filenames >>/dev/null 2>&1
        # 将下载的解压initrd.img.new
        gunzip -S .img <../initrd.img.new | cpio --extract --verbose --make-directories --no-absolute-filenames >>/dev/null 2>&1
    }
clear && echo -e " 生成/boot/preseed.cfg.new参考 "
    cat >/boot/preseed.cfg.new <<EOF
d-i netcfg/get_ipaddress string $IPv4
d-i netcfg/get_netmask string $MASK
d-i netcfg/get_gateway string $GATE
d-i mirror/http/hostname string $DebianMirror
d-i mirror/http/directory string $DebianMirrorDirectory
d-i passwd/root-password password $myPASSWORD
d-i passwd/root-password-again password $myPASSWORD
# 1. Localization
d-i debconf/priority string critical
d-i debian-installer/language string zh_CN
d-i debian-installer/country string CN
d-i debian-installer/locale string zh_CN.UTF-8
d-i localechooser/translation/warn-severe boolean false
d-i console-setup/ask_detect boolean false
d-i keyboard-configuration/xkb-keymap select us

# 2. Network configuration

d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string Kylin
d-i netcfg/get_domain string Kylin
d-i netcfg/hostname string Kylin
d-i netcfg/choose_interface select enp3s0
d-i hw-detect/load_firmware boolean true
# 3. Network console

# 4. Mirror settings 
#d-i mirror/protocol string http
d-i mirror/country string manual
d-i mirror/http/hostname string 172.16.81.82
d-i mirror/http/directory string /kylin
d-i mirror/http/proxy string
d-i mirror/suite string juniper

# 5. Account setup

d-i passwd/user-fullname string kylin
## 设置用户名 kylin
d-i passwd/username string kylin
## 设置用户密码
d-i passwd/user-password password 123123
## 确认用户密码
d-i passwd/user-password-again password 123123
## 允许使用弱密码
d-i user-setup/allow-password-weak boolean true
# 不加密主目录
d-i user-setup/encrypt-home boolean false


# 6. Clock and time zone setup
d-i clock-setup/utc boolean true
d-i time/zone string Asia/Shanghai


# 8. Partitioning

# 分区设置
### 不创建特殊分区：备份分区，数据分区
d-i preseed/early_command string echo '' > /tmp/.kypartselect_auto;
### 创建特殊分区：备份分区(kybackup)，数据分区(kydata)
#d-i preseed/early_command string echo 'kybackup' > /tmp/.kypartselect_auto ; echo 'kydata' >> /tmp/.kypartselect_auto ;
### 选择磁盘/dev/sda安装系统
d-i partman-auto/disk string /dev/sda
### 如果磁盘上已有lvm卷分区且需要将其移除
d-i partman-lvm/device_remove_lvm boolean true
### 如果磁盘上已有raid分区且需要将其移除
d-i partman-md/device_remove_md boolean true
### 选择对磁盘进行常规分区
d-i partman-auto/method string regular
### 自动分区
### 选择自动分区（包含特殊分区）
#d-i partman-auto/choose_recipe select atomic
### 手动分区
### 下面为自定义分区:
### boot分区 512M; 根分区 100G; swap分区 1G
d-i partman-auto/expert_recipe string\
      root-opt ::\
              512 10000 1024 ext4\
                      \$primary{ } \$bootable{ }\
                      method{ format } format{ }\
                      use_filesystem{ } filesystem{ ext4 }\
                      mountpoint{ /boot }\
              .\
              10240 10000 -1 ext4\
                      \$primary{ }\
                      method{ format } format{ }\
                      use_filesystem{ } filesystem{ ext4 }\
                      mountpoint{ / }\
              .\
              512 10000 512 fat32\
                      \$primary{ }\
                      method{ efi } format{ }\
                      mountpoint{ /boot/efi }\
              .\
              8192 10000 8192 linux-swap\
                      \$primary{ }\
                      method{ swap } format{ }\
              .
### 确认对磁盘的写入
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman-partitioning/confirm_resize boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

# 9. Base system installation
# 10. Apt setup

# 安装源的设置。不安装额外推荐包，不使用额外源，不安装额外的语言
d-i base-installer/install-recommends boolean false
# d-i apt-setup/use_mirror boolean false
d-i apt-setup/backports boolean false
d-i apt-setup/restricted boolean false
d-i apt-setup/security boolean false
d-i apt-setup/security-updates boolean false
d-i apt-setup/universe boolean false
d-i debian-installer/allow_unauthenticated boolean true

d-i pkgsel/install-language-support boolean false
d-i pkgsel/ignore-incomplete-language-support boolean true
d-i pkgsel/upgrade select none
d-i pkgsel/update-policy select none

# 指定安装的软件集：（默认支持的软件集有：）
## kylin-standard-server ：基础服务器
## kylin-web-server：WEB服务器
## kylin-gui-server：图形化服务器
## kylin-development-server：开发环境
## kylin-oem：OEM环境
### 下面以安装“基础服务器”+“图形化服务器”为例：
tasksel tasksel/first multiselect kylin-standard-server, kylin-GUI-server

#以下命令会使服务器安装完成后自动重启，请在确实需要自动重启的情况下删除‘#’号
d-i finish-install/reboot_in_progress note
EOF

    ##特别版本对preseed的兼容修改
    [[ "$setNet" == '0' ]] && [[ "$AutoNet" == '1' ]] && {
        sed -i '/netcfg\/disable_autoconfig/d' /boot/preseed.cfg.new
        sed -i '/netcfg\/dhcp_options/d' /boot/preseed.cfg.new
        sed -i '/netcfg\/get_.*/d' /boot/preseed.cfg.new
        sed -i '/netcfg\/confirm_static/d' /boot/preseed.cfg.new
    }

    [[ "$DIST" == 'trusty' ]] && GRUBPATCH='1'
    [[ "$DIST" == 'wily' ]] && GRUBPATCH='1'

    [[ "$GRUBPATCH" == '1' ]] && {
        sed -i 's/^d-i\ grub-installer\/bootdev\ string\ default//g' /boot/preseed.cfg.new
    }
    [[ "$GRUBPATCH" == '0' ]] && {
        sed -i 's/debconf-set\ grub-installer\/bootdev.*\"\;//g' /boot/preseed.cfg.new
    }
    [[ "$DIST" == 'xenial' ]] && {
        sed -i 's/^d-i\ clock-setup\/ntp\ boolean\ true/d-i\ clock-setup\/ntp\ boolean\ false/g' /boot/preseed.cfg.new
    }

    [[ "$linuxdists" == 'debian' ]] && {
        sed -i '/user-setup\/allow-password-weak/d' /boot/preseed.cfg.new
        sed -i '/user-setup\/encrypt-home/d' /boot/preseed.cfg.new
        sed -i '/pkgsel\/update-policy/d' /boot/preseed.cfg.new
        sed -i 's/umount\ \/media.*true\;\ //g' /boot/preseed.cfg.new
    }

    [[ "$ddMode" == '1' ]] && {
        WinDHCP() {
            echo -ne "@ECHO OFF\r\ncd\040\057d\040\042\045ProgramData\045\057Microsoft\057Windows\057Start\040Menu\057Programs\057Startup\042\r\ndel\040\057f\040\057q\040net\056bat\r\n\r\n" >'/boot/tmp/net.tmp'
        }
        WinNoDHCP() {
            echo -ne "@ECHO OFF\r\ncd\056\076\045windir\045\GetAdmin\r\nif\040exist\040\045windir\045\GetAdmin\040\050del\040\057f\040\057q\040\042\045windir\045\GetAdmin\042\051\040else\040\050\r\necho\040CreateObject^\050\042Shell\056Application\042^\051\056ShellExecute\040\042\045~s0\042\054\040\042\045\052\042\054\040\042\042\054\040\042runas\042\054\040\061\040\076\076\040\042\045temp\045\Admin\056vbs\042\r\n\042\045temp\045\Admin\056vbs\042\r\ndel\040\057f\040\057q\040\042\045temp\045\Admin\056vbs\042\r\nexit\040\057b\040\062\051\r\nfor\040\057f\040\042tokens=\063\052\042\040\045\045i\040in\040\050\047netsh\040interface\040show\040interface\040^|more\040+3\040^|findstr\040\057R\040\042\u672c\u5730\056\052\040\u4ee5\u592a\056\052\040Local\056\052\040Ethernet\042\047\051\040do\040\050set\040EthName=\045\045j\051\r\nnetsh\040-c\040interface\040ip\040set\040address\040name=\042\045EthName\045\042\040source=static\040address=$IPv4\040mask=$MASK\040gateway=$GATE\r\nnetsh\040-c\040interface\040ip\040add\040dnsservers\040name=\042\045EthName\045\042\040address=\070\056\070\056\070\056\070\040index=1\040validate=no\r\nnetsh\040-c\040interface\040ip\040add\040dnsservers\040name=\042\045EthName\045\042\040address=\070\056\070\056\064\056\064\040index=2\040validate=no\r\ncd\040\057d\040\042\045ProgramData\045\057Microsoft\057Windows\057Start\040Menu\057Programs\057Startup\042\r\ndel\040\057f\040\057q\040net\056bat\r\n\r\n" >'/boot/tmp/net.tmp'
        }
        [[ "$setNet" == '1' ]] && WinNoDHCP
        [[ "$setNet" == '0' ]] && {
            [[ "$AutoNet" -eq '1' ]] && WinDHCP
            [[ "$AutoNet" -eq '0' ]] && WinNoDHCP
        }
        iconv -f 'UTF-8' -t 'GBK' '/boot/tmp/net.tmp' -o '/boot/tmp/net.bat'
        rm -rf '/boot/tmp/net.tmp'
        echo "$DDURL" | grep -q '^https://'
        [[ $? -eq '0' ]] && {
            echo -ne '\nAdd ssl support...\n'
            [[ -n $SSL_SUPPORT ]] && {
                wget --no-check-certificate -qO- "$SSL_SUPPORT" | tar -x
                [[ ! -f /boot/tmp/usr/bin/wget ]] && echo 'Error! SSL_SUPPORT.' && exit 1
                sed -i 's/wget\ -qO-/\/usr\/bin\/wget\ --no-check-certificate\ --retry-connrefused\ --tries=7\ --continue\ -qO-/g' /boot/tmp/preseed.cfg
                [[ $? -eq '0' ]] && echo -ne 'Success! \n\n'
            } || {
                echo -ne 'Not ssl support package! \n\n'
                exit 1
            }
        }
    }

    [[ "$ddMode" == '0' ]] && {
        sed -i '/anna-install/d' /boot/preseed.cfg.new
        sed -i 's/wget.*\/sbin\/reboot\;\ //g' /boot/preseed.cfg.new
    }
    [[ "$INCFW" == '1' ]] && [[ "$linuxdists" == 'debian' ]] && [[ -f '/boot/firmware.cpio.gz' ]] && {
        gzip -d <../firmware.cpio.gz | cpio --extract --verbose --make-directories --no-absolute-filenames >>/dev/null 2>&1
    }
    #rm -rf ../initrd.img.new
    # 制作initrd.gz压缩文件
    find . | cpio -H newc --create --verbose | gzip -9 >../initrd.img.gz
    #rm -rf /boot/tmp;
}

[[ "$inVNC" == 'y' ]] && {
    sed -i '$i\\n' $GRUBDIR/$GRUBFILE
    sed -i '$r /tmp/grub.new' $GRUBDIR/$GRUBFILE
    echo -e "\n\033[33m\033[04mIt will reboot! \nPlease look at VNC! \nSelect\033[0m\033[32m Install OS [$DIST $VER] \033[33m\033[4mto install system.\033[04m\n\n\033[31m\033[04mThere is some information for you.\nDO NOT CLOSE THE WINDOW! "
    echo -e "\033[35mIPv4\t\tNETMASK\t\tGATEWAY\033[0m"
    echo -e "\033[36m\033[04m$IPv4\033[0m\t\033[36m\033[04m$MASK\033[0m\t\033[36m\033[04m$GATE\n"

    read -n 1 -p "Press Enter to reboot..." INP
    [[ "$INP" != '' ]] && echo -ne '\b \n\n'
}

chown root:root $GRUBDIR/$GRUBFILE
chmod 444 $GRUBDIR/$GRUBFILE
sshpass -p 'Huayun@123' scp -o StrictHostKeyChecking=no  /boot/preseed.cfg.new  root@172.16.81.81:/home/preseeds/${IPv4}.preseed.cfg

sleep 3 && reboot >/dev/null 2>&1
