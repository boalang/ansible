#!/bin/bash
# Purpose
# To install and start Hadoop
# Should be run as the user ansible and execute from /home/ansible

PATH_TO_ANSIBLE_DIR=/home/ansible/ansible
HADOOP_MAJOR_VERSION=$1
HADOOP_VERSION=$2
MASTER_NAME=$3
SLAVE_NAME_PREFIX=$4

#echo "HADOOOP_VERSION=$HADOOP_VERSION"
#echo "HADOOOP_MAJOR_VERSION=$HADOOP_MAJOR_VERSION"

# cd to 
# /home/ansible/ansible/hadoop1-playbooks/local_scripts 
# or 
# /home/ansible/ansible/hadoop2-playbooks/local_scripts

cd /home/ansible/ansible/hadoop"$HADOOP_MAJOR_VERSION"-playbooks/local_scripts

# execute high level ansible playbook scripts to install and start hadoop
./1-run-compressed-file-setup-playbook.sh 	$HADOOP_VERSION $MASTER_NAME $SLAVE_NAME_PREFIX | tee -a $PATH_TO_ANSIBLE_DIR/hadoop-install-script1.log
./2-run-deploy-playbook.sh 			$HADOOP_VERSION $MASTER_NAME $SLAVE_NAME_PREFIXN | tee -a $PATH_TO_ANSIBLE_DIR/hadoop-install-script2.log
./3-run-create-conf-master-playbook.sh 		$HADOOP_VERSION $MASTER_NAME $SLAVE_NAME_PREFIX | tee -a $PATH_TO_ANSIBLE_DIR/hadoop-install-script3.log
./4-run-set-2nn-ssh-playbook.sh 		$HADOOP_VERSION $MASTER_NAME $SLAVE_NAME_PREFIX| tee -a $PATH_TO_ANSIBLE_DIR/hadoop-install-script4.log
./5-run-format-playbook.sh 			$HADOOP_VERSION $MASTER_NAME $SLAVE_NAME_PREFIX | tee -a $PATH_TO_ANSIBLE_DIR/hadoop-install-script5.log
./6-run-boa-setup-playbook.sh 			$HADOOP_VERSION $MASTER_NAME $SLAVE_NAME_PREFIX| tee -a $PATH_TO_ANSIBLE_DIR/hadoop-install-script6.log
./7-run-start-stop-playbook.sh 			$HADOOP_VERSION start  $MASTER_NAME $SLAVE_NAME_PREFIX| tee -a $PATH_TO_ANSIBLE_DIR/hadoop-install-script7.log

