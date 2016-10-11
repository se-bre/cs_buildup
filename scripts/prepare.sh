#!/bin/bash
#
IPADDR=$(/sbin/ip addr show eth0 | /bin/grep inet | /usr/bin/head -n1 | /usr/bin/awk '{print $2}' | /usr/bin/cut -d'/' -f1)
GTW=$(ip r | head -n1 | awk '{print $3}')
TNR=1
#
echo ""
echo ""
echo "creating hostfile and hostname"
echo ""
cat <<EOF > /etc/hosts
127.0.0.1 localhost
127.0.1.1 cs$TNR
172.27.1.$TNR hv01
EOF
echo cs$TNR > /etc/hostname
echo "add Cloudstack Repository"
echo ""
#echo "deb http://cloudstack.apt-get.eu/ubuntu trusty 4.5" > /etc/apt/sources.list.d/cloudstack.list
echo "deb http://cloudstack.apt-get.eu/ubuntu trusty CSVERSION" > /etc/apt/sources.list.d/cloudstack.list
wget -O - http://cloudstack.apt-get.eu/release.asc|apt-key add -
echo ""
echo -e '\E[31m'"\033[1m  please check the config.log file\033[0m"
tput sgr0
echo ""
echo "doing update ... "
echo ""
echo -e '\E[31m'"\033[1m  please check the config.log file\033[0m"
tput sgr0
apt-get update >> config.log 2>&1
echo ""
echo "if the update of the repositorys run well we can proceed"
while true
do
read -p "can we continue? [y/n]: " ANTWORT
  case $ANTWORT in
    [yY]* ) echo "OK - lets go ..."
            break;;
    [nN]* ) echo "nothing done!"
            exit;;
    * )     echo ""
            echo "Dude, just enter Y or N, please.";;
  esac
done
echo "doing upgrade ... this could take a looong time"
apt-get upgrade -y >> config.log 2>&1
echo "installing NTP"
echo ""
echo "" >> config.log
echo "installing NTP" >> config.log
echo "" >> config.log
apt-get install ntp -y >> config.log 2>&1
echo "installing MySQL Server"
echo ""
debconf-set-selections <<< 'mysql-server mysql-server/root_password password password'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password password'
echo "" >> config.log
echo "installing MySQL Server" >> config.log
echo "" >> config.log
apt-get install mysql-server -y >> config.log 2>&1
echo "configuring MySQL"
echo ""
cat <<EOF > /etc/mysql/conf.d/cloudstack.cnf
[mysqld]
innodb_rollback_on_timeout=1
innodb_lock_wait_timeout=600
max_connections=350
log-bin=mysql-bin
binlog-format = 'ROW'
EOF
echo "Mysql restart"
service mysql restart
echo ""
echo "configuring sudo"
echo 'Defaults:cloud !requiretty' > /etc/sudoers.d/cloudstack-tty
chmod 440 /etc/sudoers.d/cloudstack-tty
echo ""
echo "configuring FS"
echo ""
echo "step 1 - creating mountpoints"
mkdir -p /mnt/primary
mkdir -p /mnt/secondary
mkdir -p /mnt/stor-loc
echo "step 2 - create partitions"
parted /dev/vdb mktable msdos >> config.log 2>&1
parted /dev/vdb mkpart primary 1049kB 20% >> config.log 2>&1
parted /dev/vdb mkpart primary 21% 60% >> config.log 2>&1
parted /dev/vdb mkpart primary 61% 100% >> config.log 2>&1
echo "step 3 - create FS"
mkfs.ext4 -m0 -L stor-loc /dev/vdb1 >> config.log 2>&1
mkfs.ext4 -m0 -L primary /dev/vdb2 >> config.log 2>&1
mkfs.ext4 -m0 -L secondary /dev/vdb3 >> config.log 2>&1
echo "step 4 - add stuff to fstab"
cat <<EOF >> /etc/fstab
/dev/vdb1 /mnt/stor-loc ext4 defaults,noatime,nodiratime 0 0
/dev/vdb2 /mnt/primary ext4 defaults,noatime,nodiratime 0 0
/dev/vdb3 /mnt/secondary ext4 defaults,noatime,nodiratime 0 0
EOF
echo "step 5 - mount it"
mount -a
echo "step 6 - check it!"
echo ""
mount | grep vdb
echo ""
echo "installing NFS Server"
echo "" >> config.log
echo "installing NFS Server" >> config.log
echo "" >> config.log
apt-get install nfs-kernel-server -y >> config.log 2>&1
cat <<EOF >> /etc/exports
/mnt/primary  *(rw,async,no_root_squash,no_subtree_check)
/mnt/secondary  *(rw,async,no_root_squash,no_subtree_check)
EOF
exportfs -ra
service nfs-kernel-server restart >> config.log 2>&1
echo ""
echo "check it!"
echo ""
showmount -e 127.0.0.1
echo ""
echo "install libvirt"
echo "" >> config.log
echo "install libvirt" >> config.log
echo "" >> config.log
apt-get install libvirt-bin -y >> config.log 2>&1
echo ""
echo "configuring libvirtd"
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
echo ""
echo "configuring apparmor"
ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmor.d/disable/
ln -s /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper /etc/apparmor.d/disable/
apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd
apparmor_parser -R /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper
echo ""
echo "network config"
echo "" >> config.log
echo "network config" >> config.log
echo "" >> config.log
apt-get install ifenslave -y >> config.log 2>&1
cat <<EOF > /etc/network/interfaces
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet static
        address $IPADDR
        netmask 255.255.0.0
        gateway $GTW
        dns-nameservers 8.8.8.8

EOF
cat <<EOF >> /etc/network/interfaces
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
iface public inet manual
        bridge_ports eth0.100
        bridge_fd 5
        bridge_stp yes
        bridge_maxwait 1

auto eth0.103
iface eth0.103 inet manual
        vlan-raw-device eth0

auto storage
iface storage inet manual
        bridge_ports eth0.103
        bridge_fd 5
        bridge_stp yes

auto storage-hv
iface storage-hv inet static
        address 172.18.1.$TNR
        netmask 255.255.0.0
        bridge_ports eth0.103
        bridge_fd 5
        bridge_stp yes

auto eth0.102
iface eth0.102 inet manual
        vlan-raw-device eth0

auto mgmt
iface mgmt inet manual
        bridge_ports eth0.102
        bridge_fd 5
        bridge_stp yes

auto mgmt-hv
iface mgmt-hv inet static
        address 172.17.1.$TNR
	netmask 255.255.0.0
        bridge_ports eth0.102
        bridge_fd 5
        bridge_stp yes
EOF
echo ""
echo "host is prepared for CloudStack installation!"
echo ""
