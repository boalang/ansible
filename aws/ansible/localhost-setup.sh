#!/bin/bash
# Purpose:
# Setup script to prepare localhost for interaction with aws using Ansible and boto3.

func_update_system(){

	echo ""
	echo "apt-get update"
	echo ""
	apt-get update

}

func_install_python(){

	echo ""
	echo "apt-get python"
	echo ""
	apt-get install -y python

	# echo ""
	# echo "apt-get python3"
	# echo ""
	# apt-get install -y python3
}

func_install_boto3(){

	echo ""
	echo "apt-get python-boto"
	echo ""
	apt-get install -y python-boto

	# echo ""
	# echo "apt-get python-boto3"
	# echo ""
	# apt-get install -y python-boto3
	
}

func_install_ansible_software(){

	# I was getting some errors when using Ansible 2.0 related to boto3 not found.
	# I tried various approached, but the biggest help was simply using the current version 2.5.2

	# This won't effect the previously written code, because that all runs on the instance in the various cloud environments (CloudLab and aws).  The update to 2.5.2 was to accomodate the use of Ansible with aws.

	func_update_system

	echo ""
	echo "apt-get install -y software-properties-common"
	apt-get install -y software-properties-common
	echo ""

	echo ""
	echo "apt-add-repository -y ppa:ansible/ansible"
	apt-add-repository -y ppa:ansible/ansible
	echo ""

	func_update_system

	echo ""
	echo "apt-get install -y ansible=2.5.2-1ppa~xenial"
	apt-get install -y ansible=2.5.2-1ppa~xenial

}

# run
func_update_system
func_install_python
func_install_boto3
func_install_ansible_software