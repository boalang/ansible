#!/bin/bash

# Purpose
# bash script to initiate the Ansible playbook to start or stop the cluster
# run as:  ./run-spark-1-start-stop-playbook.sh 1.2.1 start/stop


#########################################################################################################
# input testing
#########################################################################################################

# spark_ver parameter should be in the form a.b.c
# this will be used to create the installation directory, such as /opt/spark/a.b.c
# and a spark user for this specific version, such as spark_abc

# just basic sanity test to catch likely errors by say a tired user
# test for null
if [ -z "$1" ]; then
	echo "command line execution is mising spark version number"
	echo "eg. version 1.2.1 should be run as: ./<script-name>.sh 1.2.1"
	exit 1
fi

if [ -z "$2" ]; then
	echo "command line execution is missing a value of stop or start"
	echo "eg. version 1.2.1 should be run as: ./script.sh 1.2.1 start-or-stop-here"
	exit 1
fi

# get length of not null parameter
len=$(echo -n $1 | wc --chars)

# is it the correct length? eg. a.b.c
if [ $len -eq 5 ]; then
	# do nothing
	echo $0 > /dev/null
else
   	echo "spark_ver not of the form a.b.c"
	exit 1
fi

# okay, grab the vals and move on
a=$(echo -n $1 | cut -c1)
b=$(echo -n $1 | cut -c3)
c=$(echo -n $1 | cut -c5)

# test for proper stop/start value
if [[ "$2" != "start" && "$2" != "stop" ]]; then
	echo "invalid stop_start_cluster value"
	echo "stop_start_cluster=start or stop_start_cluster=stop"
	exit 1
fi

#########################################################################################################
# vars
#########################################################################################################

spark_ver="$a.$b.$c"
start_stop_cluster=$2
playbook_name=start-stop.yml
extra_vars="spark_version=$spark_ver start_stop_cluster=$start_stop_cluster"

########################################################################################################
# code
########################################################################################################
ansible-playbook ../local_playbooks/$playbook_name --extra-vars "$extra_vars"
