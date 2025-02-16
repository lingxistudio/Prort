#!/bin/bash

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo "请以 root 用户身份运行此脚本。"
    exit 1
fi

# 项目根目录
PROJECT_DIR="/var/www/html"
# 脚本目录
SCRIPTS_DIR="$PROJECT_DIR/scripts"
# 数据目录
DATA_DIR="$PROJECT_DIR/data"

# 检测操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    echo "无法检测操作系统类型。"
    exit 1
fi

# 函数：安装依赖（根据不同系统）
install_dependencies() {
    case "$OS" in
        "Ubuntu" | "Debian GNU/Linux")
            apt-get update
            apt-get install -y dante-server squid nginx strongswan xl2tpd pptpd
            ;;
        "CentOS Linux" | "Red Hat Enterprise Linux Server")
            yum install -y epel-release
            yum install -y dante squid nginx strongswan xl2tpd pptpd
            ;;
        *)
            echo "不支持的操作系统。仅支持 Ubuntu、Debian、CentOS 和 RHEL。"
            exit 1
            ;;
    esac
}

# 函数：部署 SOCKS5 代理
deploy_socks5() {
    local socks_port=$1
    case "$OS" in
        "Ubuntu" | "Debian GNU/Linux")
            cat <<EOF > /etc/danted.conf
logoutput: syslog
internal: eth0 port = $socks_port
external: eth0
method: username none
user.privileged: root
user.unprivileged: nobody
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: bind connect udpassociate
    log: connect disconnect error
}
EOF
            systemctl restart danted.service
            systemctl enable danted.service
            ;;
        "CentOS Linux" | "Red Hat Enterprise Linux Server")
            cat <<EOF > /etc/sockd.conf
logoutput: syslog
internal: eth0 port = $socks_port
external: eth0
method: username none
user.privileged: root
user.unprivileged: nobody
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: bind connect udpassociate
    log: connect disconnect error
}
EOF
            systemctl restart sockd.service
            systemctl enable sockd.service
            ;;
    esac
}

# 函数：部署 HTTP 代理
deploy_http() {
    local http_port=$1
    case "$OS" in
        "Ubuntu" | "Debian GNU/Linux")
            cat <<EOF > /etc/squid/squid.conf
http_port $http_port
http_access allow all
EOF
            systemctl restart squid.service
            systemctl enable squid.service
            ;;
        "CentOS Linux" | "Red Hat Enterprise Linux Server")
            cat <<EOF > /etc/squid/squid.conf
http_port $http_port
http_access allow all
EOF
            systemctl restart squid.service
            systemctl enable squid.service
            ;;
    esac
}

# 函数：部署反代（使用 Nginx 作为示例）
deploy_reverse_proxy() {
    local reverse_proxy_port=$1
    case "$OS" in
        "Ubuntu" | "Debian GNU/Linux")
            cat <<EOF > /etc/nginx/sites-available/reverse_proxy
server {
    listen $reverse_proxy_port;
    server_name _;

    location / {
        proxy_pass http://backend_server;  # 这里需要替换为实际的后端服务器地址
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
            ln -s /etc/nginx/sites-available/reverse_proxy /etc/nginx/sites-enabled/
            systemctl restart nginx.service
            systemctl enable nginx.service
            ;;
        "CentOS Linux" | "Red Hat Enterprise Linux Server")
            cat <<EOF > /etc/nginx/conf.d/reverse_proxy.conf
server {
    listen $reverse_proxy_port;
    server_name _;

    location / {
        proxy_pass http://backend_server;  # 这里需要替换为实际的后端服务器地址
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
            systemctl restart nginx.service
            systemctl enable nginx.service
            ;;
    esac
}

# 函数：部署 L2TP 服务
deploy_l2tp() {
    local l2tp_port=$1
    case "$OS" in
        "Ubuntu" | "Debian GNU/Linux")
            cat <<EOF > /etc/ipsec.conf
config setup
    charondebug="ike 1, knl 1, cfg 0"
    uniqueids=no

conn %default
    ikelifetime=60m
    keylife=20m
    rekeymargin=3m
    keyingtries=1
    keyexchange=ikev1
    authby=secret
    ike=aes256-sha1-modp1024
    esp=aes256-sha1

conn L2TP-PSK-NAT
    rightsubnet=vhost:%priv
    also=L2TP-PSK-noNAT

conn L2TP-PSK-noNAT
    authby=secret
    pfs=no
    auto=add
    keyingtries=3
    dpddelay=30
    dpdtimeout=120
    dpdaction=clear
    rekey=no
    left=%defaultroute
    leftprotoport=udp/$l2tp_port
    right=%any
    rightprotoport=udp/%any
EOF
            cat <<EOF > /etc/ipsec.secrets
%any %any : PSK "your_pre_shared_key"  # 这里需要替换为实际的预共享密钥
EOF
            cat <<EOF > /etc/xl2tpd/xl2tpd.conf
[global]
ipsec saref = yes

[lns default]
ip range = 192.168.42.10-192.168.42.250
local ip = 192.168.42.1
require chap = yes
refuse pap = yes
require authentication = yes
name = l2tpd
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF
            cat <<EOF > /etc/ppp/options.xl2tpd
ipcp-accept-local
ipcp-accept-remote
ms-dns 8.8.8.8
ms-dns 8.8.4.4
noccp
auth
crtscts
idle 1800
mtu 1280
mru 1280
lock
connect-delay 5000
EOF
            cat <<EOF > /etc/ppp/chap-secrets
# Secrets for authentication using CHAP
# client  server  secret          IP addresses
*       l2tpd   your_password    *  # 这里需要替换为实际的密码
EOF
            sysctl -w net.ipv4.ip_forward=1
            iptables -t nat -A POSTROUTING -s 192.168.42.0/24 -o eth0 -j MASQUERADE
            systemctl restart strongswan.service
            systemctl restart xl2tpd.service
            systemctl enable strongswan.service
            systemctl enable xl2tpd.service
            ;;
        "CentOS Linux" | "Red Hat Enterprise Linux Server")
            cat <<EOF > /etc/ipsec.conf
config setup
    charondebug="ike 1, knl 1, cfg 0"
    uniqueids=no

conn %default
    ikelifetime=60m
    keylife=20m
    rekeymargin=3m
    keyingtries=1
    keyexchange=ikev1
    authby=secret
    ike=aes256-sha1-modp1024
    esp=aes256-sha1

conn L2TP-PSK-NAT
    rightsubnet=vhost:%priv
    also=L2TP-PSK-noNAT

conn L2TP-PSK-noNAT
    authby=secret
    pfs=no
    auto=add
    keyingtries=3
    dpddelay=30
    dpdtimeout=120
    dpdaction=clear
    rekey=no
    left=%defaultroute
    leftprotoport=udp/$l2tp_port
    right=%any
    rightprotoport=udp/%any
EOF
            cat <<EOF > /etc/ipsec.secrets
%any %any : PSK "your_pre_shared_key"  # 这里需要替换为实际的预共享密钥
EOF
            cat <<EOF > /etc/xl2tpd/xl2tpd.conf
[global]
ipsec saref = yes

[lns default]
ip range = 192.168.42.10-192.168.42.250
local ip = 192.168.42.1
require chap = yes
refuse pap = yes
require authentication = yes
name = l2tpd
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF
            cat <<EOF > /etc/ppp/options.xl2tpd
ipcp-accept-local
ipcp-accept-remote
ms-dns 8.8.8.8
ms-dns 8.8.4.4
noccp
auth
crtscts
idle 1800
mtu 1280
mru 1280
lock
connect-delay 5000
EOF
            cat <<EOF > /etc/ppp/chap-secrets
# Secrets for authentication using CHAP
# client  server  secret          IP addresses
*       l2tpd   your_password    *  # 这里需要替换为实际的密码
EOF
            sysctl -w net.ipv4.ip_forward=1
            iptables -t nat -A POSTROUTING -s 192.168.42.0/24 -o eth0 -j MASQUERADE
            systemctl restart strongswan.service
            systemctl restart xl2tpd.service
            systemctl enable strongswan.service
            systemctl enable xl2tpd.service
            ;;
    esac
}

# 函数：部署 PPTP 服务
deploy_pptp() {
    local pptp_port=$1
    case "$OS" in
        "Ubuntu" | "Debian GNU/Linux")
            cat <<EOF > /etc/ppp/pptpd-options
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
ms-dns 8.8.8.8
ms-dns 8.8.4.4
proxyarp
lock
nobsdcomp
novj
novjccomp
nologfd
EOF
            cat <<EOF > /etc/pptpd.conf
option /etc/ppp/pptpd-options
logwtmp
localip 192.168.43.1
remoteip 192.168.43.10-192.168.43.250
EOF
            cat <<EOF > /etc/ppp/chap-secrets
# Secrets for authentication using CHAP
# client  server  secret          IP addresses
*       pptpd   your_password    *  # 这里需要替换为实际的密码
EOF
            sysctl -w net.ipv4.ip_forward=1
            iptables -t nat -A POSTROUTING -s 192.168.43.0/24 -o eth0 -j MASQUERADE
            systemctl restart pptpd.service
            systemctl enable pptpd.service
            ;;
        "CentOS Linux" | "Red Hat Enterprise Linux Server")
            cat <<EOF > /etc/ppp/pptpd-options
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
ms-dns 8.8.8.8
ms-dns 8.8.4.4
proxyarp
lock
nobsdcomp
novj
novjccomp
nologfd
EOF
            cat <<EOF > /etc/pptpd.conf
option /etc/ppp/pptpd-options
logwtmp
localip 192.168.43.1
remoteip 192.168.43.10-192.168.43.250
EOF
            cat <<EOF > /etc/ppp/chap-secrets
# Secrets for authentication using CHAP
# client  server  secret          IP addresses
*       pptpd   your_password    *  # 这里需要替换为实际的密码
EOF
            sysctl -w net.ipv4.ip_forward=1
            iptables -t nat -A POSTROUTING -s 192.168.43.0/24 -o eth0 -j MASQUERADE
            systemctl restart pptpd.service
            systemctl enable pptpd.service
            ;;
    esac
}

# 主执行流程
install_dependencies
deploy_socks5 $3
deploy_http $4
deploy_reverse_proxy $5
deploy_l2tp $6
deploy_pptp $7

echo "代理服务部署完成！"