#! /bin/bash
//set linux kernel
sudo sysctl -w vm.max_map_count=262144
ulimit -n 65536
ulimit -u 4096

//update & upgrade
sudo apt-get update -y 
sudo apt-get upgrade -y

//install unzip
sudo apt-get install wget unzip -y

//install Java
sudo apt-get install openjdk-11-jdk -y
sudo apt-get install openjdk-11-jre -y
sudo update-alternatives --config java

//Install postgresql
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
sudo apt-get -y install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql