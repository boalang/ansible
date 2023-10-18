# Boa: Ansible

Ansible scripts for configuring a Boa-like cluster

## Installing Ansible

First, make sure you have [Ansible properly installed](https://docs.ansible.com/ansible/latest/installation_guide/index.html) on your system.  For anyone running an Ubuntu-based system, we also provide some helper scripts in the `ansible-setup` directory to help get Ansible installed on the head/worker nodes.

The installation also assumes you have a working Apache webserver on the head node, with PHP enabled.

Next, if you have not already, clone this repository onto your head node.

Then be sure to edit the file in `local_hosts/hosts` to list what hosts will perform what role.  The current config assumes the head node is named `head` and the worker nodes are named `boa-#`.

## Installing Hadoop

Boa works with Hadoop 1.2.1, but might move to Hadoop 2.x/3.x in the future.  As such, we provide playbooks for both flavors of Hadoop.

In the `hadoop1-playbooks/local_scripts` directory, there are several scripts to run.  Each is numbered in the order to run them.  Some of the scripts will install/configure Hadoop and only need run once.  Other scripts are provided to aid the admin in starting/stopping the Hadoop cluster (`7-run-start-stop-playbook.sh`, and the 86/87 scripts).

## Installing Boa requirements

You also need to install some Boa-specific scripts as well as Drupal.  To do so, run the Ansible playbooks in `drupal/install-drupal.yml` and `boa/setup-boa.yml`.

If everything is up and running, you should be able to access [the head node](http://head:80/boa/) and view a working Boa installation.
