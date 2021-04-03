#! /bin/sh

sudo apt update && sudo apt install default-jdk -y
sudo groupadd tomcat && sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat

cd /tmp
tomcat_version=9.0.44
wget https://downloads.apache.org/tomcat/tomcat-9/v$tomcat_version/bin/apache-tomcat-$tomcat_version.tar.gz
sudo mkdir /opt/tomcat

sudo tar xf /tmp/apache-tomcat-9*.tar.gz -C /opt/tomcat
sudo ln -s /opt/tomcat/apache-tomcat-$tomcat_version /opt/tomcat/latest
sudo chown -RH tomcat: /opt/tomcat/latest
sudo sh -c 'chmod +x /opt/tomcat/latest/bin/*.sh'


sudo cat << EOM > /etc/systemd/system/tomcat.service

[Unit]
Description=Tomcat 9 servlet container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/default-java"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom -Djava.awt.headless=true"

Environment="CATALINA_BASE=/opt/tomcat/latest"
Environment="CATALINA_HOME=/opt/tomcat/latest"
Environment="CATALINA_PID=/opt/tomcat/latest/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/latest/bin/startup.sh
ExecStop=/opt/tomcat/latest/bin/shutdown.sh

[Install]
WantedBy=multi-user.target

EOM

sudo systemctl daemon-reload
sudo systemctl start tomcat && sudo systemctl enable tomcat

echo "tomcat installed"

sed -i -e '18,$d' -e '17a <tomcat-users>\n<!--\n Comments\n-->\n<role rolename="admin-gui"/>\n<role rolename="manager-gui"/>\n<user username="admin" password="admin" roles="admin-gui,manager-gui"/>\n</tomcat-users>' /opt/tomcat/latest/conf/tomcat-users.xml

echo "user configured"

sed -i -e '18a <!--' -e '24i -->' /opt/tomcat/latest/webapps/manager/META-INF/context.xml

sudo systemctl restart tomcat

echo "tomcat installed successfully!!!"
