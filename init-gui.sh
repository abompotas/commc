#!/bin/bash

cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $cwd

#Install X-windows GUI, Chromium browser and TigerVNC viewer
apt update && apt dist-upgrade
apt -y install xfce4 chromium lightdm tigervnc-viewer
apt purge --autoremove -y light-locker

#Add new user without root access
adduser imslab --gecos "IMS Lab,,," --disabled-password
echo "imslab:imslab" | chpasswd

#Create lightdm configuration for enabling autologin
cp ./conf/gui/lightdm.conf /etc/lightdm/lightdm.conf
chmod 644 /etc/lightdm/lightdm.conf

#Create config folder with custom options
mkdir /home/imslab/.config
cp -r ./xfce4 /home/imslab/.config/xfce4
chown -R imslab:imslab /home/imslab/.config

#Create TigerVNC viewer configuration file for the default VM
cp ./conf/gui/default.tig /home/imslab/default.tig
chown imslab:imslab /home/imslab/default.tig

#Copy the run script for the TigerVNC
cp ./conf/gui/runvnc.py /home/imslab/runvnc.py
chmod 644 /home/imslab/runvnc.py
chown imslab:imslab /home/imslab/runvnc.py

#Create TigerVNC launcher for the default VM
mkdir /home/imslab/Desktop
chown imslab:imslab /home/imslab/Desktop
cp ./conf/gui/StartOS.desktop /home/imslab/Desktop/StartOS.desktop
#Mark the launcher as executable
chmod 755 /home/imslab/Desktop/StartOS.desktop
#Set the new user as the owner of the launcher
chown imslab:imslab /home/imslab/Desktop/StartOS.desktop