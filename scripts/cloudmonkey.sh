#!/bin/bash
##apt-get install python-pip python-dev software-properties-common libffi-dev python-simplejson readline-common python-requests python-pygments python-prettytable python-argcomplete
##pip install cloudmonkey

echo -e "\ninstalling pip\n"
apt-get install python-pip -y >> config.log
easy_install --upgrade requests >> config.log
easy_install --upgrade pygments >> config.log

echo -e "\ninstalling cloudmonkey\n"
pip install cloudmonkey >> config.log
mkdir ~/.cloudmonkey >> config.log
cat <<EOF > ~/.cloudmonkey/config
[core]
profile = local
asyncblock = true
paramcompletion = true
history_file = /root/.cloudmonkey/history
log_file = /root/.cloudmonkey/log
cache_file = /root/.cloudmonkey/cache
 
[ui]
color = true
prompt = >
display = default
 
[local]
url = http://localhost:8080/client/api
username = admin
password = password
apikey =
secretkey =
timeout = 3600
expires = 600
EOF

echo -e "\nglobal Cloudstack config\n"
cloudmonkey sync >> config.log
cloudmonkey update configuration name=host value=172.17.1.1 >> config.log
cloudmonkey update configuration name=management.network.cidr value=172.17.0.0/16 >> config.log

echo -en "\nput scripts to rc.local ."
sed -i 's/exit\ 0/\ /g' /etc/rc.local
echo -n "."
echo "`pwd`/zone_setup.sh >> `pwd`/config.log" >> /etc/rc.local
echo -n "."
echo "exit 0" >> /etc/rc.local
echo " done"

while true
do
  read -p "We have to reboot the system! Do the reboot now? [y/n]: " RBOOT
    case $RBOOT in
      [yY] ) echo "restart System"
              shutdown -r now
              break;;
      [nN] ) echo ""
              echo "nothing done!"
              echo "you have to reboot the host on your own"
              break;;
      * )     echo ""
              echo "Just enter Y or N, please.";;
  esac
done

