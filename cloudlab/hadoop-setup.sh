#!/bin/bash
# Purpose
# To install and start Hadoop
# Should be run as the user ansible and execute from /home/ansible

HADOOP_VERSION=$1
MASTER_NAME=$2
SLAVE_NAME_PREFIX=$3
PATH_TO_ANSIBLE_DIR=$4
NUM_SLAVES=$5

#########################################################################################################
# hadoop_ver parameter should be in the form a.b.c
# test for null
if [ -z "$HADOOP_VERSION" ]; then
	echo "command line execution is mising hadoop version number" | tee -a $PATH_TO_ANSIBLE_DIR/hadoop-setup.log
	echo "eg. version 1.2.1 should be run as: ./<script-name>.sh 1.2.1" | tee -a $PATH_TO_ANSIBLE_DIR/hadoop-setup.log
	exit 1
fi

# get length of not null parameter
len=$(echo -n $HADOOP_VERSION | wc --chars)

# is it the correct length? eg. a.b.c
if [ $len -eq 5 ]; then
	# do nothing
	echo $0 > /dev/null
else
   	echo "hadoop_ver not of the form a.b.c" | tee -a $PATH_TO_ANSIBLE_DIR/hadoop-setup.log
	echo "a.b.c=$HADOOP_VERSION"  | tee -a $PATH_TO_ANSIBLE_DIR/hadoop-setup.log

	exit 1
fi

# check that the hadoop version is between 1.2.1 and 3.0.0
HADOOP_MAJOR_VERSION=$(echo -n $HADOOP_VERSION | cut -c1)
if (($HADOOP_MAJOR_VERSION!=1 && $HADOOP_MAJOR_VERSION!=2 ));then
	echo "Hadoop version must be of the form a.b.c, where a=1 or a=2" | tee -a $PATH_TO_ANSIBLE_DIR/hadoop-setup.log
	exit 1
fi

#########################################################################################################
# dynamically create Ansible inventory (hosts) file
# remove default hosts file and create a new one
LOCAL_HOSTS_FILE=$PATH_TO_ANSIBLE_DIR/local_hosts/hosts
rm -f $LOCAL_HOSTS_FILE
# note: 
# CL seems to setup default ssh port, if that changes you'll need to update here
# Best to pass in as a parameter.

echo ""
echo "[name_node]" | tee -a $LOCAL_HOSTS_FILE
echo "$MASTER_NAME ansible_port=22" | tee -a $LOCAL_HOSTS_FILE
echo "# port must match port variable defined in ./local_variable_files/hadoop-vars.yml" | tee -a $LOCAL_HOSTS_FILE
echo "" >> $LOCAL_HOSTS_FILE

echo "[secondary_nn]" | tee -a $LOCAL_HOSTS_FILE
echo "$MASTER_NAME ansible_port=22" | tee -a $LOCAL_HOSTS_FILE
echo "# port must match port variable defined in ./local_variable_files/hadoop-vars.yml" | tee -a $LOCAL_HOSTS_FILE
echo "" >> $LOCAL_HOSTS_FILE

echo "[resourcemanager]" | tee -a $LOCAL_HOSTS_FILE
echo "$MASTER_NAME ansible_port=22" | tee -a $LOCAL_HOSTS_FILE
echo "# port must match port variable defined in ./local_variable_files/hadoop-vars.yml" | tee -a $LOCAL_HOSTS_FILE
echo "" >> $LOCAL_HOSTS_FILE

echo "[data_nodes]" | tee -a $LOCAL_HOSTS_FILE
for (( cnt=1; cnt<=$NUM_SLAVES; cnt=cnt+1 )); do
	echo "$SLAVE_NAME_PREFIX$cnt ansible_port=22" | tee -a $LOCAL_HOSTS_FILE
done

echo "" >> $LOCAL_HOSTS_FILE

#########################################################################################################


# cd to 
# /home/ansible/ansible/hadoop1-playbooks/local_scripts 
# or 
# /home/ansible/ansible/hadoop2-playbooks/local_scripts

cd /home/ansible/ansible/hadoop"$HADOOP_MAJOR_VERSION"-playbooks/local_scripts

# execute high level ansible playbook scripts to install and start hadoop
./1-run-compressed-file-setup-playbook.sh 	$HADOOP_VERSION $MASTER_NAME $SLAVE_NAME_PREFIX | tee -a /tmp/hadoop-install-script1.log
./2-run-deploy-playbook.sh 			$HADOOP_VERSION $MASTER_NAME $SLAVE_NAME_PREFIXN | tee -a /tmp/hadoop-install-script2.log
./3-run-create-conf-master-playbook.sh 		$HADOOP_VERSION $MASTER_NAME $SLAVE_NAME_PREFIX | tee -a /tmp/hadoop-install-script3.log
./4-run-set-2nn-ssh-playbook.sh 		$HADOOP_VERSION $MASTER_NAME $SLAVE_NAME_PREFIX | tee -a /tmp/hadoop-install-script4.log
./5-run-format-playbook.sh 			$HADOOP_VERSION $MASTER_NAME $SLAVE_NAME_PREFIX | tee -a /tmp/hadoop-install-script5.log
./6-run-boa-setup-playbook.sh 			$HADOOP_VERSION $MASTER_NAME $SLAVE_NAME_PREFIX | tee -a /tmp/hadoop-install-script6.log
./7-run-start-stop-playbook.sh 			$HADOOP_VERSION start  $MASTER_NAME $SLAVE_NAME_PREFIX | tee -a /tmp/hadoop-install-script7.log

