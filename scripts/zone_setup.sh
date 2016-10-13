#!/bin/bash

sleep 180
sed -i '/zone_setup.sh/d' /etc/rc.local
 
cli=cloudmonkey
dns_ext=8.8.8.8
dns_int=$(ip r | head -n1 | awk '{print $3}')
gw=172.17.1.1
nmask=255.255.0.0
hpvr=KVM
pod_start=172.17.3.10
pod_end=172.17.3.100
pub_gw=$(ip r | head -n1 | awk '{print $3}')
get_pub_ip=$(ip a show dev eth0 | grep inet | head -n1 | awk '{print $2}')
pub_nmask=$(ipcalc $get_pub_ip | grep -i netmask | awk '{print $2}')
pub_start=$(ip a show dev eth0 | grep inet | head -n1 | awk '{print $2}' | cut -d"." -f1,2,3).240
pub_end=$(ip a show dev eth0 | grep inet | head -n1 | awk '{print $2}' | cut -d"." -f1,2,3).250
#vlan_start=10.147.28.235
#vlan_end=10.147.28.254
 
#Put space separated host ips in following
host_ips=172.17.1.1
host_user=root
host_passwd=password
sec_storage=nfs://172.18.1.1/mnt/secondary
prm_storage=nfs://172.18.1.1/mnt/primary
 
zone_id=`$cli create zone dns1=$dns_ext internaldns1=$dns_int name=MyZone networktype=Advanced isolationmethods=VLAN | grep ^id\ = | awk '{print $3}'`
echo "Created zone" $zone_id
 
phy_id=`$cli create physicalnetwork name=phy-network zoneid=$zone_id broadcastdomainrange=ZONE isolationmethods=VLAN vlan=10-20 | grep ^id\ = | awk '{print $3}'`
echo "Created physical network" $phy_id
$cli add traffictype traffictype=Guest physicalnetworkid=$phy_id kvmnetworklabel=guest
echo "Added guest traffic"
$cli add traffictype traffictype=Management physicalnetworkid=$phy_id kvmnetworklabel=mgmt
echo "Added mgmt traffic"
$cli add traffictype traffictype=Public physicalnetworkid=$phy_id kvmnetworklabel=public
echo "Added public traffic"
$cli add traffictype traffictype=Storage physicalnetworkid=$phy_id kvmnetworklabel=storage
echo "Added storage traffic"
$cli update physicalnetwork state=Enabled id=$phy_id
echo "Enabled physicalnetwork"
 
nsp_id=`$cli list networkserviceproviders name=VirtualRouter physicalnetworkid=$phy_id | grep ^id\ = | awk '{print $3}'`
vre_id=`$cli list virtualrouterelements nspid=$nsp_id | grep ^id\ = | awk '{print $3}'`
$cli api configureVirtualRouterElement enabled=true id=$vre_id
$cli update networkserviceprovider state=Enabled id=$nsp_id
echo "Enabled virtual router element and network service provider"
 
nsp_sg_id=`$cli list networkserviceproviders name=SecurityGroupProvider physicalnetworkid=$phy_id | grep ^id\ = | awk '{print $3}'`
$cli update networkserviceprovider state=Disabled id=$nsp_sg_id
echo "Disabled security group provider"

nsp_vpcvr_id=`$cli list networkserviceproviders name=VpcVirtualRouter physicalnetworkid=$phy_id | grep ^id\ = | awk '{print $3}'`
$cli update networkserviceprovider state=Enabled id=$nsp_vpcvr_id
echo "Enabled VPC Virtual Router"
 
nsp_bmpxep_id=`$cli list networkserviceproviders name=BaremetalPxeProvider physicalnetworkid=$phy_id | grep ^id\ = | awk '{print $3}'`
$cli update networkserviceprovider state=Enabled id=$nsp_bmpxep_id
echo "Enabled BaremetalPxeProvider"
 
nsp_ilbvm_id=`$cli list networkserviceproviders name=InternalLbVm physicalnetworkid=$phy_id | grep ^id\ = | awk '{print $3}'`
$cli update networkserviceprovider state=Enabled id=$nsp_ilbvm_id
echo "Enabled InternalLbVm"
 
#netoff_id=`$cli list networkofferings name=DefaultSharedNetworkOfferingWithSGService | grep ^id\ = | awk '{print $3}'`
#net_id=`$cli create network zoneid=$zone_id name=guestNetworkForBasicZone displaytext=guestNetworkForBasicZone networkofferingid=$netoff_id | grep ^id\ = | awk '{print $3}'`
#echo "Created network $net_id for zone" $zone_id

domain_id=`$cli list domains name=root | grep ^id\ = | awk '{print $3}'`
$cli create vlaniprange domainid=$domain_id forvirtualnetwork=True gateway=$pub_gw  netmask=$pub_nmask startip=$pub_start  endip=$pub_end
echo "Created public ip Range"
 
pod_id=`$cli create pod name=MyPod zoneid=$zone_id gateway=$gw netmask=$nmask startip=$pod_start endip=$pod_end | grep ^id\ = | awk '{print $3}'`
echo "Created pod"

$cli create storagenetworkiprange podid=$pod_id gateway=172.18.1.1 netmask=255.255.0.0 startip=172.18.3.10 endip=172.18.3.100

 
#$cli create vlaniprange podid=$pod_id networkid=$net_id gateway=$gw netmask=$nmask startip=$vlan_start endip=$vlan_end forvirtualnetwork=false
#echo "Created IP ranges for instances"
 
cluster_id=`$cli add cluster zoneid=$zone_id hypervisor=$hpvr clustertype=CloudManaged podid=$pod_id clustername=MyCluster | grep ^id\ = | awk '{print $3}'`
echo "Created cluster" $cluster_id
 
#Put loop here if more than one
for host_ip in $host_ips;
do
  $cli add host zoneid=$zone_id podid=$pod_id clusterid=$cluster_id hypervisor=$hpvr username=$host_user password=$host_passwd url=http://$host_ip;
  echo "Added host" $host_ip;
done;
 
$cli create storagepool zoneid=$zone_id podid=$pod_id clusterid=$cluster_id name=MyNFSPrimary url=$prm_storage scope=CLUSTER name=primNFS01
echo "Added primary storage"
 
$cli add secondarystorage zoneid=$zone_id url=$sec_storage name=secNFS01
echo "Added secondary storage"
 
$cli update zone allocationstate=Enabled id=$zone_id
echo "Advanced zone deloyment completed!"
