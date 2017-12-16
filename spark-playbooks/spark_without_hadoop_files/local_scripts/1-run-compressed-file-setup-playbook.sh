#!/bin/bash

# Purpose
# bash script to initiate the Ansible playbook to deploy Spark
# run as:  ./run-compressed-file-steup-playbook.sh 1.2.1


#########################################################################################################
# input testing
#########################################################################################################

func_print_usage(){
  echo "eg. version 1.2.1 should be run as: ./<script-name>.sh 1.2.1"
}

# spark_ver parameter should be in the form a.b.c
# this will be used to create the installation directory, such as /opt/spark/a.b.c

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

#########################################################################################################
# vars
#########################################################################################################

spark_ver="$a.$b.$c"
spark_ver_numeric="$a$b$c"
extra_vars="spark_version=$spark_ver"

#########################################################################################################
# code 
#########################################################################################################
# test for numeric value
re='^[0-9]+$'
if ! [[ $spark_ver_numeric =~ $re ]] ; then
   	echo "error: Not a number" >&2; 
	func_print_usage
	exit 1
fi

if [[ spark_ver_numeric -ge 200 && spark_ver_numeric -le 221 ]]; then
	# version 2.0.0 - 2.2.1
	ansible-playbook ../local_playbooks/compressed-file-setup.yml -e "$extra_vars"
else
	echo "Version number is not between 2.0.0 and 2.2.1"
fi
 
