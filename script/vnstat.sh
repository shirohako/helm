#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: vnStat Install
#	Version: 1.2
#	Author: ame
#=================================================

_norm=$(tput sgr0)
_red=$(tput setaf 1)
_green=$(tput setaf 2)
_tan=$(tput setaf 3)
_cyan=$(tput setaf 6)
_blue=$(tput setaf 4)


function _print() {
    printf "${_norm}%s${_norm}\n" "$@"
}
function _info() {
    printf "${_cyan}➜ %s${_norm}\n" "$@"
}
function _success() {
    printf "${_blue}✓ %s${_norm}\n" "$@"
}
function _warning() {
    printf "${_tan}⚠ %s${_norm}\n" "$@"
}
function _error() {
    printf "${_red}✗ %s${_norm}\n" "$@"
}

if [[ $EUID != 0 ]]; then echo -e "\nNaive! I think this young man will not be able to run this script without root privileges.\n" ; exit 1 ; fi

if [[ -f /etc/redhat-release ]]; then
        release="centos"
elif cat /etc/issue | grep -q -E -i "debian"; then
        release="debian"
elif cat /etc/issue | grep -q -E -i "ubuntu"; then
        release="ubuntu"
elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
elif cat /proc/version | grep -q -E -i "debian"; then
        release="debian"
elif cat /proc/version | grep -q -E -i "ubuntu"; then
        release="ubuntu"
elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
fi

if [[ $release == centos ]]; then
    _info "yum installing dependent packages..."
    yum update -y
    yum install wget sqlite-devel gcc ntpdate gd-devel make tar -y --skip-broken
else
    _info "apt-get installing dependent packages..."
    apt update
    apt-get install wget make gcc libc6-dev libgd-dev libsqlite3-dev ntpdate sqlite3 -y
fi

_info "downloading source files..."
wget -N --no-check-certificate https://humdi.net/vnstat/vnstat-latest.tar.gz
tar zxvf vnstat-latest.tar.gz
rm vnstat-latest.tar.gz -f
cd vnstat-2*
./configure --prefix=/usr --sysconfdir=/etc && make && make install

if [[ ! -f /usr/bin/vnstat ]]; then
   _error "installation has failed!"
   exit 1
fi

_info "setting timezone and enable network time sync"
ln -sf /usr/share/zoneinfo/Asia/Shanghai  /etc/localtime
ntpdate asia.pool.ntp.org

_info "creating vnStat Service"
sed -i "s/sbin\//bin\/nohup /g" examples/systemd/simple/vnstat.service
mv examples/systemd/simple/vnstat.service /etc/systemd/system -f
systemctl enable vnstat --now

cd .. && rm -rf vnstat-2*

_success "vnStat installation finished"
