#!/bin/bash
#
echo "search for script folder..."
FINDSCR=$(/usr/bin/find / -name cs_buildup)
 
echo "change to script folder ..."
cd $FINDSCR/scripts/
 
echo "remove rc.local entry to start this script"
/bin/sed -i '/ssvm.sh/d' /etc/rc.local
 
echo "wait 60 seconds for advanced zone configuration..."
/bin/sleep 60

echo "wait for ssvm bootup"

VMUP=$(/usr/bin/virsh list | /bin/grep s | /usr/bin/awk '{print $3}')
while [[ "$VMUP" != "running" ]]
do
  /bin/sleep 5
  echo "SSVM not running - trying again..."
  VMUP=$(/usr/bin/virsh list | /bin/grep s | /usr/bin/awk '{print $3}')
done

echo ""
echo "SSVM is now running - try to connect per SSH"
echo ""
SSVMIP=$(/usr/local/bin/cloudmonkey list systemvms systemvmtype=secondarystoragevm | /bin/grep linklocalip | /usr/bin/awk '{print $3}')
 
VM_SSH=$(/usr/bin/ssh $SSVMIP -p 3922 -o StrictHostKeyChecking=no  2>&1 | tail -n1 | awk '{print $2}')
while [[ "$VM_SSH" != "denied" ]]
do
   /bin/sleep 5
   echo "SSH login not possible - trying again..."
   VM_SSH=$(/usr/bin/ssh $SSVMIP -p 3922 -o StrictHostKeyChecking=no  2>&1 | tail -n1 | awk '{print $2}')
done

echo ""
echo -e '\E[31m'"SSVM preparation"
tput sgr0

echo -n "get the interface on which the link-local ip is set: "
IPADDR=$(/usr/bin/ssh -p 3922 -i ~/.ssh/id_rsa.cloud $SSVMIP "ip addr show | /bin/grep $SSVMIP")
LLIF=$(/bin/echo $IPADDR | /usr/bin/awk '{print $7}')
echo -e '\E[32m'" [ $LLIF ]"
tput sgr0

echo -n "delete default route on SSVM: "
ssh -p 3922 -i ~/.ssh/id_rsa.cloud $SSVMIP "ip route del default" > /dev/null 2>&1
echo -e '\E[32m'"[ OK ]"

tput sgr0
echo -n "set the default route on SSVM: "
ssh -p 3922 -i ~/.ssh/id_rsa.cloud $SSVMIP "ip route add default via 172.17.1.1" > /dev/null 2>&1
echo -e '\E[32m'"[ OK ]"
tput sgr0

echo ""
echo -e '\E[31m'"Hypervisor preparation"
tput sgr0

echo "nat all traffic from VM on HV"
echo -n "check if iptables-rule is already there: "
MASKON=$(iptables -L -t nat | /bin/grep -i masquer | /bin/grep anywhere | /usr/bin/awk '{ print $1 }')
if [ "$MASKON" == "MASQUERADE" ]; then
  echo -e '\E[32m'"masquerading already configured"
  else
    echo -en '\E[32m'"configure masquerading: "
    iptables -t nat -A POSTROUTING -j MASQUERADE
    echo -e '\E[32m'"[ OK ]"
fi
tput sgr0
echo ""

echo -n "enable forwarding: "
echo "1" > /proc/sys/net/ipv4/conf/all/forwarding
sed -i '/net.ipv4.conf.all.forwarding/d' /etc/sysctl.conf
echo "net.ipv4.conf.all.forwarding = 1" >> /etc/sysctl.conf
echo -e '\E[32m'"[ OK ]"

tput sgr0
echo ""
echo -e '\E[31m'"\033[1m  all done!\033[0m"
tput sgr0
echo ""
