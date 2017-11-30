#!/bin/bash

# Purpose
# Test that passwordless ssh exists for user ansible from the master to each
# node in the cluster, in cluding the master node itself

#PROG_NAME="$0"
#PROG_BASE_NAME=$(basename $0)
ANSIBLE_UN="$1"
RUN_ON="$2"
#PROG_USER=`logname`
HOST_IP=`hostname -I`
HOST_NAME=`hostname`


# call the expect script
if (( $RUN_ON == 0 )); then
	# run on the master
	echo ""
	echo "Processing: $HOST_NAME"
	echo "`pwd`/expect-script-test-ssh.sh $ANSIBLE_UN $HOST_NAME | sudo tee `pwd`/files_output/ssh-test-$HOST_NAME"
	`pwd`/expect-script-test-ssh.sh $ANSIBLE_UN $HOST_NAME | sudo tee `pwd`/files_output/ssh-test-"$HOST_NAME"

else
	# run on the slaves
	echo ""
	for SLAVE in `cat slaves.txt`; do
		echo ""
		echo "Processing: $SLAVE"
		echo "`pwd`/expect-script-test-ssh.sh $ANSIBLE_UN $SLAVE | sudo tee `pwd`/files_output/ssh-test-$SLAVE"
		`pwd`/expect-script-test-ssh.sh $ANSIBLE_UN $SLAVE | sudo tee `pwd`/files_output/ssh-test-"$SLAVE"
		echo ""
	done
fi
