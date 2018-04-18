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

#########################################################################################################
# sleep for 1 minute before starting
sleep 60
# I think there may be error due to CL not being done provisioned before the script starts working

#########################################################################################################

echo "`date`" > /tmp/1-ansible-setup-started.txt

# CloudLab is throwing errors when doing the upgrade in the ansible-setup.sh
# "Err:1 http://security.ubuntu.com/ubuntu xenial-security/main amd64 python-crypto"
# ip address of security repo found
# it seems to disappear when update is run manually from the cli, so perhaps the script is moving onto 
# the upgrade before the repo list is refreshed.
# pause here for 5 seconds to ensure the update is done before moving onto the upgrade
apt-get update
sleep 5
apt-get upgrade -y

$PATH_TO_CL_TMP/ansible-setup.sh  "$MASTER_NAME" "$SLAVE_NAME_PREFIX" "$NUM_SLAVES" "$HADOOP_VERSION" | tee -a /tmp/ansible-setup.log

echo "`date`" > /tmp/1-ansible-setup-complete.txt

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

echo "`date`" > /tmp/2-hadoop-setup-started.txt

# to be sure ansible owns everything in /home/ansible before starting script
chown -R ansible.ansible /home/ansible

su - ansible -c "$PATH_TO_CL_ANSIBLE/hadoop-setup.sh $HADOOP_VERSION $MASTER_NAME $SLAVE_NAME_PREFIX $PATH_TO_ANSIBLE_DIR $NUM_SLAVES"

echo "`date`" > /tmp/2-hadoop-setup-complete.txt

########################################################################################################

echo "`date`" > /tmp/3-boa-compiler-setup-started.txt

# setup boa items
su - ansible -c "$PATH_TO_CL_ANSIBLE/boa-setup.sh $MASTER_NAME $PATH_TO_ANSIBLE_DIR"

echo "`date`" > /tmp/3-boa-compiler-setup-complete.txt

#########################################################################################################

echo "`date`" > /tmp/4-drupal-setup-started.txt

# ansible to install Drupal (LAMP)
su - ansible -c "$PATH_TO_CL_ANSIBLE/drupal-setup.sh $MASTER_NAME $PATH_TO_CL_ANSIBLE $PATH_TO_ANSIBLE_DIR"

echo "`date`" > /tmp/4-drupal-setup-complete.txt

#########################################################################################################


