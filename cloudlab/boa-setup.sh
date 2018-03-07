#!/bin/bash
# Purpose
# To install additional items related to boa

MASTER_NAME=$1
PATH_TO_ANSIBLE_DIR=$2
PATH_TO_BOA_DIR=$PATH_TO_ANSIBLE_DIR/boa

# create link to ansible.cfg file
ln -s $PATH_TO_ANSIBLE_DIR/ansible.cfg $PATH_TO_BOA_DIR/ansible.cfg

#echo "MASTER_NAME=$MASTER_NAME" >> /tmp/boa1.log
#echo "PATH_TO_BOA_DIR=$PATH_TO_BOA_DIR" >> /tmp/boa1.log

#cat /home/ansible/ansible/local_hosts/hosts >> /tmp/boa3.log
#cat /home/ansible/ansible/ansible.cfg >> /tmp/boa4.log

cd $PATH_TO_BOA_DIR
ansible-playbook $PATH_TO_BOA_DIR/setup-boa.yml | tee -a /tmp/boa.log

