Ставим Zabbix по инструкции. Не забываем выбрать нужную версию всего
https://www.zabbix.com/download?zabbix=6.4&os_distribution=ubuntu&os_version=20.04&components=server_frontend_agent&db=pgsql&ws=nginx

a. Install Zabbix repository
Documentation
# wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb
# dpkg -i zabbix-release_6.4-1+ubuntu22.04_all.deb
# apt update
b. Install Zabbix server, frontend, agent
# apt install zabbix-server-pgsql zabbix-frontend-php php8.1-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent
c. Create initial database
Documentation

Make sure you have database server up and running.

Run the following on your database host.
# sudo -u postgres createuser --pwprompt zabbix
# sudo -u postgres createdb -O zabbix zabbix

On Zabbix server host import initial schema and data. You will be prompted to enter your newly created password.
# zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix
d. Configure the database for Zabbix server

Edit file /etc/zabbix/zabbix_server.conf
DBPassword=password 

e. Configure PHP for Zabbix frontend

Edit file /etc/zabbix/nginx.conf uncomment and set 'listen' and 'server_name' directives.
# listen 8080;
# server_name example.com;
f. Start Zabbix server and agent processes

Start Zabbix server and agent processes and make it start at system boot.
# systemctl restart zabbix-server zabbix-agent nginx php8.1-fpm
# systemctl enable zabbix-server zabbix-agent nginx php8.1-fpm
g. Open Zabbix UI web page

The URL for Zabbix UI when using Nginx depends on the configuration changes you should have made. 
