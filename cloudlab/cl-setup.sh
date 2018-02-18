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

PATH_TO_CL_ANSIBLE=/home/ansible/ansible/cloudlab
PATH_TO_CL_TMP=/tmp/ansible-master/cloudlab
PATH_TO_ANSIBLE_DIR=/home/ansible/ansible
MASTER_NAME=$1
SLAVE_NAME_PREFIX=$2
NUM_SLAVES=$3
HADOOP_VERSION=$4
TESTING=$5

# testing
echo "$MASTER_NAME : $SLAVE_NAME_PREFIX : $NUM_SLAVES : $HADOOP_VERSION" > $PATH_TO_CL_TMP/var-values.txt

#########################################################################################################

# setup ansible
$PATH_TO_CL_TMP/ansible-setup.sh  "$MASTER_NAME" "$SLAVE_NAME_PREFIX" "$NUM_SLAVES" "$HADOOP_VERSION" | tee -a $PATH_TO_CL_TMP/ansible-setup.log

# prepare hadoop for installation, rename and move ansible dir
mv /tmp/ansible-master /tmp/ansible
mv /tmp/ansible /home/ansible/
chown -R ansible.ansible /home/ansible

# setup / format the disk drive (not hadoop formatting).
if [ -z "$TESTING" ];then
	# the argument will be empty when running on cloudlab
	$PATH_TO_CL_ANSIBLE/init-hdfs.sh
fi

#########################################################################################################
# slave nodes stop here
if [ -z "$SLAVE_NAME_PREFIX" ];then
	# slave nodes will have a null prefix and if a master node cannot have a null prefix, then it
	# should stop also
	exit 1
fi

#########################################################################################################
# hadoop_ver parameter should be in the form a.b.c
# test for null
if [ -z "$HADOOP_VERSION" ]; then
	echo "command line execution is mising hadoop version number" | tee -a $PATH_TO_ANSIBLE_DIR/hadoop-setup.log
	echo "eg. version 1.2.1 should be run as: ./<script-name>.sh 1.2.1" | tee -a $PATH_TO_ANSIBLE_DIR/hadoop-setup.log
	exit 1
fi

# get length of not null parameter
len=$(echo -n $HADOOP_VERSION | wc --chars)

# is it the correct length? eg. a.b.c
if [ $len -eq 5 ]; then
	# do nothing
	echo $0 > /dev/null
else
   	echo "hadoop_ver not of the form a.b.c" | tee -a $PATH_TO_ANSIBLE_DIR/hadoop-setup.log
	echo "a.b.c=$HADOOP_VERSION"  | tee -a $PATH_TO_ANSIBLE_DIR/hadoop-setup.log

	exit 1
fi

HADOOP_MAJOR_VERSION=$(echo -n $HADOOP_VERSION | cut -c1)

if (($HADOOP_MAJOR_VERSION!=1 && $HADOOP_MAJOR_VERSION!=2));then
	echo "Hadoop version must be of the form a.b.c, where a=1 or a=2" | tee -a $PATH_TO_ANSIBLE_DIR/hadoop-setup.log
	exit 1
fi

#########################################################################################################
# dynamically create Ansible inventory (hosts) file
# remove default hosts file and create a new one
PATH_TO_HOSTS_FILE=$PATH_TO_ANSIBLE_DIR/local_hosts/hosts
rm -f $PATH_TO_HOSTS_FILE
# note: 
# CL seems to setup default ssh port, if that changes you'll need to update here
# Best to pass in as a parameter.

echo "[name_node]" | tee -a $PATH_TO_HOSTS_FILE
echo "$MASTER_NAME ansible_port=22" | tee -a $PATH_TO_HOSTS_FILE
echo "# port must match port variable defined in ./local_variable_files/hadoop-vars.yml" | tee -a $PATH_TO_HOSTS_FILE
echo ""

echo "[secondary_nn]" | tee -a $PATH_TO_HOSTS_FILE
echo "$MASTER_NAME ansible_port=22" | tee -a $PATH_TO_HOSTS_FILE
echo "# port must match port variable defined in ./local_variable_files/hadoop-vars.yml" | tee -a $PATH_TO_HOSTS_FILE
echo ""

echo "[resourcemanager]" | tee -a $PATH_TO_HOSTS_FILE
echo "$MASTER_NAME ansible_port=22" | tee -a $PATH_TO_HOSTS_FILE
echo "# port must match port variable defined in ./local_variable_files/hadoop-vars.yml" | tee -a $PATH_TO_HOSTS_FILE
echo ""

echo "[data_nodes]" | tee -a $PATH_TO_HOSTS_FILE
for (( cnt=1; cnt<=$NUM_SLAVES; cnt=cnt+1 )); do
	echo "$SLAVE_NAME_PREFIX$cnt ansible_port=22" | tee -a $PATH_TO_HOSTS_FILE
done

#########################################################################################################
# the hadoop scripts need to be run as the user ansible
# to be sure ansible owns everything in /home/ansible

chown -R ansible.ansible /home/ansible

su - ansible -c "$PATH_TO_CL_ANSIBLE/hadoop-setup.sh $HADOOP_MAJOR_VERSION $HADOOP_VERSION $MASTER_NAME $SLAVE_NAME_PREFIX"


#########################################################################################################

# run Ansible role to install Drupal
echo "run Drupal stuff here"
