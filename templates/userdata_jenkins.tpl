#!/bin/bash
# switch to root and apend initialAdminPassword
# sudo su -
# mkdir jenkins_temp
# cd jenkins_temp && touch jenkins-secrets.txt

# install Java package
sudo apt-get update -y
sudo apt install openjdk-11-jdk -y

# Install jenkins on ubuntu server on terraform first deploy
sudo apt-get update -y
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install jenkins -y
sudo systemctl start jenkins

# cd jenkins_temp
# cat /var/lib/jenkins/secrets/initialAdminPassword >> jenkins-secrets.txt
