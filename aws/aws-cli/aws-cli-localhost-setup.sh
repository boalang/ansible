#!/bin/bash

# author: brian sigurdson, bsigurd@bgsu.edu
# Purpose
# aws-cli setup script for localhost

# Assumptions
# run as root


echo ""
echo "apt-get update"
echo ""
apt-get update

echo ""
echo "apt-get install -y python"
echo ""
apt-get install -y python

echo ""
echo "apt-get install -y python-pip"
echo ""
apt-get install -y python-pip

# echo ""
# echo "apt-get python3"
# echo ""
# apt-get install -y python3

# pip install awscli --upgrade --user

echo ""
echo "apt-get install -y awscli"
echo ""
apt-get install -y awscli