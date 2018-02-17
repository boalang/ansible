#!/bin/bash

# Purpose
# To manage the cluster setup.
#
# This script will be passed the following arguments by cloudlab:
# master:  cl-setup.sh MASTER_NAME SLAVE_NAME_PREFIX NUM_SLAVES HADOOP_VERSION TESTING
# slave:   cl-setup.sh SLAVE_NAME_PREFIX
#
# The ansible-setup.sh script will take the first argument and check if it is "master" or "head", which
# are common names we've used for the master node's name.  If there is a match it will assume it is 
# running on the master or head node, otherwise it will assume that it is running on a slave node.
#
# Either way the first argument will determine the scripts execution path.  
# The slave script will ignore the last three agruments.
#########################################################################################################

PATH_TO_CL_DIR=/tmp/ansible-master/cloudlab
PATH_TO_ANSIBLE_DIR=/home/ansible/ansible
MASTER_NAME=$1
SLAVE_NAME_PREFIX=$2
NUM_SLAVES=$3
HADOOP_VERSION=$4
TESTING=$5

# testing
echo "$MASTER_NAME : $SLAVE_NAME_PREFIX : $NUM_SLAVES : $HADOOP_VERSION" > $PATH_TO_CL_DIR/var-values.txt

#########################################################################################################

# setup ansible
$PATH_TO_CL_DIR/ansible-setup.sh  "$MASTER_NAME" "$SLAVE_NAME_PREFIX" "$NUM_SLAVES" "$HADOOP_VERSION" 2>&1 | tee $PATH_TO_CL_DIR/ansible-setup.log

# setup / format the disk drive (not hadoop formatting).
if [ ! -z "$TESTING" ];then
	# the argument will be empty when running on cloudlab
	$PATH_TO_CL_DIR/init-hdfs.sh
fi

# prepare hadoop for installation
# rename and move ansible dir
mv /tmp/ansible-master /tmp/ansible
mv /tmp/ansible /home/ansible/

#########################################################################################################
# slave nodes stop here
if [ -z "$SLAVE_NAME_PREFIX" ];then
	#slave nodes will have a null prefix and a master node cannot have a null prefix
	exit 1
fi

#########################################################################################################
# hadoop_ver parameter should be in the form a.b.c
# test for null
if [ -z "$HADOOP_VERSION" ]; then
	echo "command line execution is mising hadoop version number" >> $PATH_TO_ANSIBLE_DIR/hadoop-setup.log
	echo "eg. version 1.2.1 should be run as: ./<script-name>.sh 1.2.1" >> $PATH_TO_ANSIBLE_DIR/hadoop-setup.log
	exit 1
fi

# get length of not null parameter
len=$(echo -n $HADOOP_VERSION | wc --chars)

# is it the correct length? eg. a.b.c
if [ $len -eq 5 ]; then
	# do nothing
	echo $0 > /dev/null
else
   	echo "hadoop_ver not of the form a.b.c" >> $PATH_TO_ANSIBLE_DIR/hadoop-setup.log
	echo "a.b.c=$HADOOP_VERSION" >> $PATH_TO_ANSIBLE_DIR/hadoop-setup.log

	exit 1
fi

# okay, grab the vals and move on
a=$(echo -n $HADOOP_VERSION | cut -c1)
b=$(echo -n $HADOOP_VERSION | cut -c3)
c=$(echo -n $HADOOP_VERSION | cut -c5)

if (($a==1 || $a==2));then
	cd "$PATH_TO_ANSIBLE_DIR"/hadoop"$a"-playbooks/local_scripts
else
	echo "Hadoop version must be of the form a.b.c, where a=1 or a=2" >> $PATH_TO_ANSIBLE_DIR/hadoop-setup.log
	exit 1
fi

#########################################################################################################
# dynamically create Ansible inventory (hosts) file
# remove default hosts file and create a new one
PATH_TO_HOSTS_FILE=../../local_hosts/hosts
rm -f $PATH_TO_HOSTS_FILE
# note: 
# CL seems to setup default ssh port, if that changes you'll need to update here
# Best to pass in as a parameter.

echo "[name_node]" >> $PATH_TO_HOSTS_FILE
echo "$MASTER_NAME ansible_port=22" >> $PATH_TO_HOSTS_FILE
echo "# port must match port variable defined in ./local_variable_files/hadoop-vars.yml" >> $PATH_TO_HOSTS_FILE
echo ""

echo "[secondary_nn]" >> $PATH_TO_HOSTS_FILE
echo "$MASTER_NAME ansible_port=22" >> $PATH_TO_HOSTS_FILE
echo "# port must match port variable defined in ./local_variable_files/hadoop-vars.yml" >> $PATH_TO_HOSTS_FILE
echo ""

echo "[resourcemanager]" >> $PATH_TO_HOSTS_FILE
echo "$MASTER_NAME ansible_port=22" >> $PATH_TO_HOSTS_FILE
echo "# port must match port variable defined in ./local_variable_files/hadoop-vars.yml" >> $PATH_TO_HOSTS_FILE
echo ""

echo "[data_nodes]" >> $PATH_TO_HOSTS_FILE
for (( cnt=1; cnt<=$NUM_SLAVES; cnt=cnt+1 )); do
	echo "$SLAVE_NAME_PREFIX$cnt ansible_port=22" >> $PATH_TO_HOSTS_FILE
done

# execute high level ansible playbook scripts to install and start hadoop
./1-run-compressed-file-setup-playbook.sh 	$HADOOP_VERSION > $PATH_TO_ANSIBLE_DIR/hadoop-install-script1.log
./2-run-deploy-playbook.sh 			$HADOOP_VERSION > $PATH_TO_ANSIBLE_DIR/hadoop-install-script2.log
./3-run-create-conf-master-playbook.sh 		$HADOOP_VERSION > $PATH_TO_ANSIBLE_DIR/hadoop-install-script3.log
./4-run-set-2nn-ssh-playbook.sh 		$HADOOP_VERSION > $PATH_TO_ANSIBLE_DIR/hadoop-install-script4.log
./5-run-format-playbook.sh 			$HADOOP_VERSION > $PATH_TO_ANSIBLE_DIR/hadoop-install-script5.log
./6-run-boa-setup-playbook.sh 			$HADOOP_VERSION > $PATH_TO_ANSIBLE_DIR/hadoop-install-script6.log
./7-run-start-stop-playbook.sh 			$HADOOP_VERSION > $PATH_TO_ANSIBLE_DIR/hadoop-install-script7.log

#########################################################################################################

# run Ansible role to install Drupal
