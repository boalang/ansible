#!/bin/bash

# Purpose
# To manage the cluster setup.
#
# This script will be passed the following arguments by cloudlab:
# master:  cl-setup.sh MASTER_NAME SLAVE_NAME_PREFIX NUM_SLAVES HADOOP_VERSION
# slave:   cl-setup.sh SLAVE_NAME_PREFIX
#
# The ansible-setup.sh script will take the first argument and check if it is "master" or "head", which
# are common names we've used for the master node's name.  If there is a match it will assume it is 
# running on the master or head node, otherwise it will assume that it is running on a slave node.
#
# Either way the first argument will determine the scripts execution path.  
# The slave script will ignore the last three agruments.

PATH_TO_CL_DIR=/tmp/ansible-master/cloudlab

# testing
echo "$1 : $2 : $3 : $4" > $PATH_TO_CL_DIR/var-values.txt

# setup ansible
$PATH_TO_CL_DIR/ansible-setup.sh  $1 $2 $3 $4 2>&1 | tee $PATH_TO_CL_DIR/ansible-setup.log

# setup / format the disk drive (not hadoop formatting).
$PATH_TO_CL_DIR/init-hdfs.sh

# prepare hadoop for installation
# rename and move ansible dir
mv /tmp/ansible-master /tmp/ansible
mv /tmp/ansible /home/ansible/

# dynamically create Ansible inventory (hosts) file

# execute high level ansible playbook scripts to install and start hadoop


# run Ansible role to install Drupal
