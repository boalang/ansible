#/bin/bash

# Purpose
# To teardown boa on aws

# NOTE: do not change the following access key names, as aws-cli will look for these specific environment variable names when running the script below.  
export AWS_ACCESS_KEY_ID=$(grep -F 'aws_access_key_id' ../common-input/aws-cred.yml | cut -d: -f2)
export AWS_SECRET_ACCESS_KEY=$(grep -F 'aws_secret_access_key' ../common-input/aws-cred.yml | cut -d: -f2)

AWS_REGION=$(grep -F 'aws_region' ../common-input/aws-vars.yml | cut -d: -f2)

# these variable facilitate writing various identifiers (vpc, igw, subnets, ...) to files, so that they can be retrieved by the shutdown script.
INPUT_OUTPUT_FILES=./input-output
VPC_INFO_FILE=$INPUT_OUTPUT_FILES/vpc-info.txt
VPC_ID_FILE=$INPUT_OUTPUT_FILES/vpc-id.txt
VPC_ID=$(head -n 1 $VPC_ID_FILE)

IGW_INFO_FILE=$INPUT_OUTPUT_FILES/igw-info.txt
IGW_ID_FILE=$INPUT_OUTPUT_FILES/igw-id.txt
IGW_ID=$(head -n 1 $IGW_ID_FILE)



###########################################################################################
# detach to igw from vpc and delete
aws ec2 detach-internet-gateway --region $AWS_REGION --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
sleep 3
aws ec2 delete-internet-gateway --region $AWS_REGION --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

###########################################################################################
# create public subnet

###########################################################################################
# create private subnet

###########################################################################################
# create bastion host

###########################################################################################
# create nat gateway

###########################################################################################
# create public route table

###########################################################################################
# create private route table

###########################################################################################
# create slave security group

###########################################################################################
# create head security group

###########################################################################################
# create .pem file (if it doesn't already exist)

###########################################################################################
# create slaves

###########################################################################################
# create head


###########################################################################################
# remove vpc
aws ec2 delete-vpc --region $AWS_REGION --vpc-id $VPC_ID