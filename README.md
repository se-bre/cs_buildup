# Cloudstack buildup - bash script V1.0

### do not use this for production - just for testing (use in a VM!)  

**OS:** Ubuntu 14.04  
**Cloudstack Version:** 4.4 - 4.9 (latest subversion)  
**Virtualisation:** KVM (you need nested virtualisation on your Host - otherwise you will get an error adding the host to Cloudstack)    

This script will build up an fully working Cloudstack.  
You will have the Cloudstack Management, Cloudstack Agent, NFS Server, MySQL Server, KVM on one host.  

You need at least:  
 - 2 Cores  
 - 4GB RAM  
 - 2 disks:
   - one approx. 5 - 10 GB (root disk)
   - one additional disk for the NFS Storage (primary, secondary, template) approx. 30GB or more - no partitions! no FS! - the scripts will do the needfull  

### Howto

you need all scripts from folder "scripts"  

	apt-get install git -y
	git clone https://github.com/se-bre/cs_buildup.git

make them executable

	cd cs_buildup/scripts
	chmod +x install.sh prepare.sh check.sh cs_inst_quiet.sh ssvm.sh cloudmonkey.sh zone_setup.sh

execute just the "install.sh" as root!  

	./install.sh

answer all the questions (if you don´t know - just answer with yes)  

---

configure cloudstack per IP_of_the_System:8080/client  

Username: admin  
Password: password  

---

### more things to say

 - the bigger the host the more you can build up (2core + 4GB is min) ;)  
 - if you want to test the Cloudstack Basic Setup skip the "configure cloudstack advanced zone?" step and configure it on your own (maybe i´ll implement this later)  
 - console proxy not working ... yet

---
