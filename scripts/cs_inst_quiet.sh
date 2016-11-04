#!/bin/bash
IPADDR=$(/sbin/ip addr show eth0 | /bin/grep inet | /usr/bin/head -n1 | /usr/bin/awk '{print $2}' | /usr/bin/cut -d'/' -f1)
#
echo -e "\n"'\E[31m'"\033[1m  installing Cloudstack!\033[0m""\n"
echo -e "\ninstall Cloudstack\n" >> config.log

apt-get install cloudstack-management -y >> config.log 2>&1

echo -en "\ncheck install: "
CSINST=$(apt-cache policy cloudstack-management | grep Installed | awk '{print $2}')
if [ "$CSINST" == "(none)" ]
  then
	echo -e "cloudstack not installed - retry ...\n" |tee -a config.log 2>&1
	apt-get install cloudstack-management -y >> config.log 2>&1
  else
	echo -e "[ OK ]\n"
fi

echo -e "\nsetup CS Databases\n"|tee -a config.log
cloudstack-setup-databases cloud:password@localhost --deploy-as=root:password -i $IPADDR |tee -a config.log

echo -e "\n\nsetup CS management\n"|tee -a config.log
cloudstack-setup-management |tee -a config.log

echo -e "\nsetup and download system-template KVM:\n"|tee -a config.log
cp -rp /usr/share/cloudstack-common/scripts/storage/secondary/* /mnt/stor-loc/
mount -o bind /mnt/stor-loc /usr/share/cloudstack-common/scripts/storage/secondary
/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/secondary -u http://cloudstack.apt-get.eu/systemvm/PATHVERSION/systemvm64template-TMPLVERSION-kvm.qcow2.bz2 -h kvm -F |tee -a config.log
cat <<EOF >> /etc/fstab
/mnt/stor-loc /usr/share/cloudstack-common/scripts/storage/secondary bind bind 0 0
EOF

echo -e "\ninstall Cloudstack Agent\n"|tee -a config.log
apt-get install cloudstack-agent -y >> config.log 2>&1
