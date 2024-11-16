#!/bin/bash

cp /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/sources.list.d/pve-enterprise.list.original
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-enterprise.list
apt update
apt -y install libpve-network-perl ifupdown2

IFACE_NAME=$(cat /etc/network/interfaces | grep "inet manual" | cut -d " " -f2)
IPADDR=$(cat /etc/network/interfaces | grep "address" | cut -d " " -f2)
GATEWAY=$(cat /etc/network/interfaces | grep "gateway" | cut -d " " -f2)

NAT_IPADDR="192.168.7.1/24"
NAT_NETADDR="192.168.7.0/24"

mv /etc/network/interfaces /etc/network/interfaces.bu
tee /etc/network/interfaces > /dev/null <<EOF
auto lo
iface lo inet loopback

auto ${IFACE_NAME}
iface ${IFACE_NAME} inet static
        address ${IPADDR}
        gateway ${GATEWAY}

auto vmbr0
iface vmbr0 inet static
        address ${NAT_IPADDR}
        bridge_ports none
        bridge_stp off
        bridge_fd 0
        mtu 1500

        post-up   echo 1 > /proc/sys/net/ipv4/ip_forward
        post-up   iptables -t nat -A PREROUTING -p tcp --dport 2022 -j DNAT --to-destination 192.168.7.2:22
        post-up   iptables -t nat -A PREROUTING -p tcp --dport 3022 -j DNAT --to-destination 192.168.7.3:22
        post-up   iptables -t nat -A PREROUTING -p tcp --dport 4022 -j DNAT --to-destination 192.168.7.4:22
        post-up   iptables -t nat -A PREROUTING -p tcp --dport 5022 -j DNAT --to-destination 192.168.7.5:22
        post-up   iptables -t nat -A PREROUTING -p tcp --dport 6022 -j DNAT --to-destination 192.168.7.6:22
        post-up   iptables -t nat -A PREROUTING -p tcp --dport 7022 -j DNAT --to-destination 192.168.7.7:22
        post-up   iptables -t nat -A PREROUTING -p tcp --dport 8022 -j DNAT --to-destination 192.168.7.8:22
        post-up   iptables -t nat -A PREROUTING -p tcp --dport 9022 -j DNAT --to-destination 192.168.7.9:22
        post-up   iptables -t nat -A PREROUTING -p tcp --dport 10022 -j DNAT --to-destination 192.168.7.10:22
        post-up   iptables -t nat -A PREROUTING -p tcp --dport 11022 -j DNAT --to-destination 192.168.7.11:22
        post-up   iptables -t nat -A POSTROUTING -s '${NAT_NETADDR}' -o ${IFACE_NAME} -j MASQUERADE
        post-down iptables -t nat -D POSTROUTING -s '${NAT_NETADDR}' -o ${IFACE_NAME} -j MASQUERADE
		
source /etc/network/interfaces.d/*
EOF