#!/bin/bash
IPADDR=$(/sbin/ip addr show eth0 | /bin/grep inet | /usr/bin/head -n1 | /usr/bin/awk '{print $2}' | /usr/bin/cut -d'/' -f1)
#
echo ""
echo -e '\E[31m'"\033[1m  installing Cloudstack!\033[0m"
echo ""
echo "" >> config.log
echo "install Cloudstack" >> config.log
echo "" >> config.log
apt-get install cloudstack-management -y >> config.log 2>&1
echo "setup CS Databases"
echo ""
echo "" >> config.log
echo "setup CS Databases" >> config.log
echo "" >> config.log
cloudstack-setup-databases cloud:password@localhost --deploy-as=root:password -i $IPADDR
echo ""
echo ""
echo "setup CS management"
echo ""
echo "" >> config.log
echo "setup CS management" >> config.log
echo "" >> config.log
cloudstack-setup-management
echo ""
echo "setup and download system-template KVM:"
echo ""
cp -rp /usr/share/cloudstack-common/scripts/storage/secondary/* /mnt/stor-loc/
mount -o bind /mnt/stor-loc /usr/share/cloudstack-common/scripts/storage/secondary
#/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/secondary -u http://cloudstack.apt-get.eu/systemvm/4.5/systemvm64template-4.5-kvm.qcow2.bz2 -h kvm -F
/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/secondary -u http://cloudstack.apt-get.eu/systemvm/CSVERSION/systemvm64template-CSVERSION-kvm.qcow2.bz2 -h kvm -F
cat <<EOF >> /etc/fstab
/mnt/stor-loc /usr/share/cloudstack-common/scripts/storage/secondary bind bind 0 0
EOF
echo "install Cloudstack Agent"
echo "" >> config.log
echo "install Cloudstack Agent" >> config.log
echo "" >> config.log
apt-get install cloudstack-agent -y >> config.log 2>&1
