#!/bin/bash
#
echo "wait for ssvm bootup"

/usr/bin/virsh list | /bin/grep s | /usr/bin/awk '{print $3}' 
while test ![[$? != "running"]
do
  /bin/sleep 5
  echo "Trying again..."
  /usr/bin/virsh list | /bin/grep s | /usr/bin/awk '{print $3}'
done
 
SSVMIP=$(/usr/local/bin/cloudmonkey list systemvms systemvmtype=secondarystoragevm | /bin/grep linklocalip | /usr/bin/awk '{print $3}')
 
/usr/bin/ssh $SSVMIP -p 3922
while test ![[$? = "Permission denied (publickey)."]] 
do
   /bin/sleep 5
   echo "Trying again..."
   /usr/bin/ssh $SSVMIP -p 3922
done

#echo ""
#echo "get the link-local ip of the ssvm from Cloudstack UI!"
#echo -en "enter the link-local IP of the secondary-storage VM: "
#echo -en '\E[32m'
#read SSVMIP
#tput sgr0
echo ""
echo -e '\E[31m'"SSVM preparation"
tput sgr0
echo -n "get the interface on which the link-local ip is set: "
IPADDR=$(/usr/bin/ssh -p 3922 -i ~/.ssh/id_rsa.cloud $SSVMIP "ip addr show | /bin/grep $SSVMIP")
LLIF=$(/bin/echo $IPADDR | /usr/bin/awk '{print $7}')
echo -e '\E[32m'" [ $LLIF ]"
tput sgr0
echo -n "set all other interfaces down: "
ALLIF=$(/usr/bin/ssh -p 3922 -i ~/.ssh/id_rsa.cloud $SSVMIP "ip addr show | grep eth |grep -v $LLIF | grep -v link | grep -v inet | cut -d: -f2")
for i in $(/bin/echo $ALLIF); do /usr/bin/ssh -p 3922 -i ~/.ssh/id_rsa.cloud $SSVMIP "ip link set $i down";done
echo -e '\E[32m'"[ OK ]"
tput sgr0
echo -n "get the link-local ip of the hypervisor: "
OWNLL=$(ip addr show | /bin/grep 169.254 | /usr/bin/awk '{print $2}' | cut -d"/" -f1)
echo -e '\E[32m'" [ $OWNLL ]"
tput sgr0
echo -n "set the default route on SSVM: "
ssh -p 3922 -i ~/.ssh/id_rsa.cloud $SSVMIP "ip route add default via $OWNLL" > /dev/null 2>&1
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
echo -e '\E[31m'"\033[1m  all done!\033[0m"
tput sgr0
echo ""
