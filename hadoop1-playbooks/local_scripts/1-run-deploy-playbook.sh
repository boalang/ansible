#!/bin/bash

# Purpose
# bash script to initiate the Ansible playbook to deploy Hadoop
# this script makes running the playbook a little easier by preparing the command line 
# 	arguments to pass to the playbook, which are read from other files

# ansible is REALLY picky about quotes, so I must have tried 18 different iterations, before getting some
#	intuition about what to do in the following post:
# https://github.com/ansible/ansible/issues/9320

# *NOTES*
# The simplest way to describe what seems to work when using scripts to pass playbooks arguments 
# is to not try to escape thing. It doesn't seem to work as expected.  It appears that Ansible will
# replace " with ' and ' with " so "a=" "b" becomes 'a=" "b' etc...
# 
# Try to have whatever you pass to Ansible to be like "$myvar=5 $myvar2=bbb ..." or 'var1=5 var2=boy ...'


########################################################################################################
# run as:  ./run-hadoop-1-deploy-playbook.sh 1.2.1
########################################################################################################


#########################################################################################################
# input testing
#########################################################################################################

# hadoop_ver parameter should be in the form a.b.c
# this will be used to create the installation directory, such as /opt/hadoop/a.b.c
# and a hadoop user for this specific version, such as hadoop_abc

# just basic sanity test to catch likely errors by say a tired user
# test for null
if [ -z "$1" ]; then
	echo "hadoop_ver=NULL"
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

#########################################################################################################
# vars
#########################################################################################################

hadoop_ver="$a.$b.$c"
playbook_name=deploy.yml
extra_vars="hadoop_version=$hadoop_ver"

#########################################################################################################
# code 
#########################################################################################################
ansible-playbook ../local_playbooks/$playbook_name -e "$extra_vars"
