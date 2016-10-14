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

/usr/bin/virsh list | /bin/grep s | /usr/bin/awk '{print $3}' 
while test ![[$? = "running"]
do
  /bin/sleep 5
  echo "Trying again..."
  /usr/bin/virsh list | /bin/grep s | /usr/bin/awk '{print $3}'
done
 
SSVMIP=$(/usr/local/bin/cloudmonkey list systemvms systemvmtype=secondarystoragevm | /bin/grep linklocalip | /usr/bin/awk '{print $3}')
 
/usr/bin/ssh $SSVMIP -p 3922 -o StrictHostKeyChecking=no
while test ![[$? = "Permission denied (publickey)."]] 
do
   /bin/sleep 5
   echo "Trying again..."
   /usr/bin/ssh $SSVMIP -p 3922 -o StrictHostKeyChecking=no
done

echo ""
echo -e '\E[31m'"SSVM preparation"
tput sgr0

echo -n "get the interface on which the link-local ip is set: "
IPADDR=$(/usr/bin/ssh -p 3922 -i ~/.ssh/id_rsa.cloud $SSVMIP "ip addr show | /bin/grep $SSVMIP")
LLIF=$(/bin/echo $IPADDR | /usr/bin/awk '{print $7}')
echo -e '\E[32m'" [ $LLIF ]"
tput sgr0

echo -n "delete default route on SSVM"
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

echo "enable forwarding"
echo "1" > /proc/sys/net/ipv4/conf/all/forwarding
echo "net.ipv4.conf.all.forwarding = 1" >> /etc/sysctl.conf
echo -e '\E[32m'"[ OK ]"

tput sgr0
echo ""
echo -e '\E[31m'"\033[1m  all done!\033[0m"
tput sgr0
echo ""
