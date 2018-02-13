#!/bin/bash
# Purpose:
# To install user ansible on node and allow local passwordless ssh login.


####################################################################################################################
# globals
PROG_NAME="$0"
PROG_BASE_NAME=$(basename $0)

ANSIBLE_UN="ansible"
ANSIBLE_PWD="$ANSIBLE_UN"
HADOOP_UN="hadoop"
HADOOP_PWD="$HADOOP_UN"

PROG_USER=`logname`
PROG_USER_PWD="not set"
HOST_IP=`hostname -I`
HOST_NAME=`hostname`

####################################################################################################################
# Begin General Functions
####################################################################################################################
func_print_script_info(){

	echo ""
	echo "###############################################"
	echo "Script name:	$PROG_BASE_NAME"
	echo "Script user:	$PROG_USER"
	echo "Running as:	$USER"
	echo "Running on:	`hostname -f`"
	echo "IP-Address:	$HOST_IP"	
	echo "###############################################"
	echo ""
}
#===================================================================================================================
func_update_system(){

	# Update, upgrade, autoremove

	echo ""
	echo "apt-get update"
	echo ""
	apt-get update

	echo ""
	echo "apt-get upgrade -y"
	echo ""
	apt-get upgrade -y

	echo ""
	echo "apt-get autoremove -y"
	echo ""
	apt-get autoremove -y
}
#===================================================================================================================
func_create_ansible_user(){

	# Create a user to run Ansible playbooks

	echo ""
	echo "adduser --quiet --disabled-password --shell /bin/bash --home /home/$ANSIBLE_UN --gecos 'User to run Ansible Playbooks' $ANSIBLE_UN"
	adduser --quiet --disabled-password --shell /bin/bash --home "/home/$ANSIBLE_UN" --gecos "User to run Ansible Playbooks" "$ANSIBLE_UN"

	echo ""
	echo "$ANSIBLE_UN:$ANSIBLE_PWD | chpasswd"
	echo "$ANSIBLE_UN:$ANSIBLE_PWD" | chpasswd
}
#===================================================================================================================
func_set_ansible_sudoer_privileges(){

	# In order to run Ansible playbooks unencumbered, the user ansible will need to have the following:
	#    a)  sudoer privileges without password prompt
	#    b)  not be a member of the sudoers group 
	#    This will require that a file be added to /ect/sudoers.d, as per the directions in /etc/sudoers.d/README
	#    Note:	Being a member of sudoers and updating sudoers via visudo caused errors during testing.
	#		The errors disappeared once the user ansible was removed from the sudoers group.

	# the following is from the /etc/sudoers file and is used as a guide for use on user ansible.
	# User privilege specification
	#root    ALL=(ALL:ALL) ALL

	echo ""
	echo "$ANSIBLE_UN ALL=(ALL:ALL) NOPASSWD: ALL > /etc/sudoers.d/$ANSIBLE_UN"
	echo "$ANSIBLE_UN ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/"$ANSIBLE_UN"

	echo ""
	echo "chmod 0440 /etc/sudoers.d/$ANSIBLE_UN"
	chmod 0440 /etc/sudoers.d/"$ANSIBLE_UN"

	# Note:	Below are the contents of the current (2017-09-19) /etc/sudoers.d/README file.

	# As of Debian version 1.7.2p1-1, the default /etc/sudoers file created on
	# installation of the package now includes the directive:
	# 
	# 	#includedir /etc/sudoers.d
	# 
	# This will cause sudo to read and parse any files in the /etc/sudoers.d 
	# directory that do not end in '~' or contain a '.' character.
	# 
	# Note that there must be at least one file in the sudoers.d directory (this
	# one will do), and all files in this directory should be mode 0440.
	# 
	# Note also, that because sudoers contents can vary widely, no attempt is 
	# made to add this directive to existing sudoers files on upgrade.  Feel free
	# to add the above directive to the end of your /etc/sudoers file to enable 
	# this functionality for existing installations if you wish!
	#
	# Finally, please note that using the visudo command is the recommended way
	# to update sudoers content, since it protects against many failure modes.
	# See the man page for visudo for more information.
}
#===================================================================================================================
func_create_set_ssh_keys_localhost(){

	local SSH_DIR=/home/$ANSIBLE_UN/.ssh
	echo ""
	echo "mkdir -p $SSH_DIR"
	mkdir -p $SSH_DIR

	echo ""
	echo "chmod 700 $SSH_DIR"
	chmod 700 $SSH_DIR
	
	echo ""
	local ID_RSA=$SSH_DIR/id_rsa
	echo "ssh-keygen -v -b 2048 -t rsa -f $ID_RSA -N ''"
	ssh-keygen -v -b 2048 -t rsa -f $ID_RSA -N ''

	# the key will be specific to root@localhost-name, change to ansible@localhost-name
	echo ""
	echo "sed -i s/$USER/$ANSIBLE_UN/g $ID_RSA.pub"
	sed -i "s/$USER/$ANSIBLE_UN/g" "$ID_RSA".pub

	echo ""
	echo "chmod 600 $ID_RSA"
	chmod 600 $ID_RSA

	# copy id_rsa.pub to authorized_keys
	echo ""
	AUTH_KEYS=$SSH_DIR/authorized_keys
	echo "cp $SSH_DIR/id_rsa.pub $AUTH_KEYS"
	cp "$SSH_DIR/id_rsa.pub" "$AUTH_KEYS"

	echo ""
	echo "chmod 640 $AUTH_KEYS"
	chmod 640 $AUTH_KEYS

	# setup known_hosts file to facilitate ssh login localhost
	local KNOWN_HOSTS=$SSH_DIR/known_hosts
	echo ""
	# this sets up ssh passwordless by ip address
	echo "ssh-keyscan $HOST_IP >> $KNOWN_HOSTS"
	ssh-keyscan $HOST_IP >> $KNOWN_HOSTS

	# this sets up ssh passwordless by host name
	echo "ssh-keyscan $HOST_NAME >> $KNOWN_HOSTS"
	ssh-keyscan $HOST_NAME >> $KNOWN_HOSTS

	# user ansible owns everything in .ssh
	echo ""
	echo "chown -R $ANSIBLE_UN:$ANSIBLE_UN $SSH_DIR"
	chown -R $ANSIBLE_UN:$ANSIBLE_UN $SSH_DIR
}
####################################################################################################################
# End General Functions
####################################################################################################################


####################################################################################################################
# Begin Functions to setup Slaves
####################################################################################################################
func_install_python(){

	echo ""
	echo "apt-get install -y python"
	echo ""
	apt-get install -y python
}
#===================================================================================================================
func_get_master_rsa_pub(){

	# set the public key for the user on the master node
	echo ""
	echo "cat `pwd`/id_rsa.pub >> /home/$ANSIBLE_UN/.ssh/authorized_keys"
	cat `pwd`/id_rsa.pub >> /home/"$ANSIBLE_UN"/.ssh/authorized_keys

	# and remove the master's public key
	echo ""
	echo "rm -f `pwd`/id_rsa.pub"
	rm -f `pwd`/id_rsa.pub
}
#===================================================================================================================
func_slave_script_delete_yourself(){
	
	# this is to be run on the slave
	echo ""
	echo "rm -f `pwd`/$PROG_BASE_NAME"
	rm -f `pwd`/$PROG_BASE_NAME
}
####################################################################################################################
# End Functions to setup Slaves
####################################################################################################################


####################################################################################################################
# Begin Sequences of Functions to setup Cluster
####################################################################################################################
func_setup_master(){

	# functions to prep master
	func_create_slaves_file
	func_print_script_info
	func_update_system
	func_install_ansible_software
	func_create_ansible_user
	func_set_ansible_sudoer_privileges
	func_create_set_ssh_keys_localhost
}
#===================================================================================================================
func_prep_master_to_setup_slaves(){

	# preparing the master to setup the slaves

	func_install_sshpass
	func_install_expect

	# for each slave, copy over script, execute script using expect script, remove script
	func_setup_slaves

	# collect all the host keys from slave nodes
	func_ssh-keyscan_ansible

	# unprepare master for slave update
	func_remove_sshpass

	# i'm not sure this needs to be removed, since it will be a fresh install
	# func_remove_public_key_file

	# test that the user ansible can ssh into all nodes (master and slaves)
	####### leave this for now, but comment out once it seems to be working
	func_test_ansible_ssh

	# expect needed for ssh testing, so remove last
	func_remove_expect
}
#===================================================================================================================
func_run_on_slaves(){

	# functions to run on the slave
	func_print_script_info
	func_update_system
	func_install_python
	func_create_ansible_user
	func_set_ansible_sudoer_privileges
	func_create_set_ssh_keys_localhost
	# func_get_master_rsa_pub	
	# func_slave_script_delete_yourself
}
####################################################################################################################
# End Sequences of Functions to setup Cluster
####################################################################################################################


# setup slaves
func_run_on_slaves	




