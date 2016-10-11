#!/bin/bash
echo ""
echo -e '\E[31m'"\033[1m checking installations \033[0m"
echo ""
tput sgr0
echo -en "NTP installation: "
NTPIN=$(dpkg -s ntp 2>&1 | grep install | head -n1)
if [ "$NTPIN" = "Status: install ok installed" ]; then
        echo -e '\E[32m'"[ OK ]"
        tput sgr0
        echo -en "NTP is running: "
        NTPRUN=$(service ntp status | awk '{ print $5 }')
        if [ "$NTPRUN" = "running" ]; then
          echo -e '\E[32m'"[ OK ]"
        else
          echo -e '\E[31m'"\033[1mNTP is not running!\033[0m"
        fi
else
        echo -e '\E[31m'"\033[1mcheck the installation of NTP!\033[0m"
fi
tput sgr0
echo ""
echo -en "MySQL installation: "
SQLIN=$(dpkg -s mysql-server 2>&1 | grep install | head -n1)
if [ "$SQLIN" = "Status: install ok installed" ]; then
        echo -e '\E[32m'"[ OK ]"
        tput sgr0
        echo -en "MySQL is running: "
        SQLRUN=$(service mysql status | awk '{print $2}')
        if [ "$SQLRUN" = "start/running," ]; then
          echo -e '\E[32m'"[ OK ]"
        else
          echo -e '\E[31m'"\033[1mMySQL Server is not running!\033[0m"
        fi
else
        echo -e '\E[31m'"\033[1mcheck the installation of MySQL Server!\033[0m"
fi
tput sgr0
echo ""
echo -e "check if secondary disk are mounted:"
echo ""
echo -en "temporary template storage: "
STORLOC=$(mount | grep stor-loc | grep vdb | cut -d"/" -f2)
if [ "$STORLOC" == "dev" ];then
        STORLOCDF=$(df -h /mnt/stor-loc/ | grep vdb | awk '{ print $2 }')
        echo -en '\E[32m'"[ OK ]"
        tput sgr0
        echo -e " - Size: $STORLOCDF"
else echo -e '\E[31m'"not mounted!"
        tput sgr0
fi
echo -en "primary storage: "
STORPRIM=$(mount | grep primary | grep vdb | cut -d"/" -f2)
if [ "$STORPRIM" == "dev" ];then
        STORPRIMDF=$(df -h /mnt/primary/ | grep vdb | awk '{ print $2 }')
        echo -en '\E[32m'"[ OK ]"
        tput sgr0
        echo -e " - Size: $STORPRIMDF"
else echo -e '\E[31m'"not mounted!"
        tput sgr0
fi
echo -en "secondary storage: "
STORSEC=$(mount | grep secondary | grep vdb | cut -d"/" -f2)
if [ "$STORSEC" == "dev" ];then
        STORSECDF=$(df -h /mnt/secondary/ | grep vdb | awk '{ print $2 }')
        echo -en '\E[32m'"[ OK ]"
        tput sgr0
        echo -e " - Size: $STORSECDF"
else echo -e '\E[31m'"not mounted!"
        tput sgr0
fi
echo ""
echo -en "NFS installation: "
NFSIN=$(dpkg -s nfs-kernel-server 2>&1 | grep install | head -n1)
if [ "$NFSIN" = "Status: install ok installed" ]; then
        echo -e '\E[32m'"[ OK ]"
        tput sgr0
        echo -en "NFS-Server is running: "
        NFSRUN=$(service nfs-kernel-server status)
        if [ "$NFSRUN" = "nfsd running" ]; then
          echo -e '\E[32m'"[ OK ]"
          tput sgr0
          echo -e "check exports:"
          echo -en "primary storage: "
          NFSPRIM=$(showmount -e 127.0.0.1 | grep primary | awk '{ print $1 }')
          if [ "$NFSPRIM" == "/mnt/primary" ];then
            NFSPRIMEX=$(showmount -e 127.0.0.1 | grep primary | awk '{ print $2 }')
            echo -en '\E[32m'"[ OK ]"
            tput sgr0
            echo -en " - exported to: "
            echo -e '\E[32m'"$NFSPRIMEX"
            tput sgr0
          else echo -e '\E[31m'"not exported!"
            tput sgr0
          fi
          echo -en "secondary storage: "
          NFSSEC=$(showmount -e 127.0.0.1 | grep secondary | awk '{ print $1 }')
          if [ "$NFSSEC" == "/mnt/secondary" ];then
            NFSSECEX=$(showmount -e 127.0.0.1 | grep secondary | awk '{ print $2 }')
            echo -en '\E[32m'"[ OK ]"
            tput sgr0
            echo -en " - exported to: "
            echo -e '\E[32m'"$NFSSECEX"
            tput sgr0
          else echo -e '\E[31m'"not exported!"
            tput sgr0
          fi
        else
          echo -e '\E[31m'"\033[1mNFS Server is not running!\033[0m"
        fi
else
        echo -e '\E[31m'"\033[1mcheck the installation of NFS Server!\033[0m"
fi
echo ""
tput sgr0
echo -en "libvirt installation: "
KVMIN=$(dpkg -s libvirt-bin 2>&1 | grep install | head -n1)
if [ "$KVMIN" = "Status: install ok installed" ]; then
        echo -e '\E[32m'"[ OK ]"
        tput sgr0
        echo -en "libvirt is running: "
        KVMRUN=$(service libvirt-bin status | awk '{ print $2 }')
        if [ "$KVMRUN" = "start/running," ]; then
          echo -e '\E[32m'"[ OK ]"
        else
          echo -e '\E[31m'"\033[1mlibvirt is not running!\033[0m"
        fi
else
        echo -e '\E[31m'"\033[1mcheck the installation of libvirt!\033[0m"
fi
tput sgr0
echo ""
echo -en "cloudstack-management installation: "
CSMIN=$(dpkg -s cloudstack-management 2>&1 | grep install | head -n1)
if [ "$CSMIN" = "Status: install ok installed" ]; then
        echo -e '\E[32m'"[ OK ]"
        tput sgr0
        echo -en "cloudstack-management is running: "
        CSMRUN=$(service cloudstack-management status | awk '{ print $7 }')
        if [ "$CSMRUN" = "running" ]; then
          echo -e '\E[32m'"[ OK ]"
        else
          echo -e '\E[31m'"\033[1mcloudstack-management is not running!\033[0m"
        fi
else
        echo -e '\E[31m'"\033[1mcheck the installation of cloudstack-management\033[0m"
fi
tput sgr0
echo ""
echo -en "cloudstack-agent installation: "
CSAIN=$(dpkg -s cloudstack-agent 2>&1 | grep install | head -n1)
if [ "$CSAIN" = "Status: install ok installed" ]; then
        echo -e '\E[32m'"[ OK ]"
        tput sgr0
        echo -en "cloudstack-agent is running: "
        CSARUN=$(service cloudstack-agent status | awk '{ print $4 }')
        if [ "$CSARUN" = "running" ]; then
          echo -e '\E[32m'"[ OK ]"
        else
          echo -e '\E[31m'"\033[1mcloudstack-agent is not running! - did you already set up a zone?\033[0m"
        fi
else
        echo -e '\E[31m'"\033[1mcheck the installation of cloudstack-agent\033[0m"
fi
tput sgr0
echo ""
echo -en "system template installation: "
STIN=$(find /mnt/secondary/ -name *.qcow2 2>&1 | cut -d"/" -f4 | head -n1)
if [ "$STIN" = "template" ]; then
        echo -e '\E[32m'"system template installation seems to be [ OK ]"
        tput sgr0
else
        echo -e '\E[31m'"\033[1mcheck the installation of system template for CloudStack\033[0m"
fi
tput sgr0
echo ""
