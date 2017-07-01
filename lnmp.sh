#! /bin/bash
echo "Hello This script is for install nginx, php and mysql on linux. "


##
#
# update yum at first
#
##

yum -y install epel-release
yum update -y

##
#
# install desp 
#
##

echo "Install desp..."
yum install -y gcc gcc-c++ autoconf automake libtool re2c flex bison php-mcrypt libmcrypt libmcrypt-devel openssl-devel libxml2 libxml2-devel libcurl-devel libjpeg-devel libpng-devel freetype-devel zlib-devel mcrypt bzip2-devel libicu-devel systemd-devel mhash  glibc-devel glib2-devel ncurses-devel curl-devel gettext-devel libxslt-devel libxslt-dev


##
#
# install mysql with yum 
#
##
wget -O /usr/local/src/mysql57-community-release-el7-11.noarch.rpm https://repo.mysql.com//mysql57-community-release-el7-11.noarch.rpm
yum localinstall -y /usr/local/src/mysql57-community-release-el7-11.noarch.rpm
yum install -y mysql-community-server
mysqld --initialize-insecure --user=mysql
systemctl daemon-reload
systemctl enable mysqld.service
systemctl start mysqld

##
#
# install php
#
##

groupadd www
useradd -s /sbin/nologin -g www php

wget -O /usr/local/src/php7.tar.gz http://cn2.php.net/get/php-7.1.6.tar.gz/from/this/mirror
tar -zxvf /usr/local/src/php7.tar.gz -C /usr/local/src
cd /usr/local/src/php-7.1.6

./configure --prefix=/usr/local/php  --with-curl  --with-freetype-dir --with-libdir=/usr/lib64 --with-png-dir=/usr/lib64 --with-gettext=/usr/lib64  --with-jpeg-dir --with-gd  --with-gettext  --with-iconv-dir  --with-kerberos  --with-libxml-dir  --with-mysqli  --with-openssl  --with-pcre-regex  --with-pdo-mysql  --with-pdo-sqlite  --with-pear  --with-png-dir  --with-xmlrpc  --with-xsl  --with-zlib  --enable-fpm  --enable-bcmath  --enable-libxml  --enable-inline-optimization  --enable-gd-native-ttf  --enable-mbregex  --enable-mbstring  --enable-opcache  --enable-pcntl  --enable-shmop  --enable-soap  --enable-sockets  --enable-sysvsem  --enable-xml  --with-libdir=lib64  --enable-zip --with-config-file-path=/usr/local/php/etc/ --with-fpm-user=php --with-fpm-group=www
if [ ! $? ];then
    echo 'PHP configure failed.'
	exit 3
fi


make && make install
if [ ! $? ];then
    echo 'PHP make failed.'
	exit 3
fi


##
#
# 复制相关文件
#
##
cp php.ini-development /usr/local/php/etc/php.ini
cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf
cp -R ./sapi/fpm/php-fpm /etc/init.d/php-fpm

cd ..

##
#
# 设置php-fpm.service文件
#
##
touch /lib/systemd/system/php-fpm.service
echo  "[Unit]" >> /lib/systemd/system/php-fpm.service
echo  "Description=The PHP FastCGI Process Manager" >> /lib/systemd/system/php-fpm.service
echo  "After=syslog.target network.target" >> /lib/systemd/system/php-fpm.service

echo  "[Service]" >> /lib/systemd/system/php-fpm.service
echo  "Type=simple" >> /lib/systemd/system/php-fpm.service
echo  "PIDFile=/run/php-fpm.pid" >> /lib/systemd/system/php-fpm.service
echo  "ExecStart=/usr/local/php/sbin/php-fpm --nodaemonize --fpm-config /usr/local/php/etc/php-fpm.conf -g /run/php-fpm.pid " >> /lib/systemd/system/php-fpm.service
echo  "ExecReload=/bin/kill -USR2 $MAINPID" >> /lib/systemd/system/php-fpm.service
echo  "ExecStop=/bin/kill -SIGINT $MAINPID" >> /lib/systemd/system/php-fpm.service

echo  "[Install]" >> /lib/systemd/system/php-fpm.service
echo  "WantedBy=multi-user.target" >> /lib/systemd/system/php-fpm.service


chmod +x /lib/systemd/system/php-fpm.service
systemctl daemon-reload
systemctl enable php-fpm.service
systemctl start php-fpm.service


##
#
# 安装nginx
#
##

wget -O /usr/local/src/nginx-1.10.0.tar.gz http://nginx.org/download/nginx-1.10.0.tar.gz
tar -zxvf /usr/local/src/nginx-1.10.0.tar.gz -C /usr/local/src
cd /usr/local/src/nginx-1.10.0

./configure --sbin-path=/usr/local/nginx/nginx --conf-path=/usr/local/nginx/nginx.conf --pid-path=/usr/local/nginx/nginx.pid --with-http_ssl_module 
if [ ! $? ];then
    echo 'Nginx configure failed.'
	exit 3
fi


make && make install
if [ ! $? ];then
    echo 'Nginx make failed.'
	exit 3
fi
##
#
# 设置nginx.service文件
#
##
touch /lib/systemd/system/nginx.service
echo  "[Unit]" >> /lib/systemd/system/nginx.service
echo  "Description=nginx.service" >> /lib/systemd/system/nginx.service
echo  "After=network.target" >> /lib/systemd/system/nginx.service

echo  "[Service]" >> /lib/systemd/system/nginx.service
echo  "Type=forking" >> /lib/systemd/system/nginx.service
echo  "ExecStart=/usr/local/nginx/nginx" >> /lib/systemd/system/nginx.service
echo  "ExecReload=/usr/local/nginx/nginx -s reload" >> /lib/systemd/system/nginx.service
echo  "ExecStop=/usr/local/nginx/nginx -s stop" >> /lib/systemd/system/nginx.service
echo  "PrivateTmp=true" >> /lib/systemd/system/nginx.service

echo  "[Install]" >> /lib/systemd/system/nginx.service
echo  "WantedBy=multi-user.target" >> /lib/systemd/system/nginx.service


chmod +x /lib/systemd/system/nginx.service
systemctl daemon-reload
systemctl enable nginx.service
systemctl start nginx.service

##
#
# 防火墙设置
#
##
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=9000/tcp
firewall-cmd --permanent --add-port=3306/tcp

firewall-cmd --reload
