#!/bin/bash
#
IPADDR=$(/sbin/ip addr show eth0 | /bin/grep inet | /usr/bin/head -n1 | /usr/bin/awk '{print $2}' | /usr/bin/cut -d'/' -f1)
GTW=$(ip r | head -n1 | awk '{print $3}')
TNR=1
#
echo -e "\nchanging root password"|tee config.log
echo root:password | chpasswd

echo -e "\ncreating hostfile and hostname"|tee -a config.log
hostname cs$TNR
domainname local
cat <<EOF > /etc/hosts
127.0.0.1 localhost
127.0.1.1 cs$TNR.local	cs$TNR
$IPADDR	 cs$TNR.local	cs$TNR
172.27.1.$TNR hv01
EOF
echo cs$TNR > /etc/hostname

echo -e "\nadd Cloudstack Repository"|tee -a config.log
echo "deb http://cloudstack.apt-get.eu/ubuntu trusty CSVERSION" > /etc/apt/sources.list.d/cloudstack.list
wget -O - http://cloudstack.apt-get.eu/release.asc|apt-key add -

echo -e "\ndoing update ... "|tee -a config.log

CHKUPD=$(apt-get update | tail -n1 2>&1)
if [ "$CHKUPD" != "Reading package lists..." ]
  then
	echo -e "\nsomething went wrong while adding the GPG key ... retry\n"|tee -a config.log
	wget http://cloudstack.apt-get.eu/release.asc
	apt-key add release.asc
	rm release.asc
	apt-get update >> config.log 2>&1
  else
	echo -e "\nupdate apt: [ OK ]\n"|tee -a config.log
fi
echo -e '\E[31m'"\033[1m  please check the config.log file if update run well\033[0m"
tput sgr0

echo -e "\nif the update of the repositorys run well we can proceed"
while true
do
read -p "can we continue? [y/n]: " ANTWORT
  case $ANTWORT in
    [yY] ) echo -e "\nOK - lets go ...\n"
            break;;
    [nN] ) echo -e "\nnothing done!\n"
            exit;;
    * )    echo -e "\nPlease, just enter Y or N, please.";;
  esac
done

echo -e "\ndoing upgrade ... this could take a looong time"
apt-get upgrade -y >> config.log 2>&1

echo -e "\ninstalling IPcalc\n" |tee -a config.log
apt-get install ipcalc -y >> config.log 2>&1

echo -e "\ninstalling NTP\n"|tee -a config.log
apt-get install ntp -y >> config.log 2>&1

echo -e "\ninstalling MySQL Server\n"|tee -a config.log
debconf-set-selections <<< 'mysql-server mysql-server/root_password password password'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password password'
apt-get install mysql-server -y >> config.log 2>&1

echo -e "\nconfiguring MySQL\n"
cat <<EOF > /etc/mysql/conf.d/cloudstack.cnf
[mysqld]
innodb_rollback_on_timeout=1
innodb_lock_wait_timeout=600
max_connections=350
log-bin=mysql-bin
binlog-format = 'ROW'
EOF

echo -e "\nMysql restart\n"
service mysql restart

echo -e "\nconfiguring sudo\n"
echo 'Defaults:cloud !requiretty' > /etc/sudoers.d/cloudstack-tty
chmod 440 /etc/sudoers.d/cloudstack-tty

echo -e "\nconfiguring FS\n\nstep 1 - creating mountpoints"|tee -a config.log
mkdir -p /mnt/primary
mkdir -p /mnt/secondary
mkdir -p /mnt/stor-loc
echo -e "step 2 - create partitions"|tee -a config.log
parted -s /dev/vdb mktable msdos >> config.log 2>&1
parted /dev/vdb mkpart primary 1049kB 20% >> config.log 2>&1
parted /dev/vdb mkpart primary 21% 60% >> config.log 2>&1
parted /dev/vdb mkpart primary 61% 100% >> config.log 2>&1
echo "step 3 - create FS"|tee -a config.log
mkfs.ext4 -m0 -L stor-loc /dev/vdb1 >> config.log 2>&1
mkfs.ext4 -m0 -L primary /dev/vdb2 >> config.log 2>&1
mkfs.ext4 -m0 -L secondary /dev/vdb3 >> config.log 2>&1
echo "step 4 - add stuff to fstab"|tee -a config.log
cat <<EOF >> /etc/fstab
/dev/vdb1 /mnt/stor-loc ext4 defaults,noatime,nodiratime 0 0
/dev/vdb2 /mnt/primary ext4 defaults,noatime,nodiratime 0 0
/dev/vdb3 /mnt/secondary ext4 defaults,noatime,nodiratime 0 0
EOF
echo "step 5 - mount it"|tee -a config.log
mount -a
echo -e "step 6 - check it!\n"|tee -a config.log
mount | grep vdb |tee -a config.log

echo -e "\ninstalling NFS Server\n"|tee -a config.log
apt-get install nfs-kernel-server -y >> config.log 2>&1
cat <<EOF >> /etc/exports
/mnt/primary  *(rw,async,no_root_squash,no_subtree_check)
/mnt/secondary  *(rw,async,no_root_squash,no_subtree_check)
EOF
exportfs -ra
service nfs-kernel-server restart >> config.log 2>&1
echo -e "\ncheck it!\n"|tee -a config.log
showmount -e 127.0.0.1|tee -a config.log

echo -e "\ninstall libvirt\n"|tee -a config.log
apt-get install libvirt-bin -y >> config.log 2>&1

echo -e "\nconfiguring libvirtd"|tee -a config.log
cat <<EOF >> /etc/libvirt/libvirtd.conf
listen_tls = 0
listen_tcp = 1
tcp_port = "16509"
auth_tcp = "none"
mdns_adv = 0
EOF
cat <<EOF > /etc/default/libvirt-bin
start_libvirtd="yes"
libvirtd_opts="-d -l"
EOF

echo -e "\nconfiguring apparmor"|tee -a config.log
ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmor.d/disable/
ln -s /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper /etc/apparmor.d/disable/
apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd
apparmor_parser -R /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper

echo -e "\nnetwork config\n"
apt-get install ifenslave -y >> config.log 2>&1
GET_PUB_NET()
{
  ip a show dev eth0 | grep inet | head -n1 | awk '{print $2}'
}
NMASK=$(ipcalc GET_PUB_NET | grep -i netmask | awk '{print $2}') 
cat <<EOF > /etc/network/interfaces
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet manual

auto eth0.101
        iface eth0.101 inet manual
        vlan-raw-device eth0

auto guest
iface guest inet manual
        bridge_ports eth0.101
        bridge_fd 5
        bridge_stp yes
        bridge_maxwait 1

auto eth0.100
        iface eth0.100 inet manual
        vlan-raw-device eth0

auto public
iface public inet static
        bridge_ports eth0
        address $IPADDR
        netmask $NMASK
        gateway $GTW
        dns-nameservers 8.8.8.8
        bridge_fd 5
        bridge_stp yes
        bridge_maxwait 1

auto eth0.103
iface eth0.103 inet manual
        vlan-raw-device eth0

auto storage
iface storage inet static
        address 172.18.1.$TNR
        netmask 255.255.0.0
        bridge_ports eth0.103
        bridge_fd 5
        bridge_stp yes

auto eth0.102
iface eth0.102 inet manual
        vlan-raw-device eth0

auto mgmt
iface mgmt inet static
        address 172.17.1.$TNR
	netmask 255.255.0.0
        bridge_ports eth0.102
        bridge_fd 5
        bridge_stp yes
EOF

echo -e "\nprepare SSHD\n"|tee -a config.log
sed -i 's/PermitRootLogin\ without-password/PermitRootLogin\ yes/g' /etc/ssh/sshd_config

echo -e "\nload Kernel modules\n"|tee -a config.log
echo "kvm" >> /etc/modules
echo "kvm-intel" >> /etc/modules

echo -e "\nhost is prepared for CloudStack installation!\n"|tee -a config.log
