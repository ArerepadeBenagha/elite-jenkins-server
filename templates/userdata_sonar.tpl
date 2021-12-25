#! /bin/bash

sudo apt-get install openjdk-11-jdk -y
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
sudo apt install postgresql postgresql-contrib -y
sudo systemctl enable postgresql
sudo systemctl start postgresql

/////sonar
sudo apt-get install zip -y
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.2.4.50792.zip
sudo unzip sonarqube-9.2.4.50792.zip
sudo mv sonarqube-9.2.4.50792 /opt/sonarqube
sudo groupadd sonar
sudo useradd -d /opt/sonarqube -g sonar sonar
sudo chown sonar:sonar /opt/sonarqube -R