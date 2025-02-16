#!/bin/bash

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo "请以 root 用户身份运行此脚本。"
    exit 1
fi

# 定义 GitHub 仓库信息
GITHUB_REPO="https://github.com/lingxistudio/Prort.git"
# 临时下载目录，放在 root 文件夹下
TEMP_DIR="/root/temp_project"
PROJECT_DIR="/var/www/html"
# 项目主题文件所在文件夹
THEME_DIR="$PROJECT_DIR/Port"
# 脚本目录
SCRIPTS_DIR="$PROJECT_DIR/scripts"
# PHP 目录
PHP_DIR="$PROJECT_DIR/php"
# 数据目录
DATA_DIR="$PROJECT_DIR/data"
# 模板目录
TEMPLATES_DIR="$PROJECT_DIR/templates"
# 静态资源目录
STATIC_DIR="$PROJECT_DIR/static"

# 检测操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    echo "无法检测操作系统类型。"
    exit 1
fi

# 让用户输入 Nginx 监听端口号
read -p "请输入 Nginx 监听的端口号（默认 80）: " NGINX_PORT
NGINX_PORT=${NGINX_PORT:-80}

# 安装依赖函数
install_dependencies() {
    case "$OS" in
        "Ubuntu" | "Debian GNU/Linux")
            apt update
            apt upgrade -y
            apt install -y nginx php-fpm php-mysql git dante-server squid strongswan xl2tpd pptpd
            ;;
        "CentOS Linux" | "Red Hat Enterprise Linux Server")
            yum update -y
            yum install -y epel-release
            yum install -y nginx php-fpm php-mysqlnd git dante squid strongswan xl2tpd pptpd
            ;;
        *)
            echo "不支持的操作系统。仅支持 Ubuntu、Debian、CentOS 和 RHEL。"
            exit 1
            ;;
    esac
}

# 配置 Nginx 函数
configure_nginx() {
    case "$OS" in
        "Ubuntu" | "Debian GNU/Linux")
            cat <<EOF > /etc/nginx/sites-available/default
server {
    listen $NGINX_PORT default_server;
    listen [::]:$NGINX_PORT default_server;

    root $TEMPLATES_DIR;
    index index.php index.html index.htm;

    server_name _;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;  # 根据实际安装的 PHP 版本调整
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
            ;;
        "CentOS Linux" | "Red Hat Enterprise Linux Server")
            cat <<EOF > /etc/nginx/conf.d/default.conf
server {
    listen $NGINX_PORT;
    server_name _;
    root $TEMPLATES_DIR;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
            ;;
    esac

    nginx -t
    if [ $? -eq 0 ]; then
        systemctl reload nginx
        echo "Nginx 配置已重新加载。"
    else
        echo "Nginx 配置检查失败，请手动检查配置文件。"
        exit 1
    fi
}

# 启动服务函数
start_services() {
    case "$OS" in
        "Ubuntu" | "Debian GNU/Linux")
            systemctl start nginx php8.1-fpm
            systemctl enable nginx php8.1-fpm
            ;;
        "CentOS Linux" | "Red Hat Enterprise Linux Server")
            systemctl start nginx php-fpm
            systemctl enable nginx php-fpm
            ;;
    esac
}

# 从 GitHub 下载项目文件到临时目录
download_project() {
    mkdir -p $TEMP_DIR
    rm -rf $TEMP_DIR/*
    if git clone $GITHUB_REPO $TEMP_DIR; then
        chmod +x $SCRIPTS_DIR/proxy_scripts.sh
        chmod +x $SCRIPTS_DIR/deploy_script.sh
    else
        echo "项目下载失败，清理临时文件..."
        rm -rf $TEMP_DIR
        exit 1
    fi
}

# 将临时目录的文件复制到目标目录
copy_project_files() {
    rm -rf $PROJECT_DIR/*
    cp -r $TEMP_DIR/* $PROJECT_DIR
    if [ $? -ne 0 ]; then
        echo "文件复制失败，请检查权限和目标目录。"
        exit 1
    fi
    rm -rf $TEMP_DIR
}

# 配置脚本权限
configure_script_permissions() {
    echo "www-data ALL=(ALL) NOPASSWD: $SCRIPTS_DIR/proxy_scripts.sh" >> /etc/sudoers
}

# 开放防火墙端口
open_firewall_ports() {
    case "$OS" in
        "Ubuntu" | "Debian GNU/Linux")
            ufw allow $NGINX_PORT
            ;;
        "CentOS Linux" | "Red Hat Enterprise Linux Server")
            firewall-cmd --permanent --add-port=$NGINX_PORT/tcp
            firewall-cmd --reload
            ;;
    esac
}

# 创建初始用户文件
create_user_file() {
    USER_FILE="$DATA_DIR/users.txt"
    if [ ! -d "$DATA_DIR" ]; then
        mkdir -p "$DATA_DIR"
    fi
    echo "admin:123456" > $USER_FILE
    chmod 600 $USER_FILE
}

# 主执行流程
install_dependencies
start_services
configure_nginx
download_project
copy_project_files
configure_script_permissions
open_firewall_ports
create_user_file

echo "一键部署完成！你可以通过浏览器访问 http://your_server_ip:$NGINX_PORT 来使用项目。"