#!/bin/bash

# Purpose
# bash script to initiate the Ansible playbook to deploy Hadoop
# run as:  ./run-hadoop-1-deploy-playbook.sh 1.2.1


#########################################################################################################
# input testing
#########################################################################################################

func_print_usage(){
  echo "eg. version 1.2.1 should be run as: ./<script-name>.sh 1.2.1"
}

# hadoop_ver parameter should be in the form a.b.c
# this will be used to create the installation directory, such as /opt/hadoop/a.b.c
# and a hadoop user for this specific version, such as hadoop_abc

# just basic sanity test to catch likely errors by say a tired user
# test for null
if [ -z "$1" ]; then
	func_print_usage
	exit 1
fi

# get length of not null parameter
len=$(echo -n $1 | wc --chars)

# is it the correct length? eg. a.b.c
if [ $len -eq 5 ]; then
	# do nothing
	echo $0 > /dev/null
else
	echo "Error: version is in an incorrect format"
   	func_print_usage
	exit 1
fi

# okay, grab the vals and move on
a=$(echo -n $1 | cut -c1)
b=$(echo -n $1 | cut -c3)
c=$(echo -n $1 | cut -c5)

HADOOP_NN=$2
HADOOP_2NN=$3
SLAVE_NODE_PREFIX=$4
HADOOP_RM=$5

# test if the head/master name is specified and use default if now
if [ -z "$2" ]; then
	HADOOP_NN="head"
fi

# same for 2NN
if [ -z "$3" ]; then
	HADOOOP_2NN=$HADOOP_NN
fi

# same for slave prefix
if [ -z "$4" ]; then
	SLAVE_NODE_PREFIX="boa-"
fi

# same for RM
if [ -z "$5" ]; then
	HADOOP_RM=$HADOOP_NN
fi

#########################################################################################################
# vars
#########################################################################################################

hadoop_ver="$a.$b.$c"
hadoop_ver_numeric="$a$b$c"
extra_vars="hadoop_version=$hadoop_ver hadoop_name_node=$HADOOP_NN hadoop_secondary_name_node=$HADOOP_2NN hadoop_data_node_base_name=$SLAVE_NODE_PREFIX hadoop_resourcemanager_node=$HADOOP_RM"

#########################################################################################################
# code 
#########################################################################################################
# test for numeric value
re='^[0-9]+$'
if ! [[ $hadoop_ver_numeric =~ $re ]] ; then
   	echo "error: Not a number" >&2; 
	func_print_usage
	exit 1
fi

if [[ hadoop_ver_numeric -ge 220 && hadoop_ver_numeric -le 274 ]]; then
	# version 2.2.0 - 2.7.4
	ansible-playbook ../local_playbooks/compressed-file-setup_220_274.yml -e "$extra_vars"
elif [[ hadoop_ver_numeric -gt 274 && hadoop_ver_numeric -le 300 ]]; then
	# version 2.8.0 - 2.9.0
	ansible-playbook ../local_playbooks/compressed-file-setup_280_300.yml -e "$extra_vars"
else
	echo "Version number is not between 2.2.0 and 3.0.0"
fi
 
