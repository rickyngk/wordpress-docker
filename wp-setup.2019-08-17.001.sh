yum install wget -y
yum install nano -y
yum install git -y
sudo yum update -y curl nss nss-util nspr

sudo yum install firewalld -y
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --zone=home --change-interface=eth0
sudo firewall-cmd --set-default-zone=home
sudo firewall-cmd --zone=home --add-service=http --permanent
sudo firewall-cmd --zone=home --add-service=https --permanent
sudo firewall-cmd --zone=home --add-port=8000/tcp --permanent
firewall-cmd --reload
sudo systemctl restart network
sudo systemctl reload firewalld

sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io

sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

sudo systemctl start docker

mkdir -p my-wp
cd my-wp

if grep -q wpstarup "/etc/rc.d/rc.local"; then
  echo "wpstarup.sh has been already init"
else
  chmod +x /etc/rc.d/rc.local
  echo "
    cd /root/my-wp
    sudo systemctl start docker
    docker-compose up -d
  " > wpstarup.sh
  echo "sh /root/my-wp/wpstarup.sh" >> /etc/rc.d/rc.local
fi

dbPassword=database_password_here
dbRootPassword=database_root_password_here
dbUsername=wp_msql_user

echo "
echo \"Doing my thing! E.g. install wp cli, install wordpress, etc...\"
sed -i \"/WP_DEBUG.*/a define('FS_METHOD', 'direct');\" /var/www/html/wp-config.php 
chown -R www-data:www-data /var/www/html/wp-content
exec \"apache2-foreground\"
" > wp-init.sh

chmod 777 /root/my-wp/wp-init.sh

echo "
version: '3.3'
services:
  db:
    image: mysql:5.7
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    networks:
      - vlan
    environment:
      MYSQL_ROOT_PASSWORD: $dbRootPassword
      MYSQL_DATABASE: wp_db_docker
      MYSQL_USER: $dbUsername
      MYSQL_PASSWORD: $dbPassword
    logging:
      driver: \"json-file\"
      options:
        max-file: \"10\"
        max-size: \"20m\"

  dbmanager:
    image: adminer
    depends_on:
      - db
    restart: always
    networks:
      - vlan
    ports:
      - \"8000:8080\"
    logging:
      driver: \"json-file\"
      options:
        max-file: \"10\"
        max-size: \"20m\"

  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    networks:
      - vlan
    ports:
      - \"80:80\"
    restart: always
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: $dbUsername
      WORDPRESS_DB_PASSWORD: $dbPassword
      WORDPRESS_DB_NAME: wp_db_docker
    volumes:
      - wp-content:/var/www/html/wp-content
      - /root/my-wp/wp-init.sh:/usr/local/bin/apache2-custom.sh
    command:
      - apache2-custom.sh
    logging:
      driver: \"json-file\"
      options:
        max-file: \"10\"
        max-size: \"20m\"
networks:
  vlan:
    driver: \"bridge\"
volumes:
    db_data: {}
    wp-content: {}
" > docker-compose.yml
reboot