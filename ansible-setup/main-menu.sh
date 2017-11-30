#!/bin/bash

####################################################################################################################
# Assumptions
# 1)  This script is run as sudo on the master node.  
# 2)  The script assumes that slave host names are in a file named slaves.txt and are resolveable
# 3)  ** Please see additional notes and assumptions at the top of ansible-setup.sh

# Purpose
# The purpose of these scripts are to prepare the master and slave nodes to use Ansible for cluster management.
# 
# Ansible is installed on the master, but only Python 2.7 is necessary on the slave nodes, according to
# 	http://docs.ansible.com/ansible/latest/intro_installation.html#basics-what-will-be-installed
#
# A user "ansible" is installed on all nodes with sudo privileges without password prompt.  This and the use of ssh
#	keys to allow passwordless login, allow cluser management from the master node.
####################################################################################################################

# globals
ANSIBLE_UN="ansible"
ANSIBLE_PWD="$ANSIBLE_UN"
SLAVE_FILE="slaves.txt"
SHOW_EXPECT_SCRIPT_MSG=1

####################################################################################################################
# menu for Ansible setup on the master and slave nodes

while [[ $REPLY != 0 ]]; do

	clear

	echo ""
	echo "-----------------------------------"
	echo "           Ansible Setup"
	echo "-----------------------------------"
	echo "1) Master Setup"
	echo "2) Slaves Setup (all)"
	echo "0) Quit / Exit"
	echo "-----------------------------------"
	read -p "Enter Selection [0-2]: "
	echo "-----------------------------------"
	echo ""

	case $REPLY in
		0)	echo ""
			echo "0) Script Terminated."
			echo ""
			clear
			;;

		1) 	echo ""
			echo "1) Master Setup Selected."

			echo "   output to:  `pwd`/files_output/master-setup.log"
			sleep 5

			echo ""
			./ansible-setup.sh $ANSIBLE_UN $ANSIBLE_PWD $REPLY $SLAVE_FILE | tee `pwd`/files_output/master-setup.log
			chown `logname`.`logname` `pwd`/files_output/master-setup.log
			echo ""
			
			read -n 1 -s -r -p "Press any key to continue"
			;;

		2) 	echo ""
			echo "2) Slave Setup Selected."
		
			cat <<- _EOF_

			Note:	
			Managed node (slaves) log files will be stored in 
			`pwd`/files_output upon upon completion of updates.
			_EOF_
			sleep 5

			echo ""
			./ansible-setup.sh $ANSIBLE_UN $ANSIBLE_PWD $REPLY $SLAVE_FILE $SHOW_EXPECT_SCRIPT_MSG
			chown -R `logname`.`logname` `pwd`/files_output/
			echo ""
			
			read -n 1 -s -r -p "Press any key to continue"
			;;

		*) 	echo ""
			echo "** Invalid selection. **" >&2
			echo ""
			read -n 1 -s -r -p "Press any key to continue"
			;;
	esac
done	
####################################################################################################################

