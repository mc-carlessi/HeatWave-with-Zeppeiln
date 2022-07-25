#!/bin/bash
#set -x

while true
do
        read -s -r -p "Insert new password for zeppelin admin (don't use spaces): " ZEPPELIN_PASSWORD
        echo
        read -r -s -p "Retype password: " ZEPPELIN_PASSWORD_CONFIRM

        if [ "X${ZEPPELIN_PASSWORD}" == "X${ZEPPELIN_PASSWORD_CONFIRM}" ] ; then
            break
        else
            echo "Password mismatch, please retry"
            echo
        fi
done

echo "Setup firewall"
echo
sudo firewall-cmd --zone=public --permanent --add-port=80/tcp
sudo firewall-cmd --zone=public --permanent --add-port=443/tcp
sudo firewall-cmd --reload

cd /opt
echo "Downloading zeppelin package"
echo
sudo wget https://dlcdn.apache.org/zeppelin/zeppelin-0.10.1/zeppelin-0.10.1-bin-all.tgz
echo "Extracting zeppelin package (please wait)"
echo
sudo tar zxf zeppelin-0.10.1-bin-all.tgz
echo "Configuring zeppelin"
echo
sudo rm -f zeppelin-0.10.1-bin-all.tgz
sudo mv zeppelin-0.10.1-bin-all zeppelin
cd /opt/zeppelin
sudo cp conf/zeppelin-site.xml.template conf/zeppelin-site.xml

sudo sed -i 's/127.0.0.1/0.0.0.0/' conf/zeppelin-site.xml
sudo sed -i 's/8080/80/' conf/zeppelin-site.xml
sudo sed -i 's/8443/443/' conf/zeppelin-site.xml

sudo cp conf/shiro.ini.template conf/shiro.ini
sudo sed -i 's/^#admin = password1, admin$/admin = '${ZEPPELIN_PASSWORD}', admin/' conf/shiro.ini
sudo sed -i '/^user[1-9] = password/s/^/#/g' conf/shiro.ini

echo "Installing MySQL Java connector"
echo
sudo dnf install -y mysql-connector-java mysql-connector-python3
sudo mkdir interpreter/mysql
sudo cp /usr/share/java/mysql-connector-java.jar interpreter/mysql

echo "Enabling and starting zeppelin"
echo
sudo /opt/zeppelin/bin/zeppelin-systemd-service.sh enable
sudo mv /etc/systemd/system/zeppelin.systemd /etc/systemd/system/zeppelin.service
sudo /usr/bin/systemctl daemon-reload

sudo systemctl start zeppelin

echo "Zepping installed and started !"
