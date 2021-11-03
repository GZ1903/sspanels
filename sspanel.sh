#/bin/bash

# Date : 2021-11-02 22:07:23

# Author : GZ

# Mail : v2board@qq.com

# Function : 脚本介绍

# Version : V1.0


# 检查用户是否为root用户
if [ $(id -u) != "0" ]; then
    echo "Error: 您必须是root才能运行此脚本，请使用root安装sspanel"
    exit 1
fi

process()
{
install_date="sspanel_install_$(date +%Y-%m-%d_%H:%M:%S).log"
printf "
\033[36m#######################################################################
#                     欢迎使用sspanel一键部署脚本                     #
#                脚本适配环境Ubuntu 18.04+/Debian 10+、内存1G+        #
#                请使用干净主机部署！                                 #
#                更多信息请访问 https://gz1903.github.io              #
#######################################################################\033[0m
"

# 设置数据库密码
while :; do echo
    read -p "请输入Mysql数据库root密码: " Database_Password 
    [ -n "$Database_Password" ] && break
done

#获取主机内网ip
ip="$(ifconfig|grep "inet "|awk '{print $2;exit;}')"
#获取主机外网ip
ips="$(curl ip.sb)"

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                    正在安装常用组件 请稍等~                         #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
# 更新必备基础软件
apt update && apt upgrade -y
apt install -y curl vim wget unzip apt-transport-https lsb-release ca-certificates git gnupg2
# 更新PPA软件源
apt install software-properties-common

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                  正在配置Firewall策略 请稍等~                       #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
sudo ufw allow 80
#放行TCP80端口

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                 正在安装MariaDB数据库 请稍等~                       #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
# MariaDB 是 MySQL 关系数据库管理系统的一个复刻，由社区开发，有商业支持，旨在继续保持在 GNU GPL 下开源。
# MariaDB 与 MySQL 完全兼容
# 选取官方源的镜像进行安装 MariaDB 10.5 稳定版本
# 添加清华源
sudo apt-get install software-properties-common dirmngr apt-transport-https
sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://mirrors.tuna.tsinghua.edu.cn/mariadb/repo/10.5/ubuntu bionic main'
# 安装 MariaDB Server
sudo apt update
sudo apt install mariadb-server -y

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#         正在安装Nginx环境  时间较长请稍等~                          #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
# 添加 PPA
add-apt-repository ppa:ondrej/nginx -y
apt update
sudo apt install nginx -y
# 开机自启
sudo systemctl enable nginx
# 检测Nginx版本
nginx -V

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#         正在安装配置PHP环境及扩展  时间较长请稍等~                  #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
# 添加 PPA
add-apt-repository ppa:ondrej/php -y
apt update
# 安装PHP 7.3，如果需要其他版本，自行替换
apt install -y php7.3-fpm php7.3-mysql php7.3-curl php7.3-gd php7.3-mbstring php7.3-xml php7.3-xmlrpc php7.3-opcache php7.3-zip php7.3 php7.3-json php7.3-bz2 php7.3-bcmath
# 开机自启
sudo systemctl enable php7.3-fpm

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                   正在配置Mysql数据库 请稍等~                       #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
#修改数据库密码
mysqladmin -u root password "$Database_Password"
echo -e "\033[36m数据库密码设置完成！\033[0m"
#创建数据库
mysql -uroot -p$Database_Password -e "CREATE DATABASE sspanel CHARACTER set utf8 collate utf8_bin;"
echo $?="正在创建sspanel数据库"

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                    正在配置Nginx 请稍等~                            #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
# 删除默认配置
rm -rf /etc/nginx/sites-enabled/default
rm -rf /etc/nginx/sites-available/sspanel.conf
touch /etc/nginx/sites-available/sspanel.conf
cat > /etc/nginx/sites-available/sspanel.conf <<"eof"
server {  
    listen 80;
    listen [::]:80;
    root /var/www/sspanel/public; # 改成你自己的路径，需要以 /public 结尾
    index index.php index.html;
    # server_name https://gz1903.github.io; # 改成你自己的域名

    location / {
        try_files $uri /index.php$is_args$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.3-fpm.sock;
    }
}
eof
# 配置软连接。
cd /etc/nginx/sites-enabled
ln -s /etc/nginx/sites-available/sspanel.conf sspanel
nginx -s reload

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                   正在编译sspanel软件 请稍等~                       #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
# 安装sspanel软件包
# 去官网下载编译安装的sspanel：https://github.com/Anankke/SSPanel-Uim.git
# 清空目录文件
rm -rf /var/www/*

cd /var/www/
git clone https://gitee.com/gz1903/sspanel.git ${pwd}
# 下载 composer
cd /var/www/sspanel/
git config core.filemode false
wget https://getcomposer.org/installer -O composer.phar
echo -e "\033[32m软件下载安装中，时间较长请稍等~\033[0m"
# 安装 PHP 依赖
php composer.phar
echo -e "\033[32m请输入yes确认安装！~\033[0m"
php composer.phar install
# 调整目录权限
chmod -R 755 ${PWD}
chown -R www-data:www-data ${PWD}

# 修改配置文件
cd /var/www/sspanel/
cp config/.config.example.php config/.config.php
cp config/appprofile.example.php config/appprofile.php
# 设置sspanel数据库连接
# 设置此key为随机字符串确保网站安全 !!!
sed -i "s/1145141919810/aksgsj@h$RANDOM/" /var/www/sspanel/config/.config.php
# 站点名称
sed -i "s/SSPanel-UIM/飞一般的感觉/" /var/www/sspanel/config/.config.php
# 站点地址
sed -i "s/https:\/\/sspanel.host/http:\/\/$ips/" /var/www/sspanel/config/.config.php
# 用于校验魔改后端请求
sed -i "s/NimaQu/sadg^#@s$RANDOM/" /var/www/sspanel/config/.config.php
# 设置sspanel数据库连接地址
sed -i "s/host'\]      = ''/host'\]      = '127.0.0.1'/" /var/www/sspanel/config/.config.php
# 设置数据库连接密码
sed -i "s/password'\]  = 'sspanel'/password'\]  = '$Database_Password'/" /var/www/sspanel/config/.config.php
# 导入数据库文件
mysql -uroot -p$Database_Password sspanel < /var/www/sspanel/sql/glzjin_all.sql;
echo -e "\033[36m设置管理员账号：\033[0m"
php xcat User createAdmin
# 重置所有流量
php xcat User resetTraffic
# 下载 IP 地址库
php xcat Tool initQQWry

nginx -s reload
echo $?="服务启动完成"

echo -e "\033[32m--------------------------- 安装已完成 ---------------------------\033[0m"
echo -e "\033[32m 数据库名     :sspanel\033[0m"
echo -e "\033[32m 数据库用户名 :root\033[0m"
echo -e "\033[32m 数据库密码   :"$Database_Password
echo -e "\033[32m 网站目录     :/var/www/sspanel\033[0m"
echo -e "\033[32m 配置目录     :/var/www/sspanel/config/.config.php\033[0m"
echo -e "\033[32m 网页内网访问 :http://"$ip
echo -e "\033[32m 网页外网访问 :http://"$ips
echo -e "\033[32m 安装日志文件 :/var/log/"$install_date
echo -e "\033[32m------------------------------------------------------------------\033[0m"
echo -e "\033[32m 如果安装有问题请反馈安装日志文件。\033[0m"
echo -e "\033[32m 使用有问题请在这里寻求帮助:https://gz1903.github.io\033[0m"
echo -e "\033[32m 电子邮箱:v2board@qq.com\033[0m"
echo -e "\033[32m------------------------------------------------------------------\033[0m"

}

LOGFILE=/var/log/"sspanel_install_$(date +%Y-%m-%d_%H:%M:%S).log"
touch $LOGFILE
tail -f $LOGFILE &
pid=$!
exec 3>&1
exec 4>&2
exec &>$LOGFILE
process
ret=$?
exec 1>&3 3>&-
exec 2>&4 4>&-
