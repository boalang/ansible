#!/bin/bash
# Purpose
# To install Drupal with LAMP
#
# The tutorial on https://lakshminp.com/just-enough-ansible-drupal covers using Ansible
# to install Drupal 7, mysql, PHP7.0, apache
#
# The tutorial code can be found in links with the tutorial and 
# also at https://github.com/badri/drupal-ansible/

MASTER_NAME=$1
PATH_TO_CL_ANSIBLE=$2
PATH_TO_ANSIBLE_DIR=$3
LOCAL_HOSTS_FILE=$PATH_TO_ANSIBLE_DIR/local_hosts/hosts
PATH_TO_DRUPAL_DIR=/home/ansible/ansible/drupal
DRUPAL_LOG_FILE=/tmp/drupal.log

# add drupal to the ansible hosts file
echo "[drupal]" | tee -a $LOCAL_HOSTS_FILE
echo "$MASTER_NAME ansible_port=22" | tee -a $LOCAL_HOSTS_FILE
echo "# port must match port variable defined in ./local_variable_files/hadoop-vars.yml" | tee -a $LOCAL_HOSTS_FILE

# create link to ansible.cfg file
ln -s $PATH_TO_ANSIBLE_DIR/ansible.cfg $PATH_TO_DRUPAL_DIR/roles/ansible.cfg
ln -s $PATH_TO_ANSIBLE_DIR/ansible.cfg $PATH_TO_DRUPAL_DIR/ansible.cfg

# stop here for now and run ansible playbooks by hand until debugged
#exit 1

cd $PATH_TO_ANSIBLE_DIR/drupal

ansible-playbook install-drupal.yml | tee -a $DRUPAL_LOG_FILE

