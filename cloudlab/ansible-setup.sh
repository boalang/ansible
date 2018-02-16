#!/bin/bash
# Purpose:
# To install user ansible on all nodes and Ansible on master node, so that Ansible can be used to setup hadoop.
#
# run as
# /path-to-script/cluster-setup.sh {master|slave} NUM_SLAVES


####################################################################################################################
# globals
PROG_NAME="$0"
PROG_BASE_NAME=$(basename $0)

ANSIBLE_UN="ansible"
ANSIBLE_PWD="$ANSIBLE_UN"

# default value is setup master
PROG_USER_SELECTION=$1

NUM_SLAVES=$2
# just assume the prefix is slave for now
SLAVE_NAME_PREFIX="slave"
MASTER_NAME_PREFIX="master"
SLAVE_FILE="slaves.txt"

PROG_USER=`logname`
PROG_USER_PWD="not set"
HOST_IP=`hostname -I`
HOST_NAME=`hostname`
HOST_NAME_SHORT=`hostname -s`

####################################################################################################################
# Begin General Functions
####################################################################################################################
func_create_slaves_file(){
	
	for (( i=0; i<$NUM_SLAVES; i=i+1 )); do
		echo "$SLAVE_NAME_PREFIX$i" >> $SLAVE_FILE
	done
}
#===================================================================================================================
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
	echo "ssh-keyscan $HOST_NAME_SHORT >> $KNOWN_HOSTS"
	ssh-keyscan $HOST_NAME_SHORT >> $KNOWN_HOSTS

	# user ansible owns everything in .ssh
	echo ""
	echo "chown -R $ANSIBLE_UN:$ANSIBLE_UN $SSH_DIR"
	chown -R $ANSIBLE_UN:$ANSIBLE_UN $SSH_DIR
}
#===================================================================================================================
func_update_restart_sshd(){

	# cloudlab comes with sshd_config PasswordAuthentication no, but we need yes to allow the sharing of 
	# public keys, so update /etc/ssh/sshd_conf with sed
	
	PA=PasswordAuthentication
	sed -i "s/$PA\ no/$PA\ yes/g" /etc/ssh/sshd_config

	# this works on systems using systemd, ubuntu 16
	systemctl restart ssh

	# for sysvinit / upstart, ubuntu 14
	# sudo /etc/init.d/ssh restart

	
}
####################################################################################################################
# End General Functions
####################################################################################################################


####################################################################################################################
# Begin Functions for Master Setup
####################################################################################################################
func_install_ansible_software(){

	# Install the Ansible software from the current Ubuntu repo, or add Ansible's repo, if desired.

	echo ""
	echo "apt-get install -y ansible"
	echo ""
	apt-get install -y ansible
}
####################################################################################################################
# End Functions for Master Setup
####################################################################################################################


####################################################################################################################
# Begin Functions to Prepare the Master to setup Slaves
####################################################################################################################
func_install_sshpass(){

	# install sshpass to facilitate automated interaction with managed nodes

	echo ""
	echo "apt-get install -y sshpass"
	echo ""
	apt-get install -y sshpass
}
#===================================================================================================================
func_install_expect(){

	# install expect to facilitate logging into the user account of slave nodes and running setup script with sudo

	echo ""
	echo "apt-get install -y expect"
	echo ""
	apt-get install -y expect
}
#===================================================================================================================
func_setup_slaves(){

	# process nodes
	echo ""
	for NODE in `cat $SLAVE_FILE`; do
		echo ""
		echo "Processing: $NODE"
	# I was going to try and run the functions in the background to parallelize the process, but it seems to
	# to be creating issues with the expect script.
	#	func_setup_slaves_detail $NODE &
		func_setup_slaves_detail $NODE 
		echo ""
	done
}
#===================================================================================================================
func_setup_slaves_detail(){

	# process addresses
	# func_send_script_to_slave $NODE
	func_send_public_key_to_slave $NODE
	func_copy_master_pub_key_to_slave_auth_keys $NODE
	#func_ssh-copy-id_slave $NODE

	# func_execute_script_on_slave $NODE	
	# echo ""
	# func_retrieve_slave_log_file $NODE
	# func_remove_slave_log_file $NODE
	echo ""
	echo "$NODE process complete"
	echo ""
}
#===================================================================================================================
func_send_script_to_slave(){

	# use sshpass & scp to copy the installation script to the slave
	# using StrictHostKeyChecking=no will automatically add the remote host's key to the user's known_host file
	# but allow $PROG_USER to log into $PROG_USER's account on $IP with only a password
	# .ssh and known_hosts will be removed and the origial .ssh put back, if exited, upon program completion

	local IP=$1
	echo ""
	echo "sshpass -p $PROG_USER_PWD scp -o StrictHostKeyChecking=no `pwd`/$PROG_BASE_NAME $PROG_USER@$IP:~"
	sshpass -p "$PROG_USER_PWD" scp -o StrictHostKeyChecking=no `pwd`/$PROG_BASE_NAME "$PROG_USER@$IP:~"

}
#===================================================================================================================
func_send_public_key_to_slave(){

	# use sshpass & scp to copy the public key to the slave
	# using StrictHostKeyChecking=no will automatically add the remote host's key to the user's known_host file
	# but allow $PROG_USER to log into $PROG_USER's account on $IP with only a password
	# .ssh and known_hosts will be removed and the origial .ssh put back, if exited, upon program completion

	local IP=$1
	local PUB_KEY_FILE=/home/$ANSIBLE_UN/.ssh/id_rsa.pub
	
#	echo ""
#	echo "sshpass -p $PROG_USER_PWD scp -o StrictHostKeyChecking=no $PUB_KEY_FILE $PROG_USER@$IP:~"
#	sshpass -p "$PROG_USER_PWD" scp -o StrictHostKeyChecking=no $PUB_KEY_FILE "$PROG_USER@$IP:~"

	echo ""
	echo "sshpass -p $ANSIBLE_PWD scp -o StrictHostKeyChecking=no $PUB_KEY_FILE $ANSIBLE_UN@$IP:~"
	sshpass -p "$ANSIBLE_PWD" scp -o StrictHostKeyChecking=no $PUB_KEY_FILE "$ANSIBLE_UN@$IP:~"

}
#===================================================================================================================
func_copy_master_pub_key_to_slave_auth_keys(){

	# the public key should have already been copied to the slave, now cat it to the authorized_keys file on the slave
	local REMOTE_IP=$1
	echo ""
	echo "sshpass -p "$ANSIBLE_PWD" ssh -o StrictHostKeyChecking=no "$ANSIBLE_UN@$REMOTE_IP" 'cat /home/$ANSIBLE_UN/id_rsa.pub >> /home/"$ANSIBLE_UN"/.ssh/authorized_keys'"
	sshpass -p "$ANSIBLE_PWD" ssh -o StrictHostKeyChecking=no "$ANSIBLE_UN@$REMOTE_IP" "cat /home/$ANSIBLE_UN/id_rsa.pub >> /home/"$ANSIBLE_UN"/.ssh/authorized_keys"
}
#===================================================================================================================
func_ssh-copy-id_slave(){

	local REMOTE_IP=$1
	local PAUSE=45
	local EXPECT_TIMEOUT=120
	# PROG_USER_SELECTION=3 is required to force slave to run proper functions
	PROG_USER_SELECTION=3

	echo ""
	echo "./expect-ssh-copy-id-script.sh $ANSIBLE_UN $ANSIBLE_PWD $REMOTE_IP"
	echo ""

	./expect-ssh-copy-id-script.sh $ANSIBLE_UN $ANSIBLE_PWD $REMOTE_IP
}
#===================================================================================================================
func_execute_script_on_slave(){

	local REMOTE_IP=$1
	local PAUSE=45
	local EXPECT_TIMEOUT=120
	# PROG_USER_SELECTION=3 is required to force slave to run proper functions
	PROG_USER_SELECTION=3

	echo ""
	echo "./expect-script.sh $ANSIBLE_UN $ANSIBLE_PWD $PROG_USER_SELECTION $SLAVE_FILE $REMOTE_IP $PROG_USER $PROG_USER_PWD $EXPECT_TIMEOUT $SHOW_EXPECT_SCRIPT_MSG"
	echo ""

	./expect-script.sh $ANSIBLE_UN $ANSIBLE_PWD $PROG_USER_SELECTION $SLAVE_FILE $REMOTE_IP $PROG_USER $PROG_USER_PWD $EXPECT_TIMEOUT $SHOW_EXPECT_SCRIPT_MSG
}
#===================================================================================================================
func_retrieve_slave_log_file(){

	# to void having to set the master's public key in the slave's known_host file by using scp to send
	# the slave's log file to the master, just let the master retrieve it, since the master's .ssh directory
	# is going to be replaced with it original .ssh, if it existed, anyway

	local IP=$1
	echo ""
	echo "sshpass -p $PROG_USER_PWD scp -o StrictHostKeyChecking=no $PROG_USER@$IP:~/$IP.log `pwd`/files_output"
	sshpass -p $PROG_USER_PWD scp -o StrictHostKeyChecking=no $PROG_USER@$IP:~/$IP.log `pwd`/files_output
}
#===================================================================================================================
func_remove_slave_log_file(){

	local IP=$1
	echo ""
	echo "sshpass -p $PROG_USER_PWD ssh -o StrictHostKeyChecking=no $PROG_USER@$IP rm -f $IP.log"
	sshpass -p $PROG_USER_PWD ssh -o StrictHostKeyChecking=no $PROG_USER@$IP "rm -f $IP.log"
}
#===================================================================================================================
func_ssh-keyscan_ansible(){

	# ssh-keyscan will copy all the public keys from the nodes listed in SLAVE_FILE and add them
	# to the known_hosts for ANSIBLE_UN
	# this will avoid being prompted to accept rsa keys when connecting

	echo ""
	echo "running:  ssh-keyscan -4 -f $SLAVE_FILE >> /home/$ANSIBLE_UN/.ssh/known_hosts"
	ssh-keyscan -4 -f "$SLAVE_FILE" >> "/home/$ANSIBLE_UN/.ssh/known_hosts"

	# note:  as is, only the host name will be added to the known_hosts file, but the ip address would be helpful too
	# run the keyscan command again, but this time collect the keys asociated with the ip addresses

	# get the ip v4 version
	IPV4=getent hosts | cut -d' ' -f1

	echo ""
	echo "running:  ssh-keyscan -4 $IPV4 >> /home/$ANSIBLE_UN/.ssh/known_hosts"
	ssh-keyscan -4 -f "$IPV4" >> "/home/$ANSIBLE_UN/.ssh/known_hosts"

}
#===================================================================================================================
func_remove_sshpass(){

	echo ""
	echo "apt-get purge -y sshpass"
	echo ""
	apt-get purge -y sshpass
}
#===================================================================================================================
func_remove_public_key_file(){
	
	# remove master_id_rsa.pub
	echo ""
	echo "rm -f `pwd`/master_id_rsa.pub"
	rm -f `pwd`/master_id_rsa.pub
}
#===================================================================================================================
func_test_ansible_ssh(){

	# process addresses
	# invoke a script as the user ansible
	# that script then uses an expect script to log into each node in the cluster and verify that
	# 	the user ansible is able to ssh without a password to each node.

	echo ""
	echo "** Testing passwordless ssh for user $ANSIBLE_UN **"

	# process the master
	su -c './test-ansible-ssh.sh ansible 0' $ANSIBLE_UN

	# process slaves
	su -c './test-ansible-ssh.sh ansible 1' $ANSIBLE_UN

	# make sure all of the ssh log files are owned by $PROG_USER
	chown -R $PROG_USER.$PROG_USER `pwd`/files_output
}
#===================================================================================================================
func_remove_expect(){

	echo ""
	echo "apt-get purge -y expect"
	echo ""
	apt-get purge -y expect
}
####################################################################################################################
# End Functions to Prepare the Master to setup Slaves
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
	#func_update_system
	func_install_ansible_software
	func_create_ansible_user
	func_set_ansible_sudoer_privileges
	func_create_set_ssh_keys_localhost
}
#===================================================================================================================
func_prep_master_to_setup_slaves(){

	# preparing the master to setup the slaves

	func_install_sshpass
	# func_install_expect

	# for each slave, copy over script, execute script using expect script, remove script
	func_setup_slaves

	# collect all the host keys from slave nodes
	func_ssh-keyscan_ansible

	# unprepare master for slave update
	# func_remove_sshpass

	# i'm not sure this needs to be removed, since it will be a fresh install
	# func_remove_public_key_file

	# test that the user ansible can ssh into all nodes (master and slaves)
	####### leave this for now, but comment out once it seems to be working
	# func_test_ansible_ssh

	# expect needed for ssh testing, so remove last
	# func_remove_expect
}
#===================================================================================================================
func_run_on_slaves(){

	# functions to run on the slave
	func_print_script_info
	#func_update_system
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


if [[ $PROG_USER_SELECTION == "master" ]]; then

	func_setup_master
	func_prep_master_to_setup_slaves

else

	func_run_on_slaves	

fi

# restart ssh
func_update_restart_sshd

# signal script is done
echo `date` > /tmp/$HOST_NAME_SHORT.txt

