#!/bin/bash

dec2ip () {
    local ip dec=$@
    for e in {3..0}
    do
        ((octet = dec / (256 ** e) ))
        ((dec -= octet * 256 ** e))
        ip+=$delim$octet
        delim=.
    done
    printf '%s\n' "$ip"
}

ip2dec () {
    local a b c d ip=$@
    IFS=. read -r a b c d <<< "$ip"
    printf '%d\n' "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))"
}

decrease_ip () {
	echo $(dec2ip $(ip2dec $@)-1)
}

kali_nic=$1
kali_ip=$2
kali_mac=$3
kali_gw=$4
kali_dns=$5

echo -e "\n$0: The following information will be used, please double check it."
echo -e "$0:\t Network intergface=$kali_nic"
echo -e "$0:\t MAC address=$kali_mac"
echo -e "$0:\t IP address=$kali_ip"
echo -e "$0:\t Network gateway=$kali_gw"
echo -e "$0:\t DNS servers=$kali_dns"
echo -e "$0: If they are correct, press <enter> to proceed, otherwise CTRL+C to abort!"; 
read -s -p ""

echo -e "\n$0: Installing DNSMASQ ..." 
apt-get clean
apt-get update
apt-get install dnsmasq

echo -e "\n$0: Downloading KALI image ..." 
mkdir -p /tftpboot
cd /tftpboot
#wget http://repo.kali.org/kali/dists/kali-current/main/installer-amd64/current/images/netboot/netboot.tar.gz
wget http://repo.kali.org/kali/dists/kali-rolling/main/installer-amd64/current/images/netboot/netboot.tar.gz
tar zxpf netboot.tar.gz
rm netboot.tar.gz

echo -e "\n$0: Configuring DNSMASQ ..." 
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak
echo "
interface=$kali_nic
dhcp-range=$(decrease_ip $kali_ip),$kali_ip,1h
dhcp-boot=pxelinux.0
enable-tftp
tftp-root=/tftpboot/
dhcp-option=3,$kali_gw
dhcp-option=6,$kali_dns
dhcp-host=$kali_mac,$kali_ip
"  > /etc/dnsmasq.conf

echo -e "\n$0: Restarting DNSMASQ..." 
service dnsmasq restart

echo -e "\n$0: FINISHED" 


