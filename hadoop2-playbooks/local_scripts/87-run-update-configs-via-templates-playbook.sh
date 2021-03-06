#!/bin/bash

# Purpose
# To deploy the configuration template files to the cluter, updating both the 
# <version>_conf_in_use and <version>_conf_master directories.
# run as:  ./<file-name><version>


#########################################################################################################
# input testing
#########################################################################################################

# hadoop_ver parameter should be in the form a.b.c
# this will be used to create the installation directory, such as /opt/hadoop/a.b.c
# and a hadoop user for this specific version, such as hadoop_abc

# just basic sanity test to catch likely errors by say a tired user
# test for null
if [ -z "$1" ]; then
	echo "command line execution is mising hadoop version number"
	echo "eg. version 1.2.1 should be run as: ./<script-name>.sh 1.2.1"
	exit 1
fi

# get length of not null parameter
len=$(echo -n $1 | wc --chars)

# is it the correct length? eg. a.b.c
if [ $len -eq 5 ]; then
	# do nothing
	echo $0 > /dev/null
else
   	echo "hadoop_ver not of the form a.b.c"
	exit 1
fi

# okay, grab the vals and move on
a=$(echo -n $1 | cut -c1)
b=$(echo -n $1 | cut -c3)
c=$(echo -n $1 | cut -c5)

HADOOP_NN=$2
HADOOP_2NN=$4
SLAVE_NODE_PREFIX=$3
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
if [ -z "$3" ]; then
	SLAVE_NODE_PREFIX="boa-"
fi

# same for RM
if [ -z "$4" ]; then
	HADOOP_RM=$HADOOP_NN
fi

#########################################################################################################
# vars
#########################################################################################################

hadoop_ver="$a.$b.$c"
playbook_name=update-configs-via-templates.yml

extra_vars="hadoop_version=$hadoop_ver hadoop_name_node=$HADOOP_NN hadoop_secondary_name_node=$HADOOP_2NN hadoop_data_node_base_name=$SLAVE_NODE_PREFIX hadoop_resourcemanager_node=$HADOOP_RM"

########################################################################################################
# code
########################################################################################################
ansible-playbook ../local_playbooks/$playbook_name --extra-vars "$extra_vars"
