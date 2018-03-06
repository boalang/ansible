#!/bin/bash
# Purpose
# To install additional items related to boa

MASTER_NAME=$1
PATH_TO_ANSIBLE_DIR=$2
PATH_TO_BOA_DIR=$PATH_TO_ANSIBLE_DIR/boa
BOA_LOG_FILE=/tmp/boa.log

# create link to ansible.cfg file
ln -s $PATH_TO_ANSIBLE_DIR/ansible.cfg $PATH_TO_BOA_DIR/ansible.cfg

cd $PATH_TO_BOA_DIR

ansible-playbook setup-boa.yml --extra-vars "master_name=$MASTER_NAME" | tee -a $BOA_LOG_FILE


