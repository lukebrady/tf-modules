#!/usr/bin/env bash

# First, ensure the userdata script is run as root.
# This ensures that all of the commands below can be run successfully.
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# Install network tools for debugging purposes.
apt update && apt upgrade -y
# Install necessary packages
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt install -y net-tools iptables-persistent

# Set the hostname of the NAT instance.
# TODO: Update the hostname to tag:Name.
hostnamectl set-hostname nat-instance

# Find the primary network interface on the NAT instance.
IF=$(ip -o -4 route show to default | awk '{print $5}')

# Configure IPv4 forwarding on the primary network interface.
# Make IP forwarding persistent across reboots
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Set up NAT rules
iptables -t nat -A POSTROUTING -o $IF -j MASQUERADE
iptables -F FORWARD
iptables -A FORWARD -i $IF -j ACCEPT
iptables -A FORWARD -o $IF -j ACCEPT

# iptables rules are saved so that iptable configuration
# persists when NAT the instance is rebooted.
iptables-save > /etc/iptables/rules.v4

# Ensure the iptables-persistent service is enabled to load rules at boot
systemctl enable netfilter-persistent
