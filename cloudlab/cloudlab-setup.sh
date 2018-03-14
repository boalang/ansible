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

func_cloudlab_setup_log(){
	echo "$1 $2:  `date`" >> /tmp/cloudlab-setup.log
}

#########################################################################################################

func_cloudlab_setup_log "start" "ansible-setup.sh"

# setup ansible
$PATH_TO_CL_TMP/ansible-setup.sh  "$MASTER_NAME" "$SLAVE_NAME_PREFIX" "$NUM_SLAVES" "$HADOOP_VERSION" | tee -a /tmp/ansible-setup.log

func_cloudlab_setup_log "end" "ansible-setup.sh"

#########################################################################################################

# prepare hadoop for installation, rename and move ansible dir
mv /tmp/ansible-master /tmp/ansible
mv /tmp/ansible /home/ansible/
chown -R ansible.ansible /home/ansible

# setup / format the disk drive (not hadoop formatting).
$PATH_TO_CL_ANSIBLE/init-hdfs.sh

# slave nodes stop here
if [ -z "$SLAVE_NAME_PREFIX" ];then
	# slave nodes will have a null prefix and if a master node cannot have a null prefix, then it
	# should stop also
	exit 1
fi

#########################################################################################################
# the hadoop scripts need to be run as the user ansible

# to be sure ansible owns everything in /home/ansible before starting script
chown -R ansible.ansible /home/ansible

func_cloudlab_setup_log "start" "hadoop-setup.sh"

su - ansible -c "$PATH_TO_CL_ANSIBLE/hadoop-setup.sh $HADOOP_VERSION $MASTER_NAME $SLAVE_NAME_PREFIX $PATH_TO_ANSIBLE_DIR $NUM_SLAVES"

func_cloudlab_setup_log "end" "hadoop-setup.sh"

########################################################################################################

func_cloudlab_setup_log "start" "boa-setup.sh"

# setup boa items
su - ansible -c "$PATH_TO_CL_ANSIBLE/boa-setup.sh $MASTER_NAME $PATH_TO_ANSIBLE_DIR"

# runs fine from cli as user hadoop, but cannot overcome errors from within ansible playbook
# let root su to hadoop and run it
su - hadoop -c "exec /home/hadoop/bin/run-poller.sh >/dev/null 2>&1"

func_cloudlab_setup_log "end" "boa-setup.sh"

#########################################################################################################

func_cloudlab_setup_log "start" "drupal-setup.sh"

# ansible to install Drupal (LAMP)
su - ansible -c "$PATH_TO_CL_ANSIBLE/drupal-setup.sh $MASTER_NAME $PATH_TO_CL_ANSIBLE $PATH_TO_ANSIBLE_DIR"

func_cloudlab_setup_log "end" "drupal-setup.sh"

