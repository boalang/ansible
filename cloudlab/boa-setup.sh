#!/bin/bash
# Purpose
# To install additional items related to boa

MASTER_NAME=$1
PATH_TO_ANSIBLE_DIR=$2
PATH_TO_BOA_DIR=$PATH_TO_ANSIBLE_DIR/boa

# create link to ansible.cfg file
ln -s $PATH_TO_ANSIBLE_DIR/ansible.cfg $PATH_TO_BOA_DIR/ansible.cfg

cd $PATH_TO_BOA_DIR
ansible-playbook $PATH_TO_BOA_DIR/setup-boa.yml | tee -a /tmp/boa.log



