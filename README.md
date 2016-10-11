# Cloudstack buildup - bash script

**OS:** Ubuntu 14.04  
**Cloudstack Version:** 4.4 - 4.9 (latest subversion)  

This script will build up an fully working Cloudstack.  
You will have the Cloudstack Management, Cloudstack Agent, NFS Server, MySQL Server, KVM on one host.  

You need 2 disks:
 - one approx. 5 - 10 GB (root disk)
 - one additional disk for the NFS Storage (primary, secondary, template) approx. 30GB or more

### Howto

you need all scripts from folder "scripts"  

	apt-get install git
	git clone https://github.com/se-bre/cs_buildup.git

make them executable

	cd cs_buildup/scripts
	chmod +x install.sh prepare.sh check.sh cs_inst_quiet.sh ssvm.sh

execute just the "install.sh" as root!  

	./install.sh

answer all the questions (if you don´t know - just answer with yes)  

---

reboot the system   

---

configure cloudstack per <IP of the system>:8080/client  

Username: admin  
Password: password  

---
