#!/bin/bash

# Update and upgrade the system
apt update && apt upgrade -y

# Install OpenVPN and Easy-RSA
apt install -y openvpn easy-rsa

# Set up the CA directory
make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa

# Initialize the PKI
./easyrsa init-pki

# Build the CA
./easyrsa --batch build-ca nopass

# Generate server certificate and key
./easyrsa --batch build-server-full server nopass

# Generate Diffie-Hellman parameters
./easyrsa gen-dh

# Generate TLS-Auth key
openvpn --genkey secret /etc/openvpn/ta.key

# Copy the files to the OpenVPN directory
cp pki/ca.crt pki/issued/server.crt pki/private/server.key pki/dh.pem /etc/openvpn/

# Create server configuration
cat << EOF > /etc/openvpn/server.conf
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "route 10.8.0.0 255.255.255.0"
push "route 10.0.0.0 255.255.255.0"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
tls-auth ta.key 0
cipher AES-256-CBC
auth SHA256
user nobody
group nogroup
persist-key
persist-tun
tun-mtu 1472
mssfix 1432
status openvpn-status.log
verb 3
EOF

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

# Configure NAT for VPN subnet and AWS private subnet
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections
apt install -y iptables-persistent

# Enable and start OpenVPN service
systemctl enable openvpn@server
systemctl start openvpn@server

# Generate client configuration
mkdir -p /etc/openvpn/client
cat << EOF > /etc/openvpn/client/client.ovpn
client
dev tun
proto udp
remote YOUR_EC2_PUBLIC_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
auth SHA256
key-direction 1
verb 3

# Split tunneling configuration
route-nopull
route 10.8.0.0 255.255.255.0
route 10.0.0.0 255.255.255.0
EOF

echo "<ca>" >> /etc/openvpn/client/client.ovpn
cat /etc/openvpn/ca.crt >> /etc/openvpn/client/client.ovpn
echo "</ca>" >> /etc/openvpn/client/client.ovpn

echo "<cert>" >> /etc/openvpn/client/client.ovpn
./easyrsa --batch build-client-full client nopass
cat pki/issued/client.crt >> /etc/openvpn/client/client.ovpn
echo "</cert>" >> /etc/openvpn/client/client.ovpn

echo "<key>" >> /etc/openvpn/client/client.ovpn
cat pki/private/client.key >> /etc/openvpn/client/client.ovpn
echo "</key>" >> /etc/openvpn/client/client.ovpn

echo "<tls-auth>" >> /etc/openvpn/client/client.ovpn
cat /etc/openvpn/ta.key >> /etc/openvpn/client/client.ovpn
echo "</tls-auth>" >> /etc/openvpn/client/client.ovpn

# Replace YOUR_EC2_PUBLIC_IP with the actual public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
sed -i "s/YOUR_EC2_PUBLIC_IP/$PUBLIC_IP/" /etc/openvpn/client/client.ovpn

echo "OpenVPN server setup complete. Client configuration file is available at /etc/openvpn/client/client.ovpn"
