# Cloudstack buildup - bash script

**OS:** Ubuntu 14.04  
**Cloudstack Version:** 4.5 (latest)  

This script will build up an fully working Cloudstack.  
You will have the Cloudstack Management, Cloudstack Agent, NFS Server, MySQL Server, KVM on one host.  

You need 2 disks:
 - one approx. 5 - 10 GB (root disk)
 - one additional disk for the NFS Storage (primary, secondary, template) approx. 20GB or more

### Howto

you need all scripts from folder "scripts"  

	git clone 

make them executable

	cd cs_buildup/scripts
	chmod +x install.sh prepare.sh check.sh inst_cs_quiet.sh

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
