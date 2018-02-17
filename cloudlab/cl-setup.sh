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

# testing
echo "$1 : $2 : $3 : $4" > var-values.txt

# setup ansible
./ansible-setup.sh  $1 $2 $3 $4 2>&1 | tee ansible-setup.log

# setup / format the disk drive (not hadoop formatting).
# ./init-hdfs.sh

# prepare hadoop for installation
# rename and move ansible dir
# mv /tmp/ansible-master /tmp/ansible
# mv /tmp/ansible /home/ansible/ansible

